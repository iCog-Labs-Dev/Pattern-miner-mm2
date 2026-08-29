;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/conjunction-expansion-triplet.metta

(INPUT DB db)
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)

(pattern 0 (Inheritance $x $y))
(pattern 0 (Inheritance $x human))
(pattern 0 (Inheritance $x ugly))
(pattern 0 (Inheritance $x sodaDrinker))

;; Constant-slot expansion.
(EXPECTED-RESULT constant-singleton (expanded-conjunct 1 ((Inheritance (var 0) human)) 19))
(EXPECTED-RESULT constant-size-2 (expanded-conjunct 2 ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
(EXPECTED-RESULT constant-size-3 (expanded-conjunct 3 ((Inheritance (var 0) ugly) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) 4))

;; Distinct-variable connected expansion and canonicalization.
(EXPECTED-RESULT canonical-fan (expanded-conjunct 2 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2))) 183))
(EXPECTED-RESULT canonical-join (expanded-conjunct 2 ((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) 761))
