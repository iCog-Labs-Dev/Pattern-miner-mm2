;; TEST-AUX src/truth-values/est/truth-value-defs.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Truth value definition helper tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(count-confidence-request 16)
(confidence-count-request 0.1)

(EXPECTED-RESULT count-confidence (count-confidence-of 16 0.0196078431372549))

(EXPECTED-RESULT confidence-count (confidence-count-of 0.1 88.88888888888889))
