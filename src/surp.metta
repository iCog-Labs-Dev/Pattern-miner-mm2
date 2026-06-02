
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
          (pure ($out $pattern $count) $count (i64_to_string (length (' (cdr (' $pattern))))))
      
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





(exec (Z)
    (, (INPUT DB $db-name) (INPUT PATTERN ($pattern $support) )  
        ((count-db $db-name -> db-size ) $src-of-count $sink-of-count)  
         ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
         ((total-counts $db-name $pattern  -> total-count-of) $src-of-tc $sink-of-tc)
         ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))

    (O (+ (exec 0 $src-of-count $sink-of-count) )
        (+ (exec 0 $src-of-cnj $sink-of-cnj))
        (+ (exec 1 $src-of-tc $sink-of-tc))
        (+ (exec 2 $src-of-prob $sink-of-prob))
        (pure (partition-of $pattern $partition) $partition  (partitions  (cdr ('  $pattern)))) 
    )
)



(exec  (S Z)
    (, (partition-of $pattern $partition)  (exec (S Z) $src $sink))
    (O 
        
        (pure (block-of-partition $car) $car (car (' $partition)))
        (pure (partition-of $pattern $cdr) $cdr (cdr (' $partition)))
        (-  (partition-of $pattern $partition))
        (+ (exec (S Z) $src $sink))
        (+ (exec (Z)  (, (partition-of $pattern ()) (exec (S Z) $src $sink))
                    (O (- (exec (S Z) $src $sink)))))
 
 ))



; (exec (STEP2)
;     (, (INPUT PATTERN ($pattern $support)) (partition-of $pattern $partition))
;     (O
;         (pure
;             ($out $pattern $partition $est-prob)
;             $est-prob
;             (mul_f64_list (map (fn ($p) (block-probability $p))) $partition))
;     )
; )


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







