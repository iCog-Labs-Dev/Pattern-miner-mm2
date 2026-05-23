
;; High-Level Flow
; pattern
;  -> count support
;  -> compute actual probability
;  -> generate partitions of conjuncts
;  -> estimate probability of each partition by multiplying block probabilities
;  -> take [min, max]
;  -> distance(actual, [min, max])
;  -> optional normalization


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


;; Pattern facts
(pattern p1 (, (Inheritance $x sodaDrinker) (Inheritance $x ugly)))

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

; ;;count-db usage
; (exec 0 (, ((count-db db -> db-size ) $p $t))
;        (, (exec 0 $p $t)))



;; Count conjuncts in apattern.
((count-conjuncts  $pattern -> $out ) 
    (, (pattern $pattern-id $pattern))
    (O
          (pure ($out $pattern-id $count) $count (i64_to_string (length (' (cdr (' $pattern))))))
      
    )
)

; ;; count-conjuncts usage
; (exec 0 (, ((count-conjuncts (, (Inheritance $x sodaDrinker) (Inheritance $x ugly)) -> num-of-conjuncts) $p $t))
;          (, (exec 0 $p $t)))


;; How many ways can we choose k items from n items, without caring about order.
;; total-counts(pattern, db) = db_size! / (num_conjuncts! * (db_size - num_conjuncts)!)
;; C(n, k) = falling_factorial(n, k) / k!

((total-counts $db $pattern-id  -> $out)
    (, ($db-size-fact $db $n) ($num-conjuncts-fact $pattern-id $k))
    (O
        (pure
           ($out $pattern-id $db $total)
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


        (+ )
    )
)




((total-counts $db $pattern-id  -> $out)
    (,  ((count-db $db -> db-size ) $p $t)  ((count-conjuncts $pattern-id -> num-of-conjuncts) $p $t))
    (, (exec 0 $p 
                 (, $t 
                     (exec 0 ))))
    
)

(db2 db 100000 )
(num-of-conjuncts p1 3)
;; total-counts usage
(exec 0 (, ((total-counts db p1 -> total-counts-of) $p $t))
        (, (exec 0 $p $t)))











