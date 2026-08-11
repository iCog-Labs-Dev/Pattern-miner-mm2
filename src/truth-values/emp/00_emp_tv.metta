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
;; Strength reuses `emp-prob-pbs-of`.  Confidence follows PeTTa/C++:
;;
;;   confidence = 0.1 * count_to_confidence(universe-count)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 150 emp-tv-universe-1)
    (, (INPUT DB-SIZE $db-size)
       (INPUT PATTERN ((, $c1) $support)))
    (, (emp-prob-pbs-universe-count (, $c1) $db-size)))


(exec (surp 152 emp-tv-final)
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
