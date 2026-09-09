;; TEST-AUX src/frequent-miner.metta
;; TEST-STEPS 100000

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(INPUT MIN-SUPPORT 2)

(run-iterative-miner iter-smoke (Inheritance $a $b))

(FACT (Inheritance Allen sodaDrinker))
(FACT (Inheritance Abe sodaDrinker))
(FACT (Inheritance Cason sodaDrinker))
(FACT (Inheritance Davion sodaDrinker))
(FACT (Inheritance Hessley sodaDrinker))
(FACT (Inheritance Breonna sodaDrinker))
(FACT (Inheritance Jaleesa sodaDrinker))
(FACT (Inheritance Jassy sodaDrinker))
(FACT (Inheritance Jenica (eval gen sodarinker)))
(FACT (Inheritance Kecia (eval gen sodarinker)))

(exec (freq 001 call-iterative-miner)
  (, (run-iterative-miner iter-smoke (Inheritance $a $b))
     (DEF iterative-miner-fn $iter-p $iter-t))
  (O
    (+ (exec (freq 002 run-iterative-miner) $iter-p $iter-t))))

(EXPECTED-RESULT iterative-miner-nested-all (iterative-candidate-pattern iter-smoke (Inheritance $a (eval $b $c)) (Inheritance (var 0) (eval (var 1) (var 2))) 2))
(EXPECTED-RESULT iterative-miner-nested-right-const (iterative-candidate-pattern iter-smoke (Inheritance $a (eval $b $c)) (Inheritance (var 0) (eval (var 1) sodarinker)) 2))
(EXPECTED-RESULT iterative-miner-nested-left-const (iterative-candidate-pattern iter-smoke (Inheritance $a (eval $b $c)) (Inheritance (var 0) (eval gen (var 2))) 2))
(EXPECTED-RESULT iterative-miner-nested-const (iterative-candidate-pattern iter-smoke (Inheritance $a (eval $b $c)) (Inheritance (var 0) (eval gen sodarinker)) 2))
(EXPECTED-RESULT iterative-miner-all (iterative-candidate-pattern iter-smoke (Inheritance $a $b) (Inheritance (var 0) (var 1)) 10))
(EXPECTED-RESULT iterative-miner-eval (iterative-candidate-pattern iter-smoke (Inheritance $a $b) (Inheritance (var 0) (eval (var (1 1)) (var (1 2)))) 2))
(EXPECTED-RESULT iterative-miner-soda (iterative-candidate-pattern iter-smoke (Inheritance $a $b) (Inheritance (var 0) sodaDrinker) 8))
(EXPECTED-RESULT iterative-miner-recursive-eval (iterative-recursive-candidate iter-smoke (Inheritance $a $b) (Inheritance (var 0) (eval (var (1 1)) (var (1 2)))) 2))
