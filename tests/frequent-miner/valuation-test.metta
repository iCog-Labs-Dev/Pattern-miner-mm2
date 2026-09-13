;; TEST-AUX data/freq-db.metta
;; TEST-AUX src/freq/frequent-miner.metta

;;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;;

(valuation val-test (Inheritance $x $y))


(exec (freq 000 call-valuation)
  (, (valuation val-test $pattern)
     (DEF valuation-fn $val-p $val-t))
  (O (+ (exec (freq 001 run-valuation-soda) $val-p $val-t))))


(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Abe))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Allen))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Cason))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Jassy))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Kecia))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Davion))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Jenica))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Breonna))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Hessley))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/1) (var 0) Jaleesa))
(EXPECTED-RESULT valuation-test (valuation-binding val-test (root arg/2) (var 1) sodaDrinker))