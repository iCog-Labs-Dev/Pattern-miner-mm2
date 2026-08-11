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
;;   (block-tv-of $partition $block (EMPTV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 160 block-tv-universe-1)
    (, (INPUT DB-SIZE $db-size)
       (block-support $partition ($c1) $support))
    (, (pro-block-universe-count $partition ($c1) $db-size)))


(exec (surp 162 block-tv-final)
    (, (pro-block-prob $partition $block $strength)
       (pro-block-universe-count $partition $block $universe-count))
    (O
        (pure
            (block-tv-of $partition $block (EMPTV $strength $confidence))
            $confidence
            (f64_to_string
                (product_f64
                    (f64_from_string 0.1)
                    (div_f64
                        (f64_from_string $universe-count)
                        (sum_f64
                            (f64_from_string $universe-count)
                            (f64_from_string 800.0))))))))
