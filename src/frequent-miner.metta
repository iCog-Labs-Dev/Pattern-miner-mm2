(DEF gv-expand
  (, (gv-visit $id $path $node))
  (O
    (- (gv-visit $id $path $node))
    (pure (gv-var-check $id $path $node $is-var) $is-var
      (i8_to_string (is_var (' $node))))

    (+ (exec (freq 030 gv-record)
         (, (gv-var-check $record-id $record-path $var-node 1))
         (O
           (- (gv-var-check $record-id $record-path $var-node 1))
           (+ (get-vars-for-tree-result $record-id $record-path $var-node)))))

    (+ (exec (freq 031 gv-split-pair)
         (, (gv-var-check $split-id $split-path ($a $b) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (exec (freq 020 gv-expand) $expand-p $expand-t)))))

    (+ (exec (freq 032 gv-split-triplet)
         (, (gv-var-check $split-id $split-path ($a $b $c) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b $c) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (gv-visit $split-id ($split-path arg/2) $c))
           (+ (exec (freq 020 gv-expand) $expand-p $expand-t)))))

    (+ (exec (freq 039 gv-discard-non-var)
         (, (gv-var-check $discard-id $discard-path $node 0))
         (O
           (- (gv-var-check $discard-id $discard-path $node 0)))))
  )
)

; Reusable variable-extraction function.
;
; To call it from another miner stage, match/create:
;   (get-vars-for-tree $id $tree)
;   (DEF get-vars-for-tree-fn $gv-p $gv-t)
; then emit:
;   (+ (exec (freq 010 run-get-vars) $gv-p $gv-t))
(DEF get-vars-for-tree-fn
  (, (get-vars-for-tree $id $tree)
     (DEF gv-expand $expand-p $expand-t))
  (O
    (- (get-vars-for-tree $id $tree))
    (pure (gv-visit $id root $indexed-tree) $indexed-tree
      (vars_to_indices (' $tree)))
    (+ (exec (freq 020 gv-expand) $expand-p $expand-t)))
)

; Example call, kept inactive so this file can be loaded as a library:
; (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
; (exec (freq 000 call-get-vars-example)
;   (, (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
;      (DEF get-vars-for-tree-fn $gv-p $gv-t))
;   (O (+ (exec (freq 010 run-get-vars) $gv-p $gv-t))))

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
    (+ (exec (freq 130 gap-select-by-index)
         (, (gap-wait $sel-id $path $parent $arg)
            (gap-value $sel-id $parent $parent-value)
            (gap-arg-index $arg $index)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-wait $sel-id $path $parent $arg))
           (- (gap-value $sel-id $parent $parent-value))
           (pure (gap-value $sel-id $path $value) $value
             (index-atom $index (' $parent-value)))
           (+ (exec (freq 120 gap-select) $select-p $select-t)))))

    (+ (exec (freq 190 gap-result)
         (, (gap-value $result-id $result-path $result-value)
            (gap-target $result-id $result-path))
         (O
           (- (gap-target $result-id $result-path))
           (- (gap-value $result-id $result-path $result-value))
           (+ (get-value-at-position-result $result-id $result-path $result-value)))))
  )
)

(DEF get-value-at-position-step
  (, (gap-task $id $expr $path))
  (O
    (+ (exec (freq 110 gap-root)
         (, (gap-task $root-id $expr root)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-task $root-id $expr root))
           (+ (gap-value $root-id root $expr))
           (+ (exec (freq 120 gap-select) $select-p $select-t)))))

    (+ (exec (freq 111 gap-descend)
         (, (gap-task $desc-id $expr ($parent $arg))
            (DEF get-value-at-position-step $step-p $step-t))
         (O
           (- (gap-task $desc-id $expr ($parent $arg)))
           (+ (gap-wait $desc-id ($parent $arg) $parent $arg))
           (+ (gap-task $desc-id $expr $parent))
           (+ (exec (freq 100 gap-step) $step-p $step-t)))))
  )
)

; Reusable get-value-at-position function.
;
; To call it from another miner stage, match/create:
;   (get-value-at-position $id $expr $path)
;   (DEF get-value-at-position-fn $gap-p $gap-t)
; then emit:
;   (+ (exec (freq 101 run-get-value-at-position) $gap-p $gap-t))
(DEF get-value-at-position-fn
  (, (get-value-at-position $id $expr $path)
     (DEF get-value-at-position-step $step-p $step-t))
  (O
    (- (get-value-at-position $id $expr $path))
    (+ (gap-target $id $path))
    (+ (gap-task $id $expr $path))
    (+ (exec (freq 100 gap-step) $step-p $step-t)))
)
; Example call, kept inactive:
; (get-value-at-position gap-example
;   (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;   (((root arg/2) arg/1) arg/0))
; (exec (freq 000 call-gap-example)
;   (, (get-value-at-position gap-example
;        (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;        (((root arg/2) arg/1) arg/0))
;      (DEF get-value-at-position-fn $gap-p $gap-t))
;   (O (+ (exec (freq 101 run-get-value-at-position) $gap-p $gap-t))))

; valuation
;
; Valuation pipeline:
;   1. Extract variables and their paths from the pattern.
;   2. Match the raw pattern against loaded FACT rows.
;   3. For each satisfying expression and each variable path, get the value at
;      that path.
;   4. Emit variable bindings for the valuation request.
;
; Request:
;   (valuation $id $pattern)
;
; Knowledge base facts:
;   (FACT $expr)
;
; Results:
;   (valuation-satisfying-set $id $candidate-expr)
;   (valuation-binding $id $path $var $value)
;
; Candidate ids are intentionally not part of the valuation result model.

(DEF valuation-start
  (, (valuation $id $pattern))
  (O
    (- (valuation $id $pattern))
    (+ (get-vars-for-tree (VAL-VARS $id) $pattern))
    (+ (valuation-pattern $id $pattern)))
)

(DEF valuation-match
  (, (valuation-pattern $id $pattern)
     (FACT $pattern))
  (O
    (+ (valuation-satisfying-set $id $pattern)))
)

(DEF valuation-bind
  (, (valuation-satisfying-set $id $candidate-expr)
     (get-vars-for-tree-result (VAL-VARS $id) $path $var)
     (DEF get-value-at-position-fn $gap-p $gap-t))
  (O
    (+ (gap-valuation-binding (VAL-VALUE $id $candidate-expr $path)
         $id
         $path
         $var))
    (+ (get-value-at-position (VAL-VALUE $id $candidate-expr $path)
         $candidate-expr
         $path))
    (- (get-vars-for-tree-result (VAL-VARS $id) $path $var))
    (- (valuation-satisfying-set $id $candidate-expr))
    (+ (exec (freq 231 valuation-get-value) $gap-p $gap-t)))
)

(DEF valuation-binding-finish
  (, (gap-valuation-binding (VAL-VALUE $id $candidate-expr $path) $id $path $var)
     (get-value-at-position-result (VAL-VALUE $id $candidate-expr $path) $path $value))
  (O
    (- (gap-valuation-binding (VAL-VALUE $id $candidate-expr $path) $id $path $var))
    (- (get-value-at-position-result (VAL-VALUE $id $candidate-expr $path) $path $value))
    (+ (valuation-binding $id $path $var $value)))
)

; Reusable valuation function.
;
; To call it from another miner stage, match/create:
;   (valuation $id $pattern)
;   (FACT $candidate-expr)
;   (DEF valuation-fn $val-p $val-t)
; then emit:
;   (+ (exec (freq 200 run-valuation) $val-p $val-t))
(DEF valuation-fn
  (, (valuation $id $pattern)
     (DEF valuation-start $start-p $start-t)
     (DEF valuation-match $match-p $match-t)
     (DEF valuation-bind $bind-p $bind-t)
     (DEF valuation-binding-finish $finish-p $finish-t)
     (DEF get-vars-for-tree-fn $gv-p $gv-t))
  (O
    (+ (exec (freq 200 valuation-start) $start-p $start-t))
    (+ (exec (freq 210 valuation-get-vars) $gv-p $gv-t))
    (+ (exec (freq 220 valuation-match) $match-p $match-t))
    (+ (exec (freq 230 valuation-bind) $bind-p $bind-t))
    (+ (exec (freq 240 valuation-finish) $finish-p $finish-t)))
)

; Example call, kept inactive:
; (valuation val-example (Inheritance $x $y))
; (FACT (Inheritance Allen human))
; (FACT (Inheritance Lily human))
; (FACT (Inheritance Allen sodaDrinker))
; (exec (freq 000 call-example)
;   (, (valuation val-example (Inheritance $x human))
;      (DEF valuation-fn $val-p $val-t))
;   (O (+ (exec (freq 001 run-valuation) $val-p $val-t))))


; shallow abstraction for valuation bindings
;
; This is intentionally shallow:
;   - symbols/atoms stay unchanged
;   - variables stay unchanged
;   - pair/triplet expressions keep their link unchanged
;   - only direct arguments are replaced by split variables
;
; Example:
;   (valuation-binding $id $path (var 0) (Eval Allen soda))
; becomes:
;   (shallow-abstraction-binding $id $path (var 0)
;      (Eval (var (0 1)) (var (0 2))))
;
; Nested expression arguments are treated as one shallow child for now.
(sae-index-next 1 2)
(sae-index-next 2 3)
(sae-index-next 3 4)
(sae-index-next 4 5)
(sae-index-next 5 6)
(sae-index-next 6 7)
(sae-index-next 7 8)
(sae-index-next 8 9)

(DEF sae-start
  (, (shallow-abstract-expression $id (var $source-index) $expr))
  (O
    (pure (sae-link $id $link) $link (car-atom (' $expr)))
    (pure (sae-args $id (var $source-index) $args) $args (cdr-atom (' $expr)))))

(DEF sae-start-walk
  (, (sae-args $id (var $source-index) $args))
  (O
    (+ (sae-walk $id (var $source-index) $args 1 ()))))

(DEF sae-step
  (, (sae-walk $id (var $source-index) $args $pos $acc)
     (sae-index-next $pos $next-pos)
     (DEF sae-history-resolve $hist-p $hist-t))
  (O
    (pure (sae-current $id $pos $value) $value (car-atom (' $args)))
    (pure (sae-step-rest $id (var $source-index) $pos $rest) $rest (cdr-atom (' $args)))
    (- (sae-walk $id (var $source-index) $args $pos $acc))
    (+ (sae-history-pending $id (var $source-index) $pos $next-pos $acc))
    (+ (exec (freq 320 sae-resolve-history) $hist-p $hist-t))))

(DEF sae-history-resolve
  (, (sae-history-pending $id (var $source-index) $pos $next-pos $acc)
     (sae-current $id $pos $value)
     (sae-step-rest $id (var $source-index) $pos $rest)
     (DEF sae-continue $cont-p $cont-t))
  (O
    (+ (exec (freq 321 sae-reuse-history)
         (, (sae-history-pending $reuse-id (var $reuse-source-index) $reuse-pos $reuse-next-pos $reuse-acc)
            (sae-current $reuse-id $reuse-pos $reuse-value)
            (sae-step-rest $reuse-id (var $reuse-source-index) $reuse-pos $reuse-rest)
            (sae-pos-history $reuse-id (var $reuse-source-index) $reuse-value $first-pos))
         (O
           (- (sae-history-pending $reuse-id (var $reuse-source-index) $reuse-pos $reuse-next-pos $reuse-acc))
           (pure (sae-step-acc $reuse-id (var $reuse-source-index) $reuse-next-pos $reuse-next-acc) $reuse-next-acc
             (append (' ($reuse-acc ((var ($reuse-source-index $first-pos)))))))
           (+ (exec (freq 330 sae-continue) $cont-p $cont-t)))))
    (+ (exec (freq 322 sae-new-history)
         (, (sae-history-pending $new-id (var $new-source-index) $new-pos $new-next-pos $new-acc)
            (sae-current $new-id $new-pos $new-value)
            (sae-step-rest $new-id (var $new-source-index) $new-pos $new-rest))
         (O
           (- (sae-history-pending $new-id (var $new-source-index) $new-pos $new-next-pos $new-acc))
           (+ (sae-pos-history $new-id (var $new-source-index) $new-value $new-pos))
           (pure (sae-step-acc $new-id (var $new-source-index) $new-next-pos $new-next-acc) $new-next-acc
             (append (' ($new-acc ((var ($new-source-index $new-pos)))))))
           (+ (exec (freq 330 sae-continue) $cont-p $cont-t)))))))

(DEF sae-continue
  (, (sae-step-rest $id (var $source-index) $pos $rest)
     (sae-step-acc $id (var $source-index) $next-pos $next-acc)
     (DEF sae-finish $finish-p $finish-t)
     (DEF sae-step $step-p $step-t))
  (O
    (- (sae-step-rest $id (var $source-index) $pos $rest))
    (- (sae-step-acc $id (var $source-index) $next-pos $next-acc))
    (+ (sae-walk $id (var $source-index) $rest $next-pos $next-acc))
    (+ (exec (freq 305 sae-finish) $finish-p $finish-t))
    (+ (exec (freq 310 sae-step) $step-p $step-t))))

(DEF sae-finish
  (, (sae-walk $id (var $source-index) () $pos $acc)
     (sae-link $id $link)
     (sae-current $rid $rpos $rvalue)
     (sae-pos-history $rid $rs-index $rvalue $rfirst-pos))
  (O
    (- (sae-walk $id (var $source-index) () $pos $acc))
    (- (sae-link $id $link))
    (- (sae-current $rid $rpos $rvalue))
    (- (sae-pos-history $rid $rs-index $rvalue $rfirst-pos))
    (pure (sae-step-result $id (var $source-index) $res) $res (append (' (($link) $acc))))))

(DEF shallow-abstract-expression-fn
  (, (shallow-abstract-expression $id (var $source-index) $expr)
     (DEF sae-start $start-p $start-t)
     (DEF sae-start-walk $walk-p $walk-t)
     (DEF sae-step $step-p $step-t))
  (O
    (+ (exec (freq 300 sae-start) $start-p $start-t))
    (+ (exec (freq 301 sae-start-walk) $walk-p $walk-t))
    (+ (exec (freq 310 sae-step) $step-p $step-t))))



(DEF shallow-abstraction-start
  (, (run-shallow-abstraction $id) (valuation-binding $id $path (var $source-index) $value))
  (O (pure (shallow-abstraction-request-var $id $path (var $source-index) $value $is-var)
       $is-var (i8_to_string (is_var (' $value))))
     (pure (shallow-abstraction-request-expr $id $path (var $source-index) $value $is-exp)
       $is-exp (i8_to_string (is_exp (' $value))))))

(DEF shallow-abstraction-step
  (, (shallow-abstraction-request-var $id $path (var $source-index) $value $is-var)
     (shallow-abstraction-request-expr $id $path (var $source-index) $value $is-exp))
  (O
    (+ (exec (freq 351 shallow-keep-var)
         (, (shallow-abstraction-request-var $keep-id $keep-path (var $keep-source-index) $keep-value 1))
         (O (- (shallow-abstraction-request-var $keep-id $keep-path (var $keep-source-index) $keep-value 1))
            (+ (shallow-abstraction-binding $keep-id $keep-path (var $keep-source-index) $keep-value)))))
    (+ (exec (freq 352 shallow-abstract-expression)
         (, (shallow-abstraction-request-var $expr-id $expr-path (var $expr-source-index) $expr-value 0)
            (shallow-abstraction-request-expr $expr-id $expr-path (var $expr-source-index) $expr-value 1)
            (DEF shallow-abstract-expression-fn $sae-p $sae-t)
            (DEF shallow-abstraction-expression-finish $finish-p $finish-t))
         (O
            (- (shallow-abstraction-request-expr $expr-id $expr-path (var $expr-source-index) $expr-value 1))
            (+ (shallow-abstract-expression (SAE $expr-id $expr-path) (var $expr-source-index) $expr-value))
            (+ (shallow-abstraction-wait $expr-id $expr-path (var $expr-source-index) (SAE $expr-id $expr-path)))
            (+ (exec (freq 353 shallow-run-sae) $sae-p $sae-t))
            (+ (exec (freq 390 shallow-finish-expression) $finish-p $finish-t)))))
    (+ (exec (freq 359 shallow-keep-atom)
         (, (shallow-abstraction-request-var $atom-id $atom-path (var $atom-source-index) $atom-value 0)
           (shallow-abstraction-request-expr $atom-id $atom-path (var $atom-source-index) $atom-value 0))
         (O (- (shallow-abstraction-request-expr $atom-id $atom-path (var $atom-source-index) $atom-value 0))
            (- (shallow-abstraction-request-var $atom-id $atom-path (var $atom-source-index) $atom-value 0))
            (+ (shallow-abstraction-binding $atom-id $atom-path (var $atom-source-index) $atom-value)))))))



(DEF shallow-abstraction-expression-finish
  (, (shallow-abstraction-wait $id $path (var $source-index) $sae-id)
     (sae-step-result $sae-id (var $source-index) $abstracted-value))
  (O
    (- (shallow-abstraction-wait $id $path (var $source-index) $sae-id))
    (+ (shallow-abstraction-binding $id $path (var $source-index) $abstracted-value))))

(DEF shallow-abstraction-fn
  (, (run-shallow-abstraction $id)
     (DEF shallow-abstraction-start $start-p $start-t)
     (DEF shallow-abstraction-step $step-p $step-t))
  (O
    (+ (exec (freq 350 shallow-start) $start-p $start-t))
    (+ (exec (freq 360 shallow-step) $step-p $step-t))))

; specialization
;
; This stage builds all combinations of shallow abstraction choices across the
; variable positions of a pattern. It does not yet rewrite the original pattern;
; it emits complete binding combinations that the replacement stage can consume.
;
; Request:
;   (run-specialization $id $pattern)
;
; Inputs:
;   (specialization-position $id $pos $path $var)
;   (specialization-final-position $id $final-pos)
;   (shallow-abstraction-binding $id $path $var $value)
;
; Result:
;   (specialization-combination $id $bindings)
;
; Binding list item shape:
;   (binding $path $var $value)
(spec-index-next 1 2)
(spec-index-next 2 3)
(spec-index-next 3 4)
(spec-index-next 4 5)
(spec-index-next 5 6)
(spec-index-next 6 7)
(spec-index-next 7 8)
(spec-index-next 8 9)

(DEF specialization-start
  (, (run-specialization $id $pattern))
  (O
    (+ (specialization-position spec-test 1 (var 0)))
    (+ (specialization-partial $id 1 ()))))

(DEF specialization-extend
  (, (specialization-partial $id $pos $partial)
     (specialization-position $id $pos $var)
     (shallow-abstraction-binding $id $path $var $value)
     (spec-index-next $pos $next-pos)
     (DEF specialization-extend $extend-p $extend-t)
     (DEF specialization-finish $finish-p $finish-t))
  (O
    (- (specialization-partial $id $pos $partial))
    (- (specialization-position $id $pos $var))
    (pure (specialization-partial $id $next-pos $next-partial) $next-partial
      (append (' ($partial ($value)))))
    (+ (specialization-position $id $next-pos (var $pos)))
    (+ (exec (freq 510 specialization-extend) $extend-p $extend-t))
    (+ (exec (freq 590 specialization-finish) $finish-p $finish-t))))

(DEF specialization-finish
  (, (specialization-partial $id $pos $partial)
     (run-specialization $id $pattern))
  (O
    (- (specialization-partial $id $pos $partial))
    (+ (specialization-combination $id $partial))
    (pure (specialization-result $id $specialized-pattern) $specialized-pattern
      (substitute (' ($pattern $partial))))))

(DEF specialization-combinations-fn
  (, (run-specialization $id $pattern)
     (DEF specialization-start $start-p $start-t)
     (DEF specialization-extend $extend-p $extend-t)
     (DEF specialization-finish $finish-p $finish-t))
  (O
    (+ (exec (freq 500 specialization-start) $start-p $start-t))
    (+ (exec (freq 510 specialization-extend) $extend-p $extend-t))
    (+ (exec (freq 590 specialization-finish) $finish-p $finish-t))))

; specialization cross-product smoke
; (run-specialization spec-test (Inheritance $x $y))

; (shallow-abstraction-binding spec-test (root arg/1) (var 0) Allen)
; (shallow-abstraction-binding spec-test (root arg/1) (var 0) Lily)
; (shallow-abstraction-binding spec-test (root arg/1) (var 0) (var 0))
; (shallow-abstraction-binding spec-test (root arg/2) (var 1) human)
; (shallow-abstraction-binding spec-test (root arg/2) (var 1) sodaDrinker)
; (shallow-abstraction-binding spec-test (root arg/2) (var 1) (var 1))

; (exec (freq 000 call-specialization-combinations)
;   (, (run-specialization spec-test (Inheritance $x $y))
;      (DEF specialization-combinations-fn $spec-p $spec-t))
;   (O (+ (exec (freq 001 run-specialization-combinations) $spec-p $spec-t))))




(DEF support-count-fn
  (, (support-count $id $pattern)
     (support-count $id $patt)
     (FACT $pattern))
  (O
    (count (support-count-result $id $patt $count) $count $pattern)))

(DEF candidate-pattern-check-fn
  (, (support-count-result $id $pattern $support)
     (INPUT MIN-SUPPORT $min-support))
  (O
    (pure (minimum-support-check-result $id $pattern $support $min-support $passes) $passes
      (le_f64 (f64_from_string $min-support) (f64_from_string $support)))
    (+ (exec (freq 630 minimum-support-pass)
         (, (minimum-support-check-result $pass-id $pass-pattern $pass-support $pass-min true))
         (O (- (minimum-support-check-result $pass-id $pass-pattern $pass-support $pass-min true))
            (+ (candidate-pattern $pass-id $pass-pattern $pass-support)))))))