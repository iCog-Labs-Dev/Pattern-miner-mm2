;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX isurp-old-mm2.metta


(INPUT DB db)
(INPUT SURP-MODE isurp-old)
(INPUT NORMALIZATION True)

;; Transform raw Inheritance facts into DB-FACT format
(exec (test-setup transform-db-facts)
    (, (Inheritance $entity $class))
    (O (+ (DB-FACT (Inheritance $entity $class)))))

(INPUT PATTERN ((,  (Inheritance $x man) (Inheritance $x ugly) (Inheritance $x sodaDrinker)) 5))

;; Expected result for the isurp-old-mm2 implementation  
(EXPECTED-RESULT isurp-old-mm2-basic (isurp-old-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 0.999707773232028))
