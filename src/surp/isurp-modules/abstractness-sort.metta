;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Abstractness sorting for blocks of predicate clauses
;;
;; Scope:
;;
;;   This module treats each clause as a relation head followed by one or more
;;   arguments:
;;
;;     ($rel $arg1 $arg2 ... $argN)
;;
;;   Arguments may be deeply nested expressions. Blocks and partitions may
;;   contain any number of clauses/blocks.
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
;;   This MM2 version keeps the same intent by using a deterministic weighted
;;   score:
;;
;;     1. syntactic abstractness relative to the joint variable
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
;;   (abstract-clause-arg $partition $var $block $clause $arg)
;;   (abstract-clause-has-var $partition $var $block $clause)
;;   (abstract-clause-has-other-var $partition $var $block $clause)
;;   (abstract-term-has-var $partition $var $term)
;;   (abstract-term-has-other-var $partition $var $term)
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


;; Walk all arguments of a clause. `cdr-atom` removes the relation head, so this
;; works for clauses with any number of top-level arguments.
(exec (surp 062 abstract-clause-args-start)
    (, (abstractness-sort-request $partition $var)
       (abstract-block-clause $partition $block $clause))
    (O
        (pure
            (abstract-clause-args $partition $var $block $clause $args)
            $args
            (cdr-atom (' $clause)))))

(exec (surp 063 abstract-clause-args-walk)
    (, (abstract-clause-args $partition $var $block $clause $remaining)
       (exec (surp 063 abstract-clause-args-walk) $src $sink))
    (O
        (pure
            (abstract-clause-arg $partition $var $block $clause $arg)
            $arg
            (car-atom (' $remaining)))
        (pure
            (abstract-clause-args $partition $var $block $clause $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (abstract-clause-args $partition $var $block $clause $remaining))
        (+ (exec (surp 063 abstract-clause-args-walk) $src $sink))))

(exec (surp 064 abstract-clause-arg-scan)
    (, (abstract-clause-arg $partition $var $block $clause $arg))
    (, (abstract-term-scan $partition $var $arg)))

(exec (surp 067 abstract-clause-has-var)
    (, (abstract-clause-arg $partition $var $block $clause $arg)
       (abstract-term-has-var $partition $var $arg))
    (, (abstract-clause-has-var $partition $var $block $clause)))

(exec (surp 067 abstract-clause-has-other-var)
    (, (abstract-clause-arg $partition $var $block $clause $arg)
       (abstract-term-has-other-var $partition $var $arg))
    (, (abstract-clause-has-other-var $partition $var $block $clause)))


;; Recursively scan any term for the requested joint variable and for variables
;; different from the requested joint variable.

(exec (surp 064 abstract-term-has-var-direct)
    (, (abstract-term-scan $partition (var $n) (var $n)))
    (, (abstract-term-has-var $partition (var $n) (var $n))))

(exec (surp 064 abstract-term-has-other-var-direct)
    (, (abstract-term-scan $partition (var $n) (var $m)))
    (O
        (pure
            (abstract-term-other-var? $partition (var $n) (var $m) $different)
            $different
            (ne_i32
                (i32_from_string $n)
                (i32_from_string $m)))))

(exec (surp 065 abstract-term-has-other-var-emit)
    (, (abstract-term-other-var? $partition $var $term true))
    (, (abstract-term-has-other-var $partition $var $term)))

(exec (surp 064 abstract-term-compound-check)
    (, (abstract-term-scan $partition $var $term))
    (O
        (pure
            (abstract-term-is-compound $partition $var $term $is-compound)
            $is-compound
            (i8_to_string
                (is_exp (' $term))))))

(exec (surp 065 abstract-term-children-start)
    (, (abstract-term-is-compound $partition $var $term 1))
    (O
        (pure
            (abstract-term-children $partition $var $term $children)
            $children
            (cdr-atom (' $term)))))

(exec (surp 066 abstract-term-children-walk)
    (, (abstract-term-children $partition $var $term $remaining)
       (exec (surp 066 abstract-term-children-walk) $src $sink))
    (O
        (pure
            (abstract-term-child $partition $var $term $remaining $child)
            $child
            (car-atom (' $remaining)))
        (pure
            (abstract-term-children $partition $var $term $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (abstract-term-children $partition $var $term $remaining))
        (+ (exec (surp 066 abstract-term-children-walk) $src $sink))))

(exec (surp 067 abstract-term-child-scan)
    (, (abstract-term-child $partition $var $term $remaining $child))
    (, (abstract-term-scan $partition $var $child)))

(exec (surp 068 abstract-term-has-var-from-child)
    (, (abstract-term-child $partition $var $term $remaining $child)
       (abstract-term-has-var $partition $var $child))
    (, (abstract-term-has-var $partition $var $term)))

(exec (surp 068 abstract-term-has-other-var-from-child)
    (, (abstract-term-child $partition $var $term $remaining $child)
       (abstract-term-has-other-var $partition $var $child))
    (, (abstract-term-has-other-var $partition $var $term)))


;; Clause-level syntactic abstractness relative to the requested joint variable.
;; A clause is open when it contains the requested joint variable and also
;; contains another variable somewhere in its argument list.
(exec (surp 069 abstract-open-generic)
    (, (abstract-clause-has-var $partition $var $block $clause)
       (abstract-clause-has-other-var $partition $var $block $clause))
    (, (abstract-open-score $partition $var $block $clause 1)))

(exec (surp 069 abstract-open-fallback)
    (, (abstract-block-clause $partition $block $clause))
    (, (abstract-open-score $partition $var $block $clause 0)))


(exec (surp 070 abstract-open-total)
    (, (abstractness-sort-request $partition $var)
       (block $partition $block)
       (exec (surp 070 abstract-open-total) $src $sink))
    (,
        (exec (surp 070 abstract-open-total)
            (, (abstract-open-score $partition $var $block $clause 1))
            (O
                (count
                    (abstract-open-total $partition $var $block $score)
                    $score
                    $clause)))))


(exec (surp 070 abstract-open-total-zero)
    (, (abstract-open-score $partition $var $block $clause 0))
    (, (abstract-open-total $partition $var $block 0)))


;; Weighted block score.
(exec (surp 071 abstract-block-score)
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


(exec (surp 072 abstract-best-start)
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
        (+ (exec (surp 073 abstract-best-step) $step-p $step-t))))


(exec (surp 072 abstract-best-acc-start)
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
        (+ (exec (surp 074 abstract-best-resolve) $resolve-p $resolve-t))))


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
        (+ (exec (surp 075 abstract-best-final) $final-p $final-t))
        (+ (exec (surp 076 abstract-best-step) $step-p $step-t))))


(exec (surp 075 abstract-best-keep)
    (, (abstract-best-pending $partition $var $remaining $best-block $best-score)
       (abstract-best-tail $partition $var $remaining $tail)
       (abstract-current-better? $partition $var $remaining false))
    (O
        (- (abstract-best-pending $partition $var $remaining $best-block $best-score))
        (- (abstract-best-tail $partition $var $remaining $tail))
        (+ (abstract-best-acc $partition $var $tail $best-block $best-score))))


(exec (surp 075 abstract-best-replace)
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


(exec (surp 077 most-abstract-support)
    (, (most-abstract-block $partition $var $block)
       (block-support $partition $block $support))
    (, (most-abstract-block-support $partition $var $block $support)))
