;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/frequent-miner.metta
;; TEST-AUX src/freq/iterative-miner.metta
;; TEST-AUX src/freq/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/pattern-miner.metta
;; TEST-AUX src/surp/isurp-old.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX src/surp/isurp-modules/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp-modules/block-support.metta
;; TEST-AUX src/surp/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/surp/isurp-modules/eq-prob.metta
;; TEST-AUX src/surp/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp-modules/ji-prob-est.metta
;; TEST-AUX src/surp/isurp-modules/do-ji-prob.metta
;; TEST-AUX src/surp/isurp-modules/emp-prob-pbs.metta
;; TEST-AUX src/surp/isurp-modules/isurp-new.metta
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
;; TEST-STEPS 100000
;; TEST-MODE isurp-old
;; TEST-MODE isurp
;; TEST-MODE jsd
;; TEST-EXPECTED isurp-old frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5)
;; TEST-EXPECTED isurp-old indexed-handoff (INPUT INDEXED-PATTERN (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
;; TEST-EXPECTED isurp-old dispatched-result (surprisingess-of isurp-old ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 0.999707773232028)
;; TEST-EXPECTED isurp-old scored-frequent-result (pattern-miner-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.999707773232028)
;; TEST-EXPECTED isurp frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5)
;; TEST-EXPECTED isurp indexed-handoff (INPUT INDEXED-PATTERN (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
;; TEST-EXPECTED isurp dispatched-result (surprisingess-of isurp ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 0.8333333333333334)
;; TEST-EXPECTED isurp scored-frequent-result (pattern-miner-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.8333333333333334)
;; TEST-EXPECTED jsd frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5)
;; TEST-EXPECTED jsd indexed-handoff (INPUT INDEXED-PATTERN (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
;; TEST-EXPECTED jsd dispatched-result (surprisingess-of jsd ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 0.8507324751176143)
;; TEST-EXPECTED jsd scored-frequent-result (pattern-miner-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.8507324751176143)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pattern-miner to surprisingness integration test.
;;
;; The fixture is shared across all surprisingness modes. The test runner injects
;; one `(INPUT SURP-MODE <mode>)` per run from the TEST-MODE lines
;; above, so adding or changing a mode does not duplicate the integration setup.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)

;; The test starts from raw database atoms. `pattern-miner-fn` materializes the
;; frequent-miner facts, runs frequent mining, and then scores every frequent
;; pattern with the injected surprisingness mode.
(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))
