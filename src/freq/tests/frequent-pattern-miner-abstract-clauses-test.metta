;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/candidate-patterns.metta
;; TEST-AUX src/freq/components/iterative-miner.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta

(INPUT DB db)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)

(exec (freq f000 materialize-frequent-miner-facts)
  (, (Inheritance $entity $class))
  (O (+ (FACT (Inheritance $entity $class)))))

(run-frequent-pattern-miner abstract-clause-test (Inheritance $x $y))

(exec (freq f001 call-frequent-pattern-miner)
  (, (run-frequent-pattern-miner abstract-clause-test (Inheritance $x $y))
     (DEF frequent-pattern-miner-fn $miner-p $miner-t))
  (O (+ (exec (freq f002 run-frequent-pattern-miner) $miner-p $miner-t))))

;; A real three-clause pattern at the threshold remains.
(EXPECTED-RESULT three-conjuncts-at-threshold (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
(EXPECTED-RESULT shared-right-variables-survive (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 3) (var 1))) 10859))

;; In every candidate below, one variable-only clause is covered, per
;; variable, by the other two clauses.
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 3) (var 1))) 2334)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 3) (var 2))) 2334)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) (var 3))) 2334)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) man) (Inheritance (var 2) (var 1))) 371)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) man)) 371)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) woman) (Inheritance (var 2) (var 1))) 390)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) woman)) 390)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) ugly) (Inheritance (var 2) (var 1))) 421)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) ugly)) 421)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) sodaDrinker) (Inheritance (var 2) (var 1))) 421)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) sodaDrinker)) 421)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) human) (Inheritance (var 2) (var 1))) 731)
;; TEST-ABSENT (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)) (Inheritance (var 2) human)) 731)
