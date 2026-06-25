(DEF gv-expand
  (, (gv-visit $id $path $node))
  (O
    (- (gv-visit $id $path $node))
    (pure (gv-var-check $id $path $node $is-var) $is-var
      (i8_to_string (is_var (' $node))))

    (+ (exec (GV 3 0 record)
         (, (gv-var-check $record-id $record-path $var-node 1))
         (O
           (- (gv-var-check $record-id $record-path $var-node 1))
           (+ (get-vars-for-tree-result $record-id $record-path $var-node)))))

    (+ (exec (GV 3 1 split-pair)
         (, (gv-var-check $split-id $split-path ($a $b) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (exec (GV 2) $expand-p $expand-t)))))

    (+ (exec (GV 3 1 split-triplet)
         (, (gv-var-check $split-id $split-path ($a $b $c) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b $c) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (gv-visit $split-id ($split-path arg/2) $c))
           (+ (exec (GV 2) $expand-p $expand-t)))))
  )
)

; Reusable variable-extraction function.
;
; To call it from another miner stage, match/create:
;   (get-vars-for-tree $id $tree)
;   (DEF get-vars-for-tree-fn $gv-p $gv-t)
; then emit:
;   (+ (exec (GV 0 run-get-vars) $gv-p $gv-t))
(DEF get-vars-for-tree-fn
  (, (get-vars-for-tree $id $tree)
     (DEF gv-expand $expand-p $expand-t))
  (O
    (pure (gv-visit $id root $indexed-tree) $indexed-tree
      (vars_to_indices (' $tree)))
    (+ (exec (GV 2) $expand-p $expand-t)))
)

; Example call, kept inactive so this file can be loaded as a library:
; (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
; (exec (GV 0 call-example)
;   (, (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
;      (DEF get-vars-for-tree-fn $gv-p $gv-t))
;   (O (+ (exec (GV 0 run-get-vars) $gv-p $gv-t))))

; get-value-at-position
;
; Recursive positional lookup. It walks only the requested path:
;   root                      -> the whole expression
;   ($parent arg/0)           -> first child of value at $parent
;   ($parent arg/1)           -> second child of value at $parent
;   ($parent arg/2)           -> third child of value at $parent
;
; Request:
;   (get-value-at-position $id $expr $path)
;
; Result:
;   (get-value-at-position-result $id $path $value)
;
; Internal:
;   (gap-task $id $expr $path)
;   (gap-wait $id $path $parent $arg)
;   (gap-value $id $path $value)

(gap-arg-index arg/0 0)
(gap-arg-index arg/1 1)
(gap-arg-index arg/2 2)

(DEF get-value-at-position-select
  (, (gap-value $id $parent $parent-value))
  (O
    (+ (exec (GAP 3 select-by-index)
         (, (gap-wait $sel-id $path $parent $arg)
            (gap-value $sel-id $parent $parent-value)
            (gap-arg-index $arg $index)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-wait $sel-id $path $parent $arg))
           (pure (gap-value $sel-id $path $value) $value
             (index-atom $index (' $parent-value)))
           (+ (exec (GAP 0 select) $select-p $select-t)))))

    (+ (exec (GAP 9 result)
         (, (gap-value $result-id $result-path $result-value)
            (gap-target $result-id $result-path))
         (O
           (- (gap-target $result-id $result-path))
           (+ (get-value-at-position-result $result-id $result-path $result-value)))))
  )
)

(DEF get-value-at-position-step
  (, (gap-task $id $expr $path))
  (O
    (+ (exec (GAP 1 root)
         (, (gap-task $root-id $expr root)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-task $root-id $expr root))
           (+ (gap-value $root-id root $expr))
           (+ (exec (GAP 0 select) $select-p $select-t)))))

    (+ (exec (GAP 2 descend)
         (, (gap-task $desc-id $expr ($parent $arg))
            (DEF get-value-at-position-step $step-p $step-t))
         (O
           (- (gap-task $desc-id $expr ($parent $arg)))
           (+ (gap-wait $desc-id ($parent $arg) $parent $arg))
           (+ (gap-task $desc-id $expr $parent))
           (+ (exec (GAP 0 step) $step-p $step-t)))))
  )
)

; Reusable get-value-at-position function.
;
; To call it from another miner stage, match/create:
;   (get-value-at-position $id $expr $path)
;   (DEF get-value-at-position-fn $gap-p $gap-t)
; then emit:
;   (+ (exec (GAP 0 run-get-value-at-position) $gap-p $gap-t))
(DEF get-value-at-position-fn
  (, (get-value-at-position $id $expr $path)
     (DEF get-value-at-position-step $step-p $step-t))
  (O
    (+ (gap-target $id $path))
    (+ (gap-task $id $expr $path))
    (+ (exec (GAP 0 step) $step-p $step-t)))
)

; Example call, kept inactive:
; (get-value-at-position gap-example
;   (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;   (((root arg/2) arg/1) arg/0))
; (exec (GAP 0 call-example)
;   (, (get-value-at-position gap-example
;        (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;        (((root arg/2) arg/1) arg/0))
;      (DEF get-value-at-position-fn $gap-p $gap-t))
;   (O (+ (exec (GAP 0 run-get-value-at-position) $gap-p $gap-t))))

; valuation
;
; Valuation pipeline:
;   1. Extract variables and their paths from the pattern.
;   2. Match the pattern against a knowledge base.
;   3. For each satisfying expression and each variable path, get the value at
;      that path.
;   4. Emit variable bindings for the satisfying expression.
;
; Request:
;   (valuation $id $kb $pattern)
;
; Knowledge base facts:
;   (knowledge-base $kb $candidate-id $expr)
;
; Results:
;   (valuation-satisfying-set $id $candidate-id $candidate-expr)
;   (valuation-binding $id $candidate-id $path $var $value)

(DEF valuation-start
  (, (valuation $id $kb $pattern))
  (O
    (+ (get-vars-for-tree (VAL-VARS $id) $pattern))
    (+ (valuation-pattern $id $kb $pattern)))
)

(DEF valuation-match
  (, (valuation-pattern $id $kb $pattern)
     (knowledge-base $kb $candidate-id $pattern))
  (O
    (+ (valuation-satisfying-set $id $candidate-id $pattern))
  )
)

(DEF valuation-bind
  (, (valuation-satisfying-set $id $candidate-id $candidate-expr)
     (get-vars-for-tree-result (VAL-VARS $id) $path $var)
     (DEF get-value-at-position-fn $gap-p $gap-t))
  (O
    (+ (gap-valuation-binding (VAL-VALUE $id $candidate-id $path)
         $id
         $candidate-id
         $path
         $var))
    (+ (get-value-at-position (VAL-VALUE $id $candidate-id $path)
         $candidate-expr
         $path))
    (+ (exec (VAL 4 get-value) $gap-p $gap-t)))
)

(DEF valuation-binding-finish
  (, (gap-valuation-binding (VAL-VALUE $id $candidate-id $path)
       $id
       $candidate-id
       $path
       $var)
     (get-value-at-position-result (VAL-VALUE $id $candidate-id $path)
       $path
       $value))
  (O
    (- (gap-valuation-binding (VAL-VALUE $id $candidate-id $path)
         $id
         $candidate-id
         $path
         $var))
    (+ (valuation-binding $id $candidate-id $path $var $value))
    (+ (valuation-binding $id v $path $var $var)))
)

; Reusable valuation function.
;
; To call it from another miner stage, match/create:
;   (valuation $id $kb $pattern)
;   (knowledge-base $kb $candidate-id $candidate-expr)
;   (DEF valuation-fn $val-p $val-t)
; then emit:
;   (+ (exec (VAL 0 run-valuation) $val-p $val-t))
(DEF valuation-fn
  (, (valuation $id $kb $pattern)
     (DEF valuation-start $start-p $start-t)
     (DEF valuation-match $match-p $match-t)
     (DEF valuation-bind $bind-p $bind-t)
     (DEF valuation-binding-finish $finish-p $finish-t)
     (DEF get-vars-for-tree-fn $gv-p $gv-t))
  (O
    (+ (exec (VAL 0 start) $start-p $start-t))
    (+ (exec (VAL 1 get-vars) $gv-p $gv-t))
    (+ (exec (VAL 2 match) $match-p $match-t))
    (+ (exec (GV 9 0 valuation-bind-after-get-vars) $bind-p $bind-t))
    (+ (exec (GAP 9 0 valuation-finish-after-get-value) $finish-p $finish-t)))
)


