;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; emp-prob-pbs-only test DB
;;
;; This tests the direct, no-sampling MM2 implementation.
;;
;; DB-SIZE is 4.
;; Pattern has 2 conjuncts.
;; Universe count is 4 ^ 2 = 16.
;; Support is 4.
;;
;; Expected result:
;;
;;   4 / 16 = 0.25
;;
;; Expected important output:
;;
;;   (emp-prob-pbs-of
;;       (, (Inheritance (var 0) man) (Inheritance (var 0) ugly))
;;       0.25)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(INPUT PATTERN
    ((, (Inheritance (var 0) man)
        (Inheritance (var 0) ugly))
     4))

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)
