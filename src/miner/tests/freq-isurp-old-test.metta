;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/candidate-patterns.metta
;; TEST-AUX src/freq/components/iterative-miner.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/miner/pattern-miner.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX src/surp/isurp-old.metta
;; TEST-AUX data/ugly-sodaDrinker.metta

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(INPUT SURP-MODE isurp-old)

;; Final scored patterns captured from the full frequent-miner -> isurp-old run.
(EXPECTED-RESULT scored-pattern-001 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) (var 3))) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a $d)) 593 0.9994679304529859))
(EXPECTED-RESULT scored-pattern-002 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) man)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a man)) 93 0.9994249731339906))
(EXPECTED-RESULT scored-pattern-003 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) ugly)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a ugly)) 118 0.9995032144944477))
(EXPECTED-RESULT scored-pattern-004 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a human)) 174 0.9994160503033112))
(EXPECTED-RESULT scored-pattern-005 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a woman)) 90 0.9994058055717904))
(EXPECTED-RESULT scored-pattern-006 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $a sodaDrinker)) 118 0.9995032144944477))
(EXPECTED-RESULT scored-pattern-007 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 3) (var 1))) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $d $b)) 2334 0.9974285672073988))
(EXPECTED-RESULT scored-pattern-008 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 3) (var 2))) (, (Inheritance $a $b) (Inheritance $a $c) (Inheritance $d $c)) 2334 0.9974285672073988))
(EXPECTED-RESULT scored-pattern-009 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) ugly)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a ugly)) 19 0.9994770678888922))
(EXPECTED-RESULT scored-pattern-010 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a human)) 26 0.9993705884997527))
(EXPECTED-RESULT scored-pattern-011 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $a sodaDrinker)) 19 0.9994770678888922))
(EXPECTED-RESULT scored-pattern-012 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 2) (var 1))) (, (Inheritance $a $b) (Inheritance $a man) (Inheritance $c $b)) 371 0.9972581094897296))
(EXPECTED-RESULT scored-pattern-013 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) human)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a human)) 31 0.9993910371222262))
(EXPECTED-RESULT scored-pattern-014 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a woman)) 15 0.9993376193259303))
(EXPECTED-RESULT scored-pattern-015 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 19 0.9994770678888922))
(EXPECTED-RESULT scored-pattern-016 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 2) (var 1))) (, (Inheritance $a $b) (Inheritance $a ugly) (Inheritance $c $b)) 421 0.9975837496928496))
(EXPECTED-RESULT scored-pattern-017 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 0) woman)) (, (Inheritance $a $b) (Inheritance $a human) (Inheritance $a woman)) 30 0.9994252873563219))
(EXPECTED-RESULT scored-pattern-018 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a human) (Inheritance $a sodaDrinker)) 31 0.9993910371222262))
(EXPECTED-RESULT scored-pattern-019 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 2) (var 1))) (, (Inheritance $a $b) (Inheritance $a human) (Inheritance $c $b)) 731 0.9973560073588378))
(EXPECTED-RESULT scored-pattern-020 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) woman) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $a woman) (Inheritance $a sodaDrinker)) 15 0.9993376193259303))
(EXPECTED-RESULT scored-pattern-021 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) woman) (Inheritance (var 2) (var 1))) (, (Inheritance $a $b) (Inheritance $a woman) (Inheritance $c $b)) 390 0.9973916887709992))
(EXPECTED-RESULT scored-pattern-022 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 0) sodaDrinker) (Inheritance (var 2) (var 1))) (, (Inheritance $a $b) (Inheritance $a sodaDrinker) (Inheritance $c $b)) 421 0.9975837496928496))
(EXPECTED-RESULT scored-pattern-023 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) (var 3))) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c $d)) 2334 0.9974285672073988))
(EXPECTED-RESULT scored-pattern-024 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) man)) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c man)) 371 0.9972581094897296))
(EXPECTED-RESULT scored-pattern-025 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) ugly)) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c ugly)) 421 0.9975837496928496))
(EXPECTED-RESULT scored-pattern-026 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) human)) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c human)) 731 0.9973560073588378))
(EXPECTED-RESULT scored-pattern-027 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) woman)) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c woman)) 390 0.9973916887709992))
(EXPECTED-RESULT scored-pattern-028 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) sodaDrinker)) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $c sodaDrinker)) 421 0.9975837496928496))
(EXPECTED-RESULT scored-pattern-029 (frequent-with-surprisingness ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 3) (var 1))) (, (Inheritance $a $b) (Inheritance $c $b) (Inheritance $d $b)) 10859 0.999879172210561))
(EXPECTED-RESULT scored-pattern-030 (frequent-with-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.999707773232028))
(EXPECTED-RESULT scored-pattern-031 (frequent-with-surprisingness ((Inheritance (var 0) ugly) (Inheritance (var 0) human) (Inheritance (var 0) woman)) (, (Inheritance $a ugly) (Inheritance $a human) (Inheritance $a woman)) 5 0.9994155464640562))
(EXPECTED-RESULT scored-pattern-032 (frequent-with-surprisingness ((Inheritance (var 0) human) (Inheritance (var 0) woman) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a human) (Inheritance $a woman) (Inheritance $a sodaDrinker)) 5 0.9994155464640562))

(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))
