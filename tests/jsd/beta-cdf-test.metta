;; TEST-AUX src/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/truth-values/est/beta-distribution.metta
;; TEST-AUX src/jsd/beta-cdf.metta

(jsd-cdf-request (STV 0.5 0.1) 2)

(EXPECTED-RESULT beta-cdf-mid-end (jsd-cdf-of (STV 0.5 0.1) 2 (0.5000000000000238 1.0)))
