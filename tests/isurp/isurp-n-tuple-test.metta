;; TEST-STEPS 1000000
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/isurp-modules/input-bootstrap.metta
;; TEST-AUX src/isurp-modules/bootstrap-partitions.metta
;; TEST-AUX src/isurp-modules/block-support.metta
;; TEST-AUX src/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/isurp-modules/eq-prob.metta
;; TEST-AUX src/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/isurp-modules/ji-prob-est.metta
;; TEST-AUX src/isurp-modules/do-ji-prob.metta
;; TEST-AUX src/isurp-modules/emp-prob-pbs.metta
;; TEST-AUX src/isurp-modules/isurp-new.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Full ISurp pipeline test for n-tuple clauses.
;;
;; The clauses here are not triplets. This verifies that variable scanning,
;; partitioning, support counting, eq-prob, and final ISurp calculation work
;; with wider clause shapes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 10)
(INPUT NORMALIZATION FALSE)

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

(EXPECTED-RESULT indexed-pattern-n-tuple (indexed-pattern-of (, (Relation $a left A tag) (Relation $a right B tag) (Relation $a extra C tag)) ((Relation (var 0) left A tag) (Relation (var 0) right B tag) (Relation (var 0) extra C tag))))

(EXPECTED-RESULT partition-singletons-n-tuple (partition (((Relation (var 0) left A tag)) ((Relation (var 0) right B tag)) ((Relation (var 0) extra C tag)))))

(EXPECTED-RESULT eq-joint-var-n-tuple (eq-joint-var (((Relation (var 0) left A tag)) ((Relation (var 0) right B tag)) ((Relation (var 0) extra C tag))) (var 0)))

(EXPECTED-RESULT ji-interval-n-tuple (ji-prob-est-interval-of ((((Relation (var 0) left A tag) (Relation (var 0) right B tag)) ((Relation (var 0) extra C tag))) (((Relation (var 0) left A tag) (Relation (var 0) extra C tag)) ((Relation (var 0) right B tag))) (((Relation (var 0) left A tag)) ((Relation (var 0) right B tag) (Relation (var 0) extra C tag))) (((Relation (var 0) left A tag)) ((Relation (var 0) right B tag)) ((Relation (var 0) extra C tag)))) 0.00035999999999999997 0.0009))

(EXPECTED-RESULT isurp-n-tuple (isurp-new-of (, (Relation $a left A tag) (Relation $a right B tag) (Relation $a extra C tag)) 0.0011))
