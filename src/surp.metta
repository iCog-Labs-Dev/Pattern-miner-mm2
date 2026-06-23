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
;; Function definitions
;;===============================================================

;; Count all db facts in the main db.
((count-db $db-name -> $out)
    (, ($db-name $fact))
    (O
        (count ($out $db-name $count) $count $fact)))

;; Count conjuncts in a pattern.
((count-conjuncts $pattern -> $out)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            ($out $pattern $count)
            $count
            (size-atom
                (cdr-atom (' $pattern))))))

;; How many ways can we choose k items from n items, without caring about order.
;; total-counts(pattern, db) = db_size! / (num_conjuncts! * (db_size - num_conjuncts)!)
;; C(n, k) = falling_factorial(n, k) / k!
((total-counts $db $pattern -> $out)
    (, (db-size $db $n)
       (num-of-conjuncts $pattern $k))
    (O
        (pure
            (total-count-of $pattern $total)
            $total
            (i64_to_string
                (div_i64
                    (falling_factorial
                        (i64_from_string $n)
                        (i64_from_string $k))
                    (factorial
                        (i64_from_string $k)))))))

;; Compute the probability of a pattern by dividing the support by total counts.
((prob $pattern $db -> $out)
    (, (INPUT PATTERN ($pattern $support))
       (total-count-of $pattern $count))
    (O
        (pure
            ($out $pattern $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $count))))))

;; Distance from an empirical value to an interval [emin, emax].
;; Cases are materialized as facts so the three execs below stay easy to read.
((dst-from-interval $pattern $emin $emax $emp -> $out)
    (, (dst-request $pattern $emin $emax $emp $out))
    (O
        (pure
            (dst-above? $pattern $emin $emax $emp $out $above)
            $above
            (gt_f64
                (f64_from_string $emp)
                (f64_from_string $emax)))
        (pure
            (dst-below? $pattern $emin $emax $emp $out $below)
            $below
            (lt_f64
                (f64_from_string $emp)
                (f64_from_string $emin)))
        (pure
            (dst-inside? $pattern $emin $emax $emp $out $inside)
            $inside
            (and_bool
                (le_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))
                (le_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))))


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

;; Convert each indexed block back to a real variable pattern and count its support.
(exec 6
    (, (block $partition $indexed-block))
    (O
        (pure
            (exec 6
                $query
                (O
                    (count
                        (block-support $partition $indexed-block $support)
                        $support
                        $query)))
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))))

;; Convert block support into block probability: support / db-size.
(exec 7
    (, (INPUT DB $db-name)
       (db-size $db-name $db-size)
       (block-support $partition $indexed-block $support))
    (O
        (pure
            (block-prob $partition $indexed-block $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $db-size))))))

;; Current partition shapes have either two or three blocks.
(exec 8
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

(exec 8
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
(exec 9
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

(exec 10
    (, (min-partition-product $min)
       (max-partition-product $max))
    (, (partition-product-range $min $max)))

(exec 11
    (, (partition-product-range $emin $emax)
       (prob-of $pattern $emp)
       ((dst-from-interval $pattern $emin $emax $emp -> dst-of) $src $sink))
    (,
        (dst-request $pattern $emin $emax $emp dst-of)
        (exec 11 $src $sink)))

;; emp > emax: distance = emp - emax.
(exec 12
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
(exec 12
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
(exec 12
    (, (dst-inside? $pattern $emin $emax $emp $out true))
    (O
        (+ ($out $pattern 0.0))
        (- (dst-request $pattern $emin $emax $emp $out))
        (- (dst-inside? $pattern $emin $emax $emp $out true))))

;; If normalization is enabled, surprisingness = distance / empirical probability.
(exec 13
    (, (INPUT NORMALIZATION TRUE)
       (dst-of $pattern $dst)
       (prob-of $pattern $prob))
    (O
        (pure
            (surprisingess-of $pattern $value)
            $value
            (f64_to_string
                (div_f64
                    (f64_from_string $dst)
                    (f64_from_string $prob))))
        (- (dst-of $pattern $dst))))

;; Otherwise, surprisingness is just the distance from the interval.
(exec 14
    (, (dst-of $pattern $dst))
    (O
        (+ (surprisingess-of $pattern $dst))
        (- (dst-of $pattern $dst))))

;; Final cleanup: once surprisingness exists, create cleanup tasks for
;; intermediate mining facts. We intentionally keep db-size,
;; num-of-conjuncts, total-count-of, prob-of, and partitions-of.
(exec 15
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
(exec 16
    (, (cleanup $fact) $fact)
    (O
        (- (cleanup $fact))
        (- $fact)
        (+ (exec 16
            (, (cleanup $f) $f)
            (O
                (- (cleanup $f))
                (- $f))))))

;; Remove the generic cleanup tasks after they are no longer useful.
(exec 17
    (, (cleanup $fact))
    (O
        (- (cleanup $fact))
        (+ (exec 17
            (, (cleanup $f))
            (O
                (- (cleanup $f)))))))


;;;;;;;;;;;;;;;;;;;;;;;;
;; INPUTS AND DB FACTS;;
;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT NORMALIZATION FALSE)
(INPUT PATTERN ((, (Inheritance $x sodaDrinker) (Inheritance $x ugly) (Inheritance $x man)) 4))

;; DB facts used for db-size.
(db (Inheritance Allen sodaDrinker))
(db (Inheritance Lily sodaDrinker))
(db (Inheritance Cason sodaDrinker))

(db (Inheritance Lily ugly))
(db (Inheritance Allen ugly))
(db (Inheritance Abe ugly))

(db (Inheritance Lily man))
(db (Inheritance Allen man))
(db (Inheritance cason man))

;; Raw facts used by the dynamic support-count queries.
(Inheritance Allen sodaDrinker)
(Inheritance Lily sodaDrinker)
(Inheritance Cason sodaDrinker)

(Inheritance Lily ugly)
(Inheritance Allen ugly)
(Inheritance Abe ugly)

(Inheritance Lily man)
(Inheritance Allen man)
(Inheritance cason man)
