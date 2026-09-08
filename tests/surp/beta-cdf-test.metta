;; TEST-AUX src/common-utils/beta-cdf.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Beta(alpha, beta) CDF  ==  regularized incomplete beta  I_x(alpha, beta)
;;
;; Reference values (scipy.stats.beta.cdf, confirmed by direct integration):
;;     I_0.5 (0.5, 0.5) = 0.5                 ( = (2/pi) asin(sqrt 0.5) )
;;     I_0.5 (5,   2)   = 0.109375
;;     I_0.5 (2,   3)   = 0.6875
;;     I_0.5 (2,   2)   = 0.5
;;     I_0.37(1,   1)   = 0.37
;;     I_0.25(3,   7)   = 0.399322509766      (non-round; exercises rounding)
;;   x is clamped to [0, 1]:
;;     I_(-0.2)(2, 3)   = 0.0
;;     I_(1.5) (2, 3)   = 1.0
;;
;; beta-cdf.metta rounds its result to 1e-12, so these strings are exact.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(beta-cdf? sym  0.5 0.5 0.5)
(beta-cdf? p52  5.0 2.0 0.5)
(beta-cdf? p23  2.0 3.0 0.5)
(beta-cdf? p22  2.0 2.0 0.5)
(beta-cdf? u11  1.0 1.0 0.37)
(beta-cdf? p37  3.0 7.0 0.25)
(beta-cdf? clo  2.0 3.0 -0.2)
(beta-cdf? chi  2.0 3.0 1.5)

(EXPECTED-RESULT beta-cdf-symmetric  (beta-cdf-of sym 0.5))
(EXPECTED-RESULT beta-cdf-5-2        (beta-cdf-of p52 0.109375))
(EXPECTED-RESULT beta-cdf-2-3        (beta-cdf-of p23 0.6875))
(EXPECTED-RESULT beta-cdf-2-2        (beta-cdf-of p22 0.5))
(EXPECTED-RESULT beta-cdf-uniform    (beta-cdf-of u11 0.37))
(EXPECTED-RESULT beta-cdf-3-7        (beta-cdf-of p37 0.399322509766))
(EXPECTED-RESULT beta-cdf-clamp-low  (beta-cdf-of clo 0.0))
(EXPECTED-RESULT beta-cdf-clamp-high (beta-cdf-of chi 1.0))
