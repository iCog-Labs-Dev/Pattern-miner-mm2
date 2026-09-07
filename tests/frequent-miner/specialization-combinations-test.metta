;; TEST-AUX src/frequent-miner.metta

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(run-specialization spec-test (Inheritance $x $y))

(shallow-abstraction-binding spec-test (root arg/1) (var 0) Allen)
(shallow-abstraction-binding spec-test (root arg/1) (var 0) Lily)
(shallow-abstraction-binding spec-test (root arg/1) (var 0) (var 0))
(shallow-abstraction-binding spec-test (root arg/2) (var 1) human)
(shallow-abstraction-binding spec-test (root arg/2) (var 1) sodaDrinker)
(shallow-abstraction-binding spec-test (root arg/2) (var 1) (var 1))

(exec (freq 000 call-specialization-combinations)
  (, (run-specialization spec-test (Inheritance $x $y))
     (DEF specialization-combinations-fn $spec-p $spec-t))
  (O (+ (exec (freq 001 run-specialization-combinations) $spec-p $spec-t))))
  
(EXPECTED-RESULT specialization-var-var (specialization-result spec-test (Inheritance (var 0) (var 1))))
(EXPECTED-RESULT specialization-var-human (specialization-result spec-test (Inheritance (var 0) human)))
(EXPECTED-RESULT specialization-var-soda (specialization-result spec-test (Inheritance (var 0) sodaDrinker)))
(EXPECTED-RESULT specialization-lily-var (specialization-result spec-test (Inheritance Lily (var 1))))
(EXPECTED-RESULT specialization-lily-human (specialization-result spec-test (Inheritance Lily human)))
(EXPECTED-RESULT specialization-lily-soda (specialization-result spec-test (Inheritance Lily sodaDrinker)))
(EXPECTED-RESULT specialization-allen-var (specialization-result spec-test (Inheritance Allen (var 1))))
(EXPECTED-RESULT specialization-allen-human (specialization-result spec-test (Inheritance Allen human)))
(EXPECTED-RESULT specialization-allen-soda (specialization-result spec-test (Inheritance Allen sodaDrinker)))