;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Truth value definitions and beta-distribution helpers.
;;
;; Source PeTTa utilities:
;;
;;   experiments/utils/TruthValue.metta
;;   experiments/utils/surp-utils/beta-dist.metta
;;
;; Public facts:
;;
;;   (tv-default-k 800.0)
;;   (tv-prior-alpha 1.0)
;;   (tv-prior-beta 1.0)
;;   (count-confidence-of $count $confidence)
;;   (confidence-count-of $confidence $count)
;;   (tv-beta-of (STV $strength $confidence) (Beta (mean $m) (variance $v)))
;;   (tv-beta-of (EMPTV $strength $confidence) (Beta (mean $m) (variance $v)))
;;   (mk-stv-of $mean $variance (STV $strength $confidence))
;;
;; Notes:
;;
;;   OpenCog SimpleTruthValue strength is treated as the beta mode.  The PeTTa
;;   port uses the truth-value strength as the positive sample ratio when
;;   creating a beta distribution, then `mk_stv` converts an averaged beta
;;   distribution back to an STV.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(tv-default-k 800.0)
(tv-prior-alpha 1.0)
(tv-prior-beta 1.0)


;; count_to_confidence(count) = count / (count + DEFAULT_K)
(exec (surp 130 count-confidence)
    (, (count-confidence-request $count))
    (O
        (pure
            (count-confidence-of $count $confidence)
            $confidence
            (f64_to_string
                (div_f64
                    (f64_from_string $count)
                    (sum_f64
                        (f64_from_string $count)
                        (f64_from_string 800.0)))))))


