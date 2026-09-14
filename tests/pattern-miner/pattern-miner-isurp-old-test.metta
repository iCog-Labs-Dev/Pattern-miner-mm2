;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/pattern-miner.metta
;; TEST-AUX src/surp/isurp-old.metta

(INPUT DB db)
(INPUT DB-SIZE 6)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(INPUT SURPRISINGNESS-MODE isurp-old)

(Inheritance Allen man)
(Inheritance Allen ugly)
(Inheritance Allen sodaDrinker)
(Inheritance Allen human)
(Inheritance Abe man)
(Inheritance Abe ugly)
(Inheritance Abe sodaDrinker)
(Inheritance Abe human)

;; Seed the public frequent-miner result contract. The full frequent miner is
;; already covered in tests/frequent-miner/frequent-pattern-miner-test.metta;
;; this test isolates the next exec handoff into surprisingness scoring.
(expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 2)
(expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) 2)
(pattern-miner-score integration-surp-test isurp-old)

(exec (surp s000 call-pattern-miner-handoff)
  (, (DEF pattern-miner-isurp-old-input-fn $input-p $input-t)
     (DEF pattern-miner-collect-surprisingness-fn $collect-p $collect-t))
  (O
    (+ (exec (surp s000 materialize-isurp-old-inputs) $input-p $input-t))
    (+ (exec (surp s930 collect-surprisingness-results) $collect-p $collect-t))))

(EXPECTED-RESULT frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 2))
(EXPECTED-RESULT second-frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) 2))
(EXPECTED-RESULT scored-frequent-result (pattern-miner-surprisingness integration-surp-test ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 2 0.8999999999999999))
(EXPECTED-RESULT scored-second-frequent-result (pattern-miner-surprisingness integration-surp-test ((Inheritance (var 0) man) (Inheritance (var 0) human) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a human) (Inheritance $a sodaDrinker)) 2 0.8999999999999999))
