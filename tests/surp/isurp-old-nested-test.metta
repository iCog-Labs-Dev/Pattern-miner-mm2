;; TEST-AUX data/isurp-true-nested.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta

;;;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;;;


(INPUT DB-SIZE 25)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (Inheritance (And (And (Person $x) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker)))
                           (Inheritance (And (And (Person $x)   man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))
                           (Inheritance (And (And human man)   (Or (Person $x) (Person Mike)))   (Or (And human man)   (And human sodaDrinker)))
                            (Inheritance (And (And (Person $x) man) (Or human ugly))        (Or (And human man) (And human sodaDrinker)))) 1))


(EXPECTED-RESULT isurp-old (surprisingess-of (, (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human ugly))) (Inheritance (And (And human man) (Or (Person $a) (Person Mike))) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human ugly)) (Or (And human man) (And human sodaDrinker)))) 0.9996837944664032))
