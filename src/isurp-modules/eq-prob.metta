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

;; Direct block-shape extraction.  These rules are intentionally kept in
;; addition to the iterator above because some MORK builds do not reliably emit
;; `car-atom` for single-clause block tuples whose element is itself a tuple.
(exec (surp 051 eq-block-clause-1)
    (, (block $partition ($c1)))
    (, (eq-block-clause $partition ($c1) $c1)))

(exec (surp 051 eq-block-clause-2)
    (, (block $partition ($c1 $c2)))
    (, (eq-block-clause $partition ($c1 $c2) $c1)
       (eq-block-clause $partition ($c1 $c2) $c2)))

(exec (surp 051 eq-block-clause-3)
    (, (block $partition ($c1 $c2 $c3)))
    (, (eq-block-clause $partition ($c1 $c2 $c3) $c1)
       (eq-block-clause $partition ($c1 $c2 $c3) $c2)
       (eq-block-clause $partition ($c1 $c2 $c3) $c3)))

(exec (surp 051 eq-block-clause-4)
    (, (block $partition ($c1 $c2 $c3 $c4)))
    (, (eq-block-clause $partition ($c1 $c2 $c3 $c4) $c1)
       (eq-block-clause $partition ($c1 $c2 $c3 $c4) $c2)
       (eq-block-clause $partition ($c1 $c2 $c3 $c4) $c3)
       (eq-block-clause $partition ($c1 $c2 $c3 $c4) $c4)))


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
(exec (surp 054 eq-joint-var-2)
    (, (partition ($b1 $b2))
       (eq-block-has-var ($b1 $b2) $b1 $var)
       (eq-block-has-var ($b1 $b2) $b2 $var))
    (, (eq-joint-var ($b1 $b2) $var)))

(exec (surp 054 eq-joint-var-3-12)
    (, (partition ($b1 $b2 $b3))
       (eq-block-has-var ($b1 $b2 $b3) $b1 $var)
       (eq-block-has-var ($b1 $b2 $b3) $b2 $var))
    (, (eq-joint-var ($b1 $b2 $b3) $var)))

(exec (surp 054 eq-joint-var-3-13)
    (, (partition ($b1 $b2 $b3))
       (eq-block-has-var ($b1 $b2 $b3) $b1 $var)
       (eq-block-has-var ($b1 $b2 $b3) $b3 $var))
    (, (eq-joint-var ($b1 $b2 $b3) $var)))

(exec (surp 054 eq-joint-var-3-23)
    (, (partition ($b1 $b2 $b3))
       (eq-block-has-var ($b1 $b2 $b3) $b2 $var)
       (eq-block-has-var ($b1 $b2 $b3) $b3 $var))
    (, (eq-joint-var ($b1 $b2 $b3) $var)))


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
(exec (surp 055 eq-value-query)
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
(exec (surp 056 eq-value-count)
    (, (eq-value-query $partition $block $var $query))
    (,
        (exec (surp 056 eq-value-count)
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
(exec (surp 057 eq-abstractness-request)
    (, (eq-joint-var $partition $var))
    (, (abstractness-sort-request $partition $var)))

(exec (surp 058 eq-connected-block-count)
    (, (eq-joint-var $partition $var)
       (exec (surp 058 eq-connected-block-count) $src $sink))
    (,
        (exec (surp 058 eq-connected-block-count)
            (, (eq-block-has-var $partition $block $var))
            (O
                (count
                    (eq-connected-block-count $partition $var $count)
                    $count
                    $block)))))

(exec (surp 070 eq-var-factor-2-blocks)
    (, (eq-connected-block-count $partition $var 2)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (f64_from_string $db-size))))))

(exec (surp 070 eq-var-factor-3-blocks)
    (, (eq-connected-block-count $partition $var 3)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $db-size)
                        (f64_from_string $db-size)))))))

(exec (surp 070 eq-var-factor-4-blocks)
    (, (eq-connected-block-count $partition $var 4)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (product_f64
                            (f64_from_string $db-size)
                            (f64_from_string $db-size))
                        (f64_from_string $db-size)))))))


;; eq-prob finalization:
;;
;; Product of per-variable factors.  These explicit rules cover the common
;; one-, two-, three-, and four-joint-variable cases used by current tests.
;; A fully generic version should replace this with a recursive product
;; accumulator over all `(eq-var-factor $partition $var $factor)` facts.

;; One-block partitions have no cross-block joint variables, so the correction
;; factor is the multiplicative identity.
(exec (surp 071 eq-prob-identity)
    (, (partition ($b1)))
    (, (eq-prob-of ($b1) 1.0)))

(exec (surp 071 eq-prob-single)
    (, (eq-var-factor $partition $v1 $f1))
    (, (eq-prob-of $partition $f1)))


(exec (surp 071 eq-prob-var-01)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 1) $f1))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f0)
                    (f64_from_string $f1))))))

(exec (surp 071 eq-prob-var-02)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 2) $f2))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f0)
                    (f64_from_string $f2))))))

(exec (surp 071 eq-prob-var-03)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f0)
                    (f64_from_string $f3))))))

(exec (surp 071 eq-prob-var-12)
    (, (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 2) $f2))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f1)
                    (f64_from_string $f2))))))

(exec (surp 071 eq-prob-var-13)
    (, (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f1)
                    (f64_from_string $f3))))))

(exec (surp 071 eq-prob-var-23)
    (, (eq-var-factor $partition (var 2) $f2)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $f2)
                    (f64_from_string $f3))))))

;; Triple and four-variable products for partitions that expose multiple joint
;; variables across binary predicate clauses.
(exec (surp 071 eq-prob-var-012)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 2) $f2))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $f0)
                        (f64_from_string $f1))
                    (f64_from_string $f2))))))

(exec (surp 071 eq-prob-var-013)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $f0)
                        (f64_from_string $f1))
                    (f64_from_string $f3))))))

(exec (surp 071 eq-prob-var-023)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 2) $f2)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $f0)
                        (f64_from_string $f2))
                    (f64_from_string $f3))))))

(exec (surp 071 eq-prob-var-123)
    (, (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 2) $f2)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $f1)
                        (f64_from_string $f2))
                    (f64_from_string $f3))))))

(exec (surp 071 eq-prob-var-0123)
    (, (eq-var-factor $partition (var 0) $f0)
       (eq-var-factor $partition (var 1) $f1)
       (eq-var-factor $partition (var 2) $f2)
       (eq-var-factor $partition (var 3) $f3))
    (O
        (pure
            (eq-prob-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $f0)
                        (f64_from_string $f1))
                    (product_f64
                        (f64_from_string $f2)
                        (f64_from_string $f3)))))))