;; confidence_to_count(conf) = DEFAULT_K * min(conf, 0.9999998) / (1 - conf)
(exec (surp 182 confidence-count)
    (, (confidence-count-request $confidence))
    (O
        (pure
            (confidence-count-of $confidence $count)
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


;; Request confidence->count for any TV that needs beta conversion.
(exec (surp 181 tv-beta-count-request-stv)
    (, (tv-beta-request (STV $strength $confidence)))
    (, (confidence-count-request $confidence)))

(exec (surp 181 tv-beta-count-request-emptv)
    (, (tv-beta-request (EMPTV $strength $confidence)))
    (, (confidence-count-request $confidence)))


;; Convert STV to a beta distribution.
(exec (surp 183 tv-beta-stv)
    (, (tv-beta-request (STV $strength $confidence))
       (confidence-count-of $confidence $count))
    (O
        (pure
            (tv-beta-alpha (STV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (tv-beta-beta (STV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))


;; Convert EMPTV to a beta distribution.
(exec (surp 183 tv-beta-emptv)
    (, (tv-beta-request (EMPTV $strength $confidence))
       (confidence-count-of $confidence $count))
    (O
        (pure
            (tv-beta-alpha (EMPTV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (tv-beta-beta (EMPTV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))


;; beta_mean = alpha / (alpha + beta)
;; beta_var  = alpha * beta / ((alpha + beta)^2 * (alpha + beta + 1))
(exec (surp 184 tv-beta-final)
    (, (tv-beta-alpha $tv $alpha)
       (tv-beta-beta $tv $beta))
    (O
        (pure
            (tv-beta-mean $tv $mean)
            $mean
            (f64_to_string
                (div_f64
                    (f64_from_string $alpha)
                    (sum_f64
                        (f64_from_string $alpha)
                        (f64_from_string $beta)))))
        (pure
            (tv-beta-variance $tv $variance)
            $variance
            (f64_to_string
                (div_f64
                    (product_f64
                        (f64_from_string $alpha)
                        (f64_from_string $beta))
                    (product_f64
                        (product_f64
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta))
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta)))
                        (sum_f64
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta))
                            (f64_from_string 1.0))))))))


(exec (surp 184 tv-beta-assemble)
    (, (tv-beta-mean $tv $mean)
       (tv-beta-variance $tv $variance))
    (, (tv-beta-of $tv (Beta (mean $mean) (variance $variance)))))


;; Late beta conversion pass for TV requests created after the first average
;; pass, mainly from `do-ji-tv-est`.
(exec (surp 203 tv-beta-count-request-stv-late)
    (, (tv-beta-request (STV $strength $confidence)))
    (, (confidence-count-request-late $confidence)))

(exec (surp 203 tv-beta-count-request-emptv-late)
    (, (tv-beta-request (EMPTV $strength $confidence)))
    (, (confidence-count-request-late $confidence)))

(exec (surp 204 confidence-count-late)
    (, (confidence-count-request-late $confidence))
    (O
        (pure
            (confidence-count-of-late $confidence $count)
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

(exec (surp 205 tv-beta-stv-late)
    (, (tv-beta-request (STV $strength $confidence))
       (confidence-count-of-late $confidence $count))
    (O
        (pure
            (tv-beta-alpha-late (STV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (tv-beta-beta-late (STV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))

(exec (surp 205 tv-beta-emptv-late)
    (, (tv-beta-request (EMPTV $strength $confidence))
       (confidence-count-of-late $confidence $count))
    (O
        (pure
            (tv-beta-alpha-late (EMPTV $strength $confidence) $alpha)
            $alpha
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (product_f64
                        (f64_from_string $strength)
                        (f64_from_string $count)))))
        (pure
            (tv-beta-beta-late (EMPTV $strength $confidence) $beta)
            $beta
            (f64_to_string
                (sum_f64
                    (f64_from_string 1.0)
                    (sub_f64
                        (f64_from_string $count)
                        (product_f64
                            (f64_from_string $strength)
                            (f64_from_string $count))))))))

(exec (surp 206 tv-beta-final-late)
    (, (tv-beta-alpha-late $tv $alpha)
       (tv-beta-beta-late $tv $beta))
    (O
        (pure
            (tv-beta-mean-late $tv $mean)
            $mean
            (f64_to_string
                (div_f64
                    (f64_from_string $alpha)
                    (sum_f64
                        (f64_from_string $alpha)
                        (f64_from_string $beta)))))
        (pure
            (tv-beta-variance-late $tv $variance)
            $variance
            (f64_to_string
                (div_f64
                    (product_f64
                        (f64_from_string $alpha)
                        (f64_from_string $beta))
                    (product_f64
                        (product_f64
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta))
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta)))
                        (sum_f64
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta))
                            (f64_from_string 1.0))))))))

(exec (surp 206 tv-beta-assemble-late)
    (, (tv-beta-mean-late $tv $mean)
       (tv-beta-variance-late $tv $variance))
    (, (tv-beta-of $tv (Beta (mean $mean) (variance $variance)))))


;; mk_stv, part 1: compute alpha and beta from mean + variance.
(exec (surp 188 mk-stv-alpha-beta)
    (, (mk-stv-request $mean $variance))
    (O
        (pure
            (mk-stv-alpha $mean $variance $alpha)
            $alpha
            (f64_to_string
                (product_f64
                    (f64_from_string $mean)
                    (sub_f64
                        (div_f64
                            (product_f64
                                (f64_from_string $mean)
                                (sub_f64
                                    (f64_from_string 1.0)
                                    (f64_from_string $mean)))
                            (f64_from_string $variance))
                        (f64_from_string 1.0)))))
        (pure
            (mk-stv-beta $mean $variance $beta)
            $beta
            (f64_to_string
                (product_f64
                    (sub_f64
                        (f64_from_string 1.0)
                        (f64_from_string $mean))
                    (sub_f64
                        (div_f64
                            (product_f64
                                (f64_from_string $mean)
                                (sub_f64
                                    (f64_from_string 1.0)
                                    (f64_from_string $mean)))
                            (f64_from_string $variance))
                        (f64_from_string 1.0)))))))


;; mk_stv, part 2: confidence from reconstructed count.
(exec (surp 189 mk-stv-confidence)
    (, (mk-stv-alpha $mean $variance $alpha)
       (mk-stv-beta $mean $variance $beta))
    (O
        (pure
            (mk-stv-count $mean $variance $count)
            $count
            (f64_to_string
                (max_f64
                    (sub_f64
                        (sum_f64
                            (f64_from_string $alpha)
                            (f64_from_string $beta))
                        (f64_from_string 2.0))
                    (f64_from_string 0.1))))
        (pure
            (mk-stv-confidence $mean $variance $confidence)
            $confidence
            (f64_to_string
                (div_f64
                    (max_f64
                        (sub_f64
                            (sum_f64
                                (f64_from_string $alpha)
                                (f64_from_string $beta))
                            (f64_from_string 2.0))
                        (f64_from_string 0.1))
                    (sum_f64
                        (max_f64
                            (sub_f64
                                (sum_f64
                                    (f64_from_string $alpha)
                                    (f64_from_string $beta))
                                (f64_from_string 2.0))
                            (f64_from_string 0.1))
                        (f64_from_string 800.0)))))))


;; mk_stv mode calculation.
;;
;; The normal beta case is alpha > 1 and beta > 1:
;;
;;   mode = (alpha - 1) / (alpha + beta - 2)
;;
;; Edge cases are materialized separately to match PeTTa's branch shape.
(exec (surp 190 mk-stv-mode-normal)
    (, (mk-stv-alpha $mean $variance $alpha)
       (mk-stv-beta $mean $variance $beta)
       (mk-stv-confidence $mean $variance $confidence))
    (O
        (pure
            (mk-stv-alpha-gt-one $mean $variance $ok-alpha)
            $ok-alpha
            (gt_f64
                (f64_from_string $alpha)
                (f64_from_string 1.0)))
        (pure
            (mk-stv-beta-gt-one $mean $variance $ok-beta)
            $ok-beta
            (gt_f64
                (f64_from_string $beta)
                (f64_from_string 1.0)))
        (pure
            (mk-stv-normal-mode $mean $variance $mode)
            $mode
            (f64_to_string
                (div_f64
                    (sub_f64
                        (f64_from_string $alpha)
                        (f64_from_string 1.0))
                    (sub_f64
                        (sum_f64
                            (f64_from_string $alpha)
                            (f64_from_string $beta))
                        (f64_from_string 2.0)))))))


(exec (surp 191 mk-stv-result-normal)
    (, (mk-stv-alpha-gt-one $mean $variance true)
       (mk-stv-beta-gt-one $mean $variance true)
       (mk-stv-normal-mode $mean $variance $mode)
       (mk-stv-confidence $mean $variance $confidence))
    (, (mk-stv-of $mean $variance (STV $mode $confidence))))


;; Edge branches for degenerate beta distributions.  These keep the executable
;; path stable for zero/one means without introducing a Python-style nested
;; `if`.
(exec (surp 191 mk-stv-result-edge-alpha)
    (, (mk-stv-alpha-gt-one $mean $variance false)
       (mk-stv-beta-gt-one $mean $variance true)
       (mk-stv-confidence $mean $variance $confidence))
    (, (mk-stv-of $mean $variance (STV 0 $confidence))))

(exec (surp 191 mk-stv-result-edge-beta)
    (, (mk-stv-alpha-gt-one $mean $variance true)
       (mk-stv-beta-gt-one $mean $variance false)
       (mk-stv-confidence $mean $variance $confidence))
    (, (mk-stv-of $mean $variance (STV 1 $confidence))))

(exec (surp 191 mk-stv-result-edge-both)
    (, (mk-stv-alpha-gt-one $mean $variance false)
       (mk-stv-beta-gt-one $mean $variance false)
       (mk-stv-confidence $mean $variance $confidence))
    (, (mk-stv-of $mean $variance (STV $mean $confidence))))
