;; TEST-AUX src/surp/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/surp/truth-values/est/beta-distribution.metta
;; TEST-AUX src/surp/jsd/beta-cdf.metta
;; TEST-AUX src/surp/jsd/average-cdf.metta
;; TEST-AUX src/surp/jsd/kld.metta
;; TEST-AUX src/surp/jsd/do-jsd.metta

(do-jsd-request (STV 0.5 0.1) (STV 0.5 0.1) 4)
(do-jsd-request (STV 0.3 0.1) (STV 0.7 0.1) 4)

(EXPECTED-RESULT identical-tv-jsd (do-jsd-of (STV 0.5 0.1) (STV 0.5 0.1) 4 0.0))
(EXPECTED-RESULT nonidentical-tv-jsd (do-jsd-of (STV 0.3 0.1) (STV 0.7 0.1) 4 0.9994540468031129))
