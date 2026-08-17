;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/02_beta_distribution.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta
;; TEST-AUX src/truth-values/est/06_do_ji_tv_est.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-tv-est component test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(do-ji-tv-est-request (p1 p2 p3))

(ji-tv-est-of p1 (STV 0.5 0.1))
(ji-tv-est-of p2 (STV 0.5 0.1))
(ji-tv-est-of p3 (STV 0.5 0.1))

(EXPECTED-RESULT do-ji-tv-list-result (do-ji-tv-est-list-of (p1 p2 p3) ((STV 0.5 0.1) (STV 0.5 0.1) (STV 0.5 0.1))))
(EXPECTED-RESULT do-ji-tv-result (do-ji-tv-est-of (p1 p2 p3) (STV 0.5 0.09999999999999999)))
