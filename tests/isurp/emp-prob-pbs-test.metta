;; TEST-AUX src/isurp-modules/emp-prob-pbs.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; emp-prob-pbs component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(INPUT PATTERN
    ((, (Inheritance (var 0) man)
        (Inheritance (var 0) ugly))
     4))

(EXPECTED-RESULT emp-universe (emp-prob-pbs-universe-count (, (Inheritance (var 0) man) (Inheritance (var 0) ugly)) 16))

(EXPECTED-RESULT emp-prob (emp-prob-pbs-of (, (Inheritance (var 0) man) (Inheritance (var 0) ugly)) 0.25))
