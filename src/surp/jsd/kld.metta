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
       (DEF jsd-kld-size $size-p $size-t))
    (O
        (+ (jsd-kld-acc $left-cdf $right-cdf $left-cdf $right-cdf 0.0 0.0 0.0))
        (+ (exec (surp 321 jsd-kld-size) $size-p $size-t))))


(DEF jsd-kld-size
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (DEF jsd-kld-compare-size $compare-p $compare-t))
    (O
        (pure
            (jsd-kld-left-size $left-cdf $right-cdf $left-rem $right-rem $left-size)
            $left-size
            (size-atom (' $left-rem)))
        (pure
            (jsd-kld-right-size $left-cdf $right-cdf $left-rem $right-rem $right-size)
            $right-size
            (size-atom (' $right-rem)))
        (+ (exec (surp 322 jsd-kld-compare-size) $compare-p $compare-t))))


(DEF jsd-kld-compare-size
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-left-size $left-cdf $right-cdf $left-rem $right-rem $left-size)
       (jsd-kld-right-size $left-cdf $right-cdf $left-rem $right-rem $right-size)
       (DEF jsd-kld-state $state-p $state-t))
    (O
        (pure
            (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem $has-items)
            $has-items
            (gt_i32
                (i32_from_string $left-size)
                (i32_from_string 0)))
        (- (jsd-kld-left-size $left-cdf $right-cdf $left-rem $right-rem $left-size))
        (- (jsd-kld-right-size $left-cdf $right-cdf $left-rem $right-rem $right-size))
        (+ (exec (surp 323 jsd-kld-state) $state-p $state-t))))


(DEF jsd-kld-state
    (, (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem $has-items)
       (DEF jsd-kld-state-done $done-p $done-t)
       (DEF jsd-kld-state-more $more-p $more-t))
    (O
        (+ (exec (surp 324 jsd-kld-state-done) $done-p $done-t))
        (+ (exec (surp 324 jsd-kld-state-more) $more-p $more-t))))


(DEF jsd-kld-state-done
    (, (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem false)
       (DEF jsd-kld-final $final-p $final-t))
    (O
        (- (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem false))
        (+ (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem done))
        (+ (exec (surp 323 jsd-kld-final) $final-p $final-t))
    ))


(DEF jsd-kld-state-more
    (, (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem true)
       (DEF jsd-kld-step $step-p $step-t))
    (O
        (- (jsd-kld-left-has-items $left-cdf $right-cdf $left-rem $right-rem true))
        (+ (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem more))
        (+ (exec (surp 324 jsd-kld-step) $step-p $step-t))))


(DEF jsd-kld-step
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem more)
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
        (- (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem more))
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
        (pure
            (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $left-pos)
            $left-pos
            (gt_f64
                (sub_f64
                    (f64_from_string $left-head)
                    (f64_from_string $last-left))
                (f64_from_string 1e-32)))
        (pure
            (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $right-pos)
            $right-pos
            (gt_f64
                (sub_f64
                    (f64_from_string $right-head)
                    (f64_from_string $last-right))
                (f64_from_string 1e-32)))
        (+ (jsd-kld-pending $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum))
        (- (jsd-kld-prob-pending $left-cdf $right-cdf $left-rest $right-rest $last-left $last-right $sum $left-head $right-head))
        (+ (exec (surp 322 jsd-kld-classify) $classify-p $classify-t))))


(DEF jsd-kld-classify
    (, (jsd-kld-pending $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum)
       (jsd-kld-left-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp)
       (jsd-kld-right-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $rp)
       (DEF jsd-kld-branch-use $use-p $use-t)
       (DEF jsd-kld-branch-skip-left $skip-left-p $skip-left-t)
       (DEF jsd-kld-branch-skip-right $skip-right-p $skip-right-t))
    (O
        (- (jsd-kld-left-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp))
        (- (jsd-kld-right-prob $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $rp))
        (+ (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp))
        (+ (exec (surp 322 jsd-kld-branch-use) $use-p $use-t))
        (+ (exec (surp 322 jsd-kld-branch-skip-left) $skip-left-p $skip-left-t))
        (+ (exec (surp 322 jsd-kld-branch-skip-right) $skip-right-p $skip-right-t))))


(DEF jsd-kld-branch-use
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true)
       (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true)
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
        (- (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true))
        (- (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true))
        (+ (exec (surp 323 jsd-kld-continue) $continue-p $continue-t))))


(DEF jsd-kld-branch-skip-left
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum false)
       (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $right-pos)
       (DEF jsd-kld-continue $continue-p $continue-t))
    (O
        (+ (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum 0.0))
        (- (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum false))
        (- (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $right-pos))
        (+ (exec (surp 323 jsd-kld-continue) $continue-p $continue-t))))


(DEF jsd-kld-branch-skip-right
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true)
       (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum false)
       (DEF jsd-kld-continue $continue-p $continue-t))
    (O
        (+ (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum 0.0))
        (- (jsd-kld-left-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum true))
        (- (jsd-kld-right-positive $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum false))
        (+ (exec (surp 323 jsd-kld-continue) $continue-p $continue-t))))


(DEF jsd-kld-continue
    (, (jsd-kld-classified $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $lp $rp)
       (jsd-kld-contribution $left-cdf $right-cdf $left-rest $right-rest $left-head $right-head $sum $term)
       (DEF jsd-kld-size $size-p $size-t))
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
        (+ (exec (surp 321 jsd-kld-size) $size-p $size-t))))


(DEF jsd-kld-final
    (, (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum)
       (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem done))
    (O
        (- (jsd-kld-acc $left-cdf $right-cdf $left-rem $right-rem $last-left $last-right $sum))
        (- (jsd-kld-loop-state $left-cdf $right-cdf $left-rem $right-rem done))
        (+ (jsd-kld-of $left-cdf $right-cdf $sum))))
