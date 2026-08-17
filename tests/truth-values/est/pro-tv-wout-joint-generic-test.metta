;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta
;; TEST-AUX src/truth-values/est/04_pro_tv_wout_joint.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pro-tv-wout-joint generic partition walk.
;;
;; This intentionally uses five blocks to validate that block collection is
;; handled by the generic walker.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (b1 b2 b3 b4 b5))

(block-tv-of (b1 b2 b3 b4 b5) b1 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3 b4 b5) b2 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3 b4 b5) b3 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3 b4 b5) b4 (EMPTV 0.2 0.1))
(block-tv-of (b1 b2 b3 b4 b5) b5 (EMPTV 0.2 0.1))

(EXPECTED-RESULT pro-tv-five-block-request (pro-tv-request (b1 b2 b3 b4 b5) ((EMPTV 0.2 0.1) (EMPTV 0.2 0.1) (EMPTV 0.2 0.1) (EMPTV 0.2 0.1) (EMPTV 0.2 0.1))))
(EXPECTED-RESULT pro-tv-five-block-result (pro-tv-wout-joint-of (b1 b2 b3 b4 b5) (STV 0.2 0.1)))
