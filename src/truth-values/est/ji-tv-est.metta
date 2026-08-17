;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joint-independent truth value estimate for one partition.
;;
;; Source PeTTa function:
;;
;;   ji-est-tv
;;
;; Source meaning:
;;
;;   pro_tv = average empirical TV of partition blocks
;;   eq_p   = eq-prob(partition, pattern, db)
;;   result = STV(pro_tv.strength * eq_p, pro_tv.confidence * 0.1)
;;
;; MM2 public result:
;;
;;   (ji-tv-est-of $partition (STV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 195 ji-tv-est)
    (, (pro-tv-wout-joint-of $partition (STV $strength $confidence))
       (eq-prob-of $partition $eq-prob))
    (O
        (pure
            (ji-tv-est-strength $partition $out-strength)
            $out-strength
            (f64_to_string
                (product_f64
                    (f64_from_string $strength)
                    (f64_from_string $eq-prob))))
        (pure
            (ji-tv-est-confidence $partition $out-confidence)
            $out-confidence
            (f64_to_string
                (product_f64
                    (f64_from_string $confidence)
                    (f64_from_string 0.1))))))


(exec (surp 195 ji-tv-est-assemble)
    (, (ji-tv-est-strength $partition $strength)
       (ji-tv-est-confidence $partition $confidence))
    (, (ji-tv-est-of $partition (STV $strength $confidence))))
