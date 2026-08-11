;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/isurp_modules/00_input_bootstrap.metta
;; TEST-AUX src/isurp_modules/01_bootstrap_partitions.metta
;; TEST-AUX src/isurp_modules/02_block_support.metta
;; TEST-AUX src/isurp_modules/03_abstractness_sort.metta
;; TEST-AUX src/isurp_modules/04_eq_prob.metta
;; TEST-AUX src/isurp_modules/05_pro_prob_wout_joint.metta
;; TEST-AUX src/isurp_modules/06_ji_prob_est.metta
;; TEST-AUX src/isurp_modules/07_do_ji_prob.metta
;; TEST-AUX src/isurp_modules/08_emp_prob_pbs.metta
;; TEST-AUX src/truth-values/est/00_truth_value_defs.metta
;; TEST-AUX src/truth-values/est/01_average_tv.metta
;; TEST-AUX src/truth-values/est/02_emp_tv.metta
;; TEST-AUX src/truth-values/est/03_block_tv.metta
;; TEST-AUX src/truth-values/est/04_pro_tv_wout_joint.metta
;; TEST-AUX src/truth-values/est/05_ji_tv_est.metta
;; TEST-AUX src/truth-values/est/06_do_ji_tv_est.metta
;; TEST-AUX src/truth-values/est/07_est_tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Full estimated truth value pipeline test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 4)
(INPUT NORMALIZATION FALSE)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly))
     1))

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)

(EXPECTED-RESULT emp-tv (emp-tv-of (, (Inheritance $a man) (Inheritance $a ugly)) (EMPTV 0.0625 0.00196078431372549)))

(EXPECTED-RESULT pro-tv (pro-tv-wout-joint-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (STV 0.5 0.0004975124378109451)))

(EXPECTED-RESULT ji-tv (ji-tv-est-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (STV 0.125 4.975124378109452e-5)))

(EXPECTED-RESULT est-tv (est-tv-of (, (Inheritance $a man) (Inheritance $a ugly)) (STV 0.125 4.975124378109452e-5)))
