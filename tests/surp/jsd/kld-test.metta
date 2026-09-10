;; TEST-AUX src/surp/jsd/kld.metta

(jsd-kld-request (0.5 1.0) (0.5 1.0))

(EXPECTED-RESULT identical-cdf-kld (jsd-kld-of (0.5 1.0) (0.5 1.0) 0.0))
