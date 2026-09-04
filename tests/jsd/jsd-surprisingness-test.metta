;; TEST-AUX src/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/truth-values/est/beta-distribution.metta
;; TEST-AUX src/jsd/beta-cdf.metta
;; TEST-AUX src/jsd/average-cdf.metta
;; TEST-AUX src/jsd/kld.metta
;; TEST-AUX src/jsd/do-jsd.metta
;; TEST-AUX src/jsd/jsd-surprisingness.metta

(emp-tv-of pattern-a (EMPTV 0.5 0.1))
(est-tv-of pattern-a (STV 0.5 0.1))

(EXPECTED-RESULT identical-pattern-jsd (jsd-surp-of pattern-a 0.0))
