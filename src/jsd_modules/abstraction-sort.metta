;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting for blocks of binary predicate clauses
;;
;; Scope:
;;
;;   This module assumes each clause is a binary relation triple:
;;
;;     ($rel $left $right)
;;
;;   Blocks and partitions may still contain many clauses/blocks:
;;
;;     block     = (($rel $left $right) ...)
;;     partition = (block ...)
;;
;; Purpose:
;;
;;   `eq-prob` needs the most abstract block connected to a joint variable.  The
;;   C++/PeTTa implementation ranks blocks by syntactic abstractness relative to
;;   that joint variable, then uses value-count/support from the selected block.
;;
;; MM2 approximation:
;;
;;   The full C++ relation uses unification over block partitions and subsets.
;;   This MM2 version keeps the same intent for binary triplet clauses by using
;;   a deterministic weighted score:
;;
;;     1. syntactic triplet abstractness relative to the joint variable
;;        - a non-joint variable argument is more abstract than a constant
;;     2. fewer clauses is more abstract
;;     3. larger support is the empirical fallback
;;     4. equal scores keep original partition order
;;
;; Public request:
;;
;;   (abstractness-sort-request $partition $var)
;;
;; Public result facts:
;;
;;   (abstract-block-clause $partition $block $clause)
;;   (abstract-open-score $partition $var $block $clause $score)
;;   (abstract-size-priority $partition $block $priority)
;;   (abstract-block-score $partition $var $block $score)
;;   (most-abstract-block $partition $var $block)
;;   (most-abstract-block-support $partition $var $block $support)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Expand block tuples into clauses.  This duplicates a small part of
;; `04_eq_prob.metta` so the sorter can be tested independently.
(exec (eq-prob 132 abstract-expand)
    (, (abstractness-sort-request $partition $var)
        (block $partition $block))
    (O
        (pure
            (abstract-size-priority $block $priority)
            $priority
            (f64_to_string
                (div_f64 (f64_from_string 100000000000000) (f64_from_string (length (' $block)))))
        )
    )
)




;; Clause-level syntactic abstractness relative to the requested joint variable.
;;
;; If the joint variable is in one argument position, the other argument is the
;; one that determines whether this clause is more open/abstract:
;;
;;   ($rel (var N) (var M)) -> 1
;;   ($rel (var N) const)   -> 0
;;   ($rel (var M) (var N)) -> 1
;;   ($rel const   (var N)) -> 0
;;
;; `is_var` lets the same rule cover constants and indexed variables without
;; needing negation.


(exec (eq-prob 133 abstract-open-score)
    (, (abstractness-sort-request $partition $var)
        (block $partition $block)
        (block-clause $block $clause)
        (var-in $var $clause $depth)
        (var-in $other-vars $clause $other-depth))
    (O
        (count
            (exec (eq-prob 133 abstract-open-score) (,)
                (O (pure
                    (abstract-open-score $var $clause $score)
                    $score
                    (i32_to_string (sub_i32 (i32_from_string $count) (i32_from_string 1))))))
            $count
            ($other-vars $other-depth)
        )
    )
)

(exec (eq-prob 135 abstract-open-total)
     (, (block-clause $block $clause) (abstract-open-score $var $clause $score))
    (, (abstract-open-total $var $block $block 0))
)
(exec (eq-prob 136 abstract-open-total)
    (, (abstract-open-total $var $block $reduced-blk $sum) (exec (eq-prob 136 abstract-open-total) $src $sink))
    (O
        (pure
            (exec (eq-prob 135 abstract-open-total)
                (, (abstract-open-score $var $clause $score))
                (O
                    (pure
                        (exec (eq-prob 135 abstract-open-total) (,) (O 
                            (- (abstract-open-total $var $block $reduced-blk $sum))
                            (pure (abstract-open-total $var $block $new-blk $new-sum) $new-sum (i64_to_string (sum_i64 (i64_from_string $score) (i64_from_string $sum))))))
                        $new-blk
                        (cdr (' $reduced-blk)))
                    (+ (exec (eq-prob 136 abstract-open-total) $src $sink))))
            $clause
            (car (' $reduced-blk))
        )
        
    )
)

;; Weighted block score.
;;
;; The weights encode the priority order:
;;
;;   open-total * 1000000000000000  >  size-priority  >  support
;;
;; Support is intentionally last.  It breaks ties empirically, but it does not
;; override syntactic openness or the fewer-clauses fallback.
(exec (eq-prob 137 abstract-block-score)
    (, (abstract-open-total $var $block () $open-total)
        (abstract-size-priority $block $size-priority)
        (block-support $block $support))
    (O
        (pure
            (abstract-block-score $var $block $score)
            $score
            (i64_to_string
                (f64_as_i64 (sum_f64
                    (product_f64
                        (f64_from_string $open-total)
                        (f64_from_string 1000000000000000))
                    (f64_from_string $size-priority)
                    (f64_from_string $support))))))
)


;; Pairwise comparisons between block scores.

(exec (eq-prob 138 abstract-score-compare)
    (, (block $partition $block) (abstract-block-score $var $block $score))
    (O
        (fmax
            (exec (eq-prob 138 abstract-score-compare)
                (, (abstract-block-score $var $most-ab-block $max-score) (block $partition $most-ab-block))
                (, (most-abstract-block $partition $var $most-ab-block))
            )
            $max-score
            $score
        )
    )
)

;; Select the highest-scoring block.  Ties keep partition order.
(exec (eq-prob 139 same-abstract-score-separate)
    (, (most-abstract-block $partition $var $block-1) (most-abstract-block $partition $var $block-2))
    (O (pure
            (equal-block-pair $sorted-pair) $sorted-pair (sort-atom (' ($block-1 $block-2))))
        (- (equal-block-pair ($block-1 $block-1)))
    )
)

(exec (eq-prob 140 same-abstract-score-separate) 
    (, (most-abstract-block $partition $var $block-2) (most-abstract-block $partition $var $block-1) (equal-block-pair ($block-1 $block-2)))
    (O (- (most-abstract-block $partition $var $block-2)))
)

;; Expose the support of the chosen block, which is the value eq-prob needs
;; next as its divisor/count input.
(exec (eq-prob 141 most-abstract-support)
     (, (most-abstract-block $partition $var $block)
       (block-support $block $support) (block $partition $block))
    (, (most-abstract-block-support $partition $var $block $support)))
