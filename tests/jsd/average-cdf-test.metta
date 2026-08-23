;; TEST-AUX src/jsd/average-cdf.metta

(jsd-average-cdf-request (0.2 0.6 1.0) (0.4 0.7 1.0))

(EXPECTED-RESULT average-cdf (jsd-average-cdf-of (0.2 0.6 1.0) (0.4 0.7 1.0) (0.30000000000000004 0.6499999999999999 1.0)))
