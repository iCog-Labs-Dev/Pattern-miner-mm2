;; High-Level Flow
; pattern
;  -> count support
;  -> compute actual probability
;  -> generate partitions of conjuncts
;  -> estimate probability of each partition by multiplying block probabilities
;  -> take [min, max]
;  -> distance(actual, [min, max])
;  -> optional normalization





;;===============================================================
;; Pipeline
;;===============================================================

;; Legacy public input. Index the raw pattern once and use that canonical value
;; as the owner of every intermediate fact.
(exec (surp s010 raw-input)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (isurp-old-pattern $indexed-copy $pattern $support)
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))))

;; Compatibility input for callers that already provide both the indexed id and
;; the raw pattern.
(exec (surp s010 normalize-scoped-input)
    (, (INPUT SCOPED-PATTERN ($pattern-id $pattern $support)))
    (, (isurp-old-pattern $pattern-id $pattern $support)))

;; Integrated input from the frequent miner. `$indexed-pattern` is already the
;; canonical pattern id, so only convert it to real MM2 variables for database
;; matching; do not index it again.
(exec (surp s010 indexed-input)
    (, (INPUT SURP-MODE isurp-old)
       (INPUT INDEXED-PATTERN ($indexed-pattern $support)))
    (O
        (pure
            (isurp-old-pattern $indexed-pattern $pattern $support)
            $pattern
            (indices_to_vars
                (cons , (' $indexed-pattern))))))

(exec (surp s020 init)
    (, (isurp-old-pattern $ctx $pattern $support))
    (O
        (pure
            (isurp-num-of-conjuncts $ctx $pattern $count)
            $count
            (size-atom
                (cdr-atom (' $pattern))))))

;; Expose the canonical owner as the indexed pattern consumed by partitioning.
(exec (surp s021 expose-indexed-pattern)
    (, (isurp-old-pattern $ctx $pattern $support))
    (, (indexed-pattern $ctx $ctx)))

(exec (surp s030 total-count)
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

(exec (surp s040 empirical-prob)
    (, (isurp-old-pattern $ctx $pattern $support)
       (isurp-total-count-of $ctx $pattern $count))
    (O
        (pure
            (isurp-prob-of $ctx $pattern $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $count))))))

(exec (surp s050 partition-list)
    (, (indexed-pattern $ctx $indexed-pattern))
    (O
        (pure
            (partitions-of $ctx $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))



(exec (surp s060 emit-partition)
    (, (partitions-of $ctx $indexed-pattern $indexed-partition)
       (exec (surp s060 emit-partition) $src $sink))
    (O
        (pure
            (partition $ctx $car)
            $car
            (car-atom (' $indexed-partition)))
        (pure
            (partitions-of $ctx $indexed-pattern $cdr)
            $cdr
            (cdr-atom (' $indexed-partition)))
        (- (partitions-of $ctx $indexed-pattern $indexed-partition))
        (+ (exec (surp s060 emit-partition) $src $sink))))

;; Copy partitions before expanding them into blocks.
(exec (surp s070 copy-partition)
    (, (partition $ctx $partition))
    (, (copy-of-partition $ctx $partition $partition)))

(exec (surp s080 emit-block)
    (, (copy-of-partition $ctx $partition $partition-copy)
       (exec (surp s080 emit-block) $src $sink))
    (O
        (pure
            (block $ctx $partition $block)
            $block
            (car-atom (' $partition-copy)))
        (pure
            (copy-of-partition $ctx $partition $cdr)
            $cdr
            (cdr-atom (' $partition-copy)))
        (- (copy-of-partition $ctx $partition $partition-copy))
        (+ (exec (surp s080 emit-block) $src $sink))))

;; Convert each indexed block back to a real variable pattern and count its support.
(exec (surp s090 count-block-support)
    (, (block $ctx $partition $indexed-block))
    (O
        (pure
            (exec (surp s090 count-block-support)
                $query
                (O
                    (count
                        (block-support $ctx $partition $indexed-block $support)
                        $support
                        $query)))
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))))

;; Convert block support into block probability using the full pattern total count.
(exec (surp s100 block-prob)
    (, (isurp-old-pattern $ctx $pattern $pattern-support)
       (isurp-total-count-of $ctx $pattern $total-count)
       (block-support $ctx $partition $indexed-block $support))
    (O
        (pure
            (block-prob $ctx $partition $indexed-block $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $total-count))))))

;; Current partition shapes have either two or three blocks.
(exec (surp s110 product-2)
    (, (partition $ctx ($b1 $b2))
       (block-prob $ctx ($b1 $b2) $b1 $p1)
       (block-prob $ctx ($b1 $b2) $b2 $p2))
    (O
        (pure
            (partition-product $ctx ($b1 $b2) $product)
            $product
            (f64_to_string
                (product_f64
                    (f64_from_string $p1)
                    (f64_from_string $p2))))))

(exec (surp s111 product-3)
    (, (partition $ctx ($b1 $b2 $b3))
       (block-prob $ctx ($b1 $b2 $b3) $b1 $p1)
       (block-prob $ctx ($b1 $b2 $b3) $b2 $p2)
       (block-prob $ctx ($b1 $b2 $b3) $b3 $p3))
    (O
        (pure
            (partition-product $ctx ($b1 $b2 $b3) $product)
            $product
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $p1)
                        (f64_from_string $p2))
                    (f64_from_string $p3))))))

;; Take [min, max] over the current three-conjunct partition products.
(exec (surp s120 interval-bounds)
    (, (indexed-pattern $ctx ($c1 $c2 $c3))
       (partition-product $ctx (($c1) ($c2 $c3)) $p1)
       (partition-product $ctx (($c1 $c3) ($c2)) $p2)
       (partition-product $ctx (($c1 $c2) ($c3)) $p3)
       (partition-product $ctx (($c1) ($c2) ($c3)) $p4))
    (O
        (pure
            (min-partition-product $ctx $min)
            $min
            (min-atom (' ($p1 $p2 $p3 $p4))))
        (pure
            (max-partition-product $ctx $max)
            $max
            (max-atom (' ($p1 $p2 $p3 $p4))))))

(exec (surp s130 interval-range)
    (, (min-partition-product $ctx $min)
       (max-partition-product $ctx $max))
    (, (partition-product-range $ctx $min $max)))

(exec (surp s140 distance-request)
    (, (isurp-old-pattern $ctx $pattern $support)
       (partition-product-range $ctx $emin $emax)
       (isurp-prob-of $ctx $pattern $emp)
       ((dst-from-interval $ctx $emin $emax $emp -> isurp-dst-of) $src $sink))
    (,
        (dst-request $ctx $emin $emax $emp isurp-dst-of)
        (exec (surp s140 distance-request) $src $sink)))

;; emp > emax: distance = emp - emax.
(exec (surp s150 distance-above)
    (, (dst-above? $ctx $emin $emax $emp $out true))
    (O
        (pure
            ($out $ctx $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))
        (- (dst-request $ctx $emin $emax $emp $out))
        (- (dst-above? $ctx $emin $emax $emp $out true))))

;; emp < emin: distance = emin - emp.
(exec (surp s151 distance-below)
    (, (dst-below? $ctx $emin $emax $emp $out true))
    (O
        (pure
            ($out $ctx $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))))
        (- (dst-request $ctx $emin $emax $emp $out))
        (- (dst-below? $ctx $emin $emax $emp $out true))))

;; emin <= emp <= emax: distance = 0.0.
(exec (surp s152 distance-inside)
    (, (dst-inside? $ctx $emin $emax $emp $out true))
    (O
        (+ ($out $ctx 0.0))
        (- (dst-request $ctx $emin $emax $emp $out))
        (- (dst-inside? $ctx $emin $emax $emp $out true))))


;; If normalization is enabled, surprisingness = min(dst / max(emax, empirical probability), 1.0).
(exec (surp s160 normalization-denom)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-dst-of $ctx $dst)
       (isurp-prob-of $ctx $pattern $prob)
       (partition-product-range $ctx $emin $emax))
    (O
        (pure
            (normalization-denom $ctx $dst $denom)
            $denom
            (max-atom (' ($emax $prob))))))

(exec (surp s170 normalization-candidate)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-dst-of $ctx $dst)
       (normalization-denom $ctx $dst $denom))
    (O
        (pure
            (normalization-candidate $ctx $dst $candidate)
            $candidate
            (f64_to_string
                (div_f64
                    (f64_from_string $dst)
                    (f64_from_string $denom))))))

(exec (surp s180 normalized-result)
    (, (INPUT NORMALIZATION TRUE)
       (isurp-old-pattern $ctx $pattern $support)
       (isurp-dst-of $ctx $dst)
       (normalization-denom $ctx $dst $denom)
       (normalization-candidate $ctx $dst $candidate))
    (O
        (pure
            (isurp-old-of $pattern $value)
            $value
            (min-atom (' ($candidate 1.0))))
        (pure
            (isurp-old-of $ctx $pattern $value)
            $value
            (min-atom (' ($candidate 1.0))))
        (- (normalization-denom $ctx $dst $denom))
        (- (normalization-candidate $ctx $dst $candidate))
        (- (isurp-dst-of $ctx $dst))))



;; Otherwise, surprisingness is just the distance from the interval.
(exec (surp s190 raw-result)
    (, (INPUT NORMALIZATION FALSE)
       (isurp-old-pattern $ctx $pattern $support)
       (isurp-dst-of $ctx $dst))
    (O
        (+ (isurp-old-of $pattern $dst))
        (+ (isurp-old-of $ctx $pattern $dst))
        (- (isurp-dst-of $ctx $dst))))






;; Final cleanup: 
(exec (surp s900 cleanup-plan)
    (, (isurp-old-of $ctx $pattern $value))
    (,
        (cleanup $ctx (block $ctx $partition $block))
        (cleanup $ctx (partition $ctx $partition))
        (cleanup $ctx (block-support $ctx $partition $block $support))
        (cleanup $ctx (block-prob $ctx $partition $block $prob))
        (cleanup $ctx (partition-product $ctx $partition $product))
        (cleanup $ctx (min-partition-product $ctx $min))
        (cleanup $ctx (max-partition-product $ctx $max))
        (cleanup $ctx (partition-product-range $ctx $min $max))
        (cleanup $ctx (indexed-pattern $ctx $indexed-pattern))
        (cleanup $ctx (copy-of-partition $ctx $partition $partition-copy))
        (cleanup $ctx (dst-above? $ctx $emin $emax $emp $out $above))
        (cleanup $ctx (dst-below? $ctx $emin $emax $emp $out $below))
        (cleanup $ctx (dst-inside? $ctx $emin $emax $emp $out $inside))
        (cleanup $ctx (dst-request $ctx $emin $emax $emp $out))))

;; One cleanup matcher removes any fact selected by the cleanup task.
(exec (surp s910 cleanup-fact)
    (, (cleanup $ctx $fact) $fact)
    (O
        (- (cleanup $ctx $fact))
        (- $fact)
        ))

;; Remove the generic cleanup tasks after they are no longer useful.
(exec (surp s920 cleanup-task)
    (, (cleanup $ctx $fact))
    (O
        (- (cleanup $ctx $fact))
        ))
















