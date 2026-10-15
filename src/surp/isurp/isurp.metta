;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Newer ISurp integration
;;
;; This module connects the already-ported helper stages:
;;
;;   partitions -> do-ji-prob -> ji interval
;;   input pattern/support -> emp-prob-pbs
;;   interval + empirical probability -> distance
;;   distance -> final normalized/raw ISurp value
;;
;; Public final result:
;;
;;   (isurp-of $pattern $value)
;;
;; This is the active modular ISurp integration path.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. ji_prob_est_interval
;;
;; Source PeTTa:
;;
;;   ($comp-ji (do-ji-prob $gen-parts $pattern $db $db_ratio))
;;   ($emin (min-atom $comp-ji))
;;   ($emax (max-atom $comp-ji))
;;
;; MM2 materialized result:
;;
;;   (ji-prob-est-interval-of $pattern $partitions $emin $emax)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec (surp s120 ji-interval)
    (, (do-ji-prob-of $pattern $partitions $prob-list))
    (O
        (pure
            (ji-prob-est-min-of $pattern $partitions $emin)
            $emin
            (min-atom (' $prob-list)))
        (pure
            (ji-prob-est-max-of $pattern $partitions $emax)
            $emax
            (max-atom (' $prob-list)))))


(exec (surp s121 ji-interval)
    (, (ji-prob-est-min-of $pattern $partitions $emin)
       (ji-prob-est-max-of $pattern $partitions $emax))
    (, (ji-prob-est-interval-of $pattern $partitions $emin $emax)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Distance from interval
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec (surp s122 isurp-distance-request)
    (, (isurp-pattern $pattern $support)
       (ji-prob-partitions-of $pattern $partitions)
       (ji-prob-est-interval-of $pattern $partitions $emin $emax)
       (emp-prob-pbs-of $pattern $emp)
       ((dst-from-interval $pattern $emin $emax $emp -> isurp-new-dst-of) $src $sink))
    (O
        (+ (isurp-new-interval-of $pattern $emin $emax))
        (+ (dst-request $pattern $emin $emax $emp isurp-new-dst-of))
        (+ (exec (surp s122 isurp-distance-request) $src $sink))
        (pure
            (isurp-new-dst-of $pattern $direct-dst)
            $direct-dst
            (f64_to_string
                (max_f64
                    (sub_f64
                        (f64_from_string $emin)
                        (f64_from_string $emp))
                    (sub_f64
                        (f64_from_string $emp)
                        (f64_from_string $emax))
                    (f64_from_string 0.0))))))


;; Local distance predicates.  These mirror `dst-from-interval`, but keep the
;; newer ISurp path independent from the spawned reusable helper.
(exec (surp s123 isurp-distance-bools)
    (, (isurp-new-interval-of $pattern $emin $emax)
       (emp-prob-pbs-of $pattern $emp))
    (O
        (pure
            (isurp-new-above? $pattern $emin $emax $emp $above)
            $above
            (gt_f64
                (f64_from_string $emp)
                (f64_from_string $emax)))
        (pure
            (isurp-new-below? $pattern $emin $emax $emp $below)
            $below
            (lt_f64
                (f64_from_string $emp)
                (f64_from_string $emin)))
        (pure
            (isurp-new-inside? $pattern $emin $emax $emp $inside)
            $inside
            (and_bool
                (le_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))
                (le_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))))


;; Numeric distance from interval without boolean guards:
;;
;;   max(emin - emp, emp - emax, 0.0)
;;
;; If `emp` is inside the interval, both differences are <= 0, so the distance
;; is 0.0.
(exec (surp s124 isurp-distance-candidates)
    (, (isurp-new-interval-of $pattern $emin $emax)
       (emp-prob-pbs-of $pattern $emp))
    (O
        (pure
            (isurp-new-below-distance-candidate $pattern $below)
            $below
            (f64_to_string
                (sub_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))))
        (pure
            (isurp-new-above-distance-candidate $pattern $above)
            $above
            (f64_to_string
                (sub_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))
        (+ (exec (surp s125 isurp-distance-direct)
            (, (isurp-new-below-distance-candidate $p $below-value)
               (isurp-new-above-distance-candidate $p $above-value))
            (O
                (pure
                    (isurp-new-dst-of $p $dst)
                    $dst
                    (f64_to_string
                        (max_f64
                            (f64_from_string $below-value)
                            (f64_from_string $above-value)
                            (f64_from_string 0.0)))))))))


(exec (surp s125 isurp-distance-direct)
    (, (isurp-new-below-distance-candidate $pattern $below)
       (isurp-new-above-distance-candidate $pattern $above))
    (O
        (pure
            (isurp-new-dst-of $pattern $dst)
            $dst
            (f64_to_string
                (max_f64
                    (f64_from_string $below)
                    (f64_from_string $above)
                    (f64_from_string 0.0))))))


;; Case 1: empirical probability is above the interval.
(exec (surp s126 isurp-distance-above)
    (, (isurp-new-above? $pattern $emin $emax $emp true))
    (O
        (pure
            (isurp-new-dst-of $pattern $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))
        (- (isurp-new-above? $pattern $emin $emax $emp true))))


;; Case 2: empirical probability is below the interval.
(exec (surp s126 isurp-distance-below)
    (, (isurp-new-below? $pattern $emin $emax $emp true))
    (O
        (pure
            (isurp-new-dst-of $pattern $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))))
        (- (isurp-new-below? $pattern $emin $emax $emp true))))


;; Case 3: empirical probability is inside the interval.
(exec (surp s126 isurp-distance-inside)
    (, (isurp-new-inside? $pattern $emin $emax $emp true))
    (O
        (+ (isurp-new-dst-of $pattern 0.0))
        (- (isurp-new-inside? $pattern $emin $emax $emp true))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Normalize or return raw distance
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec (surp s127 isurp-normalization-denom)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-new-dst-of $pattern $dst)
       (emp-prob-pbs-of $pattern $emp)
       (isurp-new-interval-of $pattern $emin $emax))
    (O
        (pure
            (isurp-new-normalization-denom $pattern $dst $denom)
            $denom
            (max-atom (' ($emax $emp))))))


(exec (surp s128 isurp-normalization-candidate)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-new-dst-of $pattern $dst)
       (isurp-new-normalization-denom $pattern $dst $denom))
    (O
        (pure
            (isurp-new-normalization-candidate $pattern $dst $candidate)
            $candidate
            (f64_to_string
                (div_f64
                    (f64_from_string $dst)
                    (f64_from_string $denom))))))


(exec (surp s129 isurp-normalized-final)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-new-normalization-candidate $pattern $dst $candidate))
    (O
        (pure
            (isurp-of $pattern $value)
            $value
            (min-atom (' ($candidate 1.0))))))


(exec (surp s129 isurp-raw-final)
    (, (INPUT NORMALIZATION FALSE)
       (isurp-new-dst-of $pattern $dst))
    (O
        (pure
            (isurp-of $pattern $value)
            $value
            (min-atom (' ($dst 1.0))))))
