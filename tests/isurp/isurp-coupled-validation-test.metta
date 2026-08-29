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

(INPUT PATTERN
    ((, (Inheritance (Person $x) man)
        (Inheritance (Person $x) ugly)
        (Inheritance (Person $x) sodaDrinker))
     5))

(EXPECTED-RESULT isurp-coupled-three-raw (isurp-new-of (, (Inheritance (Person $a) man) (Inheritance (Person $a) ugly) (Inheritance (Person $a) sodaDrinker)) 1.9290123456790123e-5))
