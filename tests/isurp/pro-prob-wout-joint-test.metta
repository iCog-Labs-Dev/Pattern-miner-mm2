;; TEST-AUX src/isurp-modules/pro-prob-wout-joint.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pro-prob-wout-joint component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)

(EXPECTED-RESULT pro-block-man (pro-block-prob (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) ((Inheritance (var 0) man)) 0.5))

(EXPECTED-RESULT pro-prob-wout-joint (pro-prob-wout-joint-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.25))
