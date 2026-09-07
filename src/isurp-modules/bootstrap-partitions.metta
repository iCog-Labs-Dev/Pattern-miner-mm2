;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Partition
;;
;; This module is intentionally only about partitioning.
;;
;; Input fact expected from `input-bootstrap.metta`:
;;
;;   (indexed-pattern ($c1 $c2 ...))
;;
;; Output facts produced here:
;;
;;   (ji-prob-partitions-of $indexed-pattern $partitions)
;;   (do-ji-prob-request $partitions)
;;   (partition $partition)
;;   (block $partition $block)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Explicit fallback partitions for indexed inputs.  These follow
;; `partitions-wout-pattern`: the original full pattern is excluded.
(exec (surp 030 explicit-partition-2)
    (, (indexed-pattern ($c1 $c2)))
    (,
        (ji-prob-partitions-of ($c1 $c2) ((($c1) ($c2))))
        (do-ji-prob-request ((($c1) ($c2))))
        (partition (($c1) ($c2)))
        (block (($c1) ($c2)) ($c1))
        (block (($c1) ($c2)) ($c2))))


(exec (surp 030 explicit-partition-3)
    (, (indexed-pattern ($c1 $c2 $c3)))
    (,
        (ji-prob-partitions-of ($c1 $c2 $c3)
            ((($c1) ($c2 $c3))
             (($c1 $c3) ($c2))
             (($c1 $c2) ($c3))
             (($c1) ($c2) ($c3))))
        (do-ji-prob-request
            ((($c1) ($c2 $c3))
             (($c1 $c3) ($c2))
             (($c1 $c2) ($c3))
             (($c1) ($c2) ($c3))))
        (partition (($c1) ($c2 $c3)))
        (partition (($c1 $c3) ($c2)))
        (partition (($c1 $c2) ($c3)))
        (partition (($c1) ($c2) ($c3)))
        (block (($c1) ($c2 $c3)) ($c1))
        (block (($c1) ($c2 $c3)) ($c2 $c3))
        (block (($c1 $c3) ($c2)) ($c1 $c3))
        (block (($c1 $c3) ($c2)) ($c2))
        (block (($c1 $c2) ($c3)) ($c1 $c2))
        (block (($c1 $c2) ($c3)) ($c3))
        (block (($c1) ($c2) ($c3)) ($c1))
        (block (($c1) ($c2) ($c3)) ($c2))
        (block (($c1) ($c2) ($c3)) ($c3))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Generate partitions
;;
;; Source MeTTa equivalent:
;;
;;   (partitions-wout-pattern (cdr-atom $pattern))
;;
;; Current helper:
;;
;;   (partitions indexed-conjunct-list)
;;
;; The helper returns a list of partitions.  Each partition is a list of blocks,
;; and each block is a list of conjuncts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec (surp 031 generate-partitions)
    (, (indexed-pattern $indexed-pattern))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))
        (pure
            (ji-prob-partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))
        (pure
            (do-ji-prob-request $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))


;; Iterate through the partition list.
;;
;; This loop repeatedly:
;;
;;   1. takes the first partition with `car-atom`
;;   2. writes `(partition $car)`
;;   3. replaces the remaining list with `cdr-atom`
;;   4. writes itself back
;;
;; It halts naturally when the remaining list no longer has a first element.
(exec (surp 032 partition-iterator)
    (, (partitions-of $indexed-pattern $indexed-partition)
       (exec (surp 032 partition-iterator) $src $sink))
    (O
        (pure
            (partition $car)
            $car
            (car-atom (' $indexed-partition)))
        (pure
            (partitions-of $indexed-pattern $cdr)
            $cdr
            (cdr-atom (' $indexed-partition)))
        (- (partitions-of $indexed-pattern $indexed-partition))
        (+ (exec (surp 032 partition-iterator) $src $sink))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Expand partitions into blocks
;;
;; Source MeTTa equivalent:
;;
;;   isurp-old_ loops through partitions
;;   iprob loops through blocks inside one partition
;;
;; MM2 materializes:
;;
;;   (partition $partition)
;;   (block $partition $block)
;;
;; Keeping `$partition` on every `block` fact is important because later stages
;; must know which block probabilities should be multiplied together.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Copy the partition so the block iterator can consume the copy without losing
;; the original partition shape.
(exec (surp 033 copy-partition)
    (, (partition $partition))
    (, (copy-of-partition $partition $partition)))


;; Iterate through the copied partition and write one `(block partition block)`
;; fact per block.
(exec (surp 034 block-iterator)
    (, (copy-of-partition $partition $partition-copy)
       (exec (surp 034 block-iterator) $src $sink))
    (O
        (pure
            (block $partition $block)
            $block
            (car-atom (' $partition-copy)))
        (pure
            (copy-of-partition $partition $cdr)
            $cdr
            (cdr-atom (' $partition-copy)))
        (- (copy-of-partition $partition $partition-copy))
        (+ (exec (surp 034 block-iterator) $src $sink))))
