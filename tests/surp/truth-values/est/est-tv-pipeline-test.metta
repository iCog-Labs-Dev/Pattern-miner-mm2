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

(EXPECTED-RESULT petta-est-tv-ugly-man-soda (est-tv-of (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker)) (STV 0 0.00027229280235977334)))
