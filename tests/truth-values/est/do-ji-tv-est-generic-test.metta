;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta
;; TEST-AUX src/truth-values/est/06_do_ji_tv_est.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-tv-est generic partition walk.
;;
;; This intentionally uses five partitions to validate that partition
;; collection is handled by the generic walker.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(do-ji-tv-est-request (p1 p2 p3 p4 p5))

(ji-tv-est-of p1 (STV 0.5 0.1))
(ji-tv-est-of p2 (STV 0.5 0.1))
(ji-tv-est-of p3 (STV 0.5 0.1))
(ji-tv-est-of p4 (STV 0.5 0.1))
(ji-tv-est-of p5 (STV 0.5 0.1))

(EXPECTED-RESULT do-ji-tv-five-partition-list (do-ji-tv-est-list-of (p1 p2 p3 p4 p5) ((STV 0.5 0.1) (STV 0.5 0.1) (STV 0.5 0.1) (STV 0.5 0.1) (STV 0.5 0.1))))
(EXPECTED-RESULT do-ji-tv-five-partition-result (do-ji-tv-est-of (p1 p2 p3 p4 p5) (STV 0.5 0.09999999999999999)))
