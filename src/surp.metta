
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
    (, (INPUT PATTERN $pattern))
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
           ($out $pattern  $total)
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



(exec (STEP1)
    (, (INPUT DB $db-name) (INPUT PATTERN $pattern) 
        ((count-db $db-name -> db-size ) $src-of-count $sink-of-count)  
         ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
         ((total-counts $db-name $pattern  -> total-count-of) $src-of-tc $sink-of-tc))

    (O (+ (exec 0 $src-of-count $sink-of-count) )
        (+ (exec 0 $src-of-cnj $sink-of-cnj))
        (+ (exec 1 $src-of-tc $sink-of-tc)))

)



(INPUT DB db)
(INPUT PATTERN (, (Inheritance $x sodaDrinker) (Inheritance $x ugly)))













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
