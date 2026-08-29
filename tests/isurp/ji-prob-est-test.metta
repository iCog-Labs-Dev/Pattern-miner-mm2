;; TEST-AUX src/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/isurp-modules/eq-prob.metta
;; TEST-AUX src/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/isurp-modules/ji-prob-est.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ji-prob-est component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

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

(EXPECTED-RESULT ji-prob-est (ji-prob-est-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.0625))
