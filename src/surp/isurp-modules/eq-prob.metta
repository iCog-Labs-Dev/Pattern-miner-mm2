;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. EQ-prob support for newer ISurp
;;
;; Source PeTTa function:
;;
;;   (eq-prob $pattern $partition $pattern $db)
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
;;   (eq-joint-var $pattern $partition $var)
;;   (eq-value-count $pattern $partition $block $var $count)
;;   (eq-connected-block-count $pattern $partition $var $count)
;;   (abstractness-sort-request $pattern $partition $var)
;;   (eq-var-factor $pattern $partition $var $factor)
;;   (eq-prob-of $pattern $partition $prob)
;;
;; The newer `isurp` should multiply independent block probability by
;; `(eq-prob-of $pattern $partition $prob)`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; connected-subpatterns-with-var, part 1:
;;
;; Expand every block into individual clauses so variable scanning does not need
;; to know whether a block has one, two, or more clauses.
(exec (surp s050 eq-copy-block)
    (, (block $pattern $partition $block))
    (, (eq-copy-block $pattern $partition $block $block)))

;; connected-subpatterns-with-var, part 2:
;;
;; Iterate over a copied block list and emit:
;;
;;   (eq-block-clause $pattern $partition $block $clause)
;;
;; for each clause in that block.
(exec (surp s052 eq-block-iterator)
    (, (eq-copy-block $pattern $partition $block $copy)
       (exec (surp s052 eq-block-iterator) $src $sink))
    (O
        (pure
            (eq-block-clause $pattern $partition $block $clause)
            $clause
            (car-atom (' $copy)))
        (pure
            (eq-copy-block $pattern $partition $block $tail)
            $tail
            (cdr-atom (' $copy)))
        (- (eq-copy-block $pattern $partition $block $copy))
        (+ (exec (surp s052 eq-block-iterator) $src $sink))))


;; get-var / connected-subpatterns-with-var:
;;
;; Convert each clause into its argument tuple.  `cdr-atom` skips the
;; relation/operator and leaves every real argument to be scanned.
(exec (surp s053 eq-clause-args-start)
    (, (eq-block-clause $pattern $partition $block $clause))
    (O
        (pure
            (eq-clause-args $pattern $partition $block $clause $args)
            $args
            (cdr-atom (' $clause)))))

;; Walk the clause argument tuple and emit one `eq-clause-arg` fact per
;; argument.
(exec (surp s054 eq-clause-args-walk)
    (, (eq-clause-args $pattern $partition $block $clause $remaining)
       (exec (surp s054 eq-clause-args-walk) $src $sink))
    (O
        (pure
            (eq-clause-arg $pattern $partition $block $clause $arg)
            $arg
            (car-atom (' $remaining)))
        (pure
            (eq-clause-args $pattern $partition $block $clause $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (eq-clause-args $pattern $partition $block $clause $remaining))
        (+ (exec (surp s054 eq-clause-args-walk) $src $sink))))

(exec (surp s055 eq-clause-arg-vars)
    (, (eq-clause-arg $pattern $partition $block $clause $arg))
    (O
        (pure
            (eq-clause-arg-vars $pattern $partition $block $clause $arg $vars)
            $vars
            (indexed_vars_in_expr (' $arg)))))

(exec (surp s056 eq-clause-arg-vars-walk)
    (, (eq-clause-arg-vars $pattern $partition $block $clause $arg $remaining)
       (exec (surp s056 eq-clause-arg-vars-walk) $src $sink))
    (O
        (pure
            (eq-block-has-var $pattern $partition $block $var)
            $var
            (car-atom (' $remaining)))
        (pure
            (eq-clause-arg-vars $pattern $partition $block $clause $arg $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (eq-clause-arg-vars $pattern $partition $block $clause $arg $remaining))
        (+ (exec (surp s056 eq-clause-arg-vars-walk) $src $sink))))


;; joint-variables:
;;
;; A variable is joint for a partition when it appears in at least two different
;; blocks of that partition.
(exec (surp s062 eq-var-block-count)
    (, (eq-block-has-var $pattern $partition $block $var))
    (O
        (count
            (eq-var-block-count $pattern $partition $var $count)
            $count
            $block)))

(exec (surp s080 eq-var-block-joint-check)
    (, (eq-var-block-count $pattern $partition $var $count))
    (O
        (pure
            (eq-var-block-is-joint $pattern $partition $var $count $is-joint)
            $is-joint
            (ge_i32
                (i32_from_string $count)
                (i32_from_string 2)))))

(exec (surp s081 eq-joint-var-from-count)
    (, (eq-var-block-is-joint $pattern $partition $var $count true))
    (, (eq-joint-var $pattern $partition $var)))

(exec (surp s081 eq-any-var-from-count)
    (, (eq-var-block-count $pattern $partition $var $count))
    (, (eq-any-var $pattern $partition $var)))

(exec (surp s081 eq-non-joint-var-from-count)
    (, (eq-var-block-is-joint $pattern $partition $var $count false))
    (, (eq-non-joint-var $pattern $partition $var)))


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
(exec (surp s082 eq-value-query)
    (, (eq-joint-var $pattern $partition $var)
       (eq-block-has-var $pattern $partition $block $var))
    (O
        (pure
            (eq-value-query $pattern $partition $block $var $query)
            $query
            (indices_to_vars
                (cons , (' $block))))))


;; value-count, part 2:
;;
;; The current fallback is block support, so it uses the same shared cache gate
;; as frequent mining and block-support. The variable stays in the opaque
;; context and does not affect the cache key.
(exec (surp s056 eq-value-support-gate)
    (, (eq-value-query $pattern $partition $block $var $query)
       (INPUT SUPPORT-MODE $support-mode)
       ((support-gate
          $support-mode
          (eq-value-query $pattern $partition $block $var $query)
          ($pattern $partition $var)
          $block
          (surp 056 eq-support-cache-hit)
          (surp 057 count-eq-support)
          (surp 058 deliver-eq-support)
          -> eq-value-support-result)
        $gate-p $gate-t))
    (O
        (+ (exec (surp s056 run-eq-value-support-gate) $gate-p $gate-t))))

(exec (surp s059 eq-value-support-result)
    (, (eq-value-support-result ($pattern $partition $var) $block $count))
    (, (eq-value-count $pattern $partition $block $var $count)))


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
(exec (surp s084 eq-abstractness-request)
    (, (eq-joint-var $pattern $partition $var))
    (, (abstractness-sort-request $pattern $partition $var)))

(exec (surp s085 eq-connected-block-count)
    (, (eq-joint-var $pattern $partition $var)
       (exec (surp s085 eq-connected-block-count) $src $sink))
    (,
        (exec (surp s085 eq-connected-block-count)
            (, (eq-block-has-var $pattern $partition $block $var))
            (O
                (count
                    (eq-connected-block-count $pattern $partition $var $count)
                    $count
                    $block)))))

(exec (surp s086 eq-var-factor)
    (, (eq-connected-block-count $pattern $partition $var $count)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-var-factor $pattern $partition $var $factor)
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
(exec (surp s086 eq-joint-block-pair)
    (, (eq-joint-var $pattern $partition $var)
       (eq-block-has-var $pattern $partition $block $var))
    (, (eq-joint-block-pair $pattern $partition $var $block)))

(exec (surp s087 eq-joint-block-pair-count)
    (, (partition $pattern $partition)
       (exec (surp s087 eq-joint-block-pair-count) $src $sink))
    (,
        (exec (surp s087 eq-joint-block-pair-count)
            (, (eq-joint-block-pair $pattern $partition $var $block))
            (O
                (count
                    (eq-joint-block-pair-count $pattern $partition $count)
                    $count
                    ($var $block))))))

(exec (surp s087 eq-joint-var-count)
    (, (partition $pattern $partition)
       (exec (surp s087 eq-joint-var-count) $src $sink))
    (,
        (exec (surp s087 eq-joint-var-count)
            (, (eq-joint-var $pattern $partition $var))
            (O
                (count
                    (eq-joint-var-count $pattern $partition $count)
                    $count
                    $var)))))

(exec (surp s087 eq-any-var-count)
    (, (partition $pattern $partition)
       (exec (surp s087 eq-any-var-count) $src $sink))
    (,
        (exec (surp s087 eq-any-var-count)
            (, (eq-any-var $pattern $partition $var))
            (O
                (count
                    (eq-any-var-count $pattern $partition $count)
                    $count
                    $var)))))

(exec (surp s087 eq-non-joint-var-count)
    (, (partition $pattern $partition)
       (exec (surp s087 eq-non-joint-var-count) $src $sink))
    (,
        (exec (surp s087 eq-non-joint-var-count)
            (, (eq-non-joint-var $pattern $partition $var))
            (O
                (count
                    (eq-non-joint-var-count $pattern $partition $count)
                    $count
                    $var)))))

(exec (surp s088 eq-no-joint-check)
    (, (eq-any-var-count $pattern $partition $any-count)
       (eq-non-joint-var-count $pattern $partition $non-joint-count))
    (O
        (pure
            (eq-no-joint? $pattern $partition $is-no-joint)
            $is-no-joint
            (eq_i32
                (i32_from_string $any-count)
                (i32_from_string $non-joint-count)))))

(exec (surp s088 eq-prob-from-counts)
    (, (eq-joint-block-pair-count $pattern $partition $pair-count)
       (eq-joint-var-count $pattern $partition $var-count)
       (INPUT DB-SIZE $db-size))
    (O
        (pure
            (eq-prob-of $pattern $partition $prob)
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

(exec (surp s089 eq-prob-no-joint)
    (, (partition $pattern $partition)
       (eq-no-joint? $pattern $partition true))
    (, (eq-prob-of $pattern $partition 1.0)))
