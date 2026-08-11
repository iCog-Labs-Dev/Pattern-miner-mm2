;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Truth value definition helper tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(count-confidence-request 16)
(confidence-count-request 0.1)
(tv-beta-request (STV 0.5 0.1))
(mk-stv-request 0.5 0.002688172043010753)

(EXPECTED-RESULT count-confidence (count-confidence-of 16 0.0196078431372549))

(EXPECTED-RESULT confidence-count (confidence-count-of 0.1 88.88888888888889))

(EXPECTED-RESULT beta-stv (tv-beta-of (STV 0.5 0.1) (Beta (mean 0.5) (variance 0.002720677146311971))))

(EXPECTED-RESULT mk-stv (mk-stv-of 0.5 0.002688172043010753 (STV 0.5 0.10112359550561796)))
