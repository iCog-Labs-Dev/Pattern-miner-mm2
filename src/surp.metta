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

(exec (surp 101 start-surp)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (indexed-pattern ($indexed-copy $support))
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))
    )
)


(exec (surp 102 start-surp)
    (, 
       (indexed-pattern ($indexed-pattern $support))
       ((count-conjuncts $indexed-pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
       ((total-counts $db-name $indexed-pattern -> total-count-of) $src-of-tc $sink-of-tc)
       ((prob $indexed-pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))
    (O
        (+ (exec (surp 102 count-db) $src-of-count $sink-of-count))
        (+ (exec (surp 102 count-conjuncts) $src-of-cnj $sink-of-cnj))
        (+ (exec (surp 103 total-counts) $src-of-tc $sink-of-tc))
        (+ (exec (surp 104 prob) $src-of-prob $sink-of-prob))))



(exec (surp 105 partitions-of)
    (, (indexed-pattern ($indexed-pattern $support)))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))
))



(exec (surp 106 extract-partiton)
    (, (partitions-of $indexed-pattern $indexed-partitions) (exec (surp 106 extract-partiton) $src (O (pure $out $var (car $q)))))
    (O
        (pure
            (exec (surp 106 extract-partiton) (,)
                (, (exec (surp 106 extract-partiton) $src (O (pure $out $var (car (cdr $q))))) (partition $indexed-partitions $partition)))            
            $partition
            (car (' $indexed-partitions))
        )
    )
)

;; Expanding partitions into blocks.
(exec (surp 108 extract-blocks)
    (, (partition $indexed-partitions $partition) (exec (surp 108 extract-blocks) $src (O (pure $out $var (car $q)))))
    (O
        (pure
            (exec (surp 108 extract-blocks)(,)
                (, (exec (surp 108 extract-blocks) $src (O (pure $out $var (car (cdr $q))))) (block $partition $block)))            
            $block
            (car (' $partition))
        )
    )
)

;; Convert each indexed block back to a real variable pattern and count its support.
(exec (surp 109 block-support-query)
    (, (block $partition $indexed-block))
    (O
        (pure
            (block-support-query $indexed-block $query)
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))))

(exec (surp 110 block-support)
    (, (block-support-query $indexed-block $query))
    (, 
        (exec (surp 110 block-support)
            $query
            (O
                (count
                    (block-support $indexed-block $support)
                    $support
                    $query
                )
            )
        )
    )
)

;; Convert block support into block probability using the full pattern total count.
(exec (surp 111 block-prob)
    (, (partitions-of $indexed-pattern $indexed-partitions)
       (total-count-of $indexed-pattern $total-count)
       (partition $indexed-partitions $indexed-partition)
       (block $indexed-partition $indexed-block)
       (block-support $indexed-block $support))
    (O
        (pure
            (block-prob $indexed-pattern $indexed-block $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $total-count))))))

;; Current partition shapes have either two or three blocks.

(exec (surp 110 partition-product)
    (, (partition $indexed-partitions $indexed-partition))
    (, (partition-product $indexed-partition 1))
)

(exec (surp 112 partition-product)
    (, (partitions-of $indexed-pattern $indexed-partitions) (partition $indexed-partitions $indexed-partition)
        (exec (surp 112 partition-product) $src (O (pure $out $var (car $q))))
    )
    (O
        (pure
            (exec (surp 112 partition-product)
                (, (block-prob $indexed-pattern $block $prob) (partition-product $indexed-partition $product))
                (O
                    (pure
                        (partition-product $indexed-partition $new-product)
                        $new-product
                        (f64_to_string (product_f64 (f64_from_string $prob) (f64_from_string $product)))
                    )
                    (- (partition-product $indexed-partition $product))
                    (+ (exec (surp 112 partition-product) $src (O (pure $out $var (car (cdr $q))))))
                )
            )
            $block
            (car (' $indexed-partition))
        )
    )
)


;; Take [min, max] over the current three-conjunct partition products.
(exec (surp 113 partition-product-range)
    (, (partitions-of $indexed-pattern $indexed-partitions) 
        (partition $indexed-partitions $indexed-partition) 
        (partition-product $indexed-partition $product))
    (O
        (fmax 
            (max-partition-product $indexed-pattern $max)
            $max
            $product
        )
        (fmin
            (min-partition-product $indexed-pattern $min)
            $min
            $product
        )
    )
)


(exec (surp 114 partition-product-range)
    (, (max-partition-product $indexed-pattern $max)
       (min-partition-product $indexed-pattern $min))
    (, (partition-product-range $indexed-pattern $min $max)))

(exec (surp 115 dst-request)
    (, (partition-product-range $indexed-pattern $emin $emax)
       (prob-of $indexed-pattern $emp)
       ((dst-from-interval $indexed-pattern $emin $emax $emp -> dst-of) $src $sink))
    (,
        (dst-request $indexed-pattern $emin $emax $emp dst-of)
        (exec (surp 115 dst-from-interval) $src $sink)))


;; emp > emax: distance = emp - emax.
(exec (surp 116 dst-above?)
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
(exec (surp 117 dst-below?)
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
(exec (surp 118 dst-inside?)
    (, (dst-inside? $pattern $emin $emax $emp $out true))
    (O
        (+ ($out $pattern 0.0))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-inside? $pattern $emin $emax $emp $out true))))


;; If normalization is enabled, surprisingness = min(dst / max(emax, empirical probability), 1.0).
(exec (surp 119 if-normalization) 
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (prob-of $pattern $prob)
       (partition-product-range $pattern $emin $emax))
    (O
        (pure
            (normalization-denom $pattern $dst $denom)
            $denom
            (max-atom (' ($emax $prob))))))

(exec (surp 120 normalization-candidate)
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


(exec (surp 121 surprisingess)
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
(exec (surp 122 false-normalization)
    (, (INPUT NORMALIZATION FALSE)
       (dst-of $pattern $dst))
    (O
        (+ (surprisingess-of $pattern $dst))
        (- (dst-of $pattern $dst))))

(exec (surp 123 surprisingess)
    (, (surprisingess-of $indexed-pattern $value))
    (O
        (pure
            (surprisingess-of $pattern $value)
            $pattern
            (cons , (indices_to_vars (' $indexed-pattern))))
        (- (surprisingess-of $indexed-pattern $value))
    )
)





;; Final cleanup: 
(exec (surp 990 cleanup)
    (, (surprisingess-of $pattern $value))
    (,
        (cleanup (block $partition $block))
        (cleanup (partitions-of $pattern $partitions))
        (cleanup (partition $partitions $partition))
        (cleanup (block-support $block $support))
        (cleanup (block-support-query $block $query))
        (cleanup (block-prob $partition $block $prob))
        (cleanup (partition-product $partition $product))
        (cleanup (min-partition-product $pattern $min))
        (cleanup (max-partition-product $pattern $max))
        (cleanup (partition-product-range $pattern $min $max))
        (cleanup (dst-above? $p $emin $emax $emp $out $above))
        (cleanup (dst-below? $p $emin $emax $emp $out $below))
        (cleanup (dst-inside? $p $emin $emax $emp $out $inside))
        (cleanup (dst-request $p $emin $emax $emp $out))))


;; One cleanup matcher removes any fact selected by the cleanup task.
(exec (surp 991 cleanup)
    (, (cleanup $fact) $fact)
    (O
        (- (cleanup $fact))
        (- $fact)
        ))

;; Remove the generic cleanup tasks after they are no longer useful.
(exec (surp 992 cleanup)
    (, (cleanup $fact))
    (O
        (- (cleanup $fact))
        ))