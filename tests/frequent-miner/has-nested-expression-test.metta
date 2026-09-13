;; TEST-AUX src/freq/frequent-miner.metta
;; TEST-STEPS 1000

;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;

(has-nested-expression-with-respect-to hne-top-level
  (Inheritance (var 0) (var 1))
  (Inheritance (var 0) (Evaluation Allen sodaDrinker)))

(has-nested-expression-with-respect-to hne-nested-parent
  (Inheritance (var 0) (Evaluation (var 1) sodaDrinker))
  (Inheritance (var 0) (Evaluation (List Allen) sodaDrinker)))

(exec (freq 000 call-hne)
  (, (has-nested-expression-with-respect-to $id $parent $candidate)
     (DEF has-nested-expression-with-respect-to-fn $hne-p $hne-t))
  (O
    (+ (exec (freq 001 run-hne) $hne-p $hne-t))))

(EXPECTED-RESULT hne-top-level (has-nested-expression-result hne-top-level (Inheritance (var 0) (var 1)) (Inheritance (var 0) (Evaluation Allen sodaDrinker)) true))
(EXPECTED-RESULT hne-nested-parent (has-nested-expression-result hne-nested-parent (Inheritance (var 0) (Evaluation (var 1) sodaDrinker)) (Inheritance (var 0) (Evaluation (List Allen) sodaDrinker)) true))
