
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX isurp-old-mm2.metta
;; TEST-AUX isurp-kl-mm2.metta
;; TEST-AUX isurp-hellinger-mm2.metta

(INPUT DB db)
(INPUT SURP-MODE isurp-hellinger)
(INPUT NORMALIZATION True)

(exec (test-setup transform-db-facts)
    (, (Inheritance $entity $class))
    (O (+ (DB-FACT (Inheritance $entity $class)))))

;; Supports below were counted by intersecting the sample DB entity sets.
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x man) (Inheritance $x sodaDrinker)) 5))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x man) (Inheritance $x ugly)) 5))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x man) (Inheritance $x woman)) 0))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x sodaDrinker) (Inheritance $x ugly)) 5))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x sodaDrinker) (Inheritance $x woman)) 5))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x ugly) (Inheritance $x woman)) 5))
(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x sodaDrinker) (Inheritance $x ugly)) 5))
(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x sodaDrinker) (Inheritance $x woman)) 0))
(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x ugly) (Inheritance $x woman)) 0))
(INPUT PATTERN ((, (Inheritance $x sodaDrinker) (Inheritance $x ugly) (Inheritance $x woman)) 0))
