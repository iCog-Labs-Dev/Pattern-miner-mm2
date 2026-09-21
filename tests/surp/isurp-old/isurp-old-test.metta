;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp-old.metta

;;;;;;;;;;;;;;;;
;; TEST INPUT ;;
;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT SUPPORT-MODE cached)
(INPUT PATTERN ((,  (Inheritance $x man) (Inheritance $x ugly) (Inheritance $x sodaDrinker)) 5))

(EXPECTED-RESULT isurp-old (surprisingess-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 0.999707773232028))
