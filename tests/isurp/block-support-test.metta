;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/isurp-modules/block-support.metta

(INPUT PATTERN ((, (Inheritance $x human) (Inheritance $x ugly)) 1))

(Inheritance Allen human)
(Inheritance Bob human)
(Inheritance Allen ugly)

;; The same block belongs to two different partitions. The shared gate keeps
;; one cache entry but returns the support in both partition contexts.
(block partition-a ((Inheritance (var 0) human)))
(block partition-b ((Inheritance (var 0) human)))

(EXPECTED-RESULT partition-a-support (block-support partition-a ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT partition-b-support (block-support partition-b ((Inheritance (var 0) human)) 2))
(EXPECTED-RESULT block-cache (support-cache ((Inheritance (var 0) human)) 2))
