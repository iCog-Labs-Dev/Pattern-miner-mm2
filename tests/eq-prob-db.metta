;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EQ-prob-only test DB
;;
;; This file intentionally contains no `(INPUT PATTERN ...)` facts.  It should
;; exercise only the eq-prob rules in `src/isurp_modules/04_eq_prob.metta` when
;; loaded together with the abstractness sorter
;; with that implementation.
;;
;; Expected active result for the first partition:
;;
;;   (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.5)
;;
;; Why:
;;
;;   The two blocks share `(var 0)`.
;;   The first block has support 2, so the current support-backed eq-prob
;;   factor is `1 / 2 = 0.5`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Case 1: simple unary shared variable
;;
;; In this case block support equals distinct value count:
;;
;;   (Inheritance (var 0) man)
;;   matches Allen and Bob.
;;
;; So both the current support-backed MM2 implementation and the exact PeTTa
;; value-count meaning give the same factor:
;;
;;   1 / 2 = 0.5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(block
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man)))

(block
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly)))

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Case 2: documentation case for the current value-count limitation
;;
;; This data shows where support and distinct value-count can differ:
;;
;;   (Likes (var 0) (var 1))
;;
;; Full support is 3:
;;
;;   Allen pizza
;;   Allen tea
;;   Bob pizza
;;
;; Distinct values of `(var 0)` are only 2:
;;
;;   Allen
;;   Bob
;;
;; Keep this as DB data only for now.  The current eq-prob implementation uses
;; `block-support`, so an active block-support test for this case would produce
;; `1 / 3`, while exact PeTTa value-count semantics should produce `1 / 2`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(Likes Allen pizza)
(Likes Allen tea)
(Likes Bob pizza)
