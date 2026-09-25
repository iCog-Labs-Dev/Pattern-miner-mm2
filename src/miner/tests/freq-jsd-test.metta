;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/candidate-patterns.metta
;; TEST-AUX src/freq/components/iterative-miner.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/miner/pattern-miner.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX src/surp/isurp/components/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp/components/block-support.metta
;; TEST-AUX src/surp/isurp/components/abstractness-sort.metta
;; TEST-AUX src/surp/isurp/components/eq-prob.metta
;; TEST-AUX src/surp/isurp/components/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp/components/ji-prob-est.metta
;; TEST-AUX src/surp/isurp/components/do-ji-prob.metta
;; TEST-AUX src/surp/isurp/components/emp-prob-pbs.metta
;; TEST-AUX src/surp/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/surp/truth-values/est/beta-distribution.metta
;; TEST-AUX src/surp/truth-values/est/average-tv.metta
;; TEST-AUX src/surp/truth-values/emp/emp-tv.metta
;; TEST-AUX src/surp/truth-values/emp/block-tv.metta
;; TEST-AUX src/surp/truth-values/est/pro-tv-wout-joint.metta
;; TEST-AUX src/surp/truth-values/est/ji-tv-est.metta
;; TEST-AUX src/surp/truth-values/est/do-ji-tv-est.metta
;; TEST-AUX src/surp/truth-values/est/est-tv.metta
;; TEST-AUX src/surp/jsd/beta-cdf.metta
;; TEST-AUX src/surp/jsd/average-cdf.metta
;; TEST-AUX src/surp/jsd/kld.metta
;; TEST-AUX src/surp/jsd/do-jsd.metta
;; TEST-AUX src/surp/jsd/jsd-surprisingness.metta
;; TEST-AUX data/ugly-sodaDrinker.metta

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(INPUT SURP-MODE jsd)

;; Final scored patterns captured from the full frequent-miner -> jsd run.
(EXPECTED-RESULT scored-pattern-001 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) (var 3))) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a $d)) 593 0.8610443232327956))
(EXPECTED-RESULT scored-pattern-002 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) man)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a man)) 93 0.8612354050214989))
(EXPECTED-RESULT scored-pattern-003 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) ugly)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a ugly)) 118 0.8612275019754007))
(EXPECTED-RESULT scored-pattern-004 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a human)) 174 0.8612092173551048))
(EXPECTED-RESULT scored-pattern-005 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a woman)) 90 0.8612363427870906))
(EXPECTED-RESULT scored-pattern-006 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a sodaDrinker)) 118 0.8612275019754007))
(EXPECTED-RESULT scored-pattern-009 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) ugly)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a ugly)) 19 0.8612578862358145))
(EXPECTED-RESULT scored-pattern-010 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a human)) 26 0.8612558169619728))
(EXPECTED-RESULT scored-pattern-011 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a sodaDrinker)) 19 0.8612578862358145))
(EXPECTED-RESULT scored-pattern-013 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a human)) 31 0.8612543316646143))
(EXPECTED-RESULT scored-pattern-014 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a woman)) 15 0.861259063382094))
(EXPECTED-RESULT scored-pattern-015 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 19 0.8612578862358145))
(EXPECTED-RESULT scored-pattern-017 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a human) (Inheritance $a woman)) 30 0.8612546292081118))
(EXPECTED-RESULT scored-pattern-018 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a human) (Inheritance $a sodaDrinker)) 31 0.8612543316646143))
(EXPECTED-RESULT scored-pattern-020 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) woman) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a woman) (Inheritance $a sodaDrinker)) 15 0.861259063382094))
(EXPECTED-RESULT scored-pattern-029 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 3) (var 1))) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $d $b)) 10859 0.8130773583216154))
(EXPECTED-RESULT scored-pattern-030 (frequent-with-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.8507324751176143))
(EXPECTED-RESULT scored-pattern-031 (frequent-with-surprisingness ((Inheritance (var 0) ugly) (Inheritance (var 0) human) (Inheritance (var 0) woman)) (, (Inheritance $a ugly) (Inheritance $a human) (Inheritance $a woman)) 5 0.8544175048065252))
(EXPECTED-RESULT scored-pattern-032 (frequent-with-surprisingness ((Inheritance (var 0) human) (Inheritance (var 0) woman) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a human) (Inheritance $a woman) (Inheritance $a sodaDrinker)) 5 0.8544175048065252))

(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))
