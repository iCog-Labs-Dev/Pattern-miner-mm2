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

(exec 1
    (, (INPUT DB $db-name)
       (INPUT PATTERN ($pattern $support))
       ((count-db $db-name -> db-size) $src-of-count $sink-of-count)
       ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
       ((total-counts $db-name $pattern -> total-count-of) $src-of-tc $sink-of-tc)
       ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))
    (O
        (+ (exec 0 $src-of-count $sink-of-count))
        (+ (exec 0 $src-of-cnj $sink-of-cnj))
        (+ (exec 1 $src-of-tc $sink-of-tc))
        (+ (exec 2 $src-of-prob $sink-of-prob))
        (pure
            (indexed-pattern $indexed-copy)
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))))

(exec 2
    (, (indexed-pattern $indexed-pattern))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))



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

;; Copy partitions before expanding them into blocks.
(exec 4
    (, (partition $partition))
    (, (copy-of-partition $partition $partition)))

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

;; Send every indexed block through the shared support-cache gate. The partition
;; is result context only; repeated blocks across partitions share one count.
(exec 6
    (, (block $partition $indexed-block)
       (INPUT SUPPORT-MODE $support-mode)
       ((support-gate
          $support-mode
          (surp-block-support-request $partition $indexed-block)
          $partition
          $indexed-block
          7
          8
          9
          -> block-support)
        $gate-p $gate-t))
    (O
        (+ (surp-block-support-request $partition $indexed-block))
        (+ (exec 6 $gate-p $gate-t))))

;; Convert block support into block probability using the full pattern total count.
(exec 10
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
(exec 11
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

(exec 11
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
(exec 12
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

(exec 13
    (, (min-partition-product $min)
       (max-partition-product $max))
    (, (partition-product-range $min $max)))

(exec 14
    (, (partition-product-range $emin $emax)
       (prob-of $pattern $emp)
       ((dst-from-interval $pattern $emin $emax $emp -> dst-of) $src $sink))
    (,
        (dst-request $pattern $emin $emax $emp dst-of)
        (exec 14 $src $sink)))

;; emp > emax: distance = emp - emax.
(exec 15
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
(exec 15
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
(exec 15
    (, (dst-inside? $pattern $emin $emax $emp $out true))
    (O
        (+ ($out $pattern 0.0))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-inside? $pattern $emin $emax $emp $out true))))


;; If normalization is enabled, surprisingness = min(dst / max(emax, empirical probability), 1.0).
(exec 16
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (prob-of $pattern $prob)
       (partition-product-range $emin $emax))
    (O
        (pure
            (normalization-denom $pattern $dst $denom)
            $denom
            (max-atom (' ($emax $prob))))))

(exec 17
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

(exec 18
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
(exec 19
    (, (INPUT NORMALIZATION FALSE)
       (dst-of $pattern $dst))
    (O
        (+ (surprisingess-of $pattern $dst))
        (- (dst-of $pattern $dst))))






;; Final cleanup: 
(exec 20
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
(exec 21
    (, (cleanup $fact) $fact)
    (O
        (- (cleanup $fact))
        (- $fact)
        ))

;; Remove the generic cleanup tasks after they are no longer useful.
(exec 22
    (, (cleanup $fact))
    (O
        (- (cleanup $fact))
        ))



























