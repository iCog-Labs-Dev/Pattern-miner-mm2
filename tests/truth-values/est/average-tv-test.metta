;; TEST-AUX src/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/truth-values/est/beta-distribution.metta
;; TEST-AUX src/truth-values/est/average-tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; avrg_tv component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(avrg-tv-request ((STV 0.5 0.1) (STV 0.5 0.1)))

(EXPECTED-RESULT avrg-tv-identical (avrg-tv-of ((STV 0.5 0.1) (STV 0.5 0.1)) (STV 0.5 0.09999999999999999)))
