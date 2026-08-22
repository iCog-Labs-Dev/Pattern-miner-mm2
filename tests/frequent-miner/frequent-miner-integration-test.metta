;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/frequent-miner.metta

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(INPUT MIN-SUPPORT 5)

(run-frequent-miner fm-test (Inheritance $x $y))

(exec (freq 000 load-frequent-miner-facts)
  (, (Inheritance $entity $class))
  (O
    (+ (FACT (Inheritance $entity $class)))))

(exec (freq 001 call-frequent-miner)
  (, (run-frequent-miner fm-test (Inheritance $x $y))
     (DEF frequent-miner-fn $freq-p $freq-t))
  (O
    (+ (exec (freq 002 run-frequent-miner) $freq-p $freq-t))))

(EXPECTED-RESULT frequent-miner-human (candidate-pattern fm-test (Inheritance (var 0) human) 19))
(EXPECTED-RESULT frequent-miner-man (candidate-pattern fm-test (Inheritance (var 0) man) 10))
(EXPECTED-RESULT frequent-miner-woman (candidate-pattern fm-test (Inheritance (var 0) woman) 10))
(EXPECTED-RESULT frequent-miner-ugly (candidate-pattern fm-test (Inheritance (var 0) ugly) 10))
(EXPECTED-RESULT frequent-miner-soda (candidate-pattern fm-test (Inheritance (var 0) sodaDrinker) 10))
