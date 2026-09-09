;; Integrated frequent-pattern mining entry point.
;;
;; Required sibling modules in the same atomspace:
;;   src/frequent-miner.metta
;;   src/iterative-miner.metta
;;   src/common-utils/utils.metta
;;   src/conjunction-expansion-triplet.metta
;;
;; Public request:
;;   (run-frequent-pattern-miner $run-id $root-pattern)
;;
;; Public results:
;;   (iterative-candidate-pattern
;;     $run-id $parent-pattern $indexed-candidate $support)
;;   (expanded-conjunct $size $indexed-conjunction $support)
;;
;; The priority-999 handoff is a barrier between the iterative miner, whose
;; work ends at priority 970, and conjunction expansion. Recursive miner work
;; schedules lower-priority tasks and therefore completes before the handoff.
(DEF frequent-pattern-miner-fn
  (, (run-frequent-pattern-miner $run-id $root-pattern)
     (DEF iterative-miner-fn $iter-p $iter-t)
     (DEF conjunction-expansion-fn $expand-p $expand-t))
  (O
    (- (run-frequent-pattern-miner $run-id $root-pattern))
    (+ (run-iterative-miner $run-id $root-pattern))
    (+ (conjunction-expansion $run-id))
    (+ (exec (freq 010 run-iterative-miner) $iter-p $iter-t))
    (+ (exec (freq 999 run-conjunction-expansion) $expand-p $expand-t))))
