;; TEST-AUX src/isurp-modules/do-ji-prob.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-prob component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(do-ji-prob-request
    ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
     (((Inheritance (var 0) man) (Inheritance (var 0) ugly)))))

(ji-prob-est-of
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    0.125)

(ji-prob-est-of
    (((Inheritance (var 0) man) (Inheritance (var 0) ugly)))
    0.25)

(EXPECTED-RESULT do-ji-prob (do-ji-prob-of ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (((Inheritance (var 0) man) (Inheritance (var 0) ugly)))) (0.125 0.25)))
