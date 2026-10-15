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
(INPUT SUPPORT-MODE cached)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly)
        (Inheritance $x sodaDrinker))
     5))

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly))
     5))

(EXPECTED-RESULT isurp-corpus-three-raw (isurp-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 1.9290123456790123e-5))

;(EXPECTED-RESULT isurp-corpus-three-normalized (isurp-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) 0.8333333333333334))

(EXPECTED-RESULT isurp-corpus-two-raw (isurp-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly)) 0.000925925925925926))
