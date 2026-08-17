;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/02_beta_distribution.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; avrg_tv component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(avrg-tv-request ((STV 0.5 0.1) (STV 0.5 0.1)))

(EXPECTED-RESULT avrg-tv-identical (avrg-tv-of ((STV 0.5 0.1) (STV 0.5 0.1)) (STV 0.5 0.09999999999999999)))
