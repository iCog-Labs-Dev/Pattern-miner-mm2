;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Truth value definitions.
;;
;; Source PeTTa utilities:
;;
;;   experiments/utils/TruthValue.metta
;;
;; Public facts:
;;
;;   (tv-default-k 800.0)
;;   (count-confidence-of $count $confidence)
;;   (confidence-count-of $confidence $count)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(tv-default-k 800.0)
(tv-confidence-max 0.9999998)


;; count_to_confidence(count) = count / (count + DEFAULT_K)
(exec (surp 130 count-confidence)
    (, (count-confidence-request $count)
       (tv-default-k $default-k))
    (O
        (pure
            (count-confidence-of $count $confidence)
            $confidence
            (f64_to_string
                (div_f64
                    (f64_from_string $count)
                    (sum_f64
                        (f64_from_string $count)
                        (f64_from_string $default-k)))))))


;; confidence_to_count(conf) = DEFAULT_K * min(conf, 0.9999998) / (1 - conf)
(exec (surp 182 confidence-count)
    (, (confidence-count-request $confidence)
       (tv-default-k $default-k)
       (tv-confidence-max $confidence-max))
    (O
        (pure
            (confidence-count-of $confidence $count)
            $count
            (f64_to_string
                (div_f64
                    (product_f64
                        (f64_from_string $default-k)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string $confidence-max)))
                    (sub_f64
                        (f64_from_string 1.0)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string $confidence-max))))))))
