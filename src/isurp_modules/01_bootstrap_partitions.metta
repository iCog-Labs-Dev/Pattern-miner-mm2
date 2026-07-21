;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Pipeline bootstrap
;;
;; This stage finds the function definitions above and creates the first real
;; execs.  It also normalizes variables in the pattern:
;;
;;   $x, $y, ... -> (var 0), (var 1), ...
;;
;; That is necessary because generated partitions must preserve variable
;; identity across blocks.  Later, `indices_to_vars` converts the markers back
;; into real MM2 variables for support-count queries.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(exec 1
    (, (INPUT DB $db-name)
       (INPUT PATTERN ($pattern $support))
       ((count-db $db-name -> db-size) $src-of-count $sink-of-count)
       ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
       ((total-counts $db-name $pattern -> total-count-of) $src-of-tc $sink-of-tc)
       ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))
    (O
        ;; Optional DB-size count path.  The current `total-counts` definition
        ;; uses `INPUT DB-SIZE`, but this fact can help with debugging.
        (+ (exec 0 $src-of-count $sink-of-count))

        ;; Count clauses in the input comma pattern.
        (+ (exec 0 $src-of-cnj $sink-of-cnj))

        ;; Compute C(db_size, number_of_conjuncts).
        (+ (exec 1 $src-of-tc $sink-of-tc))

        ;; Compute empirical pattern probability from the provided support.
        (+ (exec 2 $src-of-prob $sink-of-prob))))


;; Newer ISurp needs only the indexed pattern and should not depend on the
;; older all-in-one bootstrap rule above.  The generic `vars_to_indices` helper
;; does not reliably index variables after the input pattern has already been
;; captured by an exec variable, so the active rules below index the common
;; miner pattern shape directly:
;;
;;   (, ($rel1 $x $arg1) ($rel2 $x $arg2) ...)
;;      -> (($rel1 (var 0) $arg1) ($rel2 (var 0) $arg2) ...)
;;
;; The repeated `$x` in the source side is a real MORK variable, so these rules
;; only fire when the same input variable is shared across the clauses.
(exec 1
    (, (INPUT PATTERN ((, ($rel1 $x $arg1)) $support)))
    (, (indexed-pattern (($rel1 (var 0) $arg1)))
       (indexed-pattern-of (, ($rel1 $x $arg1)) (($rel1 (var 0) $arg1)))))

(exec 1
    (, (INPUT PATTERN ((, ($rel1 $x $arg1)
                           ($rel2 $x $arg2)) $support)))
    (, (indexed-pattern (($rel1 (var 0) $arg1)
                         ($rel2 (var 0) $arg2)))
       (indexed-pattern-of (, ($rel1 $x $arg1)
                              ($rel2 $x $arg2))
                           (($rel1 (var 0) $arg1)
                            ($rel2 (var 0) $arg2)))))

(exec 1
    (, (INPUT PATTERN ((, ($rel1 $x $arg1)
                           ($rel2 $x $arg2)
                           ($rel3 $x $arg3)) $support)))
    (, (indexed-pattern (($rel1 (var 0) $arg1)
                         ($rel2 (var 0) $arg2)
                         ($rel3 (var 0) $arg3)))
       (indexed-pattern-of (, ($rel1 $x $arg1)
                              ($rel2 $x $arg2)
                              ($rel3 $x $arg3))
                           (($rel1 (var 0) $arg1)
                            ($rel2 (var 0) $arg2)
                            ($rel3 (var 0) $arg3)))))


;; Explicit fallback partitions for indexed inputs.  These follow
;; `partitions-wout-pattern`: the original full pattern is excluded.
(exec 2
    (, (indexed-pattern ($c1 $c2)))
    (,
        (ji-prob-partitions-of ($c1 $c2) ((($c1) ($c2))))
        (do-ji-prob-request ((($c1) ($c2))))
        (partition (($c1) ($c2)))
        (block (($c1) ($c2)) ($c1))
        (block (($c1) ($c2)) ($c2))))


(exec 2
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

(exec 2
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
(exec 3
    (, (partitions-of $indexed-pattern $indexed-partition)
       (exec 3 $src $sink))
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
        (+ (exec 3 $src $sink))))


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
(exec 4
    (, (partition $partition))
    (, (copy-of-partition $partition $partition)))


;; Iterate through the copied partition and write one `(block partition block)`
;; fact per block.
(exec 5
    (, (copy-of-partition $partition $partition-copy)
       (exec 5 $src $sink))
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
        (+ (exec 5 $src $sink))))
