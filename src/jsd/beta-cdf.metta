;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Beta CDF sampling for Jensen-Shannon divergence.
;;
;; Source PeTTa utilities:
;;
;;   experiments/utils/surp-utils/jsd-helper.metta
;;
;; Public facts:
;;
;;   (jsd-cdf-request $tv $bins)
;;   (jsd-cdf-of $tv $bins $cdf-list)
;;
;; The numeric beta CDF is provided by the MM2 helper pure function
;; `beta_cdf_f64`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 300 jsd-cdf-count-stv)
    (, (jsd-cdf-request (STV $strength $confidence) $bins))
    (O
        (pure
            (jsd-tv-count (STV $strength $confidence) $count)
            $count
            (f64_to_string
                (div_f64
                    (product_f64
                        (f64_from_string 800.0)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string 0.9999998)))
                    (sub_f64
                        (f64_from_string 1.0)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string 0.9999998))))))))


(exec (surp 300 jsd-cdf-count-emptv)
    (, (jsd-cdf-request (EMPTV $strength $confidence) $bins))
    (O
        (pure
            (jsd-tv-count (EMPTV $strength $confidence) $count)
            $count
            (f64_to_string
                (div_f64
                    (product_f64
                        (f64_from_string 800.0)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string 0.9999998)))
                    (sub_f64
                        (f64_from_string 1.0)
                        (min_f64
                            (f64_from_string $confidence)
                            (f64_from_string 0.9999998))))))))


(exec (surp 301 jsd-cdf-alpha-beta-stv)
    (, (jsd-tv-count (STV $strength $confidence) $count))
    (O
        (pure
            (jsd-tv-alpha (STV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (jsd-tv-beta (STV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))


(exec (surp 301 jsd-cdf-alpha-beta-emptv)
    (, (jsd-tv-count (EMPTV $strength $confidence) $count))
    (O
        (pure
            (jsd-tv-alpha (EMPTV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (jsd-tv-beta (EMPTV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))


(exec (surp 302 jsd-cdf-start)
    (, (jsd-cdf-request $tv $bins)
       (jsd-tv-alpha $tv $alpha)
       (jsd-tv-beta $tv $beta)
       (DEF jsd-cdf-check $check-p $check-t))
    (O
        (+ (jsd-cdf-acc $tv $bins $alpha $beta 0 ()))
        (+ (exec (surp 303 jsd-cdf-check) $check-p $check-t))))


(DEF jsd-cdf-check
    (, (jsd-cdf-acc $tv $bins $alpha $beta $index $cdf-list)
       (DEF jsd-cdf-step $step-p $step-t)
       (DEF jsd-cdf-final $final-p $final-t))
    (O
        (pure
            (jsd-cdf-state $tv $bins $alpha $beta $index $state)
            $state
            (ifnz
                (gte_i32
                    (i32_from_string $index)
                    (i32_from_string $bins))
                then done
                else more))
        (+ (exec (surp 304 jsd-cdf-step) $step-p $step-t))
        (+ (exec (surp 305 jsd-cdf-final) $final-p $final-t))))


(DEF jsd-cdf-step
    (, (jsd-cdf-acc $tv $bins $alpha $beta $index $cdf-list)
       (jsd-cdf-state $tv $bins $alpha $beta $index more)
       (DEF jsd-cdf-continue $continue-p $continue-t))
    (O
        (pure
            (jsd-cdf-x $tv $bins $index $x)
            $x
            (f64_to_string
                (div_f64
                    (f64_from_string
                        (i32_to_string
                            (sum_i32
                                (i32_from_string $index)
                                (i32_one))))
                    (f64_from_string $bins))))
        (pure
            (jsd-cdf-value $tv $bins $index $value)
            $value
            (f64_to_string
                (beta_cdf_f64
                    (f64_from_string $alpha)
                    (f64_from_string $beta)
                    (div_f64
                        (f64_from_string
                            (i32_to_string
                                (sum_i32
                                    (i32_from_string $index)
                                    (i32_one))))
                        (f64_from_string $bins)))))
        (pure
            (jsd-cdf-next-index $tv $bins $index $next-index)
            $next-index
            (i32_to_string
                (sum_i32
                    (i32_from_string $index)
                    (i32_one))))
        (- (jsd-cdf-acc $tv $bins $alpha $beta $index $cdf-list))
        (- (jsd-cdf-state $tv $bins $alpha $beta $index more))
        (+ (jsd-cdf-pending $tv $bins $alpha $beta $index $cdf-list))
        (+ (exec (surp 304 jsd-cdf-continue) $continue-p $continue-t))))


(DEF jsd-cdf-continue
    (, (jsd-cdf-pending $tv $bins $alpha $beta $index $cdf-list)
       (jsd-cdf-value $tv $bins $index $value)
       (jsd-cdf-next-index $tv $bins $index $next-index)
       (DEF jsd-cdf-check $check-p $check-t))
    (O
        (pure
            (jsd-cdf-acc $tv $bins $alpha $beta $next-index $next-list)
            $next-list
            (append (' ($cdf-list ($value)))))
        (- (jsd-cdf-pending $tv $bins $alpha $beta $index $cdf-list))
        (- (jsd-cdf-value $tv $bins $index $value))
        (- (jsd-cdf-next-index $tv $bins $index $next-index))
        (+ (exec (surp 303 jsd-cdf-check) $check-p $check-t))))


(DEF jsd-cdf-final
    (, (jsd-cdf-acc $tv $bins $alpha $beta $index $cdf-list)
       (jsd-cdf-state $tv $bins $alpha $beta $index done))
    (O
        (- (jsd-cdf-acc $tv $bins $alpha $beta $index $cdf-list))
        (- (jsd-cdf-state $tv $bins $alpha $beta $index done))
        (+ (jsd-cdf-of $tv $bins $cdf-list))))
