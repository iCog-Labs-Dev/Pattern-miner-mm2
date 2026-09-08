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
;;   - Indexed variables are discovered by walking each clause argument.  The
;;     relation/operator position is skipped, and every argument is scanned
;;     recursively for `(var N)` markers.
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
;; Convert each clause into its argument tuple.  `cdr-atom` skips the
;; relation/operator and leaves every real argument to be scanned.
(exec (surp 053 eq-clause-args-start)
    (, (eq-block-clause $partition $block $clause))
    (O
        (pure
            (eq-clause-args $partition $block $clause $args)
            $args
            (cdr-atom (' $clause)))))

;; Walk the clause argument tuple and emit one `eq-clause-arg` fact per
;; argument.
(exec (surp 054 eq-clause-args-walk)
    (, (eq-clause-args $partition $block $clause $remaining)
       (exec (surp 054 eq-clause-args-walk) $src $sink))
    (O
        (pure
            (eq-clause-arg $partition $block $clause $arg)
            $arg
            (car-atom (' $remaining)))
        (pure
            (eq-clause-args $partition $block $clause $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (eq-clause-args $partition $block $clause $remaining))
        (+ (exec (surp 054 eq-clause-args-walk) $src $sink))))

(exec (surp 055 eq-clause-arg-vars)
    (, (eq-clause-arg $partition $block $clause $arg))
    (O
        (pure
            (eq-clause-arg-vars $partition $block $clause $arg $vars)
            $vars
            (indexed_vars_in_expr (' $arg)))))

(exec (surp 056 eq-clause-arg-vars-walk)
    (, (eq-clause-arg-vars $partition $block $clause $arg $remaining)
       (exec (surp 056 eq-clause-arg-vars-walk) $src $sink))
    (O
        (pure
            (eq-block-has-var $partition $block $var)
            $var
            (car-atom (' $remaining)))
        (pure
            (eq-clause-arg-vars $partition $block $clause $arg $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (eq-clause-arg-vars $partition $block $clause $arg $remaining))
        (+ (exec (surp 056 eq-clause-arg-vars-walk) $src $sink))))


;; joint-variables:
;;
;; A variable is joint for a partition when it appears in at least two different
;; blocks of that partition.
(exec (surp 062 eq-var-block-count)
    (, (eq-block-has-var $partition $block $var))
    (O
        (count
            (eq-var-block-count $partition $var $count)
            $count
            $block)))

(exec (surp 080 eq-var-block-joint-check)
    (, (eq-var-block-count $partition $var $count))
    (O
        (pure
            (eq-var-block-is-joint $partition $var $count $is-joint)
            $is-joint
            (ge_i32
                (i32_from_string $count)
                (i32_from_string 2)))))

(exec (surp 081 eq-joint-var-from-count)
    (, (eq-var-block-is-joint $partition $var $count true))
    (, (eq-joint-var $partition $var)))

(exec (surp 081 eq-any-var-from-count)
    (, (eq-var-block-count $partition $var $count))
    (, (eq-any-var $partition $var)))

(exec (surp 081 eq-non-joint-var-from-count)
    (, (eq-var-block-is-joint $partition $var $count false))
    (, (eq-non-joint-var $partition $var)))


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
(exec (surp 082 eq-value-query)
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
(exec (surp 083 eq-value-count)
    (, (eq-value-query $partition $block $var $query))
    (,
        (exec (surp 083 eq-value-count)
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
(exec (surp 084 eq-abstractness-request)
    (, (eq-joint-var $partition $var))
    (, (abstractness-sort-request $partition $var)))

(exec (surp 085 eq-connected-block-count)
    (, (eq-joint-var $partition $var)
       (exec (surp 085 eq-connected-block-count) $src $sink))
    (,
        (exec (surp 085 eq-connected-block-count)
            (, (eq-block-has-var $partition $block $var))
            (O
                (count
                    (eq-connected-block-count $partition $var $count)
                    $count
                    $block)))))

(exec (surp 086 eq-var-factor)
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
(exec (surp 086 eq-joint-block-pair)
    (, (eq-joint-var $partition $var)
       (eq-block-has-var $partition $block $var))
    (, (eq-joint-block-pair $partition $var $block)))

(exec (surp 087 eq-joint-block-pair-count)
    (, (partition $partition)
       (exec (surp 087 eq-joint-block-pair-count) $src $sink))
    (,
        (exec (surp 087 eq-joint-block-pair-count)
            (, (eq-joint-block-pair $partition $var $block))
            (O
                (count
                    (eq-joint-block-pair-count $partition $count)
                    $count
                    ($var $block))))))

(exec (surp 087 eq-joint-var-count)
    (, (partition $partition)
       (exec (surp 087 eq-joint-var-count) $src $sink))
    (,
        (exec (surp 087 eq-joint-var-count)
            (, (eq-joint-var $partition $var))
            (O
                (count
                    (eq-joint-var-count $partition $count)
                    $count
                    $var)))))

(exec (surp 087 eq-any-var-count)
    (, (partition $partition)
       (exec (surp 087 eq-any-var-count) $src $sink))
    (,
        (exec (surp 087 eq-any-var-count)
            (, (eq-any-var $partition $var))
            (O
                (count
                    (eq-any-var-count $partition $count)
                    $count
                    $var)))))

(exec (surp 087 eq-non-joint-var-count)
    (, (partition $partition)
       (exec (surp 087 eq-non-joint-var-count) $src $sink))
    (,
        (exec (surp 087 eq-non-joint-var-count)
            (, (eq-non-joint-var $partition $var))
            (O
                (count
                    (eq-non-joint-var-count $partition $count)
                    $count
                    $var)))))

(exec (surp 088 eq-no-joint-check)
    (, (eq-any-var-count $partition $any-count)
       (eq-non-joint-var-count $partition $non-joint-count))
    (O
        (pure
            (eq-no-joint? $partition $is-no-joint)
            $is-no-joint
            (eq_i32
                (i32_from_string $any-count)
                (i32_from_string $non-joint-count)))))

(exec (surp 088 eq-prob-from-counts)
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

(exec (surp 089 eq-prob-no-joint)
    (, (partition $partition)
       (eq-no-joint? $partition true))
    (, (eq-prob-of $partition 1.0)))
