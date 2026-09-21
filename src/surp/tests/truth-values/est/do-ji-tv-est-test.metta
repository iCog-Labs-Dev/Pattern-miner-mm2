;; TEST-AUX src/surp/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/surp/truth-values/est/beta-distribution.metta
;; TEST-AUX src/surp/truth-values/est/average-tv.metta
;; TEST-AUX src/surp/truth-values/est/do-ji-tv-est.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-tv-est component test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(do-ji-tv-est-request pattern-a (p1 p2 p3))

(ji-tv-est-of pattern-a p1 (STV 0.5 0.1))
(ji-tv-est-of pattern-a p2 (STV 0.5 0.1))
(ji-tv-est-of pattern-a p3 (STV 0.5 0.1))

(EXPECTED-RESULT do-ji-tv-list-result (do-ji-tv-est-list-of pattern-a (p1 p2 p3) ((STV 0.5 0.1) (STV 0.5 0.1) (STV 0.5 0.1))))
(EXPECTED-RESULT do-ji-tv-result (do-ji-tv-est-of pattern-a (p1 p2 p3) (STV 0.5 0.09999999999999999)))
