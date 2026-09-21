;; TEST-STEPS 1000000
;; TEST-AUX data/isurp-true-nested.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp-old.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Legacy ISurp nested-pattern coverage.
;;
;; The clauses contain nested expressions under `Inheritance`.  This verifies
;; that legacy ISurp can index, partition, count support, and score nested
;; pattern terms.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 25)
(INPUT NORMALIZATION FALSE)
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human sodaDrinker)))
        (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human ugly))))
     1))

(EXPECTED-RESULT isurp-old-nested (surprisingess-of (, (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))) 0.003266666666666667))
