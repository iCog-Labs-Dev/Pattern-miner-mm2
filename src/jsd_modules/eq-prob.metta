;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eq-prob
;;
;; Source PeTTa function:
;;
;;   (eq-prob $partition $pattern $db)
;;
;; Source flow:
;;
;;   eq-prob
;;   -> joint-variables
;;   -> calculate-prob-for-vars
;;   -> connected-subpatterns-with-var
;;   -> sort-by-abstraction
;;   -> process-blocks
;;   -> value-count
;;
;; MM2 implementation style:
;;
;;   PeTTa recursion is translated into materialized facts.  The implementation
;;   below works on the indexed representation produced by `vars_to_indices`,
;;   where variables are represented as `(var 0)`, `(var 1)`, ...
;;
;;
;; Public result facts produced by this section:
;;
;;   (eq-joint-var $partition $var)
;;   (value-count $block $var $count)
;;   (abstractness-sort-request $partition $var)
;;   (eq-var-factor $partition $var $factor)
;;   (eq-prob-of $partition $prob)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; connected-subpatterns-with-var, part 1:
;;
;; Expand every block into individual clauses so variable scanning does not need
;; to know whether a block has one, two, or more clauses.


(exec (eq-prob 120 block-clause)
    (, (block $partition $block) (exec (eq-prob 120 block-clause) $src (O (pure $out $var (car $q)))))
    (O
        (pure
            (exec (eq-prob 120 block-clause) (,)
                (, (exec (eq-prob 120 block-clause) $src (O (pure $out $var (car (cdr $q))))) (block-clause $block $clause)))            
            $clause
            (car (' $block))
        )
    )
)

(exec (eq-prob 121 var-extract-request)
    (, (block-clause $block $clause))  
    (, (var-extract-request $clause 0 $clause))
)


;; ===========================================================================================================================================
;; ===========================================================================================================================================
;; Variable Extractor:
;;
;; This section recursively scans clause expressions to identify and track all
;; variable occurrences within each clause. The extraction process:
;;
;;   1. Initiates variable extraction for each clause via `var-extract-request`
;;      with position counter starting at 0 (tracking nesting level and order).
;;
;;   2. Recursively traverses clause structure (DEF rules 122-125), incrementing
;;      position for nested expressions and sequential elements, collecting 
;;      position info for each variable.
;;
;;   3. Uses `clause-values` to expose individual sub-expressions at each level,
;;      and `is-var` predicate to test if an expression is a variable marker.
;;
;;
;; POSITION NUMBERS EXPLAINED:
;;
;;   Position: A sequence of indices where each digit represents the index of an
;;   element at each nesting level in the expression tree. Traversal proceeds
;;   left-to-right, 1-indexed. Each digit selects which argument/element to
;;   navigate into at that level of nesting.
;;
;;   EXAMPLE:
;;   (Inheritance (And (And (Person Hessley) man) (Or human ugly)) 
;;                (Or (And human (var 0)) (And human (var 1))))
;;
;;   Variable (var 0) extraction:
;;     Position: 323
;;     - 3: Select 3rd element at top level: (Or (And human (var 0)) (And human (var 1)))
;;     - 2: Select 2nd element in that: (And human (var 0))
;;     - 3: Select 3rd element in that: (var 0)
;;   
;;   Variable (var 1) extraction:
;;     Position: 333
;;     - 3: Select 3rd element at top level: (Or (And human (var 0)) (And human (var 1)))
;;     - 3: Select 3rd element in that: (And human (var 1))
;;     - 3: Select 3rd element in that: (var 1)


(DEF (eq-prob 122 vars-extract)
    (, (var-extract-request $clause $depth $reduced-clause) 
        (exec (eq-prob 122 vars-extract) $src 
            (O (pure (exec (eq-prob 122 vars-extract) (,) 
                        (O (pure $out-pos $var-pos (i32_to_string $sum)) $exec $is-var)) $var (car $q)))))
    (O
        (pure
            (exec (eq-prob 122 vars-extract) (,)
                (O
                    (pure
                        (clause-values $clause $pos $expr)
                        $pos
                        (i32_to_string (sum_i32 (i32_from_string 1) (i32_from_string $depth)))
                    )

                    (+ (exec (eq-prob 122 vars-extract) $src 
                        (O (pure (exec (eq-prob 122 vars-extract) (,) 
                            (O (pure $out-pos $var-pos (i32_to_string (sum_i32 (i32_from_string 1) $sum))) $exec $is-var)) $var (car (cdr $q))))))

                    
                    (pure
                        (is-var $expr $is)
                        $is
                        (i8_to_string (is_var (' $expr)))
                    )
                )
            )            
            $expr
            (car (' $reduced-clause))
        )
    )
)
(DEF (eq-prob 123 vars-extract)
    (, (var-extract-request $clause $depth $reduced-clause))
    (O (- (var-extract-request $clause $depth $reduced-clause)))
)
(DEF (eq-prob 124 vars-extract)
    (, (clause-values $clause $depth $expr) (is-var $expr 1))
    (O (+ (var-in $expr $clause $depth)) (- (clause-values $clause $depth $expr)) (- (is-var $expr 1)))
)
(DEF (eq-prob 124 vars-extract)
    (, (clause-values $clause $depth $expr) (is-var $expr 0))
    (O 
        (pure
            (var-extract-request $clause $new-depth $expr)
            $new-depth
            (collapse_symbol (' ($depth 0)))
        )
        (- (clause-values $clause $depth $expr)) (- (is-var $expr 0)))
)

(exec (eq-prob 122 vars-extract)
    (, (DEF (eq-prob $priority $name) $src-def $sink-def) (exec (eq-prob 122 vars-extract) $src $sink))
    (, (exec (eq-prob $priority $name) $src-def $sink-def)
        (exec (eq-prob 125 vars-extract) 
            (, (var-extract-request $clause $depth $reduced-clause))
            (, (exec (eq-prob 122 vars-extract) $src $sink)))
    )
)

;; ===========================================================================================================================================
;; ===========================================================================================================================================


;; get-var / connected-subpatterns-with-var:

(exec (eq-prob 125 eq-scan-left-var)
    (, (var-in $var $clause $depth) (block-clause $block $clause) (block $partition $block))
    (, (eq-block-has-var $partition $block $var)))


;; joint-variables:
;;
;; A variable is joint for a partition when it appears in at least two different
;; blocks of that partition.

(exec (eq-prob 126 count-appearance)
    (, (eq-block-has-var $partition $block $var))
    (O
        (count
            (appears-in $var $partition $c)
            $c
            $block
        )
    )
)

(exec (eq-prob 127 check-num-appearance)
    (, (appears-in $var $partition $c))
    (O
        (pure
            (appears-ge-2 $var $partition $is)
            $is
            (ge_i64 (i64_from_string $c) (i64_from_string 2))
        )
    )
)

(exec (eq-prob 128 eq-joint-var)
    (, (appears-ge-2 $var $partition true))
    (, (eq-joint-var $partition $var))
)


;; value-count, part 1:
;;
;; Build a query and target value for each joint variable in each connected
;; block.

(exec (eq-prob 129 vc-query)
    (, (eq-block-has-var $partition $block $var))
    (O
        (pure
            (exec (eq-prob 129 vc-query) (,)
                (O
                    (pure
                        (vc-query $block $var $pair)
                        $pair
                        (indices_to_vars (' ($blk $var)))
                    )
                )
            )
            $blk
            (cons , (' $block))
        )
    )
)

;; value-count, part 2:

(exec (eq-prob 130 vc-query)
    (, (vc-query $block $ind-var ($query $var)))
    (, 
        (exec (eq-prob 130 vc-query)
            $query
            (O
                (count
                    (value-count $block $ind-var $v-count)
                    $v-count
                    $var
                )
            )
        )
    )
)



;; calculate-prob-for-vars / process-blocks:
;;
;; The PeTTa source sorts connected blocks by abstractness, then divides by the
;; value count/support of the previous more abstract block.  In this MM2 port,
;; `03_abstractness_sort.metta` performs the abstractness choice and writes:
;;
;;   (most-abstract-block-support $partition $var $block $count)
;;
;; This rule turns that count into the per-variable equality correction:
;;
;;   factor(var) = 1 / support(most abstract connected block)
(exec (eq-prob 131 eq-abstractness-request)
    (, (eq-joint-var $partition $var))
    (, (abstractness-sort-request $partition $var)))



;; calculate-prob-for-vars / process-blocks:
;;
;; The PeTTa source sorts connected blocks by abstractness, then walks every
;; additional connected block after the first one.  Each extra block adds one
;; equality correction.  If there is no earlier more-abstract block, PeTTa uses
;; the whole DB size as the denominator.
;;
;; In this MM2 port, `abstractness-sort.metta` still materializes:
;;
;;   (most-abstract-block-support $partition $var $block $count)
;;
;; for debugging and future exact value-count support.  The current PeTTa-like
;; executable path below uses the DB-size fallback and the number of connected
;; blocks:
;;
;;   factor(var) = 1 / DB-SIZE ^ (connected-block-count(var) - 1)

(exec (eq-prob 142 eq-var-factor)
    (, (eq-joint-var $partition $var) (INPUT DB-SIZE $db-size)
       (most-abstract-block-support $partition $var $most-abstract-block $count))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (powf_f64 (f64_from_string $db-size) (sub_f64 (f64_from_string $count) (f64_from_string 1))))))))



; ;; eq-prob finalization:
; ;;
; ;; Product of per-variable factors.  


(exec (eq-prob 143 max-var-index)
    (, (eq-joint-var $partition (var $num))) 
    (O 
        (fmax 
            (max-joint-var-index $partition $max) 
            $max 
            $num
        )
        (+ (eq-prob-of $partition 1))
    )
)


(exec (eq-prob 144 eq-prob)
    (, (eq-prob-of $partition $prod) (eq-var-factor $partition (var $n) $value) (max-joint-var-index $partition $n) (exec (eq-prob 144 eq-prob) $src $sink))
    (O (pure (eq-prob-of $partition $new-prod) $new-prod (f32_to_string (product_f32 (f32_from_string $value) (f32_from_string $prod))))
        (- (eq-prob-of $partition $prod))
        (pure (max-joint-var-index $partition $new-max) $new-max (i32_to_string (sub_i32 (i32_from_string $n) (i32_from_string 1))))
        (- (max-joint-var-index $partition $n))
        (- (max-joint-var-index $partition -1))
        
    )
)
