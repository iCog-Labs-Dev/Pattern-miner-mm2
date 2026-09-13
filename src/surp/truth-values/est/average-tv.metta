;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Average truth values.
;;
;; Source PeTTa function:
;;
;;   (avrg_tv $tv-list)
;;
;; Source meaning:
;;
;;   1. Convert each STV/EMPTV to a beta distribution.
;;   2. Average beta means.
;;   3. Average relative variances:
;;        variance_i + (mean_i - global_mean)^2
;;   4. Convert the averaged beta distribution back into an STV.
;;
;; MM2 public result:
;;
;;   (avrg-tv-of $tv-list (STV $strength $confidence))
;;
;; This file implements the list walk with MM2 rules only.  It does not call an
;; external helper function.  Duplicate TV values are preserved because the
;; accumulator walks the tuple position by position instead of reducing over a
;; set of emitted values.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Start the average request.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(DEF avrg-tv-start
    (, (avrg-tv-request $tv-list)
       (DEF avrg-tv-beta-step $beta-p $beta-t)
       (DEF avrg-tv-mean-step $mean-p $mean-t))
    (O
        (pure
            (avrg-tv-count-of $tv-list $count)
            $count
            (size-atom (' $tv-list)))
        (+ (avrg-tv-beta-walk $tv-list $tv-list))
        (+ (avrg-tv-mean-acc $tv-list $tv-list 0.0))
        (+ (exec (surp 175 avrg-tv-beta-step) $beta-p $beta-t))
        (+ (exec (surp 185 avrg-tv-mean-step) $mean-p $mean-t))))


(exec (surp 174 avrg-tv-start)
    (, (DEF avrg-tv-start $start-p $start-t))
    (O
        (+ (exec (surp 174 avrg-tv-start-run) $start-p $start-t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Walk the TV list and request beta conversion for every TV.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(DEF avrg-tv-beta-step
    (, (avrg-tv-beta-walk $tv-list $remaining)
       (DEF avrg-tv-beta-step $step-p $step-t))
    (O
        (pure
            (avrg-tv-beta-current $tv-list $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-beta-walk $tv-list $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-beta-walk $tv-list $remaining))
        (+ (exec (surp 175 avrg-tv-beta-step) $step-p $step-t))))


(exec (surp 176 avrg-tv-beta-request)
    (, (avrg-tv-beta-current $tv-list $tv))
    (O
        (+ (tv-beta-request $tv))
        (- (avrg-tv-beta-current $tv-list $tv))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Walk the list again and accumulate beta means.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(DEF avrg-tv-mean-step
    (, (avrg-tv-mean-acc $tv-list $remaining $sum)
       (DEF avrg-tv-mean-resolve $resolve-p $resolve-t))
    (O
        (pure
            (avrg-tv-mean-current $tv-list $remaining $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-mean-rest $tv-list $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-mean-acc $tv-list $remaining $sum))
        (+ (avrg-tv-mean-pending $tv-list $remaining $sum))
        (+ (exec (surp 186 avrg-tv-mean-resolve) $resolve-p $resolve-t))))


(DEF avrg-tv-mean-resolve
    (, (avrg-tv-mean-pending $tv-list $remaining $sum)
       (avrg-tv-mean-current $tv-list $remaining $tv)
       (avrg-tv-mean-rest $tv-list $remaining $rest)
       (tv-beta-of $tv (Beta (mean $mean) (variance $variance)))
       (DEF avrg-tv-mean-continue $continue-p $continue-t))
    (O
        (pure
            (avrg-tv-mean-next-sum $tv-list $rest $next-sum)
            $next-sum
            (f64_to_string
                (sum_f64
                    (f64_from_string $sum)
                    (f64_from_string $mean))))
        (- (avrg-tv-mean-pending $tv-list $remaining $sum))
        (- (avrg-tv-mean-current $tv-list $remaining $tv))
        (- (avrg-tv-mean-rest $tv-list $remaining $rest))
        (+ (exec (surp 187 avrg-tv-mean-continue) $continue-p $continue-t))))


(DEF avrg-tv-mean-continue
    (, (avrg-tv-mean-next-sum $tv-list $rest $next-sum)
       (DEF avrg-tv-mean-step $step-p $step-t)
       (DEF avrg-tv-mean-final $final-p $final-t))
    (O
        (- (avrg-tv-mean-next-sum $tv-list $rest $next-sum))
        (+ (avrg-tv-mean-acc $tv-list $rest $next-sum))
        (+ (exec (surp 185 avrg-tv-mean-final) $final-p $final-t))
        (+ (exec (surp 186 avrg-tv-mean-step) $step-p $step-t))))


(DEF avrg-tv-mean-final
    (, (avrg-tv-mean-acc $tv-list () $sum)
       (avrg-tv-count-of $tv-list $count)
       (DEF avrg-tv-variance-start $variance-start-p $variance-start-t))
    (O
        (pure
            (avrg-tv-mean-of $tv-list $mean)
            $mean
            (f64_to_string
                (div_f64
                    (f64_from_string $sum)
                    (f64_from_string $count))))
        (- (avrg-tv-mean-acc $tv-list () $sum))
        (+ (exec (surp 186 avrg-tv-variance-start) $variance-start-p $variance-start-t))))


(DEF avrg-tv-variance-start
    (, (avrg-tv-mean-of $tv-list $mean)
       (DEF avrg-tv-variance-step $variance-p $variance-t))
    (O
        (+ (avrg-tv-variance-acc $tv-list $tv-list $mean 0.0))
        (+ (exec (surp 186 avrg-tv-variance-step) $variance-p $variance-t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Walk the list a third time and accumulate relative variances.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(DEF avrg-tv-variance-step
    (, (avrg-tv-variance-acc $tv-list $remaining $mean $sum)
       (DEF avrg-tv-variance-resolve $resolve-p $resolve-t))
    (O
        (pure
            (avrg-tv-variance-current $tv-list $remaining $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-variance-rest $tv-list $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-variance-acc $tv-list $remaining $mean $sum))
        (+ (avrg-tv-variance-pending $tv-list $remaining $mean $sum))
        (+ (exec (surp 187 avrg-tv-variance-resolve) $resolve-p $resolve-t))))


(DEF avrg-tv-variance-resolve
    (, (avrg-tv-variance-pending $tv-list $remaining $mean $sum)
       (avrg-tv-variance-current $tv-list $remaining $tv)
       (avrg-tv-variance-rest $tv-list $remaining $rest)
       (tv-beta-of $tv (Beta (mean $tv-mean) (variance $tv-variance)))
       (DEF avrg-tv-variance-continue $continue-p $continue-t))
    (O
        (pure
            (avrg-tv-variance-next-sum $tv-list $rest $mean $next-sum)
            $next-sum
            (f64_to_string
                (sum_f64
                    (f64_from_string $sum)
                    (sum_f64
                        (f64_from_string $tv-variance)
                        (product_f64
                            (sub_f64
                                (f64_from_string $tv-mean)
                                (f64_from_string $mean))
                            (sub_f64
                                (f64_from_string $tv-mean)
                                (f64_from_string $mean)))))))
        (- (avrg-tv-variance-pending $tv-list $remaining $mean $sum))
        (- (avrg-tv-variance-current $tv-list $remaining $tv))
        (- (avrg-tv-variance-rest $tv-list $remaining $rest))
        (+ (exec (surp 188 avrg-tv-variance-continue) $continue-p $continue-t))))


(DEF avrg-tv-variance-continue
    (, (avrg-tv-variance-next-sum $tv-list $rest $mean $next-sum)
       (DEF avrg-tv-variance-step $step-p $step-t)
       (DEF avrg-tv-variance-final $final-p $final-t))
    (O
        (- (avrg-tv-variance-next-sum $tv-list $rest $mean $next-sum))
        (+ (avrg-tv-variance-acc $tv-list $rest $mean $next-sum))
        (+ (exec (surp 186 avrg-tv-variance-final) $final-p $final-t))
        (+ (exec (surp 187 avrg-tv-variance-step) $step-p $step-t))))


(DEF avrg-tv-variance-final
    (, (avrg-tv-variance-acc $tv-list () $mean $sum)
       (avrg-tv-count-of $tv-list $count)
       (DEF avrg-tv-stv-alpha-beta $stv-p $stv-t))
    (O
        (pure
            (avrg-tv-variance-of $tv-list $mean $variance)
            $variance
            (f64_to_string
                (div_f64
                    (f64_from_string $sum)
                    (f64_from_string $count))))
        (- (avrg-tv-variance-acc $tv-list () $mean $sum))
        (+ (exec (surp 188 avrg-tv-stv-alpha-beta) $stv-p $stv-t))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Convert the averaged beta distribution back to STV.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(DEF avrg-tv-stv-alpha-beta
    (, (avrg-tv-variance-of $tv-list $mean $variance)
       (DEF avrg-tv-stv-confidence $confidence-p $confidence-t))
    (O
        (pure
            (avrg-tv-stv-alpha $tv-list $mean $variance $alpha)
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
            (avrg-tv-stv-beta $tv-list $mean $variance $beta)
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
                        (f64_from_string 1.0)))))
        (+ (exec (surp 189 avrg-tv-stv-confidence) $confidence-p $confidence-t))))


(DEF avrg-tv-stv-confidence
    (, (avrg-tv-stv-alpha $tv-list $mean $variance $alpha)
       (avrg-tv-stv-beta $tv-list $mean $variance $beta)
       (DEF avrg-tv-stv-mode $mode-p $mode-t))
    (O
        (pure
            (avrg-tv-stv-confidence-of $tv-list $mean $variance $confidence)
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
                        (f64_from_string 800.0)))))
        (+ (exec (surp 190 avrg-tv-stv-mode) $mode-p $mode-t))))


(DEF avrg-tv-stv-mode
    (, (avrg-tv-stv-alpha $tv-list $mean $variance $alpha)
       (avrg-tv-stv-beta $tv-list $mean $variance $beta)
       (DEF avrg-tv-final-normal $normal-p $normal-t)
       (DEF avrg-tv-final-edge-alpha $edge-alpha-p $edge-alpha-t)
       (DEF avrg-tv-final-edge-beta $edge-beta-p $edge-beta-t)
       (DEF avrg-tv-final-edge-both $edge-both-p $edge-both-t))
    (O
        (pure
            (avrg-tv-stv-alpha-gt-one $tv-list $mean $variance $ok-alpha)
            $ok-alpha
            (gt_f64
                (f64_from_string $alpha)
                (f64_from_string 1.0)))
        (pure
            (avrg-tv-stv-beta-gt-one $tv-list $mean $variance $ok-beta)
            $ok-beta
            (gt_f64
                (f64_from_string $beta)
                (f64_from_string 1.0)))
        (pure
            (avrg-tv-stv-normal-mode $tv-list $mean $variance $mode)
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
                        (f64_from_string 2.0)))))
        (+ (exec (surp 191 avrg-tv-final-normal) $normal-p $normal-t))
        (+ (exec (surp 191 avrg-tv-final-edge-alpha) $edge-alpha-p $edge-alpha-t))
        (+ (exec (surp 191 avrg-tv-final-edge-beta) $edge-beta-p $edge-beta-t))
        (+ (exec (surp 191 avrg-tv-final-edge-both) $edge-both-p $edge-both-t))))


(DEF avrg-tv-final-normal
    (, (avrg-tv-stv-alpha-gt-one $tv-list $mean $variance true)
       (avrg-tv-stv-beta-gt-one $tv-list $mean $variance true)
       (avrg-tv-stv-normal-mode $tv-list $mean $variance $mode)
       (avrg-tv-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV $mode $confidence))))


(DEF avrg-tv-final-edge-alpha
    (, (avrg-tv-stv-alpha-gt-one $tv-list $mean $variance false)
       (avrg-tv-stv-beta-gt-one $tv-list $mean $variance true)
       (avrg-tv-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV 0 $confidence))))


(DEF avrg-tv-final-edge-beta
    (, (avrg-tv-stv-alpha-gt-one $tv-list $mean $variance true)
       (avrg-tv-stv-beta-gt-one $tv-list $mean $variance false)
       (avrg-tv-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV 1 $confidence))))


(DEF avrg-tv-final-edge-both
    (, (avrg-tv-variance-of $tv-list $mean $variance)
       (avrg-tv-stv-alpha-gt-one $tv-list $mean $variance false)
       (avrg-tv-stv-beta-gt-one $tv-list $mean $variance false)
       (avrg-tv-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV $mean $confidence))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. Late average pass.
;;
;; `do-ji-tv-est` can create average requests after the first pass has already
;; completed.  The late pass repeats the same source-level tuple walk and beta
;; arithmetic at later priorities, then emits the same public `avrg-tv-of`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec (surp 200 avrg-tv-late-start)
    (, (avrg-tv-request $tv-list)
       (DEF avrg-tv-late-beta-step $beta-p $beta-t)
       (DEF avrg-tv-late-mean-step $mean-p $mean-t))
    (O
        (pure
            (avrg-tv-late-count-of $tv-list $count)
            $count
            (size-atom (' $tv-list)))
        (+ (avrg-tv-late-beta-walk $tv-list $tv-list))
        (+ (avrg-tv-late-mean-acc $tv-list $tv-list 0.0))
        (+ (exec (surp 201 avrg-tv-late-beta-step) $beta-p $beta-t))
        (+ (exec (surp 207 avrg-tv-late-mean-step) $mean-p $mean-t))))


(DEF avrg-tv-late-beta-step
    (, (avrg-tv-late-beta-walk $tv-list $remaining)
       (DEF avrg-tv-late-beta-step $step-p $step-t))
    (O
        (pure
            (avrg-tv-late-beta-current $tv-list $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-late-beta-walk $tv-list $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-late-beta-walk $tv-list $remaining))
        (+ (exec (surp 201 avrg-tv-late-beta-step) $step-p $step-t))))


(exec (surp 202 avrg-tv-late-beta-request)
    (, (avrg-tv-late-beta-current $tv-list $tv))
    (O
        (+ (tv-beta-request $tv))
        (- (avrg-tv-late-beta-current $tv-list $tv))))


(DEF avrg-tv-late-mean-step
    (, (avrg-tv-late-mean-acc $tv-list $remaining $sum)
       (DEF avrg-tv-late-mean-resolve $resolve-p $resolve-t))
    (O
        (pure
            (avrg-tv-late-mean-current $tv-list $remaining $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-late-mean-rest $tv-list $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-late-mean-acc $tv-list $remaining $sum))
        (+ (avrg-tv-late-mean-pending $tv-list $remaining $sum))
        (+ (exec (surp 208 avrg-tv-late-mean-resolve) $resolve-p $resolve-t))))


(DEF avrg-tv-late-mean-resolve
    (, (avrg-tv-late-mean-pending $tv-list $remaining $sum)
       (avrg-tv-late-mean-current $tv-list $remaining $tv)
       (avrg-tv-late-mean-rest $tv-list $remaining $rest)
       (tv-beta-of $tv (Beta (mean $mean) (variance $variance)))
       (DEF avrg-tv-late-mean-continue $continue-p $continue-t))
    (O
        (pure
            (avrg-tv-late-mean-next-sum $tv-list $rest $next-sum)
            $next-sum
            (f64_to_string
                (sum_f64
                    (f64_from_string $sum)
                    (f64_from_string $mean))))
        (- (avrg-tv-late-mean-pending $tv-list $remaining $sum))
        (- (avrg-tv-late-mean-current $tv-list $remaining $tv))
        (- (avrg-tv-late-mean-rest $tv-list $remaining $rest))
        (+ (exec (surp 209 avrg-tv-late-mean-continue) $continue-p $continue-t))))


(DEF avrg-tv-late-mean-continue
    (, (avrg-tv-late-mean-next-sum $tv-list $rest $next-sum)
       (DEF avrg-tv-late-mean-step $step-p $step-t)
       (DEF avrg-tv-late-mean-final $final-p $final-t))
    (O
        (- (avrg-tv-late-mean-next-sum $tv-list $rest $next-sum))
        (+ (avrg-tv-late-mean-acc $tv-list $rest $next-sum))
        (+ (exec (surp 207 avrg-tv-late-mean-final) $final-p $final-t))
        (+ (exec (surp 208 avrg-tv-late-mean-step) $step-p $step-t))))


(DEF avrg-tv-late-mean-final
    (, (avrg-tv-late-mean-acc $tv-list () $sum)
       (avrg-tv-late-count-of $tv-list $count)
       (DEF avrg-tv-late-variance-start $variance-start-p $variance-start-t))
    (O
        (pure
            (avrg-tv-late-mean-of $tv-list $mean)
            $mean
            (f64_to_string
                (div_f64
                    (f64_from_string $sum)
                    (f64_from_string $count))))
        (- (avrg-tv-late-mean-acc $tv-list () $sum))
        (+ (exec (surp 210 avrg-tv-late-variance-start) $variance-start-p $variance-start-t))))


(DEF avrg-tv-late-variance-start
    (, (avrg-tv-late-mean-of $tv-list $mean)
       (DEF avrg-tv-late-variance-step $variance-p $variance-t))
    (O
        (+ (avrg-tv-late-variance-acc $tv-list $tv-list $mean 0.0))
        (+ (exec (surp 211 avrg-tv-late-variance-step) $variance-p $variance-t))))


(DEF avrg-tv-late-variance-step
    (, (avrg-tv-late-variance-acc $tv-list $remaining $mean $sum)
       (DEF avrg-tv-late-variance-resolve $resolve-p $resolve-t))
    (O
        (pure
            (avrg-tv-late-variance-current $tv-list $remaining $tv)
            $tv
            (car-atom (' $remaining)))
        (pure
            (avrg-tv-late-variance-rest $tv-list $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (avrg-tv-late-variance-acc $tv-list $remaining $mean $sum))
        (+ (avrg-tv-late-variance-pending $tv-list $remaining $mean $sum))
        (+ (exec (surp 212 avrg-tv-late-variance-resolve) $resolve-p $resolve-t))))


(DEF avrg-tv-late-variance-resolve
    (, (avrg-tv-late-variance-pending $tv-list $remaining $mean $sum)
       (avrg-tv-late-variance-current $tv-list $remaining $tv)
       (avrg-tv-late-variance-rest $tv-list $remaining $rest)
       (tv-beta-of $tv (Beta (mean $tv-mean) (variance $tv-variance)))
       (DEF avrg-tv-late-variance-continue $continue-p $continue-t))
    (O
        (pure
            (avrg-tv-late-variance-next-sum $tv-list $rest $mean $next-sum)
            $next-sum
            (f64_to_string
                (sum_f64
                    (f64_from_string $sum)
                    (sum_f64
                        (f64_from_string $tv-variance)
                        (product_f64
                            (sub_f64
                                (f64_from_string $tv-mean)
                                (f64_from_string $mean))
                            (sub_f64
                                (f64_from_string $tv-mean)
                                (f64_from_string $mean)))))))
        (- (avrg-tv-late-variance-pending $tv-list $remaining $mean $sum))
        (- (avrg-tv-late-variance-current $tv-list $remaining $tv))
        (- (avrg-tv-late-variance-rest $tv-list $remaining $rest))
        (+ (exec (surp 213 avrg-tv-late-variance-continue) $continue-p $continue-t))))


(DEF avrg-tv-late-variance-continue
    (, (avrg-tv-late-variance-next-sum $tv-list $rest $mean $next-sum)
       (DEF avrg-tv-late-variance-step $step-p $step-t)
       (DEF avrg-tv-late-variance-final $final-p $final-t))
    (O
        (- (avrg-tv-late-variance-next-sum $tv-list $rest $mean $next-sum))
        (+ (avrg-tv-late-variance-acc $tv-list $rest $mean $next-sum))
        (+ (exec (surp 211 avrg-tv-late-variance-final) $final-p $final-t))
        (+ (exec (surp 212 avrg-tv-late-variance-step) $step-p $step-t))))


(DEF avrg-tv-late-variance-final
    (, (avrg-tv-late-variance-acc $tv-list () $mean $sum)
       (avrg-tv-late-count-of $tv-list $count)
       (DEF avrg-tv-late-stv-alpha-beta $stv-p $stv-t))
    (O
        (pure
            (avrg-tv-late-variance-of $tv-list $mean $variance)
            $variance
            (f64_to_string
                (div_f64
                    (f64_from_string $sum)
                    (f64_from_string $count))))
        (- (avrg-tv-late-variance-acc $tv-list () $mean $sum))
        (+ (exec (surp 214 avrg-tv-late-stv-alpha-beta) $stv-p $stv-t))))


(DEF avrg-tv-late-stv-alpha-beta
    (, (avrg-tv-late-variance-of $tv-list $mean $variance)
       (DEF avrg-tv-late-stv-confidence $confidence-p $confidence-t))
    (O
        (pure
            (avrg-tv-late-stv-alpha $tv-list $mean $variance $alpha)
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
            (avrg-tv-late-stv-beta $tv-list $mean $variance $beta)
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
                        (f64_from_string 1.0)))))
        (+ (exec (surp 215 avrg-tv-late-stv-confidence) $confidence-p $confidence-t))))


(DEF avrg-tv-late-stv-confidence
    (, (avrg-tv-late-stv-alpha $tv-list $mean $variance $alpha)
       (avrg-tv-late-stv-beta $tv-list $mean $variance $beta)
       (DEF avrg-tv-late-stv-mode $mode-p $mode-t))
    (O
        (pure
            (avrg-tv-late-stv-confidence-of $tv-list $mean $variance $confidence)
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
                        (f64_from_string 800.0)))))
        (+ (exec (surp 216 avrg-tv-late-stv-mode) $mode-p $mode-t))))


(DEF avrg-tv-late-stv-mode
    (, (avrg-tv-late-stv-alpha $tv-list $mean $variance $alpha)
       (avrg-tv-late-stv-beta $tv-list $mean $variance $beta)
       (DEF avrg-tv-late-final-normal $normal-p $normal-t)
       (DEF avrg-tv-late-final-edge-alpha $edge-alpha-p $edge-alpha-t)
       (DEF avrg-tv-late-final-edge-beta $edge-beta-p $edge-beta-t)
       (DEF avrg-tv-late-final-edge-both $edge-both-p $edge-both-t))
    (O
        (pure
            (avrg-tv-late-stv-alpha-gt-one $tv-list $mean $variance $ok-alpha)
            $ok-alpha
            (gt_f64
                (f64_from_string $alpha)
                (f64_from_string 1.0)))
        (pure
            (avrg-tv-late-stv-beta-gt-one $tv-list $mean $variance $ok-beta)
            $ok-beta
            (gt_f64
                (f64_from_string $beta)
                (f64_from_string 1.0)))
        (pure
            (avrg-tv-late-stv-normal-mode $tv-list $mean $variance $mode)
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
                        (f64_from_string 2.0)))))
        (+ (exec (surp 217 avrg-tv-late-final-normal) $normal-p $normal-t))
        (+ (exec (surp 217 avrg-tv-late-final-edge-alpha) $edge-alpha-p $edge-alpha-t))
        (+ (exec (surp 217 avrg-tv-late-final-edge-beta) $edge-beta-p $edge-beta-t))
        (+ (exec (surp 217 avrg-tv-late-final-edge-both) $edge-both-p $edge-both-t))))


(DEF avrg-tv-late-final-normal
    (, (avrg-tv-late-stv-alpha-gt-one $tv-list $mean $variance true)
       (avrg-tv-late-stv-beta-gt-one $tv-list $mean $variance true)
       (avrg-tv-late-stv-normal-mode $tv-list $mean $variance $mode)
       (avrg-tv-late-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV $mode $confidence))))


(DEF avrg-tv-late-final-edge-alpha
    (, (avrg-tv-late-stv-alpha-gt-one $tv-list $mean $variance false)
       (avrg-tv-late-stv-beta-gt-one $tv-list $mean $variance true)
       (avrg-tv-late-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV 0 $confidence))))


(DEF avrg-tv-late-final-edge-beta
    (, (avrg-tv-late-stv-alpha-gt-one $tv-list $mean $variance true)
       (avrg-tv-late-stv-beta-gt-one $tv-list $mean $variance false)
       (avrg-tv-late-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV 1 $confidence))))


(DEF avrg-tv-late-final-edge-both
    (, (avrg-tv-late-variance-of $tv-list $mean $variance)
       (avrg-tv-late-stv-alpha-gt-one $tv-list $mean $variance false)
       (avrg-tv-late-stv-beta-gt-one $tv-list $mean $variance false)
       (avrg-tv-late-stv-confidence-of $tv-list $mean $variance $confidence))
    (, (avrg-tv-of $tv-list (STV $mean $confidence))))
