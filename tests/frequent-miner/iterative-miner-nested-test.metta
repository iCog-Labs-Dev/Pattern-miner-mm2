;; TEST-AUX src/freq/frequent-miner.metta
;; TEST-AUX src/freq/iterative-miner.metta

(INPUT MIN-SUPPORT 2)

(FACT (Inheritance Alice (Evaluation likes soda)))
(FACT (Inheritance Bob (Evaluation likes juice)))
(FACT (Inheritance Carol (Evaluation prefers soda)))

(run-iterative-miner nested-iterative-test (Inheritance $x $y))

(exec (freq 001 call-nested-iterative-miner)
  (, (run-iterative-miner nested-iterative-test (Inheritance $x $y))
     (DEF iterative-miner-fn $iter-p $iter-t))
  (O (+ (exec (freq 002 run-nested-iterative-miner) $iter-p $iter-t))))

(EXPECTED-RESULT nested-candidate-recursed (iterative-recursive-candidate nested-iterative-test (Inheritance $a $b) (Inheritance (var 0) (Evaluation (var (1 1)) (var (1 2)))) 3))
