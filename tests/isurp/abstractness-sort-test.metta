;; TEST-AUX src/isurp-modules/abstractness-sort.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting component test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; More variable arguments means more abstract.
(partition (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man))))

(abstractness-sort-request
    (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man)))
    (var 0))

(block
    (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man)))
    ((Inheritance (var 0) (var 1))))

(block
    (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man)))
    ((Inheritance (var 0) man)))

(block-support
    (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man)))
    ((Inheritance (var 0) (var 1)))
    5)

(block-support
    (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man)))
    ((Inheritance (var 0) man))
    2)

;; Tie keeps partition order.
(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(abstractness-sort-request
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    (var 0))

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

;; Fewer clauses beats support fallback.
(partition (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human))))

(abstractness-sort-request
    (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human)))
    (var 0))

(block
    (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance (var 0) Human)))

(block
    (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance Bob man) (Inheritance (var 0) Human)))

(block-support
    (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance (var 0) Human))
    3)

(block-support
    (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance Bob man) (Inheritance (var 0) Human))
    99)

;; Nested wrappers are scanned generically, not by constructor name.
(partition (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man))))

(abstractness-sort-request
    (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man)))
    (var 0))

(block
    (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man)))
    ((Inheritance (Wrapper (var 0)) (Box (var 1)))))

(block
    (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man)))
    ((Inheritance (Wrapper (var 0)) man)))

(block-support
    (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man)))
    ((Inheritance (Wrapper (var 0)) (Box (var 1))))
    5)

(block-support
    (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man)))
    ((Inheritance (Wrapper (var 0)) man))
    2)

;; Clauses may have more than two top-level arguments.
(partition (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail))))

(abstractness-sort-request
    (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail)))
    (var 0))

(block
    (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail)))
    ((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)))

(block
    (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail)))
    ((Relation (Wrapper (var 0)) fixed constant tail)))

(block-support
    (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail)))
    ((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail))
    5)

(block-support
    (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail)))
    ((Relation (Wrapper (var 0)) fixed constant tail))
    2)

(EXPECTED-RESULT abstract-variable (most-abstract-block-support (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man))) (var 0) ((Inheritance (var 0) (var 1))) 5))

(EXPECTED-RESULT abstract-tie (most-abstract-block (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0) ((Inheritance (var 0) man))))

(EXPECTED-RESULT abstract-fewer-clauses (most-abstract-block-support (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human))) (var 0) ((Inheritance (var 0) Human)) 3))

(EXPECTED-RESULT abstract-generic-nested (most-abstract-block-support (((Inheritance (Wrapper (var 0)) (Box (var 1)))) ((Inheritance (Wrapper (var 0)) man))) (var 0) ((Inheritance (Wrapper (var 0)) (Box (var 1)))) 5))

(EXPECTED-RESULT abstract-generic-n-tuple (most-abstract-block-support (((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) ((Relation (Wrapper (var 0)) fixed constant tail))) (var 0) ((Relation (Wrapper (var 0)) fixed (Box (var 1)) tail)) 5))
