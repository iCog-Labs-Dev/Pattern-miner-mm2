;; TEST-AUX src/isurp_modules/08_emp_prob_pbs.metta
;; TEST-AUX src/truth-values/emp/00_emp_tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Empirical truth value component test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(INPUT PATTERN
    ((, (Inheritance (var 0) man)
        (Inheritance (var 0) ugly))
     1))

(EXPECTED-RESULT emp-tv (emp-tv-of (, (Inheritance (var 0) man) (Inheritance (var 0) ugly)) (EMPTV 0.0625 0.00196078431372549)))
