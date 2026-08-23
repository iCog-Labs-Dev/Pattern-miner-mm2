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


(exec (surp 298 do-jsd-tv-fields-stv-stv)
    (, (do-jsd-request (STV $left-strength $left-confidence) (STV $right-strength $right-confidence) $bins))
    (, (do-jsd-tv-fields
        (STV $left-strength $left-confidence)
        (STV $right-strength $right-confidence)
        $bins
        $left-strength
        $left-confidence
        $right-strength
        $right-confidence)))


(exec (surp 298 do-jsd-tv-fields-emptv-stv)
    (, (do-jsd-request (EMPTV $left-strength $left-confidence) (STV $right-strength $right-confidence) $bins))
    (, (do-jsd-tv-fields
        (EMPTV $left-strength $left-confidence)
        (STV $right-strength $right-confidence)
        $bins
        $left-strength
        $left-confidence
        $right-strength
        $right-confidence)))


(exec (surp 298 do-jsd-tv-fields-stv-emptv)
    (, (do-jsd-request (STV $left-strength $left-confidence) (EMPTV $right-strength $right-confidence) $bins))
    (, (do-jsd-tv-fields
        (STV $left-strength $left-confidence)
        (EMPTV $right-strength $right-confidence)
        $bins
        $left-strength
        $left-confidence
        $right-strength
        $right-confidence)))


(exec (surp 298 do-jsd-tv-fields-emptv-emptv)
    (, (do-jsd-request (EMPTV $left-strength $left-confidence) (EMPTV $right-strength $right-confidence) $bins))
    (, (do-jsd-tv-fields
        (EMPTV $left-strength $left-confidence)
        (EMPTV $right-strength $right-confidence)
        $bins
        $left-strength
        $left-confidence
        $right-strength
        $right-confidence)))


(exec (surp 299 do-jsd-direct)
    (, (do-jsd-tv-fields
        $left-tv
        $right-tv
        $bins
        $left-strength
        $left-confidence
        $right-strength
        $right-confidence))
    (O
        (pure
            (do-jsd-of $left-tv $right-tv $bins $jsd)
            $jsd
            (f64_to_string
                (jsd_tv_f64
                    (f64_from_string $left-strength)
                    (f64_from_string $left-confidence)
                    (f64_from_string $right-strength)
                    (f64_from_string $right-confidence)
                    (i32_from_string $bins))))
        (pure
            (do-jsd-of $left-tv $right-tv $jsd)
            $jsd
            (f64_to_string
                (jsd_tv_f64
                    (f64_from_string $left-strength)
                    (f64_from_string $left-confidence)
                    (f64_from_string $right-strength)
                    (f64_from_string $right-confidence)
                    (i32_from_string $bins))))))

