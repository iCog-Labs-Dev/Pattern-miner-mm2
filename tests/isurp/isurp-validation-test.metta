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
;; TEST-AUX data/ugly-sodaDrinker.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PeTTa corpus validation.
;;
;; Mirrors:
;;   hyperon-miner/experiments/surprisingness/tests/test-isurp.metta
;;
;; PeTTa assertion:
;;   (isurp
;;     (, (Inheritance $x man)
;;        (Inheritance $x ugly)
;;        (Inheritance $x sodaDrinker))
;;     &kb
;;     False
;;     0.2)
;;   => 1.9290123456790123e-5
;;
;; Additional assertions mirror:
;;   hyperon-miner/experiments/validation/isurp-validation.metta
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION FALSE)
(INPUT NORMALIZATION TRUE)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly)
        (Inheritance $x sodaDrinker))
     5))

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly))
     5))

(EXPECTED-RESULT isurp-corpus-three-raw (isurp-new-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 1.9290123456790123e-5))

(EXPECTED-RESULT isurp-corpus-three-normalized (isurp-new-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) 0.8333333333333334))

(EXPECTED-RESULT isurp-corpus-two-raw (isurp-new-of (, (Inheritance $a man) (Inheritance $a ugly)) 0.000925925925925926))
