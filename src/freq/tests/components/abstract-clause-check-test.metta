;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta

;; Same shape, but the first candidate repeats one variable in both slots.
;; Freezing that variable prevents it from being more abstract than either
;; witness, so only the second candidate is rejected.
(ce-candidate-size 2
  ((Inheritance (var 0) (var 0))
   (Inheritance (var 0) man)
   (Inheritance ugly (var 0))) 3)
(ce-candidate-size 2
  ((Inheritance (var 0) (var 1))
   (Inheritance (var 0) man)
   (Inheritance ugly (var 1))) 3)

(exec (freq f500 call-abstract-check)
  (, (DEF ce-schedule-abstract-check-fn $check-p $check-t))
  (O (+ (exec (freq f511 run-abstract-check) $check-p $check-t))))

(EXPECTED-RESULT repeated-variable-survives (ce-candidate-size 2 ((Inheritance (var 0) (var 0)) (Inheritance (var 0) man) (Inheritance ugly (var 0))) 3))
;; TEST-ABSENT (ce-candidate-size 2 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance ugly (var 1))) 3)
