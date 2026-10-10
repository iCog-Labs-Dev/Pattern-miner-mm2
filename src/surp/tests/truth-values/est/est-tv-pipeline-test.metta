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
;; TEST-AUX src/surp/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/surp/truth-values/est/beta-distribution.metta
;; TEST-AUX src/surp/truth-values/est/average-tv.metta
;; TEST-AUX src/surp/truth-values/emp/emp-tv.metta
;; TEST-AUX src/surp/truth-values/emp/block-tv.metta
;; TEST-AUX src/surp/truth-values/est/pro-tv-wout-joint.metta
;; TEST-AUX src/surp/truth-values/est/ji-tv-est.metta
;; TEST-AUX src/surp/truth-values/est/do-ji-tv-est.metta
;; TEST-AUX src/surp/truth-values/est/est-tv.metta
;; TEST-AUX data/ugly-sodaDrinker.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Full estimated truth value pipeline test
;;
;; PeTTa corpus expectations mirror:
;;   hyperon-miner/experiments/validation/estimation-tv-validation.metta
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION FALSE)
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance $x ugly)
        (Inheritance $x man)
        (Inheritance $x sodaDrinker))
     5))

(EXPECTED-RESULT petta-est-tv-ugly-man-soda (est-tv-of ((Inheritance (var 0) ugly) (Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) (STV 0 0.00027229280235977334)))
