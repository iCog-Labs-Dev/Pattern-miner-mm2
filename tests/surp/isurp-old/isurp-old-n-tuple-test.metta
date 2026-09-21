;; TEST-STEPS 1000000
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp-old.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Legacy ISurp n-tuple clause coverage.
;;
;; Clauses use five atoms, not triplets.  This verifies that the legacy
;; partition-product and interval stages do not depend on fixed triplet clauses.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 10)
(INPUT NORMALIZATION FALSE)
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Relation $x left A tag)
        (Relation $x right B tag)
        (Relation $x extra C tag))
     2))

(Relation Allen left A tag)
(Relation Allen right B tag)
(Relation Allen extra C tag)

(Relation Bob left A tag)
(Relation Bob right B tag)

(Relation Cason left A tag)
(Relation Cason right B tag)
(Relation Cason extra C tag)

(Relation Lily extra C tag)

(Relation Mike left A tag)

(EXPECTED-RESULT isurp-old-n-tuple (surprisingess-of (, (Relation $a left A tag) (Relation $a right B tag) (Relation $a extra C tag)) 0.016041666666666666))
