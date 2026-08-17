;; TEST-AUX data/freq-db.metta
;; TEST-AUX src/frequent-miner.metta

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(INPUT MIN-SUPPORT 3)

(specialization-result candidate-test (Inheritance (var 0) sodaDrinker))
(specialization-result candidate-test (Inheritance (var 0) ugly))

(exec (freq 600 call-candidate-pattern)
  (, (DEF candidate-pattern-fn $candidate-p $candidate-t))
  (O
    (+ (exec (freq 601 run-candidate-pattern) $candidate-p $candidate-t))))

(EXPECTED-RESULT candidate-pattern-soda
  (candidate-pattern candidate-test (Inheritance (var 0) sodaDrinker) 10))
