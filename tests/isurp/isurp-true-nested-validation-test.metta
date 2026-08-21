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
;; TEST-AUX data/isurp-true-nested.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PeTTa true nested corpus validation.
;;
;; Mirrors:
;;   hyperon-miner/experiments/validation/isurp-validation.metta
;;
;; PeTTa assertion:
;;   (isurp
;;     (, (Inheritance
;;          (And (And (Person $x) man) (Or human sodaDrinker))
;;          (Or (And human man) (And human sodaDrinker)))
;;        (Inheritance
;;          (And (And (Person $x) man) (Or human sodaDrinker))
;;          (Or (And human man) (And human ugly))))
;;     &dbn
;;     False
;;     1)
;;   => 0.001216
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 25)
(INPUT NORMALIZATION FALSE)

(INPUT PATTERN
    ((, (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human sodaDrinker)))
        (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human ugly))))
     1))

(EXPECTED-RESULT isurp-true-nested-raw (isurp-new-of (, (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person $a) man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))) 0.001216))
