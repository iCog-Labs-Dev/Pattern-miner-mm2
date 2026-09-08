;; TEST-AUX src/jsd/kld.metta

(jsd-kld-request (0.5 1.0) (0.5 1.0))
(jsd-kld-request (0.5 1.0) (0.25 0.75 1.0))

(EXPECTED-RESULT identical-cdf-kld (jsd-kld-of (0.5 1.0) (0.5 1.0) 0.0))
(EXPECTED-RESULT kld-size-mismatch (jsd-kld-size-mismatch (0.5 1.0) (0.25 0.75 1.0)))
