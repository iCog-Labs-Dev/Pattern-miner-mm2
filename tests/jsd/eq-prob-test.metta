;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta
;; TEST-AUX src/jsd_modules/init.metta
;; TEST-AUX src/jsd_modules/emp-tv.metta
;; TEST-AUX src/jsd_modules/eq-prob.metta
;; TEST-AUX src/jsd_modules/abstraction-sort.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eq-prob component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x ugly)) 1))
(INPUT DB-SIZE 4)
(INPUT DB db)



(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)

(EXPECTED-RESULT eq-joint-var (eq-joint-var (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0)))
(EXPECTED-RESULT eq-prob (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.25))
