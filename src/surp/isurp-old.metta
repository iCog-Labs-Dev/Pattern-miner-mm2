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

(exec (surp 010 init)
    (, (INPUT DB $db-name)
       (INPUT PATTERN ($pattern $support))
       ((count-db $db-name -> db-size) $src-of-count $sink-of-count)
       ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
       ((total-counts $db-name $pattern -> total-count-of) $src-of-tc $sink-of-tc)
       ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))
    (O
        (+ (exec (surp 020 count-db) $src-of-count $sink-of-count))
        (+ (exec (surp 021 count-conjuncts) $src-of-cnj $sink-of-cnj))
        (+ (exec (surp 030 total-count) $src-of-tc $sink-of-tc))
        (+ (exec (surp 040 empirical-prob) $src-of-prob $sink-of-prob))
        (pure
            (indexed-pattern $indexed-copy)
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))))

(exec (surp 050 partition-list)
    (, (indexed-pattern $indexed-pattern))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))



(exec (surp 060 emit-partition)
    (, (partitions-of $indexed-pattern $indexed-partition)
       (exec (surp 060 emit-partition) $src $sink))
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
        (+ (exec (surp 060 emit-partition) $src $sink))))

;; Copy partitions before expanding them into blocks.
(exec (surp 070 copy-partition)
    (, (partition $partition))
    (, (copy-of-partition $partition $partition)))

(exec (surp 080 emit-block)
    (, (copy-of-partition $partition $partition-copy)
       (exec (surp 080 emit-block) $src $sink))
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
        (+ (exec (surp 080 emit-block) $src $sink))))

;; Convert each indexed block back to a real variable pattern and count its support.
(exec (surp 090 count-block-support)
    (, (block $partition $indexed-block))
    (O
        (pure
            (exec (surp 090 count-block-support)
                $query
                (O
                    (count
                        (block-support $partition $indexed-block $support)
                        $support
                        $query)))
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))))

;; Convert block support into block probability using the full pattern total count.
(exec (surp 100 block-prob)
    (, (INPUT PATTERN ($pattern $pattern-support))
       (total-count-of $pattern $total-count)
       (block-support $partition $indexed-block $support))
    (O
        (pure
            (block-prob $partition $indexed-block $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $total-count))))))

;; Current partition shapes have either two or three blocks.
(exec (surp 110 product-2)
    (, (partition ($b1 $b2))
       (block-prob ($b1 $b2) $b1 $p1)
       (block-prob ($b1 $b2) $b2 $p2))
    (O
        (pure
            (partition-product ($b1 $b2) $product)
            $product
            (f64_to_string
                (product_f64
                    (f64_from_string $p1)
                    (f64_from_string $p2))))))

(exec (surp 111 product-3)
    (, (partition ($b1 $b2 $b3))
       (block-prob ($b1 $b2 $b3) $b1 $p1)
       (block-prob ($b1 $b2 $b3) $b2 $p2)
       (block-prob ($b1 $b2 $b3) $b3 $p3))
    (O
        (pure
            (partition-product ($b1 $b2 $b3) $product)
            $product
            (f64_to_string
                (product_f64
                    (product_f64
                        (f64_from_string $p1)
                        (f64_from_string $p2))
                    (f64_from_string $p3))))))

