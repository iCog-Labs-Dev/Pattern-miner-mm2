;; TEST-AUX src/frequent-miner.metta

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(run-shallow-abstraction shallow-test)

(valuation-binding shallow-test (root arg/1) (var 0) Allen)
(valuation-binding shallow-test (root arg/2) (var 1) (Eval Allen Lily Allen))
(valuation-binding shallow-test (root arg/3) (var 2) (var 0))

(exec (freq 000 call-shallow-abstraction)
  (, (run-shallow-abstraction shallow-test)
     (DEF shallow-abstraction-fn $abs-p $abs-t))
  (O (+ (exec (freq 001 run-shallow-abstraction) $abs-p $abs-t))))

(EXPECTED-RESULT shallow-atom (shallow-abstraction-binding shallow-test (root arg/1) (var 0) Allen))
(EXPECTED-RESULT shallow-expression (shallow-abstraction-binding shallow-test (root arg/2) (var 1) (Eval (var (1 1)) (var (1 2)) (var (1 1)))))
(EXPECTED-RESULT shallow-var (shallow-abstraction-binding shallow-test (root arg/3) (var 2) (var 0)))