;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Kullback-Leibler divergence over sampled CDF lists.
;;
;; Public facts:
;;
;;   (jsd-kld-request $left-cdf $right-cdf)
;;   (jsd-kld-of $left-cdf $right-cdf $kld)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(jsd-kld-epsilon 1e-32)


(exec (surp 320 jsd-kld-identical)
    (, (jsd-kld-request $cdf $cdf))
    (, (jsd-kld-of $cdf $cdf 0.0)))


(exec (surp 320 jsd-kld-start)
    (, (jsd-kld-request $left-cdf $right-cdf)
       (DEF jsd-kld-step $step-p $step-t)
       (DEF jsd-kld-final $final-p $final-t))
    (O
        (+ (jsd-kld-acc $left-cdf $right-cdf $left-cdf $right-cdf 0.0 0.0 0.0))
        (+ (exec (surp 321 jsd-kld-final) $final-p $final-t))
        (+ (exec (surp 322 jsd-kld-step) $step-p $step-t))))


(DEF jsd-kld-step
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-epsilon $epsilon)
       (DEF jsd-kld-decons $decons-p $decons-t))
    (O
        (pure
            (jsd-kld-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head)
            $left-head
            (car-atom (' $left-rem)))
        (pure
            (jsd-kld-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head)
            $right-head
            (car-atom (' $right-rem)))
        (pure
            (jsd-kld-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest)
            $left-rest
            (cdr-atom (' $left-rem)))
        (pure
            (jsd-kld-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest)
            $right-rest
            (cdr-atom (' $right-rem)))
        (+ (jsd-kld-deconsed $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum))
        (+ (exec (surp 323 jsd-kld-decons) $decons-p $decons-t))))


(DEF jsd-kld-decons
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-deconsed $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head)
       (jsd-kld-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head)
       (jsd-kld-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest)
       (jsd-kld-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest)
       (DEF jsd-kld-prob-step $prob-p $prob-t))
    (O
        (- (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum))
        (- (jsd-kld-deconsed $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum))
        (- (jsd-kld-left-head $left-cdf $right-cdf $left-rem $right-rem $left-head))
        (- (jsd-kld-right-head $left-cdf $right-cdf $left-rem $right-rem $right-head))
        (- (jsd-kld-left-rest $left-cdf $right-cdf $left-rem $right-rem $left-rest))
        (- (jsd-kld-right-rest $left-cdf $right-cdf $left-rem $right-rem $right-rest))
        (+ (jsd-kld-prob-pending $left-cdf $right-cdf $left-rest $right-rest $last-left $last-right $sum $left-head $right-head))
        (+ (exec (surp 322 jsd-kld-prob-step) $prob-p $prob-t))))


(DEF jsd-kld-prob-step
    (, (jsd-kld-prob-pending $left-cdf $right-cdf $left-rest $right-rest $last-left $last-right $sum $left-head $right-head)
       (DEF jsd-kld-classify $classify-p $classify-t))
    (O
        (pure
            (jsd-kld-left-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp)
            $lp
            (f64_to_string
                (sub_f64
                    (f64_from_string $left-head)
                    (f64_from_string $last-left))))
        (pure
            (jsd-kld-right-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $rp)
            $rp
            (f64_to_string
                (sub_f64
                    (f64_from_string $right-head)
                    (f64_from_string $last-right))))
        (+ (jsd-kld-pending $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum))
        (- (jsd-kld-prob-pending $left-cdf $right-cdf $left-rest $right-rest $last-left $last-right $sum $left-head $right-head))
        (+ (exec (surp 322 jsd-kld-classify) $classify-p $classify-t))))


(DEF jsd-kld-classify
    (, (jsd-kld-pending $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum)
       (jsd-kld-left-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp)
       (jsd-kld-right-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $rp)
       (jsd-kld-epsilon $epsilon)
       (DEF jsd-kld-branch-true $true-p $true-t)
       (DEF jsd-kld-branch-false $false-p $false-t))
    (O
        (pure
            (jsd-kld-term-state $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp $state)
            $state
            (ifnz
                (gt_f64
                    (f64_from_string $lp)
                    (f64_from_string $epsilon))
                then
                    (ifnz
                        (gt_f64
                            (f64_from_string $rp)
                            (f64_from_string $epsilon))
                        then use
                        else skip)
                else skip))
        (- (jsd-kld-left-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp))
        (- (jsd-kld-right-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $rp))
        (+ (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp))
        (+ (exec (surp 322 jsd-kld-branch-true) $true-p $true-t))
        (+ (exec (surp 322 jsd-kld-branch-false) $false-p $false-t))))


(DEF jsd-kld-branch-true
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-term-state $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp use)
       (DEF jsd-kld-continue $continue-p $continue-t))
    (O
        (pure
            (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $term)
            $term
            (f64_to_string
                (product_f64
                    (f64_from_string $lp)
                    (log2_f64
                        (div_f64
                            (f64_from_string $lp)
                            (f64_from_string $rp))))))
        (- (jsd-kld-term-state $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp use))
        (+ (exec (surp 323 jsd-kld-continue) $continue-p $continue-t))))


(DEF jsd-kld-branch-false
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-term-state $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp skip)
       (DEF jsd-kld-continue $continue-p $continue-t))
    (O
        (+ (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum 0.0))
        (- (jsd-kld-term-state $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp skip))
        (+ (exec (surp 323 jsd-kld-continue) $continue-p $continue-t))))


(DEF jsd-kld-continue
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $term)
       (DEF jsd-kld-step $step-p $step-t)
       (DEF jsd-kld-final $final-p $final-t))
    (O
        (pure
            (jsd-kld-acc $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $next-sum)
            $next-sum
            (f64_to_string
                (sum_f64
                    (f64_from_string $sum)
                    (f64_from_string $term))))
        (- (jsd-kld-pending $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum))
        (- (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp))
        (- (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $term))
        (+ (exec (surp 321 jsd-kld-final) $final-p $final-t))
        (+ (exec (surp 322 jsd-kld-step) $step-p $step-t))))


(DEF jsd-kld-final
    (, (jsd-kld-acc $left-cdf $right-cdf () () $last-left $last-right $sum))
    (O
        (- (jsd-kld-acc $left-cdf $right-cdf () () $last-left $last-right $sum))
        (+ (jsd-kld-of $left-cdf $right-cdf $sum))))