;; Take [min, max] over the current three-conjunct partition products.
(exec (surp 120 interval-bounds)
    (, (indexed-pattern ($c1 $c2 $c3))
       (partition-product (($c1) ($c2 $c3)) $p1)
       (partition-product (($c1 $c3) ($c2)) $p2)
       (partition-product (($c1 $c2) ($c3)) $p3)
       (partition-product (($c1) ($c2) ($c3)) $p4))
    (O
        (pure
            (min-partition-product $min)
            $min
            (min-atom (' ($p1 $p2 $p3 $p4))))
        (pure
            (max-partition-product $max)
            $max
            (max-atom (' ($p1 $p2 $p3 $p4))))))

(exec (surp 130 interval-range)
    (, (min-partition-product $min)
       (max-partition-product $max))
    (, (partition-product-range $min $max)))

(exec (surp 140 distance-request)
    (, (partition-product-range $emin $emax)
       (prob-of $pattern $emp)
       ((dst-from-interval $pattern $emin $emax $emp -> dst-of) $src $sink))
    (,
        (dst-request $pattern $emin $emax $emp dst-of)
        (exec (surp 140 distance-request) $src $sink)))

;; emp > emax: distance = emp - emax.
(exec (surp 150 distance-above)
    (, (dst-above? $pattern $emin $emax $emp $out true))
    (O
        (pure
            ($out $pattern $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-above? $pattern $emin $emax $emp $out true))))

;; emp < emin: distance = emin - emp.
(exec (surp 151 distance-below)
    (, (dst-below? $pattern $emin $emax $emp $out true))
    (O
        (pure
            ($out $pattern $distance)
            $distance
            (f64_to_string
                (sub_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-below? $pattern $emin $emax $emp $out true))))

;; emin <= emp <= emax: distance = 0.0.
(exec (surp 152 distance-inside)
    (, (dst-inside? $pattern $emin $emax $emp $out true))
    (O
        (+ ($out $pattern 0.0))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-inside? $pattern $emin $emax $emp $out true))))


;; If normalization is enabled, surprisingness = min(dst / max(emax, empirical probability), 1.0).
(exec (surp 160 normalization-denom)
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (prob-of $pattern $prob)
       (partition-product-range $emin $emax))
    (O
        (pure
            (normalization-denom $pattern $dst $denom)
            $denom
            (max-atom (' ($emax $prob))))))

(exec (surp 170 normalization-candidate)
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (normalization-denom $pattern $dst $denom))
    (O
        (pure
            (normalization-candidate $pattern $dst $candidate)
            $candidate
            (f64_to_string
                (div_f64
                    (f64_from_string $dst)
                    (f64_from_string $denom))))))

(exec (surp 180 normalized-result)
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (normalization-denom $pattern $dst $denom)
       (normalization-candidate $pattern $dst $candidate))
    (O
        (pure
            (surprisingess-of $pattern $value)
            $value
            (min-atom (' ($candidate 1.0))))
        (- (normalization-denom $pattern $dst $denom))
        (- (normalization-candidate $pattern $dst $candidate))
        (- (dst-of $pattern $dst))))



;; Otherwise, surprisingness is just the distance from the interval.
(exec (surp 190 raw-result)
    (, (INPUT NORMALIZATION FALSE)
       (dst-of $pattern $dst))
    (O
        (+ (surprisingess-of $pattern $dst))
        (- (dst-of $pattern $dst))))






;; Final cleanup: 
(exec (surp 900 cleanup-plan)
    (, (surprisingess-of $pattern $value))
    (,
        (cleanup (block $partition $block))
        (cleanup (partition $partition))
        (cleanup (block-support $partition $block $support))
        (cleanup (block-prob $partition $block $prob))
        (cleanup (partition-product $partition $product))
        (cleanup (min-partition-product $min))
        (cleanup (max-partition-product $max))
        (cleanup (partition-product-range $min $max))
        (cleanup (indexed-pattern $indexed-pattern))
        (cleanup (copy-of-partition $partition $partition-copy))
        (cleanup (dst-above? $p $emin $emax $emp $out $above))
        (cleanup (dst-below? $p $emin $emax $emp $out $below))
        (cleanup (dst-inside? $p $emin $emax $emp $out $inside))
        (cleanup (dst-request $p $emin $emax $emp $out))))

;; One cleanup matcher removes any fact selected by the cleanup task.
(exec (surp 910 cleanup-fact)
    (, (cleanup $fact) $fact)
    (O
        (- (cleanup $fact))
        (- $fact)
        ))

;; Remove the generic cleanup tasks after they are no longer useful.
(exec (surp 920 cleanup-task)
    (, (cleanup $fact))
    (O
        (- (cleanup $fact))
        ))




























