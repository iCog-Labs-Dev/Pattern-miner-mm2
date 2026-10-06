;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp-jsd-mm2.metta

(INPUT DB db)
(INPUT SURP-MODE isurp-jsd)
(INPUT NORMALIZATION True)

;; Transform raw Inheritance facts into DB-FACT format
(exec (test-setup transform-db-facts)
    (, (Inheritance $entity $class))
    (O (+ (DB-FACT (Inheritance $entity $class)))))

(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x ugly) (Inheritance $x sodaDrinker)) 5))

;; Expected metric sqrt(JSD) result for man + ugly + sodaDrinker
(EXPECTED-RESULT isurp-jsd-mm2-basic (isurp-jsd-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 0.00853231694238144))
