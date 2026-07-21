;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Newer ISurp raw-variable indexing test DB
;;
;; This fixture intentionally gives the input pattern with a real MORK
;; variable `$x`.  The pipeline must:
;;
;;   1. convert `$x` to `(var 0)` in `indexed-pattern`
;;   2. generate partitions from that indexed representation
;;   3. convert `(var 0)` back to a real variable for block support counting
;;
;; Expected final result is the same as `isurp-new-db.metta`:
;;
;;   support = 1
;;   DB-SIZE = 4
;;   empirical probability = 1 / 16 = 0.0625
;;   generated interval = [0.125, 0.125]
;;   raw ISurp = 0.0625
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
