;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/02_beta_distribution.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Beta distribution truth-value helper tests.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(tv-beta-request (STV 0.5 0.1))
(mk-stv-request 0.5 0.002688172043010753)

(EXPECTED-RESULT beta-stv (tv-beta-of (STV 0.5 0.1) (Beta (mean 0.5) (variance 0.002720677146311971))))

(EXPECTED-RESULT mk-stv (mk-stv-of 0.5 0.002688172043010753 (STV 0.5 0.10112359550561796)))
