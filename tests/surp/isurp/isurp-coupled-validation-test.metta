;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/surp.metta
;; TEST-AUX src/surp/isurp-modules/bootstrap-partitions.metta
;; TEST-AUX src/surp/isurp-modules/block-support.metta
;; TEST-AUX src/surp/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/surp/isurp-modules/eq-prob.metta
;; TEST-AUX src/surp/isurp-modules/pro-prob-wout-joint.metta
;; TEST-AUX src/surp/isurp-modules/ji-prob-est.metta
;; TEST-AUX src/surp/isurp-modules/do-ji-prob.metta
;; TEST-AUX src/surp/isurp-modules/emp-prob-pbs.metta
;; TEST-AUX src/surp/isurp-modules/isurp-new.metta
;; TEST-AUX data/isurp-mock-coupled.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PeTTa coupled corpus validation.
;;
;; Mirrors:
;;   hyperon-miner/experiments/validation/isurp-validation.metta
;;
;; PeTTa assertion:
;;   (isurp
;;     (, (Inheritance (Person $x) man)
;;        (Inheritance (Person $x) ugly)
;;        (Inheritance (Person $x) sodaDrinker))
;;     &dbc
;;     False
;;     0.2)
;;   => 1.9290123456790123e-5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION FALSE)
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance (Person $x) man)
        (Inheritance (Person $x) ugly)
        (Inheritance (Person $x) sodaDrinker))
     5))

(EXPECTED-RESULT isurp-coupled-three-raw (isurp-of ((Inheritance (Person (var 0)) man) (Inheritance (Person (var 0)) ugly) (Inheritance (Person (var 0)) sodaDrinker)) 1.9290123456790123e-5))
