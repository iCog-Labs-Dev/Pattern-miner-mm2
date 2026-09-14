;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/freq/frequent-miner.metta
;; TEST-AUX src/freq/iterative-miner.metta
;; TEST-AUX src/freq/conjunction-expansion-triplet.metta
;; TEST-AUX src/freq/frequent-pattern-miner.metta
;; TEST-AUX src/pattern-miner.metta
;; TEST-AUX src/surp/isurp-old.metta
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-STEPS 100000

(INPUT DB db)
(INPUT DB-SIZE 6)
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 5)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(INPUT SURPRISINGNESS-MODE isurp-old)

; (Inheritance Allen man)
; (Inheritance Allen ugly)
; (Inheritance Allen sodaDrinker)
; (Inheritance Allen human)
; (Inheritance Abe man)
; (Inheritance Abe ugly)
; (Inheritance Abe sodaDrinker)
; (Inheritance Abe human)

;; The test starts from raw database atoms. `pattern-miner-fn` materializes the
;; frequent-miner facts, runs frequent mining, and then scores the generated
;; frequent patterns.
(run-pattern-miner (Inheritance $x $y))

(exec (freq f000 call-pattern-miner)
  (, (run-pattern-miner (Inheritance $x $y))
     (DEF pattern-miner-fn $pattern-miner-p $pattern-miner-t))
  (O
    (+ (exec (freq f001 run-pattern-miner) $pattern-miner-p $pattern-miner-t))))

; (EXPECTED-RESULT frequent-before-surp (expanded-conjunct 3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 5))
; (EXPECTED-RESULT scored-frequent-result (pattern-miner-surprisingness ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 5 0.5))
