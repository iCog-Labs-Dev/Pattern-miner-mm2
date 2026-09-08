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
;; TEST-AUX src/truth-values/est/truth-value-defs.metta
;; TEST-AUX src/truth-values/est/beta-distribution.metta
;; TEST-AUX src/truth-values/est/average-tv.metta
;; TEST-AUX src/truth-values/emp/emp-tv.metta
;; TEST-AUX src/truth-values/emp/block-tv.metta
;; TEST-AUX src/truth-values/est/pro-tv-wout-joint.metta
;; TEST-AUX src/truth-values/est/ji-tv-est.metta
;; TEST-AUX src/truth-values/est/do-ji-tv-est.metta
;; TEST-AUX src/truth-values/est/est-tv.metta
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-STEPS 1000000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Estimated truth value validation against the PeTTa corpus.
;;
;; Mirrors:
;;   hyperon-miner/experiments/validation/estimation-tv-validation.metta
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION FALSE)

(INPUT PATTERN
    ((, (Inheritance $x woman)
        (Inheritance $x human)
        (Inheritance $x sodaDrinker))
     4))

(EXPECTED-RESULT petta-est-tv-woman-human-soda (est-tv-of (, (Inheritance $a woman) (Inheritance $a human) (Inheritance $a sodaDrinker)) (STV 0 0.0002141712796459233)))
