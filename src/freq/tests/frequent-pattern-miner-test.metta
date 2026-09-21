;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/candidate-patterns.metta
;; TEST-AUX src/freq/components/iterative-miner.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta

(INPUT DB db)
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)

;; The iterative miner consumes FACT wrappers; conjunction expansion consumes
;; the raw triplets loaded from the same fixture.
(exec (freq f000 materialize-frequent-miner-facts)
  (, (Inheritance $entity $class))
  (O (+ (FACT (Inheritance $entity $class)))))

(run-frequent-pattern-miner integration-test (Inheritance $x $y))

(exec (freq f001 call-frequent-pattern-miner)
  (, (run-frequent-pattern-miner integration-test (Inheritance $x $y))
     (DEF frequent-pattern-miner-fn $miner-p $miner-t))
  (O (+ (exec (freq f002 run-frequent-pattern-miner) $miner-p $miner-t))))

(EXPECTED-RESULT generic-candidate (iterative-candidate-pattern integration-test (Inheritance $a $b) (Inheritance (var 0) (var 1)) 59))
(EXPECTED-RESULT soda-candidate (iterative-candidate-pattern integration-test (Inheritance $a $b) (Inheritance (var 0) sodaDrinker) 10))
(EXPECTED-RESULT ugly-candidate (iterative-candidate-pattern integration-test (Inheritance $a $b) (Inheritance (var 0) ugly) 10))
(EXPECTED-RESULT human-candidate (iterative-candidate-pattern integration-test (Inheritance $a $b) (Inheritance (var 0) human) 19))
(EXPECTED-RESULT recursive-conjunction-support-counted (expanded-conjunct 3 ((Inheritance (var 0) ugly) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) 4))
(EXPECTED-RESULT generic-conjunction-support-counted (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) (var 3))) 593))
