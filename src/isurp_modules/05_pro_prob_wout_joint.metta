;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pro-prob-wout-joint
;;
;; Source PeTTa function:
;;
;;   (pro-prob-wout-joint $partition $db $db_ratio 1)
;;
;; Source meaning:
;;
;;   For each block in a partition:
;;
;;     empirical probability(block) = support(block) / universe-count(block)
;;
;;   Then multiply the block probabilities together while ignoring joint
;;   variable dependencies.  Joint-variable correction is handled separately by
;;   `eq-prob`.
;;
;; MM2 public result:
;;
;;   (pro-prob-wout-joint-of $partition $prob)
;;
;; Required input facts:
;;
;;   (INPUT DB-SIZE $db-size)
;;   (partition $partition)
;;   (block-support $partition $block $support)
;;
;; `block-support` can be produced by `02_block_support.metta`, or provided
;; directly by a small test DB.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Block empirical probability:
;;
;;   universe-count(block) = DB-SIZE ^ number-of-clauses-in-block
;;   emp-prob(block)      = block-support / universe-count(block)
;;
;; These rules are explicit by block arity.  That is intentionally similar to
;; the rest of the MM2 ISurp port: current MORK builds are more reliable with
;; concrete tuple shapes than with deeply nested dynamic tuple-size expressions.
(exec 13
    (, (INPUT DB-SIZE $db-size)
       (block-support $partition ($c1) $support))
    (O
        (pure
            (pro-block-prob $partition ($c1) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $db-size))))))


(exec 13
    (, (INPUT DB-SIZE $db-size)
       (block-support $partition ($c1 $c2) $support))
    (O
        (pure
            (pro-block-universe-count $partition ($c1 $c2) $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string 2))))
        (pure
            (pro-block-prob $partition ($c1 $c2) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (i64_from_string 2)))))))))


(exec 13
    (, (INPUT DB-SIZE $db-size)
       (block-support $partition ($c1 $c2 $c3) $support))
    (O
        (pure
            (pro-block-universe-count $partition ($c1 $c2 $c3) $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string 3))))
        (pure
            (pro-block-prob $partition ($c1 $c2 $c3) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (i64_from_string 3)))))))))


;; One-block partition:
;;
;;   pro-prob-wout-joint = P(block-1)
(exec 14
    (, (partition ($b1))
       (pro-block-prob ($b1) $b1 $p1))
    (, (pro-prob-wout-joint-of ($b1) $p1)))


;; Two-block partition:
;;
;;   pro-prob-wout-joint = P(block-1) * P(block-2)
(exec 14
    (, (partition ($b1 $b2))
       (pro-block-prob ($b1 $b2) $b1 $p1)
       (pro-block-prob ($b1 $b2) $b2 $p2))
    (O
        (pure
            (pro-prob-wout-joint-of ($b1 $b2) $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $p1)
                    (f64_from_string $p2))))))


;; Three-block partition:
;;
;;   pro-prob-wout-joint = P(block-1) * P(block-2) * P(block-3)
(exec 14
    (, (partition ($b1 $b2 $b3))
       (pro-block-prob ($b1 $b2 $b3) $b1 $p1)
       (pro-block-prob ($b1 $b2 $b3) $b2 $p2)
       (pro-block-prob ($b1 $b2 $b3) $b3 $p3))
    (O
        (pure
            (pro-prob-wout-joint-of ($b1 $b2 $b3) $prob)
            $prob
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $p1)
                        (f64_from_string $p2))
                    (f64_from_string $p3))))))
