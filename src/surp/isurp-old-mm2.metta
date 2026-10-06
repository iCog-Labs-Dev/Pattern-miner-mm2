;; Legacy public input: index raw pattern once
(exec 0
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (isurp-old-pattern $indexed-copy $pattern $support)
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))))


;; Scoped pattern input
(exec 0
    (, (INPUT SCOPED-PATTERN ($pattern-id $pattern $support)))
    (, (isurp-old-pattern $pattern-id $pattern $support)))



;; Compute DB-SIZE from the number of loaded database facts.
(exec 0
    (, (DB-FACT $fact))
    (O (count (INPUT DB-SIZE $size) $size $fact)))


;; Compute the number of conjunctive clauses in the pattern
(exec 2
    (, (isurp-old-pattern $ctx $pattern $support))
    (O
        (pure
            (isurp-num-of-conjuncts $ctx $pattern $count)
            $count
            (size-atom
                (cdr-atom (' $pattern))))))


;; Extract clause list from pattern
(exec 2
    (, (isurp-old-pattern $ctx $pattern $support))
    (O
        (pure
            (isurp-clause-list $ctx $clauses)
            $clauses
            (cdr-atom (' $pattern)))))
            

;; Compute total count denominator: choose(N, k) = N! / ((N-k)! k!)
;; Equivalently, divide the falling factorial N*(N-1)*...*(N-k+1) by k!.
(exec 3
    (, (INPUT DB-SIZE $n)
       (isurp-num-of-conjuncts $ctx $pattern $k))
    (O
        (pure
            (isurp-total-count-of $ctx $pattern $total)
            $total
            (i64_to_string
                (div_i64
                    (falling_factorial
                        (i64_from_string $n)
                        (i64_from_string $k))
                    (factorial
                        (i64_from_string $k)))))))


;; Compute empirical observed pattern probability: P(pattern) = support / total_count
(exec 4
    (, (isurp-old-pattern $ctx $pattern $support)
       (isurp-total-count-of $ctx $pattern $total))
    (O
        (pure
            (isurp-pattern-prob $ctx $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $total))))))


;; Generate partition list from indexed $ctx so blocks carry (var N) notation,
;; which matches the isurp-clause-support keys produced by exec 6.
(exec 5
    (, (isurp-old-pattern $ctx $pattern $support)
       (isurp-total-count-of $ctx $pattern $total))
    (O
        (pure
            (isurp-partitions $ctx $total $p)
            $p
            (partitions (' $ctx)))))


;; Extract all 4 partitions at once by matching the 4-element partition list.
(exec 5.1
    (, (isurp-partitions $ctx $total ($p1 $p2 $p3 $p4)))
    (O
        (+ (isurp-partition $ctx $total $p1))
        (+ (isurp-partition $ctx $total $p2))
        (+ (isurp-partition $ctx $total $p3))
        (+ (isurp-partition $ctx $total $p4))))

;; 2-block partition: extract both blocks in one shot.
(exec 5.2
    (, (isurp-partition $ctx $total ($b1 $b2)))
    (O
        (+ (isurp-partition-block $ctx $total ($b1 $b2) $b1))
        (+ (isurp-partition-block $ctx $total ($b1 $b2) $b2))))


;; 3-block partition: extract all three blocks in one shot.
(exec 5.3
    (, (isurp-partition $ctx $total ($b1 $b2 $b3)))
    (O
        (+ (isurp-partition-block $ctx $total ($b1 $b2 $b3) $b1))
        (+ (isurp-partition-block $ctx $total ($b1 $b2 $b3) $b2))
        (+ (isurp-partition-block $ctx $total ($b1 $b2 $b3) $b3))))


(exec 6
    (, (DB-FACT ($rel $entity $target)))
    (O
        (count
            (isurp-clause-support (($rel (var 0) $target)) $support)
            $support
            $entity)))


;; Shared variable across any 2 facts
(exec 6
    (, (DB-FACT ($rel1 $entity $t1))
       (DB-FACT ($rel2 $entity $t2)))
    (O
        (count
            (isurp-clause-support
                (( $rel1 (var 0) $t1 )
                 ( $rel2 (var 0) $t2 )) $support)
            $support
            $entity)))


;; Connect block support: $part is the stable partition id from the iterator,
;; $block is an indexed (var N) block that matches isurp-clause-support keys.
(exec 6.1
    (, (isurp-partition-block $ctx $total $part $block)
       (isurp-clause-support $block $support))
    (O
        (+ (isurp-block-support $ctx $total $part $block $support))))



;; Turn DB-derived block supports into probabilities using the full-pattern denominator.
(exec 7.5
    (, (isurp-block-support $ctx $total $partition $block $support))
    (O
        (pure
            (isurp-block-prob $ctx $partition $block $b_prob)
            $b_prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $total))))))


;; Multiply block probabilities for the two-block partition shape.
(exec 8.1
    (, (isurp-partition $ctx $total ($b1 $b2))
       (isurp-block-prob $ctx ($b1 $b2) $b1 $p1)
       (isurp-block-prob $ctx ($b1 $b2) $b2 $p2))
    (O
        (pure
            (isurp-partition-prob $ctx ($b1 $b2) $product)
            $product
            (f64_to_string
                (product_f64
                    (f64_from_string $p1)
                    (f64_from_string $p2))))))


;; Multiply block probabilities for the three-block partition shape.
(exec 8.2
    (, (isurp-partition $ctx $total ($b1 $b2 $b3))
       (isurp-block-prob $ctx ($b1 $b2 $b3) $b1 $p1)
       (isurp-block-prob $ctx ($b1 $b2 $b3) $b2 $p2)
       (isurp-block-prob $ctx ($b1 $b2 $b3) $b3 $p3))
    (O
        (pure
            (isurp-partition-prob $ctx ($b1 $b2 $b3) $product)
            $product
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $p1)
                        (f64_from_string $p2))
                    (f64_from_string $p3))))))


;; Collect all partition probabilities and reduce to [E_min, E_max] per context.
(exec 9.1
    (, (isurp-partition-prob $ctx $pid $prob))
    (O
        (fmin (isurp-emin $ctx $emin) $emin $prob)
        (fmax (isurp-emax $ctx $emax) $emax $prob)))



;; Combine emin and emax into a single interval fact
(exec 10.1
    (, (isurp-emin $ctx $emin)
       (isurp-emax $ctx $emax))
    (, (isurp-interval $ctx $emin $emax)))



;; Distance from P(pattern) to [E_min, E_max]: zero inside the interval,
;; E_min - P below it, and P - E_max above it.
;;
;; Implementation uses nested max_f64 and sub_f64 functions to compute piecewise distance:
;;   - max_f64: Returns maximum of multiple f64 values (built-in MM2 stdlib function)
;;   - sub_f64: Subtracts second f64 from first (built-in MM2 stdlib function)
;;
;; Mathematical formula: max((emin - p), max((p - emax), 0.0))
;; This implements:
;;   - If p < emin:         distance = emin - p    (positive distance below interval)
;;   - If emin ≤ p ≤ emax:  distance = 0.0        (inside interval, no distance)
;;   - If p > emax:         distance = p - emax    (positive distance above interval)


(exec 11.1
    (, (isurp-pattern-prob $ctx $p)
       (isurp-interval $ctx $emin $emax))
    (O
        (pure
            (isurp-distance $ctx $dst)
            $dst
            (f64_to_string
                (max_f64
                    (sub_f64
                        (f64_from_string $emin)
                        (f64_from_string $p))
                    (max_f64
                        (sub_f64
                            (f64_from_string $p)
                            (f64_from_string $emax))
                        (f64_from_string 0.0)))))))


;; Emit the legacy public result with the original, unindexed pattern.
;; Keep the indexed-context forms for MM2 callers that need the owner ID.
(exec 12.1
    (, (INPUT NORMALIZATION True)
       (isurp-old-pattern $ctx $pattern $support)
       (isurp-distance $ctx $dst)
       (isurp-pattern-prob $ctx $p)
       (isurp-interval $ctx $emin $emax))
    (O
        (pure
            (OUTPUT ISURP-RESULT ($ctx $score))
            $score
            (f64_to_string
                (min_f64
                    (div_f64
                        (f64_from_string $dst)
                        (max_f64 (f64_from_string $emax) (f64_from_string $p)))
                    (f64_from_string 1.0))))
        (pure
            (isurp-old-of $pattern $score)
            $score
            (f64_to_string
                (min_f64
                    (div_f64
                        (f64_from_string $dst)
                        (max_f64 (f64_from_string $emax) (f64_from_string $p)))
                    (f64_from_string 1.0))))
        (pure
            (isurp-old-of $ctx $pattern $score)
            $score
            (f64_to_string
                (min_f64
                    (div_f64
                        (f64_from_string $dst)
                        (max_f64 (f64_from_string $emax) (f64_from_string $p)))
                    (f64_from_string 1.0))))))

(exec 12.1
    (, (INPUT NORMALIZATION False)
       (isurp-old-pattern $ctx $pattern $support)
       (isurp-distance $ctx $dst))
    (O
        (pure
            (OUTPUT ISURP-RESULT ($ctx $score))
            $score
            (f64_to_string (min_f64 (f64_from_string $dst) (f64_from_string 1.0))))
        (pure
            (isurp-old-of $pattern $score)
            $score
            (f64_to_string (min_f64 (f64_from_string $dst) (f64_from_string 1.0))))
        (pure
            (isurp-old-of $ctx $pattern $score)
            $score
            (f64_to_string (min_f64 (f64_from_string $dst) (f64_from_string 1.0))))))
