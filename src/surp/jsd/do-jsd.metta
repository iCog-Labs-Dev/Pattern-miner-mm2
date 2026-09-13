;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Jensen-Shannon divergence over two truth values.
;;
;; Source PeTTa function:
;;
;;   do-jsd
;;
;; Public facts:
;;
;;   (do-jsd-request $left-tv $right-tv)
;;   (do-jsd-request $left-tv $right-tv $bins)
;;   (do-jsd-of $left-tv $right-tv $jsd)
;;   (do-jsd-of $left-tv $right-tv $bins $jsd)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(jsd-default-bins 10)


(exec (surp 298 do-jsd-default-request)
    (, (do-jsd-request $left-tv $right-tv)
       (jsd-default-bins $bins))
    (, (do-jsd-request $left-tv $right-tv $bins)))


(exec (surp 299 do-jsd-cdf-requests)
    (, (do-jsd-request $left-tv $right-tv $bins))
    (, (jsd-cdf-request $left-tv $bins)
       (jsd-cdf-request $right-tv $bins)))


(exec (surp 306 do-jsd-average-cdf-request)
    (, (do-jsd-request $left-tv $right-tv $bins)
       (jsd-cdf-of $left-tv $bins $left-cdf)
       (jsd-cdf-of $right-tv $bins $right-cdf))
    (, (jsd-average-cdf-request $left-cdf $right-cdf)))


(exec (surp 313 do-jsd-kld-requests)
    (, (do-jsd-request $left-tv $right-tv $bins)
       (jsd-cdf-of $left-tv $bins $left-cdf)
       (jsd-cdf-of $right-tv $bins $right-cdf)
       (jsd-average-cdf-of $left-cdf $right-cdf $middle-cdf))
    (, (jsd-kld-request $left-cdf $middle-cdf)
       (jsd-kld-request $right-cdf $middle-cdf)))


(exec (surp 325 do-jsd-final)
    (, (do-jsd-request $left-tv $right-tv $bins)
       (jsd-cdf-of $left-tv $bins $left-cdf)
       (jsd-cdf-of $right-tv $bins $right-cdf)
       (jsd-average-cdf-of $left-cdf $right-cdf $middle-cdf)
       (jsd-kld-of $left-cdf $middle-cdf $left-kld)
       (jsd-kld-of $right-cdf $middle-cdf $right-kld))
    (O
        (pure
            (do-jsd-of $left-tv $right-tv $bins $jsd)
            $jsd
            (f64_to_string
                (sqrt_f64
                    (div_f64
                        (sum_f64
                            (f64_from_string $left-kld)
                            (f64_from_string $right-kld))
                        (f64_from_string 2.0)))))
        (pure
            (do-jsd-of $left-tv $right-tv $jsd)
            $jsd
            (f64_to_string
                (sqrt_f64
                    (div_f64
                        (sum_f64
                            (f64_from_string $left-kld)
                            (f64_from_string $right-kld))
                        (f64_from_string 2.0)))))))
