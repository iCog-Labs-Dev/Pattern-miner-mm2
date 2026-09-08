;; TEST-AUX src/isurp-modules/abstractness-sort.metta
;; TEST-AUX src/isurp-modules/eq-prob.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eq-prob component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(INPUT DB-SIZE 4)

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

(EXPECTED-RESULT eq-joint-var (eq-joint-var (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0)))

(EXPECTED-RESULT eq-prob (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) 0.25))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nested n-tuple argument scan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition
    (((Relation fixed (Wrapper (var 0)) tail))
     ((OtherRelation anchor middle (Box (var 0)) done))))

(block
    (((Relation fixed (Wrapper (var 0)) tail))
     ((OtherRelation anchor middle (Box (var 0)) done)))
    ((Relation fixed (Wrapper (var 0)) tail)))

(block
    (((Relation fixed (Wrapper (var 0)) tail))
     ((OtherRelation anchor middle (Box (var 0)) done)))
    ((OtherRelation anchor middle (Box (var 0)) done)))

(block-support
    (((Relation fixed (Wrapper (var 0)) tail))
     ((OtherRelation anchor middle (Box (var 0)) done)))
    ((Relation fixed (Wrapper (var 0)) tail))
    2)

(block-support
    (((Relation fixed (Wrapper (var 0)) tail))
     ((OtherRelation anchor middle (Box (var 0)) done)))
    ((OtherRelation anchor middle (Box (var 0)) done))
    2)

(Relation fixed (Wrapper A) tail)
(Relation fixed (Wrapper B) tail)
(OtherRelation anchor middle (Box A) done)
(OtherRelation anchor middle (Box C) done)

(EXPECTED-RESULT eq-joint-var-n-tuple (eq-joint-var (((Relation fixed (Wrapper (var 0)) tail)) ((OtherRelation anchor middle (Box (var 0)) done))) (var 0)))

(EXPECTED-RESULT eq-prob-n-tuple (eq-prob-of (((Relation fixed (Wrapper (var 0)) tail)) ((OtherRelation anchor middle (Box (var 0)) done))) 0.25))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Edge case: no joint variable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((Inheritance (var 0) man)) ((Inheritance Bob ugly))))

(block
    (((Inheritance (var 0) man)) ((Inheritance Bob ugly)))
    ((Inheritance (var 0) man)))

(block
    (((Inheritance (var 0) man)) ((Inheritance Bob ugly)))
    ((Inheritance Bob ugly)))

(block-support
    (((Inheritance (var 0) man)) ((Inheritance Bob ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man)) ((Inheritance Bob ugly)))
    ((Inheritance Bob ugly))
    1)

(EXPECTED-RESULT eq-prob-no-joint (eq-prob-of (((Inheritance (var 0) man)) ((Inheritance Bob ugly))) 1.0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Edge case: repeated variable in one block counts as one connected block
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly))))

(block
    (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly)))
    ((PairRelation (var 0) (var 0))))

(block
    (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly)))

(block-support
    (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly)))
    ((PairRelation (var 0) (var 0)))
    2)

(block-support
    (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)

(PairRelation Allen Allen)
(PairRelation Bob Bob)

(EXPECTED-RESULT eq-joint-var-repeated (eq-joint-var (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly))) (var 0)))

(EXPECTED-RESULT eq-prob-repeated (eq-prob-of (((PairRelation (var 0) (var 0))) ((Inheritance (var 0) ugly))) 0.25))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Edge case: two independent joint variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1)))))

(block
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((BinaryRelation (var 0) (var 1))))

(block
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((LeftFact (var 0))))

(block
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((RightFact (var 1))))

(block-support
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((BinaryRelation (var 0) (var 1)))
    2)

(block-support
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((LeftFact (var 0)))
    2)

(block-support
    (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1))))
    ((RightFact (var 1)))
    2)

(BinaryRelation Allen pizza)
(BinaryRelation Bob tea)
(LeftFact Allen)
(LeftFact Bob)
(RightFact pizza)
(RightFact tea)

(EXPECTED-RESULT eq-joint-var-left (eq-joint-var (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1)))) (var 0)))

(EXPECTED-RESULT eq-joint-var-right (eq-joint-var (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1)))) (var 1)))

(EXPECTED-RESULT eq-prob-two-vars (eq-prob-of (((BinaryRelation (var 0) (var 1))) ((LeftFact (var 0))) ((RightFact (var 1)))) 0.0625))
