;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Average two sampled CDF lists element by element.
;;
;; Public facts:
;;
;;   (jsd-average-cdf-request $left-cdf $right-cdf)
;;   (jsd-average-cdf-of $left-cdf $right-cdf $midpoint-cdf)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 310 jsd-average-cdf-start)
    (, (jsd-average-cdf-request $left-cdf $right-cdf)
       (DEF jsd-average-cdf-step $step-p $step-t)
       (DEF jsd-average-cdf-final $final-p $final-t))
    (O
        (+ (jsd-average-cdf-acc $left-cdf $right-cdf $left-cdf $right-cdf ()))
        (+ (exec (surp 311 jsd-average-cdf-step) $step-p $step-t))
        (+ (exec (surp 312 jsd-average-cdf-final) $final-p $final-t))))


(DEF jsd-average-cdf-step
    (, (jsd-average-cdf-acc $left-cdf $right-cdf $left-rem $right-rem $out)
       (DEF jsd-average-cdf-decons $decons-p $decons-t))
    (O
        (pure
            (jsd-average-cdf-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head)
            $left-head
            (car-atom (' $left-rem)))
        (pure
            (jsd-average-cdf-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head)
            $right-head
            (car-atom (' $right-rem)))
        (pure
            (jsd-average-cdf-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest)
            $left-rest
            (cdr-atom (' $left-rem)))
        (pure
            (jsd-average-cdf-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest)
            $right-rest
            (cdr-atom (' $right-rem)))
        (+ (jsd-average-cdf-deconsed $left-cdf $right-cdf $left-rem $right-rem $out))
        (+ (exec (surp 311 jsd-average-cdf-decons) $decons-p $decons-t))))


(DEF jsd-average-cdf-decons
    (, (jsd-average-cdf-acc $left-cdf $right-cdf $left-rem $right-rem $out)
       (jsd-average-cdf-deconsed $left-cdf $right-cdf $left-rem $right-rem $out)
       (jsd-average-cdf-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head)
       (jsd-average-cdf-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head)
       (jsd-average-cdf-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest)
       (jsd-average-cdf-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest)
       (DEF jsd-average-cdf-value-step $value-p $value-t))
    (O
        (- (jsd-average-cdf-acc $left-cdf $right-cdf $left-rem $right-rem $out))
        (- (jsd-average-cdf-deconsed $left-cdf $right-cdf $left-rem $right-rem $out))
        (- (jsd-average-cdf-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head))
        (- (jsd-average-cdf-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head))
        (- (jsd-average-cdf-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest))
        (- (jsd-average-cdf-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest))
        (+ (jsd-average-cdf-pending $left-cdf $right-cdf $left-rest $right-rest $out $left-head $right-head))
        (+ (exec (surp 311 jsd-average-cdf-value-step) $value-p $value-t))))


(DEF jsd-average-cdf-value-step
    (, (jsd-average-cdf-pending $left-cdf $right-cdf $left-rest $right-rest $out $left-head $right-head)
       (DEF jsd-average-cdf-continue $continue-p $continue-t))
    (O
        (pure
            (jsd-average-cdf-value $left-cdf $right-cdf $left-rest $right-rest $out $value)
            $value
            (f64_to_string
                (div_f64
                    (sum_f64
                        (f64_from_string $left-head)
                        (f64_from_string $right-head))
                    (f64_from_string 2.0))))
        (+ (exec (surp 311 jsd-average-cdf-continue) $continue-p $continue-t))))


(DEF jsd-average-cdf-continue
    (, (jsd-average-cdf-pending $left-cdf $right-cdf $left-rest $right-rest $out $left-head $right-head)
       (jsd-average-cdf-value $left-cdf $right-cdf $left-rest $right-rest $out $value)
       (DEF jsd-average-cdf-step $step-p $step-t)
       (DEF jsd-average-cdf-final $final-p $final-t))
    (O
        (pure
            (jsd-average-cdf-acc $left-cdf $right-cdf $left-rest $right-rest $next-out)
            $next-out
            (append (' ($out ($value)))))
        (- (jsd-average-cdf-pending $left-cdf $right-cdf $left-rest $right-rest $out $left-head $right-head))
        (- (jsd-average-cdf-value $left-cdf $right-cdf $left-rest $right-rest $out $value))
        (+ (exec (surp 311 jsd-average-cdf-step) $step-p $step-t))
        (+ (exec (surp 312 jsd-average-cdf-final) $final-p $final-t))))


(DEF jsd-average-cdf-final
    (, (jsd-average-cdf-acc $left-cdf $right-cdf () () $out))
    (O
        (- (jsd-average-cdf-acc $left-cdf $right-cdf () () $out))
        (+ (jsd-average-cdf-of $left-cdf $right-cdf $out))))
