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
(INPUT PATTERN ((, (Inheritance $x woman) (Inheritance $x ugly)) 5))

(CONSTANT default_k 800.0)
(CONSTANT DEFAULT_K 800.0)
(CONSTANT prior-alpha 1)
(CONSTANT prior-beta 1)


(exec (est-tv 177 ji-est-tv)
    (,)
    (, 
        (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) 0.016666666666666666)
        (eq-prob-of (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker))) 0.016666666666666666)
        (eq-prob-of (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) 0.016666666666666666)
        (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) 0.0002777777777777778)
        (eq-prob-of (((Inheritance (var 0) woman)) ((Inheritance (var 0) ugly))) 0.016666666666666666)
    )
)


;; Actual Expected Results
;; Commented out because mm2 implementation of ji-est-tv is precise enough.
;; Below are approximate results from the old implementation of ji-est-tv, which was not precise enough.
; (EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0.0 0.00019792297950462398)))
; (EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker))) (0.0 0.0001979229795046239)))
; (EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) (0.0 0.0001979229795046239)))
; (EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) (4.629629629629629e-5 0.0006976744186046511)))
; (EXPECTED-RESULT stv (STV ((Inheritance (var 0) woman) (Inheritance (var 0) ugly)) (0.0027777777777780515 0.0006976744186046523)))
; (EXPECTED-RESULT pro-prob-without-joint (pro-prob-without-joint (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0 0.0019792297950462397)))


(EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0.0 0.00019792297)))
(EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker))) (0.0 0.00019792297)))
(EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) (0.0 0.00019792297)))
(EXPECTED-RESULT ji-est-tv (ji-est-tv (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) (4.6296303e-5 0.00069767446)))

(EXPECTED-RESULT stv (STV ((Inheritance (var 0) woman) (Inheritance (var 0) ugly)) (0.0027780589 0.0006976749)))

(EXPECTED-RESULT pro-prob-without-joint (pro-prob-without-joint (((Inheritance (var 0) man)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly))) (0 0.0019792297)))
