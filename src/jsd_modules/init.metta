(exec (jsd 001 start-jsd)
    (, (INPUT DB $db-name)
       (INPUT PATTERN ($pattern $support))
       ((count-db $db-name -> db-size) $src-of-count $sink-of-count)
       ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj))
    (O
        (+ (exec (jsd 102 count-db) $src-of-count $sink-of-count))
        (+ (exec (jsd 103 count-conjuncts) $src-of-cnj $sink-of-cnj))
        (pure
            (indexed-pattern $indexed-copy)
            $indexed-copy
            (vars_to_indices
                (cdr-atom (' $pattern))))))


(exec (jsd 005 partitions-of)
    (, (indexed-pattern $indexed-pattern))
    (O
        (pure
            (partitions-of $indexed-pattern $indexed-partition)
            $indexed-partition
            (partitions (' $indexed-pattern)))))


(exec (jsd 006 extract-partiton)
    (, (partitions-of $indexed-pattern $indexed-partitions)
       (exec (jsd 006 extract-partiton) $src (O (pure $out $var (car $ind-par)))))
    (O
        (pure
            (exec (jsd 006 extract-partiton)
                (,)
                (O (+ (partition $indexed-pattern $partition)) 
                    (+ (exec (jsd 006 extract-partiton) $src (O (pure $out $var (car (cdr $ind-par))))))
                )
            )
            
            $partition
            (car (' $indexed-partitions))
        )
        ))

;; Copy partitions before expanding them into blocks.
(exec (jsd 007 copy-partition)
    (, (partition $indexed-pattern $partition))
    (, (copy-of-partition $partition $partition)))

(exec (jsd 008 extract-blocks)
    (, (copy-of-partition $partition $partition-copy)
       (exec (jsd 008 extract-blocks) $src $sink))
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
        (+ (exec (jsd 008 extract-blocks) $src $sink))))


(exec (jsd 009 sup-num-query)
    (, (block $partition $block) ((sup-num-query $block (jsd 009 sup-num-query) $db) $src $sink) (INPUT DB $db))
    (, (exec (jsd 009 sup-num-query) $src $sink) (sup-num-query $block $db ()))
)

(exec (jsd 110 sup-num)
    (, (block $partition $block) (sup-num-query $block $db $q) (INPUT DB $db))
    (O
        (pure
            (exec (jsd 110 sup-num)
                $query
                (O
                    (count 
                        (support-of $block $db $sup)
                        $sup
                        ($query)
                    )
                )
            )
            $query
            (indices_to_vars (cons , (' $q)))
        )
    )
)