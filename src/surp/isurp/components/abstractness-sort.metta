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
;;   (abstractness-sort-request $pattern $partition $var)
;;
;; Public result facts:
;;
;;   (abstract-block-clause $pattern $partition $block $clause)
;;   (abstract-clause-arg $pattern $partition $var $block $clause $arg)
;;   (abstract-clause-has-var $pattern $partition $var $block $clause)
;;   (abstract-clause-has-other-var $pattern $partition $var $block $clause)
;;   (abstract-term-has-var $pattern $partition $var $term)
;;   (abstract-term-has-other-var $pattern $partition $var $term)
;;   (abstract-open-score $pattern $partition $var $block $clause $score)
;;   (abstract-size-priority $pattern $partition $block $priority)
;;   (abstract-block-score $pattern $partition $var $block $score)
;;   (most-abstract-block $pattern $partition $var $block)
;;   (most-abstract-block-support $pattern $partition $var $block $support)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s060 abstract-copy-block)
    (, (abstractness-sort-request $pattern $partition $var)
       (block $pattern $partition $block))
    (, (abstract-copy-block $pattern $partition $block $block)))


(exec (surp s060 abstract-block-size)
    (, (abstractness-sort-request $pattern $partition $var)
       (block $pattern $partition $block))
    (O
        (pure
            (abstract-block-size $pattern $partition $block $size)
            $size
            (size-atom (' $block)))))


(exec (surp s061 abstract-size-priority)
    (, (abstract-block-size $pattern $partition $block $size))
    (O
        (pure
            (abstract-size-priority $pattern $partition $block $priority)
            $priority
            (i64_to_string
                (sub_i64
                    (i64_from_string 5000000000000)
                    (product_i64
                        (i64_from_string $size)
                        (i64_from_string 1000000000000)))))))


(exec (surp s060 abstract-block-iterator)
    (, (abstract-copy-block $pattern $partition $block $copy)
       (exec (surp s060 abstract-block-iterator) $src $sink))
    (O
        (pure
            (abstract-block-clause $pattern $partition $block $clause)
            $clause
            (car-atom (' $copy)))
        (pure
            (abstract-copy-block $pattern $partition $block $tail)
            $tail
            (cdr-atom (' $copy)))
        (- (abstract-copy-block $pattern $partition $block $copy))
        (+ (exec (surp s060 abstract-block-iterator) $src $sink))))


;; Walk all arguments of a clause. `cdr-atom` removes the relation head, so this
;; works for clauses with any number of top-level arguments.
(exec (surp s062 abstract-clause-args-start)
    (, (abstractness-sort-request $pattern $partition $var)
       (abstract-block-clause $pattern $partition $block $clause))
    (O
        (pure
            (abstract-clause-args $pattern $partition $var $block $clause $args)
            $args
            (cdr-atom (' $clause)))))

(exec (surp s063 abstract-clause-args-walk)
    (, (abstract-clause-args $pattern $partition $var $block $clause $remaining)
       (exec (surp s063 abstract-clause-args-walk) $src $sink))
    (O
        (pure
            (abstract-clause-arg $pattern $partition $var $block $clause $arg)
            $arg
            (car-atom (' $remaining)))
        (pure
            (abstract-clause-args $pattern $partition $var $block $clause $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (abstract-clause-args $pattern $partition $var $block $clause $remaining))
        (+ (exec (surp s063 abstract-clause-args-walk) $src $sink))))

(exec (surp s064 abstract-clause-arg-scan)
    (, (abstract-clause-arg $pattern $partition $var $block $clause $arg))
    (, (abstract-term-scan $pattern $partition $var $arg)))

(exec (surp s067 abstract-clause-has-var)
    (, (abstract-clause-arg $pattern $partition $var $block $clause $arg)
       (abstract-term-has-var $pattern $partition $var $arg))
    (, (abstract-clause-has-var $pattern $partition $var $block $clause)))

(exec (surp s067 abstract-clause-has-other-var)
    (, (abstract-clause-arg $pattern $partition $var $block $clause $arg)
       (abstract-term-has-other-var $pattern $partition $var $arg))
    (, (abstract-clause-has-other-var $pattern $partition $var $block $clause)))


;; Recursively scan any term for the requested joint variable and for variables
;; different from the requested joint variable.

(exec (surp s064 abstract-term-has-var-direct)
    (, (abstract-term-scan $pattern $partition (var $n) (var $n)))
    (, (abstract-term-has-var $pattern $partition (var $n) (var $n))))

(exec (surp s064 abstract-term-has-other-var-direct)
    (, (abstract-term-scan $pattern $partition (var $n) (var $m)))
    (O
        (pure
            (abstract-term-other-var? $pattern $partition (var $n) (var $m) $different)
            $different
            (ne_i32
                (i32_from_string $n)
                (i32_from_string $m)))))

(exec (surp s065 abstract-term-has-other-var-emit)
    (, (abstract-term-other-var? $pattern $partition $var $term true))
    (, (abstract-term-has-other-var $pattern $partition $var $term)))

(exec (surp s064 abstract-term-compound-check)
    (, (abstract-term-scan $pattern $partition $var $term))
    (O
        (pure
            (abstract-term-is-compound $pattern $partition $var $term $is-compound)
            $is-compound
            (i8_to_string
                (is_exp (' $term))))))

(exec (surp s065 abstract-term-children-start)
    (, (abstract-term-is-compound $pattern $partition $var $term 1))
    (O
        (pure
            (abstract-term-children $pattern $partition $var $term $children)
            $children
            (cdr-atom (' $term)))))

(exec (surp s066 abstract-term-children-walk)
    (, (abstract-term-children $pattern $partition $var $term $remaining)
       (exec (surp s066 abstract-term-children-walk) $src $sink))
    (O
        (pure
            (abstract-term-child $pattern $partition $var $term $remaining $child)
            $child
            (car-atom (' $remaining)))
        (pure
            (abstract-term-children $pattern $partition $var $term $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (abstract-term-children $pattern $partition $var $term $remaining))
        (+ (exec (surp s066 abstract-term-children-walk) $src $sink))))

(exec (surp s067 abstract-term-child-scan)
    (, (abstract-term-child $pattern $partition $var $term $remaining $child))
    (, (abstract-term-scan $pattern $partition $var $child)))

(exec (surp s068 abstract-term-has-var-from-child)
    (, (abstract-term-child $pattern $partition $var $term $remaining $child)
       (abstract-term-has-var $pattern $partition $var $child))
    (, (abstract-term-has-var $pattern $partition $var $term)))

(exec (surp s068 abstract-term-has-other-var-from-child)
    (, (abstract-term-child $pattern $partition $var $term $remaining $child)
       (abstract-term-has-other-var $pattern $partition $var $child))
    (, (abstract-term-has-other-var $pattern $partition $var $term)))


;; Clause-level syntactic abstractness relative to the requested joint variable.
;; A clause is open when it contains the requested joint variable and also
;; contains another variable somewhere in its argument list.
(exec (surp s069 abstract-open-generic)
    (, (abstract-clause-has-var $pattern $partition $var $block $clause)
       (abstract-clause-has-other-var $pattern $partition $var $block $clause))
    (, (abstract-open-score $pattern $partition $var $block $clause 1)))

(exec (surp s069 abstract-open-fallback)
    (, (abstract-block-clause $pattern $partition $block $clause))
    (, (abstract-open-score $pattern $partition $var $block $clause 0)))


(exec (surp s070 abstract-open-total)
    (, (abstractness-sort-request $pattern $partition $var)
       (block $pattern $partition $block)
       (exec (surp s070 abstract-open-total) $src $sink))
    (,
        (exec (surp s070 abstract-open-total)
            (, (abstract-open-score $pattern $partition $var $block $clause 1))
            (O
                (count
                    (abstract-open-total $pattern $partition $var $block $score)
                    $score
                    $clause)))))


(exec (surp s070 abstract-open-total-zero)
    (, (abstract-open-score $pattern $partition $var $block $clause 0))
    (, (abstract-open-total $pattern $partition $var $block 0)))


;; Weighted block score.
(exec (surp s071 abstract-block-score)
    (, (abstract-open-total $pattern $partition $var $block $open-total)
       (abstract-size-priority $pattern $partition $block $size-priority)
       (block-support $pattern $partition $block $support))
    (O
        (pure
            (abstract-block-score $pattern $partition $var $block $score)
            $score
            (i64_to_string
                (sum_i64
                    (product_i64
                        (i64_from_string $open-total)
                        (i64_from_string 1000000000000000))
                    (i64_from_string $size-priority)
                    (i64_from_string $support))))))


(exec (surp s072 abstract-best-start)
    (, (abstractness-sort-request $pattern $partition $var)
       (DEF abstract-best-step $step-p $step-t))
    (O
        (pure
            (abstract-best-first $pattern $partition $var $first)
            $first
            (car-atom (' $partition)))
        (pure
            (abstract-best-rest $pattern $partition $var $rest)
            $rest
            (cdr-atom (' $partition)))
        (+ (exec (surp s073 abstract-best-step) $step-p $step-t))))


(exec (surp s072 abstract-best-acc-start)
    (, (abstract-best-first $pattern $partition $var $first)
       (abstract-best-rest $pattern $partition $var $rest)
       (abstract-block-score $pattern $partition $var $first $score))
    (,
        (abstract-best-acc $pattern $partition $var $rest $first $score)))


(DEF abstract-best-step
    (, (abstract-best-acc $pattern $partition $var $remaining $best-block $best-score)
       (DEF abstract-best-resolve $resolve-p $resolve-t))
    (O
        (pure
            (abstract-best-current $pattern $partition $var $remaining $current)
            $current
            (car-atom (' $remaining)))
        (pure
            (abstract-best-tail $pattern $partition $var $remaining $tail)
            $tail
            (cdr-atom (' $remaining)))
        (- (abstract-best-acc $pattern $partition $var $remaining $best-block $best-score))
        (+ (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score))
        (+ (exec (surp s074 abstract-best-resolve) $resolve-p $resolve-t))))


(DEF abstract-best-resolve
    (, (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score)
       (abstract-best-current $pattern $partition $var $remaining $current)
       (abstract-best-tail $pattern $partition $var $remaining $tail)
       (abstract-block-score $pattern $partition $var $current $current-score)
       (DEF abstract-best-step $step-p $step-t)
       (DEF abstract-best-final $final-p $final-t))
    (O
        (pure
            (abstract-current-better? $pattern $partition $var $remaining $better)
            $better
            (gt_i64
                (i64_from_string $current-score)
                (i64_from_string $best-score)))
        (+ (exec (surp s075 abstract-best-final) $final-p $final-t))
        (+ (exec (surp s076 abstract-best-step) $step-p $step-t))))


(exec (surp s075 abstract-best-keep)
    (, (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score)
       (abstract-best-tail $pattern $partition $var $remaining $tail)
       (abstract-current-better? $pattern $partition $var $remaining false))
    (O
        (- (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score))
        (- (abstract-best-tail $pattern $partition $var $remaining $tail))
        (+ (abstract-best-acc $pattern $partition $var $tail $best-block $best-score))))


(exec (surp s075 abstract-best-replace)
    (, (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score)
       (abstract-best-current $pattern $partition $var $remaining $current)
       (abstract-best-tail $pattern $partition $var $remaining $tail)
       (abstract-block-score $pattern $partition $var $current $current-score)
       (abstract-current-better? $pattern $partition $var $remaining true))
    (O
        (- (abstract-best-pending $pattern $partition $var $remaining $best-block $best-score))
        (- (abstract-best-current $pattern $partition $var $remaining $current))
        (- (abstract-best-tail $pattern $partition $var $remaining $tail))
        (+ (abstract-best-acc $pattern $partition $var $tail $current $current-score))))


(DEF abstract-best-final
    (, (abstract-best-acc $pattern $partition $var () $best-block $best-score))
    (O
        (- (abstract-best-acc $pattern $partition $var () $best-block $best-score))
        (+ (most-abstract-block $pattern $partition $var $best-block))))


(exec (surp s077 most-abstract-support)
    (, (most-abstract-block $pattern $partition $var $block)
       (block-support $pattern $partition $block $support))
    (, (most-abstract-block-support $pattern $partition $var $block $support)))
