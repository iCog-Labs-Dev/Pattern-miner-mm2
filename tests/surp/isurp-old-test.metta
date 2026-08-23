;; TEST-AUX data/isurp-true-nested.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta

;;;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;;;

(INPUT DB db)

(INPUT DB db)
(INPUT DB-SIZE 25)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (Inheritance (And (And (Person $x) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker)))
                           (Inheritance (And (And (Person $x)   man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))
                           (Inheritance (And (And human man)   (Or (Person $x) (Person Mike)))   (Or (And human man)   (And human sodaDrinker)))
                            (Inheritance (And (And (Person $x) man) (Or human ugly))        (Or (And human man) (And human sodaDrinker)))) 1))


(EXPECTED-RESULT isurp-old (surprisingess-of (, (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human ugly))) (Inheritance (And (And human man) (Or (Person $a) (Person Mike))) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human ugly)) (Or (And human man) (And human sodaDrinker)))) 0.9996837944664032))



;; Use data/dataset_for_n_arry_format.metta
; (INPUT DB-SIZE 28)
; (INPUT NORMALIZATION TRUE)
; (INPUT PATTERN ((, (Inheritance $x Loves $y) (Inheritance $x $Interest $Venue) (Inheritance $y $Interest $Venue)) 12))
; (INPUT PATTERN ((, 
;    (Inheritance $_32506 $_32512 The-Slice-Shop) 
;    (Inheritance $_32506 Pizza-Lover $_32548) 
;    (Inheritance $_32506 Pizza-Lover The-Slice-Shop)) 6))

; (EXPECTED-RESULT isurp-old (surprisingess-of (, (Inheritance $a Loves $b) (Inheritance $a $c $d) (Inheritance $b $c $d)) 0.9886039886039886))
; (EXPECTED-RESULT isurp-old (surprisingess-of (, (Inheritance $a $b The-Slice-Shop) (Inheritance $a Pizza-Lover $c) (Inheritance $a Pizza-Lover The-Slice-Shop)) 0.9981684981684982))



