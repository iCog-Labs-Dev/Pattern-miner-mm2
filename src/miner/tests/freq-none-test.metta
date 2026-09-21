;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/candidate-patterns.metta
;; TEST-AUX src/freq/components/iterative-miner.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/miner/pattern-miner.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX data/ugly-sodaDrinker.metta

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(INPUT SURP-MODE none)

(EXPECTED-RESULT general-pattern (frequent-pattern (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a $d)) 593))
(EXPECTED-RESULT specific-pattern (frequent-pattern (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5))

(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))
