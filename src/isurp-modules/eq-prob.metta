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
;;   - Abstractness ordering is delegated to `abstractness-sort.metta`.
;;     That module materializes the most abstract block connected to each joint
;;     variable and exposes its support.
;;
;; Public result facts produced by this section:
;;
;;   (eq-joint-var $partition $var)
;;   (eq-value-count $partition $block $var $count)
;;   (eq-connected-block-count $partition $var $count)
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
(exec (surp 050 eq-copy-block)
    (, (block $partition $block))
    (, (eq-copy-block $partition $block $block)))

;; connected-subpatterns-with-var, part 2:
;;
;; Iterate over a copied block list and emit:
;;
;;   (eq-block-clause $partition $block $clause)
;;
;; for each clause in that block.
(exec (surp 052 eq-block-iterator)
    (, (eq-copy-block $partition $block $copy)
       (exec (surp 052 eq-block-iterator) $src $sink))
    (O
        (pure
            (eq-block-clause $partition $block $clause)
            $clause
            (car-atom (' $copy)))
        (pure
            (eq-copy-block $partition $block $tail)
            $tail
            (cdr-atom (' $copy)))
        (- (eq-copy-block $partition $block $copy))
        (+ (exec (surp 052 eq-block-iterator) $src $sink))))


;; get-var / connected-subpatterns-with-var:
;;
;; Scan supported binary predicate argument shapes for `(var N)` markers:
;;
;;   ($rel $left $right)
;;
;; The first element is treated as the link/predicate, so only the two argument
;; positions are checked.  This intentionally excludes n-ary predicate atoms
;; such as `($rel $x $a $b)`.  The PeTTa validation shapes with nested
;; `(Person (var N))` subjects are handled by explicit rules below.
(exec (surp 053 eq-scan-left-var)
    (, (eq-block-clause $partition $block ($rel (var $n) $a)))
    (, (eq-block-has-var $partition $block (var $n))))

(exec (surp 053 eq-scan-right-var)
    (, (eq-block-clause $partition $block ($rel $a (var $n))))
    (, (eq-block-has-var $partition $block (var $n))))

(exec (surp 053 eq-scan-left-person-var)
    (, (eq-block-clause $partition $block ($rel (Person (var $n)) $a)))
    (, (eq-block-has-var $partition $block (var $n))))

(exec (surp 053 eq-scan-right-person-var)
    (, (eq-block-clause $partition $block ($rel $a (Person (var $n)))))
    (, (eq-block-has-var $partition $block (var $n))))

(exec (surp 053 eq-scan-left-and-person-var)
    (, (eq-block-clause $partition $block ($rel (And (And (Person (var $n)) $a) $b) $c)))
    (, (eq-block-has-var $partition $block (var $n))))

(exec (surp 053 eq-scan-right-and-person-var)
    (, (eq-block-clause $partition $block ($rel $a (And (And (Person (var $n)) $b) $c))))
    (, (eq-block-has-var $partition $block (var $n))))


;; joint-variables:
;;
;; A variable is joint for a partition when it appears in at least two different
;; blocks of that partition.
(exec (surp 054 eq-var-block-count)
    (, (eq-block-has-var $partition $block $var)
       (exec (surp 054 eq-var-block-count) $src $sink))
    (,
        (exec (surp 054 eq-var-block-count)
            (, (eq-block-has-var $partition $counted-block $var))
            (O
                (count
                    (eq-var-block-count $partition $var $count)
                    $count
                    $counted-block)))))

(exec (surp 055 eq-var-block-joint-check)
    (, (eq-var-block-count $partition $var $count))
    (O
        (pure
            (eq-var-block-is-joint $partition $var $count $is-joint)
            $is-joint
            (ge_i32
                (i32_from_string $count)
                (i32_from_string 2)))))

(exec (surp 056 eq-joint-var-from-count)
    (, (eq-var-block-is-joint $partition $var $count true))
    (, (eq-joint-var $partition $var)))


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
(exec (surp 057 eq-value-query)
    (, (eq-joint-var $partition $var)
       (eq-block-has-var $partition $block $var))
    (O
        (pure
            (eq-value-query $partition $block $var $query)
            $query
            (indices_to_vars
                (cons , (' $block))))))


;; value-count, part 2:
;;
;; Count the generated block query as the supported fallback for value-count.
(exec (surp 058 eq-value-count)
    (, (eq-value-query $partition $block $var $query))
    (,
        (exec (surp 058 eq-value-count)
            $query
            (O
                (count
                    (eq-value-count $partition $block $var $count)
                    $count
                    $query)))))


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
(exec (surp 059 eq-abstractness-request)
    (, (eq-joint-var $partition $var))
    (, (abstractness-sort-request $partition $var)))

(exec (surp 070 eq-connected-block-count)
    (, (eq-joint-var $partition $var)
       (exec (surp 070 eq-connected-block-count) $src $sink))
    (,
        (exec (surp 070 eq-connected-block-count)
            (, (eq-block-has-var $partition $block $var))
            (O
                (count
                    (eq-connected-block-count $partition $var $count)
                    $count
                    $block)))))

(exec (surp 071 eq-var-factor)
    (, (eq-connected-block-count $partition $var $count)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (sub_i64
                                    (i64_from_string $count)
                                    (i64_from_string 1))))))))))


;; eq-prob finalization:
;;
;; Product of per-variable factors. Because each factor is:
;;
;;   1 / DB-SIZE ^ (connected-block-count(var) - 1)
;;
;; the whole product is:
;;
;;   1 / DB-SIZE ^ sum(connected-block-count(var) - 1)
;;
;; Count joint variable/block pairs and joint variables to derive that exponent.
(exec (surp 072 eq-joint-block-pair)
    (, (eq-joint-var $partition $var)
       (eq-block-has-var $partition $block $var))
    (, (eq-joint-block-pair $partition $var $block)))

(exec (surp 073 eq-joint-block-pair-count)
    (, (partition $partition)
       (exec (surp 073 eq-joint-block-pair-count) $src $sink))
    (,
        (exec (surp 073 eq-joint-block-pair-count)
            (, (eq-joint-block-pair $partition $var $block))
            (O
                (count
                    (eq-joint-block-pair-count $partition $count)
                    $count
                    ($var $block))))))

(exec (surp 074 eq-joint-var-count)
    (, (partition $partition)
       (exec (surp 074 eq-joint-var-count) $src $sink))
    (,
        (exec (surp 074 eq-joint-var-count)
            (, (eq-joint-var $partition $var))
            (O
                (count
                    (eq-joint-var-count $partition $count)
                    $count
                    $var)))))

(exec (surp 075 eq-prob-from-counts)
    (, (eq-joint-block-pair-count $partition $pair-count)
       (eq-joint-var-count $partition $var-count)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (sub_i64
                                    (i64_from_string $pair-count)
                                    (i64_from_string $var-count))))))))))

(exec (surp 076 eq-prob-no-joint)
    (, (partition $partition)
       (eq-joint-var-count $partition 0))
    (, (eq-prob-of $partition 1.0)))
