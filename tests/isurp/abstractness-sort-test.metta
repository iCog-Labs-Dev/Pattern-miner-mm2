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

(EXPECTED-RESULT abstract-variable (most-abstract-block-support (((Inheritance (var 0) (var 1))) ((Inheritance (var 0) man))) (var 0) ((Inheritance (var 0) (var 1))) 5))

(EXPECTED-RESULT abstract-tie (most-abstract-block (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) (var 0) ((Inheritance (var 0) man))))

(EXPECTED-RESULT abstract-fewer-clauses (most-abstract-block-support (((Inheritance (var 0) Human)) ((Inheritance Bob man) (Inheritance (var 0) Human))) (var 0) ((Inheritance (var 0) Human)) 3))
