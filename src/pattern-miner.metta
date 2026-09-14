;; Pattern-miner orchestration for the frequent-to-surprisingness handoff.
;;
;; Required modules in the same atomspace:
;;   src/common-utils/utils.metta
;;   src/freq/frequent-miner.metta
;;   src/freq/iterative-miner.metta
;;   src/freq/conjunction-expansion-triplet.metta
;;   src/freq/frequent-pattern-miner.metta
;;   selected surprisingness module, such as src/surp/isurp-old.metta
;;
;; Public request:
;;   (run-pattern-miner $run-id $root-pattern)
;;
;; Configuration:
;;   (INPUT SURPRISINGNESS-MODE isurp-old)
;;
;; Public surprisingness result:
;;   (pattern-miner-surprisingness $run-id $pattern-id $pattern $support $score)

(DEF pattern-miner-fn
  (, (run-pattern-miner $run-id $root-pattern)
     (INPUT SURPRISINGNESS-MODE isurp-old)
     (DEF frequent-pattern-miner-fn $freq-p $freq-t)
     (DEF pattern-miner-isurp-old-input-fn $input-p $input-t)
     (DEF pattern-miner-collect-surprisingness-fn $collect-p $collect-t))
  (O
    (- (run-pattern-miner $run-id $root-pattern))
    (+ (run-frequent-pattern-miner $run-id $root-pattern))
    (+ (pattern-miner-score $run-id isurp-old))
    (+ (exec (freq f010 run-frequent-pattern-miner) $freq-p $freq-t))
    (+ (exec (surp s000 materialize-isurp-old-inputs) $input-p $input-t))
    (+ (exec (surp s930 collect-surprisingness-results) $collect-p $collect-t))))

;; Current isurp-old scoring supports three-conjunct inputs. The frequent miner
;; emits canonical indexed conjunction lists, while isurp-old consumes comma
;; conjunctions through INPUT PATTERN.
(DEF pattern-miner-isurp-old-input-fn
  (, (pattern-miner-score $run-id isurp-old)
     (expanded-conjunct 3 $indexed-conjunction $support))
  (O
    (pure
      (INPUT SCOPED-PATTERN ($run-id $indexed-conjunction $pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $run-id $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-collect-surprisingness-fn
  (, (pattern-miner-pattern $run-id $pattern-id $pattern $support)
     (surprisingess-of (isurp-run $run-id $pattern-id) $pattern $score))
  (O
    (+ (pattern-miner-surprisingness $run-id $pattern-id $pattern $support $score))))
