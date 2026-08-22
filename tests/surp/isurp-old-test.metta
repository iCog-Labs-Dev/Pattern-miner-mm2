;; TEST-AUX data/dataset_for_n_arry_format.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta

;;;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 28)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (Inheritance $x Loves $y) (Inheritance $x $Interest $Venue) (Inheritance $y $Interest $Venue)) 12))
(INPUT PATTERN ((, 
   (Inheritance $_32506 $_32512 The-Slice-Shop) 
   (Inheritance $_32506 Pizza-Lover $_32548) 
   (Inheritance $_32506 Pizza-Lover The-Slice-Shop)) 6))

(EXPECTED-RESULT isurp-old (surprisingess-of ((Inheritance $a Loves $b) (Inheritance $a $c $d) (Inheritance $b $c $d)) 0.9886039886039886))
(EXPECTED-RESULT isurp-old (surprisingess-of ((Inheritance $a $b The-Slice-Shop) (Inheritance $a Pizza-Lover $c) (Inheritance $a Pizza-Lover The-Slice-Shop)) 0.9981684981684982))



