;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Average truth values.
;;
;; Source PeTTa function:
;;
;;   (avrg_tv $tv-list)
;;
;; Source meaning:
;;
;;   1. Convert each TV to a beta distribution.
;;   2. Average beta means.
;;   3. Average relative variances:
;;        variance_i + (mean_i - global_mean)^2
;;   4. Convert mean + variance back into STV using `mk_stv`.
;;
;; MM2 public result:
;;
;;   (avrg-tv-of $tv-list (STV $strength $confidence))
;;
;; Current scope:
;;
;;   Explicit list-shape rules for 1, 2, 3, and 4 truth values.  This follows
;;   the current ISurp module style.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 180 avrg-tv-beta-request-1)
    (, (avrg-tv-request ($tv1)))
    (, (tv-beta-request $tv1)))

(exec (surp 180 avrg-tv-beta-request-2)
    (, (avrg-tv-request ($tv1 $tv2)))
    (, (tv-beta-request $tv1)
       (tv-beta-request $tv2)))

(exec (surp 180 avrg-tv-beta-request-3)
    (, (avrg-tv-request ($tv1 $tv2 $tv3)))
    (, (tv-beta-request $tv1)
       (tv-beta-request $tv2)
       (tv-beta-request $tv3)))

(exec (surp 180 avrg-tv-beta-request-4)
    (, (avrg-tv-request ($tv1 $tv2 $tv3 $tv4)))
    (, (tv-beta-request $tv1)
       (tv-beta-request $tv2)
       (tv-beta-request $tv3)
       (tv-beta-request $tv4)))


;; One TV: the average is the reconstructed beta STV for that TV.
(exec (surp 185 avrg-tv-1)
    (, (avrg-tv-request ($tv1))
       (tv-beta-of $tv1 (Beta (mean $m1) (variance $v1))))
    (O
        (+ (mk-stv-request $m1 $v1))
        (+ (avrg-tv-variance-of ($tv1) $m1 $v1))))


(exec (surp 185 avrg-tv-2)
    (, (avrg-tv-request ($tv1 $tv2))
       (tv-beta-of $tv1 (Beta (mean $m1) (variance $v1)))
       (tv-beta-of $tv2 (Beta (mean $m2) (variance $v2))))
    (O
        (pure
            (avrg-tv-mean-of ($tv1 $tv2) $mean)
            $mean
            (f64_to_string
                (div_f64
                    (sum_f64
                        (f64_from_string $m1)
                        (f64_from_string $m2))
                    (f64_from_string 2.0))))))


(exec (surp 186 avrg-tv-2-variance)
    (, (avrg-tv-request ($tv1 $tv2))
       (tv-beta-of $tv1 (Beta (mean $m1) (variance $v1)))
       (tv-beta-of $tv2 (Beta (mean $m2) (variance $v2)))
       (avrg-tv-mean-of ($tv1 $tv2) $mean))
    (O
        (pure
            (avrg-tv-variance-of ($tv1 $tv2) $mean $variance)
            $variance
            (f64_to_string
                (div_f64
                    (sum_f64
                        (sum_f64
                            (f64_from_string $v1)
                            (product_f64
                                (sub_f64
                                    (f64_from_string $m1)
                                    (f64_from_string $mean))
                                (sub_f64
                                    (f64_from_string $m1)
                                    (f64_from_string $mean))))
                        (sum_f64
                            (f64_from_string $v2)
                            (product_f64
                                (sub_f64
                                    (f64_from_string $m2)
                                    (f64_from_string $mean))
                                (sub_f64
                                    (f64_from_string $m2)
                                    (f64_from_string $mean)))))
                    (f64_from_string 2.0))))))


(exec (surp 185 avrg-tv-3)
    (, (avrg-tv-request ($tv1 $tv2 $tv3))
       (tv-beta-of $tv1 (Beta (mean $m1) (variance $v1)))
       (tv-beta-of $tv2 (Beta (mean $m2) (variance $v2)))
       (tv-beta-of $tv3 (Beta (mean $m3) (variance $v3))))
    (O
        (pure
            (avrg-tv-mean-of ($tv1 $tv2 $tv3) $mean)
            $mean
            (f64_to_string
                (div_f64
                    (sum_f64
                        (f64_from_string $m1)
                        (f64_from_string $m2)
                        (f64_from_string $m3))
                    (f64_from_string 3.0))))
        (pure
            (avrg-tv-variance-of ($tv1 $tv2 $tv3) $mean $variance)
            $variance
            (f64_to_string
                (div_f64
                    (sum_f64
                        (sum_f64 (f64_from_string $v1)
                            (product_f64 (sub_f64 (f64_from_string $m1) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m1) (f64_from_string $mean))))
                        (sum_f64 (f64_from_string $v2)
                            (product_f64 (sub_f64 (f64_from_string $m2) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m2) (f64_from_string $mean))))
                        (sum_f64 (f64_from_string $v3)
                            (product_f64 (sub_f64 (f64_from_string $m3) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m3) (f64_from_string $mean)))))
                    (f64_from_string 3.0))))))


(exec (surp 185 avrg-tv-4)
    (, (avrg-tv-request ($tv1 $tv2 $tv3 $tv4))
       (tv-beta-of $tv1 (Beta (mean $m1) (variance $v1)))
       (tv-beta-of $tv2 (Beta (mean $m2) (variance $v2)))
       (tv-beta-of $tv3 (Beta (mean $m3) (variance $v3)))
       (tv-beta-of $tv4 (Beta (mean $m4) (variance $v4))))
    (O
        (pure
            (avrg-tv-mean-of ($tv1 $tv2 $tv3 $tv4) $mean)
            $mean
            (f64_to_string
                (div_f64
                    (sum_f64
                        (f64_from_string $m1)
                        (f64_from_string $m2)
                        (f64_from_string $m3)
                        (f64_from_string $m4))
                    (f64_from_string 4.0))))
        (pure
            (avrg-tv-variance-of ($tv1 $tv2 $tv3 $tv4) $mean $variance)
            $variance
            (f64_to_string
                (div_f64
                    (sum_f64
                        (sum_f64 (f64_from_string $v1)
                            (product_f64 (sub_f64 (f64_from_string $m1) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m1) (f64_from_string $mean))))
                        (sum_f64 (f64_from_string $v2)
                            (product_f64 (sub_f64 (f64_from_string $m2) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m2) (f64_from_string $mean))))
                        (sum_f64 (f64_from_string $v3)
                            (product_f64 (sub_f64 (f64_from_string $m3) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m3) (f64_from_string $mean))))
                        (sum_f64 (f64_from_string $v4)
                            (product_f64 (sub_f64 (f64_from_string $m4) (f64_from_string $mean))
                                         (sub_f64 (f64_from_string $m4) (f64_from_string $mean)))))
                    (f64_from_string 4.0))))))


;; Request final STV conversion for averaged beta distributions.
(exec (surp 187 avrg-tv-mk-stv-request)
    (, (avrg-tv-variance-of $tv-list $mean $variance))
    (, (mk-stv-request $mean $variance)))


(exec (surp 192 avrg-tv-final)
    (, (avrg-tv-variance-of $tv-list $mean $variance)
       (mk-stv-of $mean $variance $stv))
    (, (avrg-tv-of $tv-list $stv)))
