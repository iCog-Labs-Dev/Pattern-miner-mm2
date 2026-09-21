;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/surp/isurp/components/block-support.metta

(isurp-pattern
    ((Inheritance (var 0) human) (Inheritance (var 0) ugly))
    1)
(INPUT SUPPORT-MODE cached)

(Inheritance Allen human)
(Inheritance Bob human)
(Inheritance Allen ugly)

;; The same block belongs to two different partitions. The shared gate keeps
;; one cache entry but returns the support in both partition contexts.
(block
    ((Inheritance (var 0) human) (Inheritance (var 0) ugly))
    partition-a
    ((Inheritance (var 0) human)))

(block
    ((Inheritance (var 0) human) (Inheritance (var 0) ugly))
    partition-b
    ((Inheritance (var 0) human)))

(EXPECTED-RESULT partition-a-support (block-support ((Inheritance (var 0) human) (Inheritance (var 0) ugly)) partition-a ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT partition-b-support (block-support ((Inheritance (var 0) human) (Inheritance (var 0) ugly)) partition-b ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT block-cache (support-cache ((Inheritance (var 0) human)) 2))
