;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/isurp-modules/input-bootstrap.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input bootstrap component test
;;
;;   raw INPUT PATTERN
;;   -> indexed-pattern
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 4)

(INPUT PATTERN
    ((, (Inheritance $x man)
        (Inheritance $x ugly)
        (Inheritance $x sodaDrinker))
     1))

(EXPECTED-RESULT indexed-pattern-3 (indexed-pattern-of (, (Inheritance $a man) (Inheritance $a ugly) (Inheritance $a sodaDrinker)) ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker))))
