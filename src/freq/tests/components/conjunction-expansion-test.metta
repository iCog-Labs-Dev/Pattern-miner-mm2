;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/components/conjunction-expansion-triplet.metta

(INPUT DB db)
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)

(pattern 0 (Inheritance $x $y))
(pattern 0 (Inheritance $x human))
(pattern 0 (Inheritance $x ugly))
(pattern 0 (Inheritance $x sodaDrinker))

;; Only MAX-SIZE conjunctions are published; smaller frequent patterns still expand.
(EXPECTED-RESULT constant-size-3 (expanded-conjunct 3 ((Inheritance (var 0) ugly) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) 4))

;; Distinct-variable connected expansion and canonicalization.
(EXPECTED-RESULT canonical-fan (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 0) ugly)) 118))
(EXPECTED-RESULT canonical-join (expanded-conjunct 3 ((Inheritance (var 0) (var 1)) (Inheritance (var 0) (var 2)) (Inheritance (var 3) (var 1))) 2334))
