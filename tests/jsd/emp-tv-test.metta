;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta
;; TEST-AUX src/jsd_modules/init.metta
;; TEST-AUX src/jsd_modules/emp-tv.metta
;; TEST-AUX src/jsd_modules/est-tv.metta

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (inheritance $x woman) (inheritance $x sodaDrinker)) 5))

(CONSTANT default_k 800.0)
(CONSTANT DEFAULT_K 800.0)
(CONSTANT prior-alpha 1)
(CONSTANT prior-beta 1)



(eq-prob-of (((inheritance (var 0) woman)) ((inheritance (var 0) sodaDrinker))) 0.016666666666666666)

(EXPECTED-RESULT emp-tv (EMPTV ((inheritance (var 0) woman) (inheritance (var 0) sodaDrinker)) (0.0013888889 0.081818186)))



(est-mk-stv-mean test-pattern test-db 1.7689693569125715)
(est-mk-stv-var test-pattern test-db 1.0178393379503528)

(EXPECTED-RESULT mk-stv (mk-stv 1.7689693569125715 1.0178393379503528 (0 0.00012498438)))

