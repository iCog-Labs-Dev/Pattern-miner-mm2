;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting for blocks of binary predicate clauses
;;
;; Scope:
;;
;;   This module assumes each clause is a binary relation triple:
;;
;;     ($rel $left $right)
;;
;;   Blocks and partitions may contain any number of clauses/blocks.
;;
;; Purpose:
;;
;;   `eq-prob` needs the most abstract block connected to a joint variable. The
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
;;     2. fewer clauses is more abstract
;;     3. larger support is the empirical fallback
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


(exec (surp 060 abstract-copy-block)
    (, (abstractness-sort-request $partition $var)
       (block $partition $block))
    (, (abstract-copy-block $partition $block $block)))


(exec (surp 060 abstract-block-size)
    (, (abstractness-sort-request $partition $var)
       (block $partition $block))
    (O
        (pure
            (abstract-block-size $partition $block $size)
            $size
            (size-atom (' $block)))))


(exec (surp 061 abstract-size-priority)
    (, (abstract-block-size $partition $block $size))
    (O
        (pure
            (abstract-size-priority $partition $block $priority)
            $priority
            (i64_to_string
                (sub_i64
                    (i64_from_string 5000000000000)
                    (product_i64
                        (i64_from_string $size)
                        (i64_from_string 1000000000000)))))))


(exec (surp 060 abstract-block-iterator)
    (, (abstract-copy-block $partition $block $copy)
       (exec (surp 060 abstract-block-iterator) $src $sink))
    (O
        (pure
            (abstract-block-clause $partition $block $clause)
            $clause
            (car-atom (' $copy)))
        (pure
            (abstract-copy-block $partition $block $tail)
            $tail
            (cdr-atom (' $copy)))
        (- (abstract-copy-block $partition $block $copy))
        (+ (exec (surp 060 abstract-block-iterator) $src $sink))))


;; Clause-level syntactic abstractness relative to the requested joint variable.
(exec (surp 062 abstract-open-right)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel (var $n) $right)))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel (var $n) $right) $score)
            $score
            (i8_to_string (is_var (' $right))))))

(exec (surp 062 abstract-open-left)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel $left (var $n))))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel $left (var $n)) $score)
            $score
            (i8_to_string (is_var (' $left))))))

(exec (surp 062 abstract-open-right-person-var)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel (Person (var $n)) $right)))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel (Person (var $n)) $right) $score)
            $score
            (i8_to_string (is_var (' $right))))))

(exec (surp 062 abstract-open-left-person-var)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel $left (Person (var $n)))))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel $left (Person (var $n))) $score)
            $score
            (i8_to_string (is_var (' $left))))))

(exec (surp 062 abstract-open-right-and-person-var)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel (And (And (Person (var $n)) $a) $b) $right)))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel (And (And (Person (var $n)) $a) $b) $right) $score)
            $score
            (i8_to_string (is_var (' $right))))))

(exec (surp 062 abstract-open-left-and-person-var)
    (, (abstractness-sort-request $partition (var $n))
       (abstract-block-clause $partition $block ($rel $left (And (And (Person (var $n)) $a) $b))))
    (O
        (pure
            (abstract-open-score $partition (var $n) $block ($rel $left (And (And (Person (var $n)) $a) $b)) $score)
            $score
            (i8_to_string (is_var (' $left))))))


(exec (surp 063 abstract-open-total)
    (, (abstractness-sort-request $partition $var)
       (block $partition $block)
       (exec (surp 063 abstract-open-total) $src $sink))
    (,
        (exec (surp 063 abstract-open-total)
            (, (abstract-open-score $partition $var $block $clause 1))
            (O
                (count
                    (abstract-open-total $partition $var $block $score)
                    $score
                    $clause)))))


(exec (surp 063 abstract-open-total-zero)
    (, (abstract-open-score $partition $var $block $clause 0))
    (, (abstract-open-total $partition $var $block 0)))


;; Weighted block score.
(exec (surp 064 abstract-block-score)
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


(exec (surp 065 abstract-best-start)
    (, (abstractness-sort-request $partition $var)
       (DEF abstract-best-step $step-p $step-t))
    (O
        (pure
            (abstract-best-first $partition $var $first)
            $first
            (car-atom (' $partition)))
        (pure
            (abstract-best-rest $partition $var $rest)
            $rest
            (cdr-atom (' $partition)))
        (+ (exec (surp 066 abstract-best-step) $step-p $step-t))))


(exec (surp 065 abstract-best-acc-start)
    (, (abstract-best-first $partition $var $first)
       (abstract-best-rest $partition $var $rest)
       (abstract-block-score $partition $var $first $score))
    (,
        (abstract-best-acc $partition $var $rest $first $score)))


(DEF abstract-best-step
    (, (abstract-best-acc $partition $var $remaining $best-block $best-score)
       (DEF abstract-best-resolve $resolve-p $resolve-t))
    (O
        (pure
            (abstract-best-current $partition $var $remaining $current)
            $current
            (car-atom (' $remaining)))
        (pure
            (abstract-best-tail $partition $var $remaining $tail)
            $tail
            (cdr-atom (' $remaining)))
        (- (abstract-best-acc $partition $var $remaining $best-block $best-score))
        (+ (abstract-best-pending $partition $var $remaining $best-block $best-score))
        (+ (exec (surp 067 abstract-best-resolve) $resolve-p $resolve-t))))


(DEF abstract-best-resolve
    (, (abstract-best-pending $partition $var $remaining $best-block $best-score)
       (abstract-best-current $partition $var $remaining $current)
       (abstract-best-tail $partition $var $remaining $tail)
       (abstract-block-score $partition $var $current $current-score)
       (DEF abstract-best-step $step-p $step-t)
       (DEF abstract-best-final $final-p $final-t))
    (O
        (pure
            (abstract-current-better? $partition $var $remaining $better)
            $better
            (gt_i64
                (i64_from_string $current-score)
                (i64_from_string $best-score)))
        (+ (exec (surp 068 abstract-best-final) $final-p $final-t))
        (+ (exec (surp 069 abstract-best-step) $step-p $step-t))))


(exec (surp 068 abstract-best-keep)
    (, (abstract-best-pending $partition $var $remaining $best-block $best-score)
       (abstract-best-tail $partition $var $remaining $tail)
       (abstract-current-better? $partition $var $remaining false))
    (O
        (- (abstract-best-pending $partition $var $remaining $best-block $best-score))
        (- (abstract-best-tail $partition $var $remaining $tail))
        (+ (abstract-best-acc $partition $var $tail $best-block $best-score))))


(exec (surp 068 abstract-best-replace)
    (, (abstract-best-pending $partition $var $remaining $best-block $best-score)
       (abstract-best-current $partition $var $remaining $current)
       (abstract-best-tail $partition $var $remaining $tail)
       (abstract-block-score $partition $var $current $current-score)
       (abstract-current-better? $partition $var $remaining true))
    (O
        (- (abstract-best-pending $partition $var $remaining $best-block $best-score))
        (- (abstract-best-current $partition $var $remaining $current))
        (- (abstract-best-tail $partition $var $remaining $tail))
        (+ (abstract-best-acc $partition $var $tail $current $current-score))))


(DEF abstract-best-final
    (, (abstract-best-acc $partition $var () $best-block $best-score))
    (O
        (- (abstract-best-acc $partition $var () $best-block $best-score))
        (+ (most-abstract-block $partition $var $best-block))))


(exec (surp 070 most-abstract-support)
    (, (most-abstract-block $partition $var $block)
       (block-support $partition $block $support))
    (, (most-abstract-block-support $partition $var $block $support)))
