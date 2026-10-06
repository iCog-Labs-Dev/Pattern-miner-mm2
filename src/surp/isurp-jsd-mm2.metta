;; 
;; isurp-jsd-mm2.metta
;; 
;; Bernoulli Jensen-Shannon Divergence (JSD) & Metric Square Root sqrt(JSD)
;;
;; MATHEMATICAL DEFINITION:
;; Given empirical probability P = Bernoulli(p) and expectation boundary Q = Bernoulli(q):
;;   Mixture M = (P + Q) / 2 = Bernoulli(m) where m = (p + q) / 2
;;
;;   Bernoulli KL Divergence:
;;     D_Ber(X || Y) = X * log2(X / Y) + (1 - X) * log2((1 - X) / (1 - Y))
;;
;;   Bernoulli JSD:
;;     JSD_Ber(P || Q) = 0.5 * D_Ber(P || M) + 0.5 * D_Ber(Q || M)
;;
;;   Metric Jensen-Shannon Distance:
;;     JSD_Distance = sqrt(JSD_Ber(P || Q))
;;
;; JSD is symmetric, bounded in [0, 1], and its square root sqrt(JSD) satisfies
;; all metric space properties (including triangle inequality).

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


;; Generate partition list from indexed $ctx
(exec 5
    (, (isurp-old-pattern $ctx $pattern $support)
       (isurp-total-count-of $ctx $pattern $total))
    (O
        (pure
            (isurp-partitions $ctx $total $p)
            $p
            (partitions (' $ctx)))))


;; Extract all partitions
(exec 5.1
    (, (isurp-partitions $ctx $total ($p1 $p2 $p3 $p4)))
    (O
        (+ (isurp-partition $ctx $total $p1))
        (+ (isurp-partition $ctx $total $p2))
        (+ (isurp-partition $ctx $total $p3))
        (+ (isurp-partition $ctx $total $p4))))

(exec 5.2
    (, (isurp-partition $ctx $total ($b1 $b2)))
    (O
        (+ (isurp-partition-block $ctx $total ($b1 $b2) $b1))
        (+ (isurp-partition-block $ctx $total ($b1 $b2) $b2))))

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


(exec 6.1
    (, (isurp-partition-block $ctx $total $part $block)
       (isurp-clause-support $block $support))
    (O
        (+ (isurp-block-support $ctx $total $part $block $support))))


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


;; Collect partition bounds into [E_min, E_max]
(exec 9.1
    (, (isurp-partition-prob $ctx $pid $prob))
    (O
        (fmin (isurp-emin $ctx $emin) $emin $prob)
        (fmax (isurp-emax $ctx $emax) $emax $prob)))


(exec 10.1
    (, (isurp-emin $ctx $emin)
       (isurp-emax $ctx $emax))
    (, (isurp-interval $ctx $emin $emax)))


;; 
;; Bernoulli Jensen-Shannon Divergence & Metric Computation
;; 

;; Determine region relative to interval
(exec 11.1
    (, (isurp-pattern-prob $ctx $p)
       (isurp-interval $ctx $emin $emax))
    (O
        (pure
            (isurp-jsd-above? $ctx $above)
            $above
            (gt_f64 (f64_from_string $p) (f64_from_string $emax)))
        (pure
            (isurp-jsd-below? $ctx $below)
            $below
            (lt_f64 (f64_from_string $p) (f64_from_string $emin)))
        (pure
            (isurp-jsd-inside? $ctx $inside)
            $inside
            (and_bool
                (le_f64 (f64_from_string $emin) (f64_from_string $p))
                (le_f64 (f64_from_string $p) (f64_from_string $emax))))
        (pure
            (isurp-jsd-p-zero? $ctx $is-zero)
            $is-zero
            (eq_f64 (f64_from_string $p) (f64_from_string 0.0)))
        (pure
            (isurp-jsd-p-one? $ctx $is-one)
            $is-one
            (eq_f64 (f64_from_string $p) (f64_from_string 1.0)))))


;; Select target boundary q
(exec 11.2
    (, (isurp-jsd-above? $ctx true)
       (isurp-interval $ctx $emin $emax))
    (, (isurp-jsd-q $ctx $emax)))

(exec 11.2
    (, (isurp-jsd-below? $ctx true)
       (isurp-interval $ctx $emin $emax))
    (, (isurp-jsd-q $ctx $emin)))


;; Compute mixture distribution m = (p + q) / 2
(exec 11.3
    (, (isurp-pattern-prob $ctx $p)
       (isurp-jsd-q $ctx $q))
    (O
        (pure
            (isurp-jsd-m $ctx $m)
            $m
            (f64_to_string
                (div_f64
                    (sum_f64 (f64_from_string $p) (f64_from_string $q))
                    (f64_from_string 2.0))))))


;; Compute D_Ber(p || m) for interior 0 < p < 1
(exec 11.4
    (, (isurp-pattern-prob $ctx $p)
       (isurp-jsd-m $ctx $m)
       (isurp-jsd-p-zero? $ctx false)
       (isurp-jsd-p-one? $ctx false))
    (O
        (pure
            (isurp-jsd-dpm $ctx $dpm)
            $dpm
            (f64_to_string
                (sum_f64
                    (product_f64
                        (f64_from_string $p)
                        (log2_f64 (div_f64 (f64_from_string $p) (f64_from_string $m))))
                    (product_f64
                        (sub_f64 (f64_from_string 1.0) (f64_from_string $p))
                        (log2_f64
                            (div_f64
                                (sub_f64 (f64_from_string 1.0) (f64_from_string $p))
                                (sub_f64 (f64_from_string 1.0) (f64_from_string $m))))))))))

;; Compute D_Ber(p || m) for p = 0 (below interval)
(exec 11.41
    (, (isurp-jsd-m $ctx $m)
       (isurp-jsd-below? $ctx true)
       (isurp-jsd-p-zero? $ctx true))
    (O
        (pure
            (isurp-jsd-dpm $ctx $dpm)
            $dpm
            (f64_to_string
                (log2_f64
                    (div_f64
                        (f64_from_string 1.0)
                        (sub_f64 (f64_from_string 1.0) (f64_from_string $m))))))))

;; Compute D_Ber(p || m) for p = 1 (above interval)
(exec 11.42
    (, (isurp-jsd-m $ctx $m)
       (isurp-jsd-above? $ctx true)
       (isurp-jsd-p-one? $ctx true))
    (O
        (pure
            (isurp-jsd-dpm $ctx $dpm)
            $dpm
            (f64_to_string
                (log2_f64 (div_f64 (f64_from_string 1.0) (f64_from_string $m)))))))


;; Compute D_Ber(q || m)
(exec 11.5
    (, (isurp-jsd-q $ctx $q)
       (isurp-jsd-m $ctx $m))
    (O
        (pure
            (isurp-jsd-dqm $ctx $dqm)
            $dqm
            (f64_to_string
                (sum_f64
                    (product_f64
                        (f64_from_string $q)
                        (log2_f64 (div_f64 (f64_from_string $q) (f64_from_string $m))))
                    (product_f64
                        (sub_f64 (f64_from_string 1.0) (f64_from_string $q))
                        (log2_f64
                            (div_f64
                                (sub_f64 (f64_from_string 1.0) (f64_from_string $q))
                                (sub_f64 (f64_from_string 1.0) (f64_from_string $m))))))))))


;; Combine into JSD_Ber = 0.5 * D_Ber(p || m) + 0.5 * D_Ber(q || m)
;; and take metric square root sqrt(JSD_Ber)
(exec 11.6
    (, (isurp-jsd-dpm $ctx $dpm)
       (isurp-jsd-dqm $ctx $dqm))
    (O
        (pure
            (isurp-jsd-divergence $ctx $jsd)
            $jsd
            (f64_to_string
                (product_f64
                    (f64_from_string 0.5)
                    (sum_f64 (f64_from_string $dpm) (f64_from_string $dqm)))))
        (pure
            (isurp-jsd-metric $ctx $jsd-sqrt)
            $jsd-sqrt
            (f64_to_string
                (sqrt_f64
                    (max_f64
                        (product_f64
                            (f64_from_string 0.5)
                            (sum_f64 (f64_from_string $dpm) (f64_from_string $dqm)))
                        (f64_from_string 0.0)))))))


;; Inside interval: JSD = 0.0, metric = 0.0
(exec 11.7
    (, (isurp-jsd-inside? $ctx true))
    (O
        (pure
            (isurp-jsd-divergence $ctx $zero)
            $zero
            (f64_to_string (f64_from_string 0.0)))
        (pure
            (isurp-jsd-metric $ctx $zero)
            $zero
            (f64_to_string (f64_from_string 0.0)))))


;; Output Emission
;; 
(exec 12.1
    (, (INPUT NORMALIZATION True)
       (isurp-old-pattern $ctx $pattern $support)
       (isurp-jsd-metric $ctx $jsd-sqrt))
    (O
        (pure
            (OUTPUT ISURP-RESULT ($ctx $score))
            $score
            $jsd-sqrt)
        (pure
            (isurp-jsd-of $pattern $score)
            $score
            $jsd-sqrt)
        (pure
            (isurp-jsd-of $ctx $pattern $score)
            $score
            $jsd-sqrt)))
