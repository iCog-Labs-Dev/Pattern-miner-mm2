;; TEST-AUX src/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/truth-values/est/beta-distribution.metta
;; TEST-AUX src/truth-values/est/average-tv.metta
;; TEST-AUX src/truth-values/est/pro-tv-wout-joint.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pro-tv-wout-joint component test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (b1 b2 b3))

(block-tv-of (b1 b2 b3) b1 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3) b2 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3) b3 (EMPTV 0.2 0.1))

(EXPECTED-RESULT pro-tv-request-result (pro-tv-request (b1 b2 b3) ((EMPTV 0.2 0.1) (EMPTV 0.2 0.1) (EMPTV 0.2 0.1))))
(EXPECTED-RESULT pro-tv-result (pro-tv-wout-joint-of (b1 b2 b3) (STV 0.2 0.09999999999999998)))
