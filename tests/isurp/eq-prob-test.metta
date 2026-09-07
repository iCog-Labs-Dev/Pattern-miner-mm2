;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/isurp_modules/03_abstractness_sort.metta
;; TEST-AUX src/isurp_modules/04_eq_prob.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eq-prob component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(block
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man)))

(block
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly)))

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)

(EXPECTED-RESULT eq-joint-var (eq-joint-var (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0)))

(EXPECTED-RESULT eq-prob (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.5))
