;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Empirical truth value without sampling.
;;
;; Source PeTTa functions:
;;
;;   emp-tv
;;   do_emp_tv
;;
;; MM2 public result:
;;
;;   (emp-tv-of $pattern (EMPTV $strength $confidence))
;;
;; Strength:
;;
;;   support(pattern) / DB-SIZE ^ number-of-conjuncts(pattern)
;;
;; Confidence follows PeTTa/C++:
;;
;;   confidence = 0.1 * count_to_confidence(universe-count)
;;
;; This file intentionally computes the universe size from the actual
;; conjunction length, so it is not limited to 1/2/3-clause patterns.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 150 emp-tv-pattern-size)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (emp-tv-pattern-size-of $pattern $size)
            $size
            (size-atom
                (cdr-atom (' $pattern))))))


(exec (surp 151 emp-tv-universe)
    (, (INPUT DB-SIZE $db-size)
       (emp-tv-pattern-size-of $pattern $size))
    (O
        (pure
            (emp-prob-pbs-universe-count $pattern $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string $size))))))


(exec (surp 152 emp-tv-strength)
    (, (INPUT PATTERN ($pattern $support))
       (emp-prob-pbs-universe-count $pattern $universe-count))
    (O
        (pure
            (emp-prob-pbs-of $pattern $strength)
            $strength
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe-count))))))


(exec (surp 153 emp-tv-final)
    (, (emp-prob-pbs-of $pattern $strength)
       (emp-prob-pbs-universe-count $pattern $universe-count))
    (O
        (pure
            (emp-tv-of $pattern (EMPTV $strength $confidence))
            $confidence
            (f64_to_string
                (product_f64
                    (f64_from_string 0.1)
                    (div_f64
                        (f64_from_string $universe-count)
                        (sum_f64
                            (f64_from_string $universe-count)
                            (f64_from_string 800.0))))))))
