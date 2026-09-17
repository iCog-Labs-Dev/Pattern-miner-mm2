;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/frequent-miner.metta
;; TEST-AUX src/freq/iterative-miner.metta
;; TEST-AUX src/freq/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/pattern-miner.metta
;; TEST-AUX src/surp/isurp-modules/input-bootstrap.metta
;; TEST-AUX src/surp/isurp-modules/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp-modules/block-support.metta
;; TEST-AUX src/surp/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/surp/isurp-modules/eq-prob.metta
;; TEST-AUX src/surp/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp-modules/ji-prob-est.metta
;; TEST-AUX src/surp/isurp-modules/do-ji-prob.metta
;; TEST-AUX src/surp/isurp-modules/emp-prob-pbs.metta
;; TEST-AUX src/surp/isurp-modules/isurp-new.metta
;; TEST-STEPS 100000

(INPUT DB db)
(INPUT DB-SIZE 6)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 2)
(INPUT SUPPORT-MODE cached)
(INPUT SURPRISINGNESS-MODE isurp)
(INPUT SURPRISINGNESS-SCOPE selected)
(INPUT SURPRISINGNESS-PATTERN
  ((Inheritance (var 0) ugly)
   (Inheritance (var 0) sodaDrinker)))

(Inheritance Allen man)
(Inheritance Allen ugly)
(Inheritance Allen sodaDrinker)
(Inheritance Allen human)
(Inheritance Abe man)
(Inheritance Abe ugly)
(Inheritance Abe sodaDrinker)
(Inheritance Abe human)

(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))

(EXPECTED-RESULT frequent-before-isurp (expanded-conjunct 2 ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 2))
(EXPECTED-RESULT scored-isurp-result (pattern-miner-surprisingness ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 2 0.6666666666666666))
