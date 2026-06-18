; ((compute-support $pattern -> $out) 
;      $pattern
;      (O 
;        ( count ($out $pattern $sup) $sup  $pattern)))


; (exec 5 (, (block-im $block $im ) ((compute-support $im -> support-of) $src $sink) ) 
;         (exec 6 $src $sink)
; )


; (exec 0
;   (, (Inheritance $x man) (Inheritance $x sodaDrinker) (Inheritance $x ugly))
;   (, (yes))

;   )
; (exec 1 
;       (, (yes))
;       (, (pattern (, (Inheritance $x $y) (Inheritance $y sodaDrinker) (Inheritance $z ugly)))))


; (exec 2
;       (,(pattern $pattern) $pattern )
;       (, (yes-again))
;     )


;  (Inheritance Allen sodaDrinker)
;  (Inheritance Lily sodaDrinker)
;  (Inheritance Cason sodaDrinker)

;  (Inheritance Lily ugly)
;  (Inheritance Allen ugly)
;  (Inheritance Cason ugly)


;  (Inheritance Allen man)
;  (Inheritance Cason man)


; (DEF gv-expand
;   (, (gv-visit $id $path $node))
;   (O
;     (- (gv-visit $id $path $node))
;     (pure (gv-var-check $id $path $node $is-var) $is-var
;       (i8_to_string (is_var (' $node))))

;     (+ (exec (GV 3 0 record)
;          (, (gv-var-check $record-id $record-path $var-node 1))
;          (O
;            (- (gv-var-check $record-id $record-path $var-node 1))
;            (+ (get-vars-for-tree-result $record-id $record-path $var-node)))))

;     (+ (exec (GV 3 1 split-pair)
;          (, (gv-var-check $split-id $split-path ($a $b) 0)
;             (DEF gv-expand $expand-p $expand-t))
;          (O
;            (- (gv-var-check $split-id $split-path ($a $b) 0))
;            (+ (gv-visit $split-id ($split-path arg/0) $a))
;            (+ (gv-visit $split-id ($split-path arg/1) $b))
;            (+ (exec (GV 2) $expand-p $expand-t)))))

;     (+ (exec (GV 3 1 split-triplet)
;          (, (gv-var-check $split-id $split-path ($a $b $c) 0)
;             (DEF gv-expand $expand-p $expand-t))
;          (O
;            (- (gv-var-check $split-id $split-path ($a $b $c) 0))
;            (+ (gv-visit $split-id ($split-path arg/0) $a))
;            (+ (gv-visit $split-id ($split-path arg/1) $b))
;            (+ (gv-visit $split-id ($split-path arg/2) $c))
;            (+ (exec (GV 2) $expand-p $expand-t)))))
;   )
; )



;  (get-vars-for-tree-result sample ((root arg/2) arg/1) (var 0))
; (get-vars-for-tree-result sample ((root arg/2) arg/2) (var 1))
; (get-vars-for-tree-result sample (root arg/1) (var 0))



(INPUT PATTERN ((, (Inheritance $x sodaDrinker) (Inheritance $x man) (Inheritance $x ugly)) 4))

(exec 0 (, (INPUT PATTERN ($pattern $support))) 
(O (pure (partition-of $pattern $partition) $partition  (partitions  (cdr-atom ('  $pattern))))))

(partition-of (, (Inheritance $a sodaDrinker) (Inheritance $a man) (Inheritance $a ugly)) 
    ((((Inheritance $b sodaDrinker) (Inheritance $b man)) ((Inheritance $b ugly))) (((Inheritance $b sodaDrinker) (Inheritance $b ugly)) ((Inheritance $b man))) (((Inheritance $b sodaDrinker)) ((Inheritance $b man) (Inheritance $b ugly))) (((Inheritance $b sodaDrinker)) ((Inheritance $b man)) ((Inheritance $b ugly)))))