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
(exec 30
    (, (abstractness-sort-request $partition $var)
       (block $partition ($c1)))
    (, (abstract-block-clause $partition ($c1) $c1)
       (abstract-size-priority $partition ($c1) 4000000000000)))

(exec 30
    (, (abstractness-sort-request $partition $var)
       (block $partition ($c1 $c2)))
    (, (abstract-block-clause $partition ($c1 $c2) $c1)
       (abstract-block-clause $partition ($c1 $c2) $c2)
       (abstract-size-priority $partition ($c1 $c2) 3000000000000)))

(exec 30
    (, (abstractness-sort-request $partition $var)
       (block $partition ($c1 $c2 $c3)))
    (, (abstract-block-clause $partition ($c1 $c2 $c3) $c1)
       (abstract-block-clause $partition ($c1 $c2 $c3) $c2)
       (abstract-block-clause $partition ($c1 $c2 $c3) $c3)
       (abstract-size-priority $partition ($c1 $c2 $c3) 2000000000000)))

(exec 30
    (, (abstractness-sort-request $partition $var)
       (block $partition ($c1 $c2 $c3 $c4)))
    (, (abstract-block-clause $partition ($c1 $c2 $c3 $c4) $c1)
       (abstract-block-clause $partition ($c1 $c2 $c3 $c4) $c2)
       (abstract-block-clause $partition ($c1 $c2 $c3 $c4) $c3)
       (abstract-block-clause $partition ($c1 $c2 $c3 $c4) $c4)
       (abstract-size-priority $partition ($c1 $c2 $c3 $c4) 1000000000000)))


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
(exec 31
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel (var $n) $right)))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel (var $n) $right) $score)
            $score
            (i8_to_string (is_var (' $right))))))

(exec 31
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel $left (var $n))))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel $left (var $n)) $score)
            $score
            (i8_to_string (is_var (' $left))))))

;; Open-score totals for one-, two-, three-, and four-clause blocks.  Totals are
;; based on clauses connected to the joint variable; unrelated concrete clauses
;; are handled by the block-size fallback.
(exec 32
    (, (abstract-open-score $partition $var ($c1) $c1 $s1))
    (, (abstract-open-total $partition $var ($c1) $s1)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2) $c1 $s1))
    (, (abstract-open-total $partition $var ($c1 $c2) $s1)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2) $c2 $s2))
    (, (abstract-open-total $partition $var ($c1 $c2) $s2)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2) $c1 $s1)
       (abstract-open-score $partition $var ($c1 $c2) $c2 $s2))
    (O
        (pure
            (abstract-open-total $partition $var ($c1 $c2) $score)
            $score
            (i64_to_string
                (sum_i64
                    (i64_from_string $s1)
                    (i64_from_string $s2))))))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3) $c1 $s1))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3) $s1)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3) $c2 $s2))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3) $s2)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3) $c3 $s3))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3) $s3)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3) $c1 $s1)
       (abstract-open-score $partition $var ($c1 $c2 $c3) $c2 $s2)
       (abstract-open-score $partition $var ($c1 $c2 $c3) $c3 $s3))
    (O
        (pure
            (abstract-open-total $partition $var ($c1 $c2 $c3) $score)
            $score
            (i64_to_string
                (sum_i64
                    (i64_from_string $s1)
                    (i64_from_string $s2)
                    (i64_from_string $s3))))))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c1 $s1))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3 $c4) $s1)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c2 $s2))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3 $c4) $s2)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c3 $s3))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3 $c4) $s3)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c4 $s4))
    (, (abstract-open-total $partition $var ($c1 $c2 $c3 $c4) $s4)))

(exec 32
    (, (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c1 $s1)
       (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c2 $s2)
       (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c3 $s3)
       (abstract-open-score $partition $var ($c1 $c2 $c3 $c4) $c4 $s4))
    (O
        (pure
            (abstract-open-total $partition $var ($c1 $c2 $c3 $c4) $score)
            $score
            (i64_to_string
                (sum_i64
                    (i64_from_string $s1)
                    (i64_from_string $s2)
                    (i64_from_string $s3)
                    (i64_from_string $s4))))))


;; Weighted block score.
;;
;; The weights encode the priority order:
;;
;;   open-total * 1000000000000000  >  size-priority  >  support
;;
;; Support is intentionally last.  It breaks ties empirically, but it does not
;; override syntactic openness or the fewer-clauses fallback.
(exec 33
    (, (abstract-open-total $partition $var $block $open-total)
       (abstract-size-priority $partition $block $size-priority)
       (block-support $partition $block $support))
    (O
        (pure
            (abstract-block-score $partition $var $block $score)
            $score
            (i64_to_string
                (sum_i64
                    (product_i64
                        (i64_from_string $open-total)
                        (i64_from_string 1000000000000000))
                    (i64_from_string $size-priority)
                    (i64_from_string $support))))))


;; Pairwise comparisons between block scores.
(exec 34
    (, (abstract-block-score $partition $var $left $left-score)
       (abstract-block-score $partition $var $right $right-score))
    (O
        (pure
            (abstract-score-ge? $partition $var $left $right $ge)
            $ge
            (ge_i64
                (i64_from_string $left-score)
                (i64_from_string $right-score)))
        (pure
            (abstract-score-gt? $partition $var $left $right $gt)
            $gt
            (gt_i64
                (i64_from_string $left-score)
                (i64_from_string $right-score)))))


;; Select the highest-scoring block.  Ties keep partition order.
(exec 35
    (, (partition ($b1))
       (abstractness-sort-request ($b1) $var)
       (abstract-block-score ($b1) $var $b1 $s1))
    (, (most-abstract-block ($b1) $var $b1)))

(exec 35
    (, (partition ($b1 $b2))
       (abstractness-sort-request ($b1 $b2) $var)
       (abstract-score-ge? ($b1 $b2) $var $b1 $b2 true))
    (, (most-abstract-block ($b1 $b2) $var $b1)))

(exec 35
    (, (partition ($b1 $b2))
       (abstractness-sort-request ($b1 $b2) $var)
       (abstract-score-gt? ($b1 $b2) $var $b2 $b1 true))
    (, (most-abstract-block ($b1 $b2) $var $b2)))

(exec 35
    (, (partition ($b1 $b2 $b3))
       (abstractness-sort-request ($b1 $b2 $b3) $var)
       (abstract-score-ge? ($b1 $b2 $b3) $var $b1 $b2 true)
       (abstract-score-ge? ($b1 $b2 $b3) $var $b1 $b3 true))
    (, (most-abstract-block ($b1 $b2 $b3) $var $b1)))

(exec 35
    (, (partition ($b1 $b2 $b3))
       (abstractness-sort-request ($b1 $b2 $b3) $var)
       (abstract-score-gt? ($b1 $b2 $b3) $var $b2 $b1 true)
       (abstract-score-ge? ($b1 $b2 $b3) $var $b2 $b3 true))
    (, (most-abstract-block ($b1 $b2 $b3) $var $b2)))

(exec 35
    (, (partition ($b1 $b2 $b3))
       (abstractness-sort-request ($b1 $b2 $b3) $var)
       (abstract-score-gt? ($b1 $b2 $b3) $var $b3 $b1 true)
       (abstract-score-gt? ($b1 $b2 $b3) $var $b3 $b2 true))
    (, (most-abstract-block ($b1 $b2 $b3) $var $b3)))


;; Expose the support of the chosen block, which is the value eq-prob needs
;; next as its divisor/count input.
(exec 36
    (, (most-abstract-block $partition $var $block)
       (block-support $partition $block $support))
    (, (most-abstract-block-support $partition $var $block $support)))
