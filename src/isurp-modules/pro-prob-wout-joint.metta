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
;;   variable dependencies. Joint-variable correction is handled separately by
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 080 pro-block-universe)
    (, (INPUT DB-SIZE $db-size)
       (block-support $partition $block $support))
    (O
        (pure
            (pro-block-size $partition $block $size)
            $size
            (size-atom (' $block))
        )
        (pure
            (pro-block-universe-count $partition $block $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string
                        (size-atom (' $block))))))))


(exec (surp 081 pro-block-prob)
    (, (block-support $partition $block $support)
       (pro-block-universe-count $partition $block $universe-count))
    (O
        (pure
            (pro-block-prob $partition $block $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe-count))))))


(exec (surp 082 pro-partition-start)
    (, (partition $partition)
       (DEF pro-partition-step $step-p $step-t))
    (O
        (+ (pro-partition-acc $partition $partition 1.0))
        (+ (exec (surp 083 pro-partition-step) $step-p $step-t))))


(DEF pro-partition-step
    (, (pro-partition-acc $partition $remaining $acc)
       (DEF pro-partition-resolve $resolve-p $resolve-t))
    (O
        (pure
            (pro-partition-current $partition $remaining $block)
            $block
            (car-atom (' $remaining)))
        (pure
            (pro-partition-rest $partition $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (pro-partition-acc $partition $remaining $acc))
        (+ (pro-partition-pending $partition $remaining $acc))
        (+ (exec (surp 084 pro-partition-resolve) $resolve-p $resolve-t))))


(DEF pro-partition-resolve
    (, (pro-partition-pending $partition $remaining $acc)
       (pro-partition-current $partition $remaining $block)
       (pro-partition-rest $partition $remaining $rest)
       (pro-block-prob $partition $block $block-prob)
       (DEF pro-partition-step $step-p $step-t)
       (DEF pro-partition-final $final-p $final-t))
    (O
        (pure
            (pro-partition-acc $partition $rest $new-acc)
            $new-acc
            (f64_to_string
                (product_f64
                    (f64_from_string $acc)
                    (f64_from_string $block-prob))))
        (- (pro-partition-pending $partition $remaining $acc))
        (- (pro-partition-current $partition $remaining $block))
        (- (pro-partition-rest $partition $remaining $rest))
        (+ (exec (surp 082 pro-partition-final) $final-p $final-t))
        (+ (exec (surp 083 pro-partition-step) $step-p $step-t))))


(DEF pro-partition-final
    (, (pro-partition-acc $partition () $prob))
    (O
        (- (pro-partition-acc $partition () $prob))
        (+ (pro-prob-wout-joint-of $partition $prob))))
