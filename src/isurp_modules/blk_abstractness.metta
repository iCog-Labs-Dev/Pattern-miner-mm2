;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Block abstractness — full C++/PeTTa semantic check
;;
;; Source PeTTa file:
;;   hyperon-miner/experiments/utils/surp-utils/blk-abstractness.metta
;; C++ reference:
;;   opencog/miner MinerUtils.cc  is_blk_more_abstract / is_pat_syntax_more_abstract
;;
;; Source flow (PeTTa):
;;   is-blk-more-abstract
;;   -> partitions (of l_blk)            [partition-metta.metta]
;;   -> powerset-without-empty (of r_blk)[partition-metta.metta]
;;   -> check-partitions / check-subsets / check-all-blocks   (∃ ∃ ∀)
;;   -> is-blk-syntax-more-abstract
;;      -> erase pivot var to a constant, ground r-side vars (replace/De Bruijn),
;;         then one-way `unify`
;;
;; MM2 implementation style:
;;   Works on the indexed representation produced by `vars_to_indices`
;;   ((var 0), (var 1), ...), same as 04_eq_prob.metta.
;;
;;   KEY TRANSLATION: the PeTTa erase/replace/unify machinery (~60 lines) exists
;;   only to simulate ONE-WAY matching. MM2 matching against a ground fact IS
;;   one-way matching, so Layer 1 collapses into one generated exec:
;;
;;     - the r-side block is stored GROUND (its (var N) atoms are constants),
;;       paired with the pivot:              (check-fact <key> ($rs $var))
;;     - the l-side block goes through `indices_to_vars` applied to the PAIR
;;       ($lb $var), so every (var N) becomes a live variable AND the pivot slot
;;       shares its variable with the pivot occurrences inside the pattern:
;;                     (($lb-pattern…$pv…) $pv)
;;     - matching that pattern against the ground pair forces $pv = (var K)
;;       (the pivot stays anchored) while all other l-variables absorb whatever
;;       the r-side has. Fires  <=>  l is syntactically more abstract w.r.t. var.
;;
;;   powerset-without-empty is NOT needed as a grounded function: every
;;   non-empty subset of r_blk occurs as a block of some partition of r_blk,
;;   so unrolling `partitions` of the r side and collecting blocks yields the
;;   powerset (duplicates collapse — the space is a set).
;;
;; Input contract (caller provides, e.g. eq-prob or a test db):
;;   (blk-abstract? $id $l-blk $r-blk $var)
;;     $l-blk/$r-blk : tuple of indexed clauses, e.g.
;;                     ((Inheritance (var 0) (var 2)) (Inheritance (var 1) (var 2)))
;;     $var          : the pivot, e.g. (var 2)
;;
;; PRECONDITION (documented scope, matches the eq-prob call site where
;; connected-subpatterns-with-var pre-filters blocks): $var occurs in $l-blk.
;; If $var is absent from $r-blk the answer is correctly false (the pivot slot
;; fails to anchor); if absent from $l-blk this v1 may over-approximate to true
;; where the PeTTa guard says false.
;;
;; Public result facts:
;;   (blk-abstract-of $id true)  /  (blk-abstract-of $id false)
;;
;; Everything else ((l-parts…), (l-block…), (r-subset…), (check-fact…),
;; (syn-ok…), (ok-blocks…), (partition-ok…)) is intermediate and removed by the
;; 9xx cleanup stages.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;===============================================================
;; Stage 100 — intake
;;===============================================================
;; Default verdict is false, flipped to true at stage 108 only if evidence
;; appears ("negation by replacement" — MM2 cannot test absence directly).
;; Both sides get their partitions computed (grounded `partitions`, same call
;; as surp.metta exec 2).
(exec (surp 100 blk-intake)
    (, (blk-abstract? $id $l $r $var))
    (O
        (+ (blk-abstract-of $id false))
        (pure (blk-l-parts $id $out) $out (partitions (' $l)))
        (pure (blk-r-parts $id $out) $out (partitions (' $r)))))


;;===============================================================
;; Stage 101 — unroll the l-side partitions list
;;===============================================================
;; Self-respawning car/cdr walk, exactly surp.metta exec 3. Halts when the
;; (blk-l-parts …) fact is gone: the respawned exec then fires with no matches
;; and is consumed.
(exec (surp 101 unroll-l-parts)
    (, (blk-l-parts $id $list)
       (exec (surp 101 unroll-l-parts) $src $sink))
    (O
        (pure (blk-l-partition $id $car) $car (car-atom (' $list)))
        (pure (blk-l-parts $id $cdr) $cdr (cdr-atom (' $list)))
        (- (blk-l-parts $id $list))
        (+ (exec (surp 101 unroll-l-parts) $src $sink))))

;; Copy each partition before destroying it in the block unroll (surp exec 4).
(exec (surp 102 copy-l-partition)
    (, (blk-l-partition $id $p))
    (, (blk-l-partition-copy $id $p $p)))

;; Unroll each l-partition into its blocks (surp.metta exec 5 shape).
(exec (surp 103 unroll-l-blocks)
    (, (blk-l-partition-copy $id $p $rest)
       (exec (surp 103 unroll-l-blocks) $src $sink))
    (O
        (pure (blk-l-block $id $p $b) $b (car-atom (' $rest)))
        (pure (blk-l-partition-copy $id $p $cdr) $cdr (cdr-atom (' $rest)))
        (- (blk-l-partition-copy $id $p $rest))
        (+ (exec (surp 103 unroll-l-blocks) $src $sink))))


;;===============================================================
;; Stage 104 — r-side subsets (= blocks of all partitions of r)
;;===============================================================
(exec (surp 104 unroll-r-parts)
    (, (blk-r-parts $id $list)
       (exec (surp 104 unroll-r-parts) $src $sink))
    (O
        (pure (blk-r-partition $id $car) $car (car-atom (' $list)))
        (pure (blk-r-parts $id $cdr) $cdr (cdr-atom (' $list)))
        (- (blk-r-parts $id $list))
        (+ (exec (surp 104 unroll-r-parts) $src $sink))))

(exec (surp 105 unroll-r-subsets)
    (, (blk-r-partition $id $q)
       (exec (surp 105 unroll-r-subsets) $src $sink))
    (O
        (pure (blk-r-subset $id $s) $s (car-atom (' $q)))
        (pure (blk-r-partition $id $cdr) $cdr (cdr-atom (' $q)))
        (- (blk-r-partition $id $q))
        (+ (exec (surp 105 unroll-r-subsets) $src $sink))))
;; NOTE: this walk destroys (blk-r-partition …) tuples while extracting their
;; blocks; each extracted block is a subset. Duplicate subsets across
;; partitions collapse into one (blk-r-subset …) fact.


;;===============================================================
;; Stage 106 — generate one Layer-1 check per (l-block × r-subset)
;;===============================================================
;; For every pair: store the ground r-side pair fact, and generate the check
;; exec whose source pattern is indices_to_vars of ($b $var) — the pair trick
;; described in the header. Same generation idiom as surp.metta exec 6.
(exec (surp 106 gen-check)
    (, (blk-abstract? $id $l $r $var)
       (blk-l-block $id $p $b)
       (blk-r-subset $id $s))
    (O
        (+ (blk-check-fact ($id $p $b $s) ($s $var)))
        (pure
            (exec (surp 107 blk-check)
                (, (blk-check-fact ($id $p $b $s) $ivpair))
                (O (+ (blk-syn-ok $id $p $s $b))))
            $ivpair
            (indices_to_vars (' ($b $var))))))
;; A generated (surp 107 blk-check) exec that cannot match (l-block not more
;; abstract, or clause-count mismatch) fires empty and is consumed — failure
;; is simply the absence of its (blk-syn-ok …) fact.


;;===============================================================
;; Stage 108 — count blocks per partition, and passing blocks per (p, s)
;;===============================================================
;; Both numbers come from the SAME `count` sink, so their representations are
;; guaranteed joinable at 109 (deliberately avoiding size-atom here).
;; `count` groups by the template's free variables (verified empirically).
(exec (surp 108 count-blocks)
    (, (blk-l-block $id $p $b))
    (O (count (blk-l-part-size $id $p $n) $n $b)))

(exec (surp 109 count-ok)
    (, (blk-syn-ok $id $p $s $b))
    (O (count (blk-ok-blocks $id $p $s $n) $n $b)))


;;===============================================================
;; Stage 110 — ∀ blocks: partition passes iff passing count = block count
;;===============================================================
;; The shared $n across both source patterns is the equality constraint.
(exec (surp 110 all-blocks-pass)
    (, (blk-ok-blocks $id $p $s $n)
       (blk-l-part-size $id $p $n))
    (, (blk-partition-ok $id $p $s)))


;;===============================================================
;; Stage 111 — ∃ partition ∃ subset: flip the default verdict
;;===============================================================
(exec (surp 111 blk-verdict)
    (, (blk-partition-ok $id $p $s)
       (blk-abstract-of $id false))
    (O
        (- (blk-abstract-of $id false))
        (+ (blk-abstract-of $id true))))


;;===============================================================
;; Stage 9xx — cleanup of intermediates
;;===============================================================
(exec (surp 900 cleanup-blk-l-block)
    (, (blk-l-block $id $p $b))
    (O (- (blk-l-block $id $p $b))))

(exec (surp 901 cleanup-blk-l-partition)
    (, (blk-l-partition $id $p))
    (O (- (blk-l-partition $id $p))))

(exec (surp 902 cleanup-blk-r-subset)
    (, (blk-r-subset $id $s))
    (O (- (blk-r-subset $id $s))))

(exec (surp 903 cleanup-blk-check-fact)
    (, (blk-check-fact $key $pair))
    (O (- (blk-check-fact $key $pair))))

(exec (surp 904 cleanup-blk-syn-ok)
    (, (blk-syn-ok $id $p $s $b))
    (O (- (blk-syn-ok $id $p $s $b))))

(exec (surp 905 cleanup-blk-ok-blocks)
    (, (blk-ok-blocks $id $p $s $n))
    (O (- (blk-ok-blocks $id $p $s $n))))

(exec (surp 906 cleanup-blk-l-part-size)
    (, (blk-l-part-size $id $p $n))
    (O (- (blk-l-part-size $id $p $n))))

(exec (surp 907 cleanup-blk-partition-ok)
    (, (blk-partition-ok $id $p $s))
    (O (- (blk-partition-ok $id $p $s))))
