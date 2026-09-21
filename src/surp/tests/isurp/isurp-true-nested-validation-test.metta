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
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human sodaDrinker)))
        (Inheritance
            (And (And (Person $x) man) (Or human sodaDrinker))
            (Or (And human man) (And human ugly))))
     1))

(EXPECTED-RESULT isurp-true-nested-raw (isurp-of ((Inheritance (And (And (Person (var 0)) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))) (Inheritance (And (And (Person (var 0)) man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))) 0.001216))
