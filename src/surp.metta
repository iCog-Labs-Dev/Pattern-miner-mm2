
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
          (count ($out $db-name $count) $count $fact)
     )
)

;; Count conjuncts in apattern.
((count-conjuncts  $pattern -> $out ) 
    (, (INPUT PATTERN ($pattern $support)))
    (O
          (pure ($out $pattern $count) $count (size-atom (cdr-atom (' $pattern))))
      
    )
)

;; How many ways can we choose k items from n items, without caring about order.
;; total-counts(pattern, db) = db_size! / (num_conjuncts! * (db_size - num_conjuncts)!)
;; C(n, k) = falling_factorial(n, k) / k!

((total-counts $db $pattern  -> $out)
    (, (db-size $db $n) (num-of-conjuncts $pattern $k))
    (O
        (pure
           (total-count-of $pattern  $total)
            $total
        (i64_to_string
            (div_i64
               (falling_factorial
                   (i64_from_string $n)
                   (i64_from_string $k)
              )
           (factorial (i64_from_string $k))
           )
        )
        )

    )
)

;; Compute the probability of a pattern by dividing the support of the pattern by the total counts.
((prob $pattern $db -> $out)
      (, (INPUT PATTERN ($pattern $support)) (total-count-of $pattern $count))
      (O
          (pure
              ($out $pattern $prob)
              $prob
              (f64_to_string 
               (div_f64 
                    (f64_from_string $support) 
                    (f64_from_string $count)))
          )
      ))





(exec 1
    (, (INPUT DB $db-name) (INPUT PATTERN ($pattern $support) )  
        ((count-db $db-name -> db-size ) $src-of-count $sink-of-count)  
         ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
         ((total-counts $db-name $pattern  -> total-count-of) $src-of-tc $sink-of-tc)
         ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))

    (O (+ (exec 0 $src-of-count $sink-of-count) )
        (+ (exec 0 $src-of-cnj $sink-of-cnj))
        (+ (exec 1 $src-of-tc $sink-of-tc))
        (+ (exec 2 $src-of-prob $sink-of-prob))
        (pure
            (indexed-pattern $indexed-copy)
            $indexed-copy
            (vars_to_indices (cdr-atom (' $pattern))))
    )
)

(exec 2
    (, (indexed-pattern $indexed-pattern))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))



(exec  3
    (, (partitions-of $indexed-pattern $indexed-partition)  (exec 3 $src $sink))
    (O 
        
        (pure (partition $car) $car (car-atom (' $indexed-partition)))
        (pure (partitions-of $indexed-pattern $cdr) $cdr (cdr-atom (' $indexed-partition)))
        (-  (partitions-of $indexed-pattern $indexed-partition))
        (+ (exec 3 $src $sink))
 ))

;; compute support of the component
;; copy blocks
(exec 4 (, (partition $partition) )
              (, (copy-of-partition $partition $partition )))

(exec 5 (, (copy-of-partition $partition $partition-copy )  (exec 5 $src $sink))
    (O 
        (pure (block $partition $block) $block (car-atom (' $partition-copy)))
        (pure (copy-of-partition $partition $cdr) $cdr (cdr-atom (' $partition-copy)))
        (- (copy-of-partition $partition $partition-copy))
        (+ (exec 5 $src $sink))
     )
)

;; Convert each indexed block back to a real variable pattern and count its support.
(exec 6
    (, (block $partition $indexed-block))
    (O
        (pure
            (exec 6
                $query
                (O (count (block-support $partition $indexed-block $support) $support $query)))
            $query
            (indices_to_vars (cons , (' $indexed-block))))))

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









(INPUT DB db)
(INPUT PATTERN ((, (Inheritance $x sodaDrinker) (Inheritance $x ugly) (Inheritance $x man)) 4))











;; DB facts
(db (Inheritance Allen sodaDrinker))
(db (Inheritance Lily sodaDrinker))
(db (Inheritance Cason sodaDrinker))

(db (Inheritance Lily ugly))
(db (Inheritance Allen ugly))
(db (Inheritance Abe ugly))

(db (Inheritance Lily man))
(db (Inheritance Allen man))
(db (Inheritance cason man))


 (Inheritance Allen sodaDrinker)
 (Inheritance Lily sodaDrinker)
 (Inheritance Cason sodaDrinker)

 (Inheritance Lily ugly)
 (Inheritance Allen ugly)
 (Inheritance Abe ugly)

 (Inheritance Lily man)
 (Inheritance Allen man)
 (Inheritance cason man)


; (block-of-partition (((Inheritance $a sodaDrinker)) ((Inheritance $b ugly) (Inheritance $b man))))
; (block-of-partition (((Inheritance $a sodaDrinker) (Inheritance $b man)) ((Inheritance $b ugly))))
; (block-of-partition (((Inheritance $a sodaDrinker) (Inheritance $b ugly)) ((Inheritance $b man))))
; (block-of-partition (((Inheritance $a sodaDrinker)) ((Inheritance $b ugly)) ((Inheritance $b man))))
