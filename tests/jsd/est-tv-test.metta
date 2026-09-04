;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta
;; TEST-AUX src/jsd_modules/init.metta
;; TEST-AUX src/jsd_modules/emp-tv.metta
;; TEST-AUX src/jsd_modules/eq-prob.metta
;; TEST-AUX src/jsd_modules/abstraction-sort.metta
;; TEST-AUX src/jsd_modules/est-tv.metta

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x sodaDrinker) (Inheritance $x ugly)) 5))

(CONSTANT default_k 800.0)
(CONSTANT DEFAULT_K 800.0)
(CONSTANT prior-alpha 1)
(CONSTANT prior-beta 1)



;; Actual Expected Results
;; Commented out because mm2 implementation of ji-est-tv is precise enough.
;; Below are approximate results from the old implementation of ji-est-tv, which was not precise enough.
; (EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0.0 0.00019792297950462398)))
; (EXPECTED-RESULT stv (STV ((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly)) (0 0.00027229280235977334)))
; (EXPECTED-RESULT pro-prob-without-joint (pro-prob-without-joint (((Inheritance (var ) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0 0.0019792297950462397)))


(EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0.0 0.00019792297)))
(EXPECTED-RESULT stv (STV ((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly)) (0 0.0002722821)))
(EXPECTED-RESULT pro-prob-without-joint (pro-prob-without-joint (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0 0.0019792297)))
