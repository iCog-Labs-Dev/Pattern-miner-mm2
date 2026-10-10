;; Integrated frequent-pattern mining entry point.
;;
;; Required sibling modules in the same atomspace:
;;   src/freq/components/candidate-patterns.metta
;;   src/freq/components/iterative-miner.metta
;;   src/common-utils/utils.metta
;;   src/freq/components/conjunction-expansion-triplet.metta
;;
;; Public request:
;;   (run-frequent-pattern-miner $run-id $root-pattern)
;;
;; Public results:
;;   (iterative-candidate-pattern
;;     $run-id $parent-pattern $indexed-candidate $support)
;;   (expanded-conjunct $size $indexed-conjunction $support), at MAX-SIZE
;;

(DEF frequent-pattern-miner-fn
  (, (run-frequent-pattern-miner $run-id $root-pattern)
     (DEF iterative-miner-fn $iter-p $iter-t)
     (DEF conjunction-expansion-fn $expand-p $expand-t))
  (O
    (- (run-frequent-pattern-miner $run-id $root-pattern))
    (+ (run-iterative-miner $run-id $root-pattern))
    (+ (conjunction-expansion $run-id))
    (+ (exec (freq f010 run-iterative-miner) $iter-p $iter-t))
    (+ (exec (freq f999 run-conjunction-expansion) $expand-p $expand-t))))
