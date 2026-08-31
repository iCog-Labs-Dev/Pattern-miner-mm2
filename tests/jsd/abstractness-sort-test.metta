;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp.metta
;; TEST-AUX src/jsd_modules/init.metta
;; TEST-AUX src/jsd_modules/emp-tv.metta
;; TEST-AUX src/jsd_modules/eq-prob.metta
;; TEST-AUX src/jsd_modules/abstraction-sort.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(INPUT DB db)
(INPUT DB-SIZE 60)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN ((, (Inheritance $x man) (Inheritance $x ugly)) 5))
(INPUT PATTERN ((, (Inheritance $x $y) (Inheritance $x man)) 30))
(INPUT PATTERN ((, (Inheritance $x human) (Inheritance Bob man) (Inheritance $x human)) 20))


(EXPECTED-RESULT abstract-variable (most-abstract-block-support (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man))) (var 0) ((Inheritance (var 0) (var 1))) 60))

(EXPECTED-RESULT abstract-tie (most-abstract-block (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0) ((Inheritance (var 0) man))))

(EXPECTED-RESULT abstract-fewer-clauses (most-abstract-block-support (((Inheritance (var 0) human)) ((Inheritance Bob man) (Inheritance (var 0) human))) (var 0) ((Inheritance (var 0) human)) 20))

