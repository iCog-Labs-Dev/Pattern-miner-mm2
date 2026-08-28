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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5-clause ISurp pipeline test
;;
;; This validates the generic conjunction path end to end:
;;
;;   INPUT PATTERN
;;   -> indexed-pattern
;;   -> generated partitions
;;   -> block support
;;   -> pro-prob-wout-joint
;;   -> eq-prob
;;   -> ji-prob interval
;;   -> empirical probability
;;   -> final raw isurp-new-of
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 4)
(INPUT NORMALIZATION FALSE)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly)
        (Inheritance $x sodaDrinker)
        (Inheritance $x human)
        (Inheritance $x livingThing))
     1))

(Inheritance Allen man)
(Inheritance Allen ugly)
(Inheritance Allen sodaDrinker)
(Inheritance Allen human)
(Inheritance Allen livingThing)

(EXPECTED-RESULT indexed-pattern-5 (indexed-pattern-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker) (Inheritance $a human) (Inheritance $a livingThing)) ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human) (Inheritance (var 0) livingThing))))

(EXPECTED-RESULT empirical-prob-5 (emp-prob-pbs-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker) (Inheritance $a human) (Inheritance $a livingThing)) 0.0009765625))

(EXPECTED-RESULT isurp-five-clause (isurp-new-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker) (Inheritance $a human) (Inheritance $a livingThing)) 0.000732421875))
