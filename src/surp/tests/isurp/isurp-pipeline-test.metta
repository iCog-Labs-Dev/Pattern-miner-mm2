;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX src/surp/isurp/components/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp/components/block-support.metta
;; TEST-AUX src/surp/isurp/components/abstractness-sort.metta
;; TEST-AUX src/surp/isurp/components/eq-prob.metta
;; TEST-AUX src/surp/isurp/components/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp/components/ji-prob-est.metta
;; TEST-AUX src/surp/isurp/components/do-ji-prob.metta
;; TEST-AUX src/surp/isurp/components/emp-prob-pbs.metta
;; TEST-AUX src/surp/isurp/isurp.metta

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

(EXPECTED-RESULT indexed-pattern (indexed-pattern ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))

(EXPECTED-RESULT ji-interval (ji-prob-est-interval-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))) 0.0625 0.0625))

(EXPECTED-RESULT isurp-pipeline (isurp-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly)) 0.0))
