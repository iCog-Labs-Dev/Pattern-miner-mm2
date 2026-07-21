;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting fixture
;;
;; The first block is more abstract because it has more variable arguments:
;;
;;   (Inheritance (var 0) (var 1)) -> score 2
;;   (Inheritance (var 0) man)     -> score 1
;;
;; The module should choose the first block and expose its support.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man))))

(abstractness-sort-request
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man)))
    (var 0))

(block
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man)))
    ((Inheritance (var 0) (var 1))))

(block
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man)))
    ((Inheritance (var 0) man)))

(block-support
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man)))
    ((Inheritance (var 0) (var 1)))
    5)

(block-support
    (((Inheritance (var 0) (var 1)))
     ((Inheritance (var 0) man)))
    ((Inheritance (var 0) man))
    2)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tie case
;;
;; Both blocks have one variable argument, so both score 1.  Ties keep partition
;; order, therefore the first block should be chosen.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly))))

(abstractness-sort-request
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly)))
    (var 0))

(block
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man)))

(block
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly)))

(block-support
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reversed-order case
;;
;; The more abstract block appears second.  The sorter should still select it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1)))))

(abstractness-sort-request
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1))))
    (var 0))

(block
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1))))
    ((Inheritance (var 0) man)))

(block
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1))))
    ((Inheritance (var 0) (var 1))))

(block-support
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1))))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man))
     ((Inheritance (var 0) (var 1))))
    ((Inheritance (var 0) (var 1)))
    5)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fewer-clause fallback
;;
;; Both blocks contain the same relevant triplet for `(var 0)`, but the second
;; block adds a concrete constraint.  The first block should be considered more
;; abstract even though the second block has larger support.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(partition
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human))))

(abstractness-sort-request
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human)))
    (var 0))

(block
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance (var 0) Human)))

(block
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance Bob man) (Inheritance (var 0) Human)))

(block-support
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance (var 0) Human))
    3)

(block-support
    (((Inheritance (var 0) Human))
     ((Inheritance Bob man) (Inheritance (var 0) Human)))
    ((Inheritance Bob man) (Inheritance (var 0) Human))
    99)
