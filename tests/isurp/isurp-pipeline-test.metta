;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp-modules/input-bootstrap.metta
;; TEST-AUX src/surp/isurp-modules/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp-modules/block-support.metta
;; TEST-AUX src/surp/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/surp/isurp-modules/eq-prob.metta
;; TEST-AUX src/surp/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp-modules/ji-prob-est.metta
;; TEST-AUX src/surp/isurp-modules/do-ji-prob.metta
;; TEST-AUX src/surp/isurp-modules/emp-prob-pbs.metta
;; TEST-AUX src/surp/isurp-modules/isurp-new.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Full modular ISurp pipeline test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 4)
(INPUT NORMALIZATION FALSE)
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly))
     1))

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)

(EXPECTED-RESULT indexed-pattern (indexed-pattern-of (, (Inheritance $a man) (Inheritance $a ugly)) ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))

(EXPECTED-RESULT ji-interval (ji-prob-est-interval-of ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))) 0.0625 0.0625))

(EXPECTED-RESULT isurp-pipeline (isurp-new-of (, (Inheritance $a man) (Inheritance $a ugly)) 0.0))
