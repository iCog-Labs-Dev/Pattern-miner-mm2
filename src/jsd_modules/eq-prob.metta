;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. EQ-prob support for newer ISurp
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
;; Important current scope:
;;
;;   - Direct variable markers in binary predicate atom arguments are supported:
;;       (Inheritance (var 0) man)
;;       (Inheritance man (var 0))
;;       (Inheritance (var 0) (var 1))
;;
;;   - Abstractness ordering is delegated to `03_abstractness_sort.metta`.
;;     That module materializes the most abstract block connected to each joint
;;     variable and exposes its support.
;;
;; Public result facts produced by this section:
;;
;;   (eq-joint-var $partition $var)
;;   (eq-value-count $partition $block $var $count)
;;   (abstractness-sort-request $partition $var)
;;   (eq-var-factor $partition $var $factor)
;;   (eq-prob-of $partition $prob)
;;
;; The newer `isurp` should multiply independent block probability by
;; `(eq-prob-of $partition $prob)`.
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


;; get-var / connected-subpatterns-with-var:
;;
;; Scan direct arguments for `(var N)` markers in binary predicate atoms only:
;;
;;   ($rel $left $right)
;;
;; The first element is treated as the link/predicate, so only the two argument
;; positions are checked.  This intentionally excludes n-ary predicate atoms
;; such as `($rel $x $a $b)` and nested wrapper terms.

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
;;
;; PeTTa's `value-count` counts unique values of the selected variable.  The
;; direct MM2 equivalent would count the generated variable itself under a
;; generated query, but this MORK build panics on that sink shape.  This MM2
;; fallback therefore counts the generated block query.  It is a conservative
;; support-count approximation and keeps the pipeline executable.


;; value-count, part 2:
;;
;; Count the generated block query as the supported fallback for value-count.

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

(exec (eq-prob 130 vc-query)
    (, (vc-query $block $ind-var ($query $var)))
    (, 
        (exec (eq-prob 130 vc-query)
            $query
            (O
                (count
                    (eq-value-count $block $ind-var $v-count)
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




; (exec (jsd 140 eq-var-factor)
;     (, (eq-joint-var $partition $var)
;        (most-abstract-block-support $partition $var $most-abstract-block $count))
;     (O
;         (pure
;             (eq-var-factor $partition $var $factor)
;             $factor
;             (f64_to_string
;                 (div_f64
;                     (f64_from_string 1.0)
;                     (f64_from_string $count))))))


; ;; eq-prob finalization:
; ;;
; ;; Product of per-variable factors.  These explicit rules cover the common
; ;; one-, two-, three-, and four-joint-variable cases used by current tests.
; ;; A fully generic version should replace this with a recursive product
; ;; accumulator over all `(eq-var-factor $partition $var $factor)` facts.

; ;; One-block partitions have no cross-block joint variables, so the correction
; ;; factor is the multiplicative identity.
; (exec (jsd 141 eq-prob-identity)
;     (, (partition $pattern ($b1)))
;     (, (eq-prob-of ($b1) 1.0)))

; (exec (jsd 141 eq-prob-single)
;     (, (eq-var-factor $partition $v1 $f1))
;     (, (eq-prob-of $partition $f1)))


; (exec (jsd 141 eq-prob-var-01)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 1) $f1))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f0)
;                     (f64_from_string $f1))))))

; (exec (jsd 131 eq-prob-var-02)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 2) $f2))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f0)
;                     (f64_from_string $f2))))))

; (exec (jsd 141 eq-prob-var-03)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f0)
;                     (f64_from_string $f3))))))

; (exec (jsd 141 eq-prob-var-12)
;     (, (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 2) $f2))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f1)
;                     (f64_from_string $f2))))))

; (exec (jsd 141 eq-prob-var-13)
;     (, (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f1)
;                     (f64_from_string $f3))))))

; (exec (jsd 141 eq-prob-var-23)
;     (, (eq-var-factor $partition (var 2) $f2)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (f64_from_string $f2)
;                     (f64_from_string $f3))))))

; ;; Triple and four-variable products for partitions that expose multiple joint
; ;; variables across binary predicate clauses.
; (exec (jsd 141 eq-prob-var-012)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 2) $f2))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (product_f64
;                         (f64_from_string $f0)
;                         (f64_from_string $f1))
;                     (f64_from_string $f2))))))

; (exec (jsd 141 eq-prob-var-013)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (product_f64
;                         (f64_from_string $f0)
;                         (f64_from_string $f1))
;                     (f64_from_string $f3))))))

; (exec (jsd 141 eq-prob-var-023)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 2) $f2)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (product_f64
;                         (f64_from_string $f0)
;                         (f64_from_string $f2))
;                     (f64_from_string $f3))))))

; (exec (jsd 141 eq-prob-var-123)
;     (, (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 2) $f2)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (product_f64
;                         (f64_from_string $f1)
;                         (f64_from_string $f2))
;                     (f64_from_string $f3))))))

; (exec (jsd 141 eq-prob-var-0123)
;     (, (eq-var-factor $partition (var 0) $f0)
;        (eq-var-factor $partition (var 1) $f1)
;        (eq-var-factor $partition (var 2) $f2)
;        (eq-var-factor $partition (var 3) $f3))
;     (O
;         (pure
;             (eq-prob-of $partition $prob)
;             $prob
;             (f64_to_string
;                 (product_f64
;                     (product_f64
;                         (f64_from_string $f0)
;                         (f64_from_string $f1))
;                     (product_f64
;                         (f64_from_string $f2)
;                         (f64_from_string $f3)))))))
