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
;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/02_beta_distribution.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta
;; TEST-AUX src/truth-values/emp/00_emp_tv.metta
;; TEST-AUX src/truth-values/emp/01_block_tv.metta
;; TEST-AUX src/truth-values/est/04_pro_tv_wout_joint.metta
;; TEST-AUX src/truth-values/est/05_ji_tv_est.metta
;; TEST-AUX src/truth-values/est/06_do_ji_tv_est.metta
;; TEST-AUX src/truth-values/est/07_est_tv.metta
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

(INPUT PATTERN
    ((, (Inheritance $x ugly)
        (Inheritance $x man)
        (Inheritance $x sodaDrinker))
     5))

(EXPECTED-RESULT petta-est-tv-ugly-man-soda (est-tv-of (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker)) (STV 0 0.00027229280235977334)))
