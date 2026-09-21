;; Pattern-miner orchestration for the frequent-to-surprisingness handoff.
;;
;; Required modules in the same atomspace:
;;   src/common-utils/utils.metta
;;   src/freq/components/candidate-patterns.metta
;;   src/freq/components/iterative-miner.metta
;;   src/freq/components/conjunction-expansion-triplet.metta
;;   src/freq/frequent-pattern-miner.metta
;;   src/surp/surp.metta
;;   modules required by the selected surprisingness mode
;;
;; Public request:
;;   (run-pattern-miner $root-pattern)
;;
;; Surprisingness configuration is owned by `src/surp/surp.metta`.
;;
;; Public surprisingness result:
;;   (frequent-with-surprisingness $pattern-id $pattern $support $score)

(DEF pattern-miner-fn
  (, (run-pattern-miner $root-pattern)
     (DEF frequent-pattern-miner-fn $freq-p $freq-t)
     (DEF do-surp-fn $surp-p $surp-t)
     (DEF collect-surp $collect-p $collect-t))
  (O
    (- (run-pattern-miner $root-pattern))
    (+ (run-frequent-pattern-miner pattern-miner $root-pattern))
    (+ (do-surp))
    (+ (exec (freq f000 materialize-pattern-miner-facts)
        (, $root-pattern)
        (O (+ (FACT $root-pattern)))))
    (+ (exec (freq f010 run-frequent-pattern-miner) $freq-p $freq-t))
    (+ (exec (surp s000 dispatch-surprisingness) $surp-p $surp-t))
    (+ (exec (surp s940 collect-surp-results) $collect-p $collect-t))))

(DEF collect-surp
  (, (expanded-conjunct $size $pattern-id $support)
     (surprisingness-of $mode $pattern-id $score))
  (O
    (pure
      (frequent-with-surprisingness $pattern-id $pattern $support $score)
      $pattern
      (indices_to_vars
        (cons , (' $pattern-id))))))
