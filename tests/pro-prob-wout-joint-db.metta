;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pro-prob-wout-joint-only test DB
;;
;; This fixture provides precomputed block support facts so the test exercises
;; only the product-probability stage.
;;
;; DB-SIZE is 4.
;;
;; Partition:
;;
;;   (((Inheritance (var 0) man))
;;    ((Inheritance (var 0) ugly)))
;;
;; Block probabilities:
;;
;;   P((Inheritance (var 0) man))  = 2 / 4 = 0.5
;;   P((Inheritance (var 0) ugly)) = 2 / 4 = 0.5
;;
;; Expected result:
;;
;;   0.5 * 0.5 = 0.25
;;
;; Expected important output:
;;
;;   (pro-prob-wout-joint-of
;;       (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
;;       0.25)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)
