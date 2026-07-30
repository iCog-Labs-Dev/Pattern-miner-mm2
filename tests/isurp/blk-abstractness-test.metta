;; TEST-AUX src/isurp_modules/blk_abstractness.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Block abstractness component test
;;
;; Tests the full C++/PeTTa semantic block-abstractness check:
;;   is-blk-more-abstract via partitions / subsets / one-way matching.
;;
;; Reference:
;;   PeTTa:  hyperon-miner/experiments/utils/surp-utils/blk-abstractness.metta
;;   C++:    opencog/miner MinerUtils.cc is_blk_more_abstract
;;   Tests:  hyperon-miner/experiments/utils/surp-utils/tests/test-blk-abstractness.metta
;;
;; Expected final verdict facts:
;;   t1: true   (repo test — left generalizes right)
;;   t2: false  (repo test — constant cannot absorb variable)
;;   t3: true   (C++ MinerUtils.h doc example — Layer 2 partitions)
;;   t4: false  (pivot absent on the right side)
;;   t5: true   (reflexive — faithful to PeTTa semantics)
;;   t6: true   (nested sub-expression case)
;;
;; NOTE: t3–t6 expected values are derived from C++ semantics. Cross-check
;; on PeTTa before trusting.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; t1: ((Human $x $y)) vs ((Human $x Abebe)) w.r.t. $x
(blk-abstract? t1 ((Human (var 0) (var 1))) ((Human (var 0) Abebe)) (var 0))

;; t2: the reverse — a constant cannot absorb a variable
(blk-abstract? t2 ((Human (var 0) Abebe)) ((Human (var 0) (var 1))) (var 0))

;; t3: needs partitions: {(Inh $x $z)},{(Inh $y $z)} each ↦ ((Inh A $z))
(blk-abstract? t3
    ((Inheritance (var 0) (var 2)) (Inheritance (var 1) (var 2)))
    ((Inheritance A (var 2)))
    (var 2))

;; t4: pivot (var 0) does not occur in the right block
(blk-abstract? t4 ((Human (var 0) (var 1))) ((Human Abebe Kebede)) (var 0))

;; t5: reflexive
(blk-abstract? t5 ((Human (var 0) (var 1))) ((Human (var 0) (var 1))) (var 0))

;; t6: nested expressions (deeper than 04_eq_prob.metta's one-level scope)
(blk-abstract? t6
    ((Human (Person (var 0)) (Person (var 1))))
    ((Human (Person (var 0)) (Person Abebe)))
    (var 0))


;; Expected results
(EXPECTED-RESULT blk-t1-true       (blk-abstract-of t1 true))
(EXPECTED-RESULT blk-t2-false      (blk-abstract-of t2 false))
(EXPECTED-RESULT blk-t3-true       (blk-abstract-of t3 true))
(EXPECTED-RESULT blk-t4-false      (blk-abstract-of t4 false))
(EXPECTED-RESULT blk-t5-true       (blk-abstract-of t5 true))
(EXPECTED-RESULT blk-t6-true       (blk-abstract-of t6 true))
