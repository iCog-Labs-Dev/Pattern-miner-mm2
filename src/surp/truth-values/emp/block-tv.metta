;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Block empirical truth values.
;;
;; Source PeTTa role:
;;
;;   `ji_tv_est` builds subpatterns from partition blocks and calculates
;;   `emp_tv_mem` for each subpattern.  This module provides the equivalent
;;   materialized block TV facts.
;;
;; MM2 public result:
;;
;;   (block-tv-of $pattern $partition $block (EMPTV $strength $confidence))
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s160 block-tv-universe)
    (, (INPUT DB-SIZE $db-size)
       (block-support $pattern $partition $block $support))
    (O
        (pure
            (pro-block-universe-count $pattern $partition $block $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string
                        (size-atom (' $block))))))))


(exec (surp s161 block-tv-strength)
    (, (block-support $pattern $partition $block $support)
       (pro-block-universe-count $pattern $partition $block $universe-count))
    (O
        (pure
            (pro-block-prob $pattern $partition $block $strength)
            $strength
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe-count))))))


(exec (surp s162 block-tv-final)
    (, (pro-block-prob $pattern $partition $block $strength)
       (pro-block-universe-count $pattern $partition $block $universe-count))
    (O
        (pure
            (block-tv-of $pattern $partition $block (EMPTV $strength $confidence))
            $confidence
            (f64_to_string
                (product_f64
                    (f64_from_string 0.1)
                    (div_f64
                        (f64_from_string $universe-count)
                        (sum_f64
                            (f64_from_string $universe-count)
                            (f64_from_string 800.0))))))))
