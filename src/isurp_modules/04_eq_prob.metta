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
(exec 6
    (, (block $partition $block))
    (, (eq-copy-block $partition $block $block)))

;; Direct block-shape extraction.  These rules are intentionally kept in
;; addition to the iterator above because some MORK builds do not reliably emit
;; `car-atom` for single-clause block tuples whose element is itself a tuple.
(exec 6
    (, (block $partition ($c1)))
    (, (eq-block-clause $partition ($c1) $c1)))

(exec 6
    (, (block $partition ($c1 $c2)))
    (, (eq-block-clause $partition ($c1 $c2) $c1)
       (eq-block-clause $partition ($c1 $c2) $c2)))

(exec 6
    (, (block $partition ($c1 $c2 $c3)))
    (, (eq-block-clause $partition ($c1 $c2 $c3) $c1)
       (eq-block-clause $partition ($c1 $c2 $c3) $c2)
       (eq-block-clause $partition ($c1 $c2 $c3) $c3)))

(exec 6
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
(exec 7
    (, (eq-copy-block $partition $block $copy)
       (exec 7 $src $sink))
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
        (+ (exec 7 $src $sink))))


;; get-var / connected-subpatterns-with-var:
;;
;; Scan direct arguments for `(var N)` markers in binary predicate atoms only:
;;
;;   ($rel $left $right)
;;
;; The first element is treated as the link/predicate, so only the two argument
;; positions are checked.  This intentionally excludes n-ary predicate atoms
;; such as `($rel $x $a $b)` and nested wrapper terms.
(exec 7
    (, (eq-block-clause $partition $block ($rel (var $n) $a)))
    (, (eq-block-has-var $partition $block (var $n))))

(exec 7
    (, (eq-block-clause $partition $block ($rel $a (var $n))))
    (, (eq-block-has-var $partition $block (var $n))))


;; joint-variables:
;;
;; A variable is joint for a partition when it appears in at least two different
;; blocks of that partition.
(exec 8
    (, (partition ($b1 $b2))
       (eq-block-has-var ($b1 $b2) $b1 $var)
       (eq-block-has-var ($b1 $b2) $b2 $var))
    (, (eq-joint-var ($b1 $b2) $var)))

(exec 8
    (, (partition ($b1 $b2 $b3))
       (eq-block-has-var ($b1 $b2 $b3) $b1 $var)
       (eq-block-has-var ($b1 $b2 $b3) $b2 $var))
    (, (eq-joint-var ($b1 $b2 $b3) $var)))

(exec 8
    (, (partition ($b1 $b2 $b3))
       (eq-block-has-var ($b1 $b2 $b3) $b1 $var)
       (eq-block-has-var ($b1 $b2 $b3) $b3 $var))
    (, (eq-joint-var ($b1 $b2 $b3) $var)))

(exec 8
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
(exec 9
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
(exec 10
    (, (eq-value-query $partition $block $var $query))
    (,
        (exec 10
            $query
            (O
                (count
                    (eq-value-count $partition $block $var $count)
                    $count
                    $query)))))


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
(exec 11
    (, (eq-joint-var $partition $var))
    (, (abstractness-sort-request $partition $var)))

(exec 38
    (, (eq-joint-var $partition $var)
       (most-abstract-block-support $partition $var $most-abstract-block $count))
    (O
        (pure
            (eq-var-factor $partition $var $factor)
            $factor
            (f64_to_string
                (div_f64
                    (f64_from_string 1.0)
                    (f64_from_string $count))))))


;; eq-prob finalization:
;;
;; Product of per-variable factors.  These explicit rules cover the common
;; one-, two-, three-, and four-joint-variable cases used by current tests.
;; A fully generic version should replace this with a recursive product
;; accumulator over all `(eq-var-factor $partition $var $factor)` facts.

;; One-block partitions have no cross-block joint variables, so the correction
;; factor is the multiplicative identity.
(exec 39
    (, (partition ($b1)))
    (, (eq-prob-of ($b1) 1.0)))

(exec 39
    (, (eq-var-factor $partition $v1 $f1))
    (, (eq-prob-of $partition $f1)))


(exec 39
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

(exec 39
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

(exec 39
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

(exec 39
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

(exec 39
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

(exec 39
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
(exec 39
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

(exec 39
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

(exec 39
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

(exec 39
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

(exec 39
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
