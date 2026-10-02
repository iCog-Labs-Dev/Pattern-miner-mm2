;; One-generation frequent candidate miner.
;;
;; Inputs:
;;   (INPUT MIN-SUPPORT n)
;;   (FACT $database-expression)
;;
;; Public request:
;;   (run-frequent-miner $generation-id $pattern)
;;
;; Public result:
;;   (candidate-pattern $generation-id $indexed-pattern $support)
;;
;; `iterative-miner.metta` supplies generation scoping and recursive depth.

(DEF gv-expand
  (, (gv-visit $id $path $node))
  (O
    (- (gv-visit $id $path $node))
    (pure (gv-var-check $id $path $node $is-var) $is-var
      (i8_to_string (is_var (' $node))))

    (+ (exec (freq f030 gv-record)
         (, (gv-var-check $record-id $record-path $var-node 1))
         (O
           (- (gv-var-check $record-id $record-path $var-node 1))
           (+ (get-vars-for-tree-result $record-id $record-path $var-node)))))

    (+ (exec (freq f031 gv-split-pair)
         (, (gv-var-check $split-id $split-path ($a $b) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (exec (freq f020 gv-expand) $expand-p $expand-t)))))

    (+ (exec (freq f032 gv-split-triplet)
         (, (gv-var-check $split-id $split-path ($a $b $c) 0)
            (DEF gv-expand $expand-p $expand-t))
         (O
           (- (gv-var-check $split-id $split-path ($a $b $c) 0))
           (+ (gv-visit $split-id ($split-path arg/0) $a))
           (+ (gv-visit $split-id ($split-path arg/1) $b))
           (+ (gv-visit $split-id ($split-path arg/2) $c))
           (+ (exec (freq f020 gv-expand) $expand-p $expand-t)))))

    (+ (exec (freq f039 gv-discard-non-var)
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
;   (+ (exec (freq f010 run-get-vars) $gv-p $gv-t))
(DEF get-vars-for-tree-fn
  (, (get-vars-for-tree $id $tree)
     (DEF gv-expand $expand-p $expand-t))
  (O
    (- (get-vars-for-tree $id $tree))
    (pure (gv-visit $id root $indexed-tree) $indexed-tree
      (vars_to_indices (' $tree)))
    (+ (exec (freq f020 gv-expand) $expand-p $expand-t)))
)

; Example call, kept inactive so this file can be loaded as a library:
; (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
; (exec (freq f000 call-get-vars-example)
;   (, (get-vars-for-tree sample (Inheritance $x (Evaluation $x $y)))
;      (DEF get-vars-for-tree-fn $gv-p $gv-t))
;   (O (+ (exec (freq f010 run-get-vars) $gv-p $gv-t))))

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
; Accept the short-lived optimized encoding too, so external callers can
; migrate independently while the miner continues to publish its legacy paths.
(gap-arg-index (arg 0) 0)
(gap-arg-index (arg 1) 1)
(gap-arg-index (arg 2) 2)

(DEF get-value-at-position-select
  (, (gap-value $id $parent $parent-value))
  (O
    ; Keep variables in generated nested rules distinct from the outer rule.
    ; Otherwise substitution can capture them and multiply the join work.
    (+ (exec (freq f130 gap-select-by-index)
         (, (gap-wait $sel-id $path $sel-parent $arg)
            (gap-value $sel-id $sel-parent $sel-parent-value)
            (gap-arg-index $arg $index)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-wait $sel-id $path $sel-parent $arg))
           (- (gap-value $sel-id $sel-parent $sel-parent-value))
           (pure (gap-value $sel-id $path $value) $value
             (index-atom $index (' $sel-parent-value)))
           (+ (exec (freq f120 gap-select) $select-p $select-t)))))

    (+ (exec (freq f190 gap-result)
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
    (+ (exec (freq f110 gap-root)
         (, (gap-task $root-id $root-expr root)
            (DEF get-value-at-position-select $select-p $select-t))
         (O
           (- (gap-task $root-id $root-expr root))
           (+ (gap-value $root-id root $root-expr))
           (+ (exec (freq f120 gap-select) $select-p $select-t)))))

    (+ (exec (freq f111 gap-descend)
         (, (gap-task $desc-id $desc-expr ($parent $arg))
            (DEF get-value-at-position-step $step-p $step-t))
         (O
           (- (gap-task $desc-id $desc-expr ($parent $arg)))
           (+ (gap-wait $desc-id ($parent $arg) $parent $arg))
           (+ (gap-task $desc-id $desc-expr $parent))
           (+ (exec (freq f100 gap-step) $step-p $step-t)))))
  )
)

; Reusable get-value-at-position function.
;
; To call it from another miner stage, match/create:
;   (get-value-at-position $id $expr $path)
;   (DEF get-value-at-position-fn $gap-p $gap-t)
; then emit:
;   (+ (exec (freq f101 run-get-value-at-position) $gap-p $gap-t))
(DEF get-value-at-position-fn
  (, (get-value-at-position $id $expr $path)
     (DEF get-value-at-position-step $step-p $step-t))
  (O
    (- (get-value-at-position $id $expr $path))
    (+ (gap-target $id $path))
    (+ (gap-task $id $expr $path))
    (+ (exec (freq f100 gap-step) $step-p $step-t)))
)
; Example call, kept inactive:
; (get-value-at-position gap-example
;   (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;   (((root (arg 2)) (arg 1)) (arg 0)))
; (exec (freq f000 call-gap-example)
;   (, (get-value-at-position gap-example
;        (Inheritance Allen (Evaluation (Var 1) (like (we sodaDrinker) dean)))
;        (((root (arg 2)) (arg 1)) (arg 0)))
;      (DEF get-value-at-position-fn $gap-p $gap-t))
;   (O (+ (exec (freq f101 run-get-value-at-position) $gap-p $gap-t))))

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
    (- (get-vars-for-tree-result (VAL-VARS $id) $path $var))
    (- (valuation-satisfying-set $id $candidate-expr))
    (+ (valuation-position-wait $id $candidate-expr $path $var))
    (+ (get-value-at-position ($id $candidate-expr $path) $candidate-expr $path))
    (+ (exec (freq f230 valuation-get-value) $gap-p $gap-t))))

(DEF valuation-position-finish
  (, (valuation-position-wait $id $candidate-expr $path $var)
     (get-value-at-position-result ($id $candidate-expr $path) $path $value))
  (O
    (- (valuation-position-wait $id $candidate-expr $path $var))
    (- (get-value-at-position-result ($id $candidate-expr $path) $path $value))
    (+ (valuation-position-value $id $candidate-expr $path $var $value))))

(DEF valuation-binding-finish
  (, (valuation-position-value $id $candidate-expr $path $var $value))
  (O
    (- (valuation-position-value $id $candidate-expr $path $var $value))
    (+ (valuation-binding $id $path $var $value))
    (+ (valuation-binding $id $path $var $var))))

; Reusable valuation function.
;
; To call it from another miner stage, match/create:
;   (valuation $id $pattern)
;   (FACT $candidate-expr)
;   (DEF valuation-fn $val-p $val-t)
; then emit:
;   (+ (exec (freq f200 run-valuation) $val-p $val-t))
(DEF valuation-fn
  (, (valuation $id $pattern)
     (DEF valuation-start $start-p $start-t)
     (DEF valuation-match $match-p $match-t)
     (DEF valuation-bind $bind-p $bind-t)
     (DEF valuation-position-finish $position-p $position-t)
     (DEF valuation-binding-finish $finish-p $finish-t)
     (DEF get-vars-for-tree-fn $gv-p $gv-t)
     (DEF get-value-at-position-fn $gap-p $gap-t))
  (O
    (+ (exec (freq f200 valuation-start) $start-p $start-t))
    (+ (exec (freq f210 valuation-get-vars) $gv-p $gv-t))
    (+ (exec (freq f220 valuation-match) $match-p $match-t))
    (+ (exec (freq f230 valuation-bind) $bind-p $bind-t))
    (+ (exec (freq f235 valuation-position-finish) $position-p $position-t))
    (+ (exec (freq f240 valuation-finish) $finish-p $finish-t)))
)

; Example call, kept inactive:
; (valuation val-example (Inheritance $x $y))
; (FACT (Inheritance Allen human))
; (FACT (Inheritance Lily human))
; (FACT (Inheritance Allen sodaDrinker))
; (exec (freq f000 call-example)
;   (, (valuation val-example (Inheritance $x human))
;      (DEF valuation-fn $val-p $val-t))
;   (O (+ (exec (freq f001 run-valuation) $val-p $val-t))))


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
(sae-index-next 0 1)
(sae-index-next 1 2)
(sae-index-next 2 3)
(sae-index-next 3 4)
(sae-index-next 4 5)
(sae-index-next 5 6)
(sae-index-next 6 7)
(sae-index-next 7 8)
(sae-index-next 8 9)

(DEF sae-start
  (, (shallow-abstract-expression (SAE $parent-id $path $expr) $path (var $source-index) $expr)
     (DEF sae-start-shape $shape-p $shape-t))
  (O
    (- (shallow-abstract-expression (SAE $parent-id $path $expr) $path (var $source-index) $expr))
    (pure (sae-shape-link $parent-id $path (var $source-index) $expr $link) $link (car-atom (' $expr)))
    (pure (sae-shape-arity $parent-id $path (var $source-index) $expr $arity) $arity
      (size-atom (cdr-atom (' $expr))))
    (+ (exec (freq f301 sae-start-shape) $shape-p $shape-t))))

(DEF sae-start-shape
  (, (sae-shape-link $parent-id $path (var $source-index) $expr $link)
     (sae-shape-arity $parent-id $path (var $source-index) $expr $arity))
  (O
    (- (sae-shape-link $parent-id $path (var $source-index) $expr $link))
    (- (sae-shape-arity $parent-id $path (var $source-index) $expr $arity))
    (+ (sae-link (SAE $parent-id $path (var $source-index) $link $arity) $link))
    (+ (sae-args-arity (SAE $parent-id $path (var $source-index) $link $arity) $parent-id (var $source-index) $arity))
    (+ (shallow-abstraction-wait $parent-id $path (var $source-index) (SAE $parent-id $path (var $source-index) $link $arity)))))

(DEF sae-start-walk
  (, (sae-args-arity $id $parent-id (var $source-index) $arity))
  (O
    (- (sae-args-arity $id $parent-id (var $source-index) $arity))
    (+ (sae-slot-value $id (var $source-index) 1 1))
    (+ (sae-walk $id (var $source-index) $arity 1 ()))))

(DEF sae-step
  (, (sae-walk $id (var $source-index) $remaining $pos $acc)
     (sae-index-next $next-remaining $remaining)
     (sae-index-next $pos $next-pos)
     (DEF sae-slot-append $append-p $append-t))
  (O
    (- (sae-walk $id (var $source-index) $remaining $pos $acc))
    (+ (sae-slot-pending $id (var $source-index) $pos $next-pos $next-remaining $acc))
    (+ (exec (freq f320 sae-slot-append) $append-p $append-t))))

(DEF sae-slot-append
  (, (sae-slot-pending $id (var $source-index) $pos $next-pos $next-remaining $acc)
     (sae-slot-value $id (var $source-index) $pos $slot)
     (DEF sae-continue $cont-p $cont-t))
  (O
    (- (sae-slot-pending $id (var $source-index) $pos $next-pos $next-remaining $acc))
    (pure (sae-step-acc $id (var $source-index) $pos $next-pos $next-remaining $next-acc) $next-acc
      (append (' ($acc ((var ($source-index $slot)))))))
    (+ (sae-slot-value $id (var $source-index) $next-pos $slot))
    (+ (sae-slot-value $id (var $source-index) $next-pos $next-pos))
    (+ (exec (freq f330 sae-continue) $cont-p $cont-t))))

(DEF sae-continue
  (, (sae-step-acc $id (var $source-index) $pos $next-pos $next-remaining $next-acc)
     (DEF sae-finish $finish-p $finish-t)
     (DEF sae-step $step-p $step-t))
  (O
    (- (sae-step-acc $id (var $source-index) $pos $next-pos $next-remaining $next-acc))
    (+ (sae-walk $id (var $source-index) $next-remaining $next-pos $next-acc))
    (+ (exec (freq f305 sae-finish) $finish-p $finish-t))
    (+ (exec (freq f310 sae-step) $step-p $step-t))))

(DEF sae-finish
  (, (sae-walk $id (var $source-index) 0 $pos $acc)
     (sae-link $id $link))
  (O
    (- (sae-walk $id (var $source-index) 0 $pos $acc))
    (pure (sae-step-result $id (var $source-index) $res) $res (append (' (($link) $acc))))))

(DEF shallow-abstract-expression-fn
  (, (shallow-abstract-expression $id $path (var $source-index) $expr)
     (DEF sae-start $start-p $start-t)
     (DEF sae-start-shape $shape-p $shape-t)
     (DEF sae-start-walk $walk-p $walk-t)
     (DEF sae-step $step-p $step-t))
  (O
    (+ (exec (freq f300 sae-start) $start-p $start-t))
    (+ (exec (freq f301 sae-start-shape) $shape-p $shape-t))
    (+ (exec (freq f303 sae-start-walk) $walk-p $walk-t))
    (+ (exec (freq f310 sae-step) $step-p $step-t))))



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
    (+ (exec (freq f351 shallow-keep-var)
         (, (shallow-abstraction-request-var $keep-id $keep-path (var $keep-source-index) $keep-value 1))
         (O (- (shallow-abstraction-request-var $keep-id $keep-path (var $keep-source-index) $keep-value 1))
            (+ (shallow-abstraction-binding $keep-id $keep-path (var $keep-source-index) $keep-value)))))
    (+ (exec (freq f352 shallow-abstract-expression)
         (, (shallow-abstraction-request-var $expr-id $expr-path (var $expr-source-index) $expr-value 0)
            (shallow-abstraction-request-expr $expr-id $expr-path (var $expr-source-index) $expr-value 1)
            (DEF shallow-abstract-expression-fn $sae-p $sae-t)
            (DEF shallow-abstraction-expression-finish $finish-p $finish-t))
         (O
            (- (shallow-abstraction-request-expr $expr-id $expr-path (var $expr-source-index) $expr-value 1))
            (+ (shallow-abstract-expression (SAE $expr-id $expr-path $expr-value) $expr-path (var $expr-source-index) $expr-value))
            (+ (exec (freq f353 shallow-run-sae) $sae-p $sae-t))
            (+ (exec (freq f390 shallow-finish-expression) $finish-p $finish-t)))))
    (+ (exec (freq f359 shallow-keep-atom)
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
    (- (sae-step-result $sae-id (var $source-index) $abstracted-value))
    (+ (shallow-abstraction-binding $id $path (var $source-index) $abstracted-value))))

(DEF shallow-abstraction-fn
  (, (run-shallow-abstraction $id)
     (DEF shallow-abstraction-start $start-p $start-t)
     (DEF shallow-abstraction-step $step-p $step-t))
  (O
    (+ (exec (freq f350 shallow-start) $start-p $start-t))
    (+ (exec (freq f360 shallow-step) $step-p $step-t))))

; specialization
;
; This stage walks the indexed pattern left-to-right and builds a partial value
; list for `substitute`. Variables are replaced from `shallow-abstraction-binding`
; by matching the variable node itself; expressions push their arguments back
; onto the todo queue; atoms are skipped. A root variable is handled directly
; so it does not go through car/cdr traversal.
;
; Request:
;   (run-specialization $id $pattern)
;
; Inputs:
;   (shallow-abstraction-binding $id $path $var $value)
;
; Internal state:
;   (specialization-partial $id $todo $values)
;   (specialization-head $id $todo $values $node)
;   (specialization-rest $id $todo $values $rest)
;
; Result:
;   (specialization-result $id $specialized-pattern)
;
; The value list is passed to:
;   (substitute (' ($pattern $values)))
(DEF specialization-start
  (, (run-specialization $id $pattern)
     (DEF specialization-start-indexed $indexed-p $indexed-t))
  (O
    (pure (specialization-indexed-pattern $id $indexed-pattern) $indexed-pattern
      (vars_to_indices (' $pattern)))
    (+ (exec (freq f501 specialization-start-indexed) $indexed-p $indexed-t))))

(DEF specialization-start-indexed
  (, (specialization-indexed-pattern $id $indexed-pattern)
     (DEF specialization-start-choice $choice-p $choice-t))
  (O
    (- (specialization-indexed-pattern $id $indexed-pattern))
    (+ (specialization-template $id $indexed-pattern))
    (pure (specialization-root-is-var $id $indexed-pattern $is-var) $is-var
      (i8_to_string (is_var (' $indexed-pattern))))
    (+ (exec (freq f502 specialization-start-choice) $choice-p $choice-t))))

(DEF specialization-start-choice
  (, (DEF specialization-extend $extend-p $extend-t)
     (DEF specialization-finish $finish-p $finish-t)
     (DEF specialization-proposal-fn $gate-p $gate-t))
  (O
    (+ (exec (freq f502 specialization-start-var)
         (, (specialization-root-is-var $id $indexed-pattern 1)
            (shallow-abstraction-binding $id $path $indexed-pattern $value))
         (O
           (- (specialization-root-is-var $id $indexed-pattern 1))
           (+ (specialization-proposal $id () () ($value)))
           (+ (exec (freq f515 specialization-gate) $gate-p $gate-t)))))
    (+ (exec (freq f503 specialization-start-non-var)
         (, (specialization-root-is-var $id $indexed-pattern 0))
         (O
           (- (specialization-root-is-var $id $indexed-pattern 0))
           (+ (specialization-partial $id $indexed-pattern ()))
           (+ (exec (freq f510 specialization-extend) $extend-p $extend-t)))))))

(DEF specialization-extend
  (, (specialization-partial $id $todo $partial)
     (DEF specialization-classify $classify-p $classify-t)
     (DEF specialization-finish $finish-p $finish-t))
  (O
    (+ (exec (freq f509 specialization-finish-empty) $finish-p $finish-t))
    (+ (exec (freq f510 specialization-split)
         (, (specialization-partial $id $todo $partial))
         (O
           (- (specialization-partial $id $todo $partial))
           (pure (specialization-head $id $todo $partial $head) $head
             (car-atom (' $todo)))
           (pure (specialization-rest $id $todo $partial $rest) $rest
             (cdr-atom (' $todo)))
           (+ (exec (freq f511 specialization-classify) $classify-p $classify-t)))))))

(DEF specialization-classify
  (, (specialization-head $id $todo $partial $head)
     (DEF specialization-choose $choose-p $choose-t))
  (O
    (pure (specialization-is-var $id $todo $partial $head $is-var) $is-var
      (i8_to_string (is_var (' $head))))
    (pure (specialization-is-exp $id $todo $partial $head $is-exp) $is-exp
      (i8_to_string (is_exp (' $head))))
    (+ (exec (freq f512 specialization-choose) $choose-p $choose-t))))

(DEF specialization-choose
  (, (DEF specialization-extend $extend-p $extend-t)
     (DEF specialization-prepend-exp-args $prep-p $prep-t)
     (DEF specialization-proposal-fn $gate-p $gate-t))
  (O
    (+ (exec (freq f511 specialization-append-var)
         (, (specialization-is-var $id $todo $partial $var 1)
            (specialization-is-exp $id $todo $partial $var 0)
            (specialization-rest $id $todo $partial $rest)
            (specialization-head $id $todo $partial $var)
            (shallow-abstraction-binding $id $path $var $value))
         (O
           (- (specialization-is-var $id $todo $partial $var 1))
           (- (specialization-is-exp $id $todo $partial $var 0))
           (- (specialization-rest $id $todo $partial $rest))
           (- (specialization-head $id $todo $partial $var))
           (pure (specialization-proposal $id $rest $partial $next-partial) $next-partial
             (append (' ($partial ($value)))))
           (+ (exec (freq f515 specialization-gate) $gate-p $gate-t)))))
    (+ (exec (freq f512 specialization-expand-exp)
         (, (specialization-is-var $id $todo $partial $expr 0)
            (specialization-is-exp $id $todo $partial $expr 1)
            (specialization-rest $id $todo $partial $rest)
            (specialization-head $id $todo $partial $expr))
         (O
           (- (specialization-is-var $id $todo $partial $expr 0))
           (- (specialization-is-exp $id $todo $partial $expr 1))
           (- (specialization-rest $id $todo $partial $rest))
           (- (specialization-head $id $todo $partial $expr))
           (pure (specialization-exp-args $id $rest $partial $args) $args
             (cdr-atom (' $expr)))
           (+ (exec (freq f514 specialization-prepend-exp-args) $prep-p $prep-t)))))
    (+ (exec (freq f513 specialization-skip-atom)
         (, (specialization-is-var $id $todo $partial $atom 0)
            (specialization-is-exp $id $todo $partial $atom 0)
            (specialization-rest $id $todo $partial $rest)
            (specialization-head $id $todo $partial $atom))
         (O
           (- (specialization-is-var $id $todo $partial $atom 0))
           (- (specialization-is-exp $id $todo $partial $atom 0))
           (- (specialization-rest $id $todo $partial $rest))
           (- (specialization-head $id $todo $partial $atom))
           (+ (specialization-partial $id $rest $partial))
           (+ (exec (freq f510 specialization-extend) $extend-p $extend-t)))))
    ))

(DEF specialization-prepend-exp-args
  (, (specialization-exp-args $id $rest $partial $args)
     (DEF specialization-extend $extend-p $extend-t))
  (O
    (- (specialization-exp-args $id $rest $partial $args))
    (pure (specialization-partial $id $next-todo $partial) $next-todo
      (append (' ($args $rest))))
    (+ (exec (freq f510 specialization-extend) $extend-p $extend-t))))

(DEF specialization-finish
  (, (specialization-partial $id () $partial)
     (run-specialization $id $pattern))
  (O
    (- (specialization-partial $id () $partial))
    (pure (specialization-result $id $specialized-pattern) $specialized-pattern
      (substitute (' ($pattern $partial))))))

; Standalone combination enumeration remains exhaustive. The integrated miner
; uses pruned-specialization-combinations-fn instead.
(DEF specialization-combinations-fn
  (, (run-specialization $id $pattern)
     (DEF specialization-start $start-p $start-t))
  (O
    (+ (specialization-mode $id exhaustive))
    (+ (exec (freq f500 specialization-start) $start-p $start-t))))

; Prefix pruning retains the actual fact as its identity. Unfinished occurrences
; are fresh independent variables in the query, so each completed substitution
; is an instance of every prefix even for repeated variables in the input.
; Match sets are scoped by generation and prefix and reused by child branches.
(DEF specialization-seed-matches-fn
  (, (specialization-mode $id pruned) (FACT $fact))
  (O (+ (specialization-matches $id () $fact))))

(DEF pruned-specialization-combinations-fn
  (, (run-specialization $id $pattern)
     (DEF specialization-seed-matches-fn $seed-p $seed-t)
     (DEF specialization-start $start-p $start-t))
  (O
    (+ (specialization-mode $id pruned))
    (+ (exec (freq f499 specialization-seed-matches) $seed-p $seed-t))
    (+ (exec (freq f500 specialization-start) $start-p $start-t))))

(DEF specialization-exhaustive-proposal-fn
  (, (specialization-mode $id exhaustive)
     (specialization-proposal $id $rest $before $after)
     (DEF specialization-extend $extend-p $extend-t))
  (O
    (- (specialization-proposal $id $rest $before $after))
    (+ (specialization-partial $id $rest $after))
    (+ (exec (freq f510 specialization-extend) $extend-p $extend-t))))

(DEF specialization-prefix-prepare-fn
  (, (specialization-mode $id pruned)
     (specialization-proposal $id $rest $before $after)
     (specialization-template $id $template)
     (DEF specialization-prefix-mm2-fn $prefix-p $prefix-t))
  (O
    (- (specialization-proposal $id $rest $before $after))
    (+ (specialization-wait $id $rest $after))
    (+ (specialization-prefix-request ($id $before $after) $template $after))
    (+ (exec (freq f516 p00) $prefix-p $prefix-t))
    (+ (exec (freq f516 p90)
      (, (specialization-prefix-result ($result-id $result-before $result-after) $query))
      (O (- (specialization-prefix-result ($result-id $result-before $result-after) $query))
         (+ (specialization-prefix-indexed $result-id $result-before $result-after $query)))))))

;; MM2 rule implementation of occurrence-wise prefix specialization. Input
;; templates and values use indexed variables.
;; (specialization-prefix-request key template values)
;; -> (specialization-prefix-result key indexed-prefix)
;; Schedule specialization-prefix-mm2-fn at (freq f516 p00).
;; All internal work finishes before the miner's f517 restore stage.

(DEF specialization-prefix-mm2-fn
  (, (specialization-prefix-request $key $template $values)
     (DEF sp-count-fn $cp $ct)
     (DEF sp-fill-start-fn $fp $ft))
  (O
    (- (specialization-prefix-request $key $template $values))
    (+ (sp-input $key $template $values))
    (+ (sp-count-request $template))
    (pure (sp-used $key $used) $used (indexed_vars_in_expr (' $values)))
    (pure (sp-length $key $length) $length (size-atom (' $values)))
    (+ (exec (freq f516 p01) $cp $ct))
    ; Completed substitutions need neither fresh markers nor the fill loop.
    (+ (exec (freq f516 p29)
      (, (sp-input $full-key $full-template $full-values)
         (sp-total $full-template $full-n)
         (sp-length $full-key $full-n)
         (sp-used $full-key $full-used))
      (O (- (sp-input $full-key $full-template $full-values))
         (- (sp-length $full-key $full-n))
         (- (sp-used $full-key $full-used))
         (pure (specialization-prefix-result $full-key $full-result) $full-result
           (substitute (' ($full-template $full-values)))))))
    (+ (exec (freq f516 p30) $fp $ft))))

;; Count occurrences once per template, including variable expression heads.
;; The traversal treats (var label) as a leaf, including compound labels.
;; A linked stack of child lists avoids flattening wide trees into an oversized
;; tuple. sp-total is an intentional cache; all per-request state is consumed.
(DEF sp-count-fn
  (, (DEF sp-walk-fn $wp $wt))
  (O
    (+ (exec (freq f516 p02)
      (, (sp-count-request $cached-template) (sp-total $cached-template $cached-n))
      (O (- (sp-count-request $cached-template)))))
    (+ (exec (freq f516 p03)
      (, (sp-count-request $new-template))
      (O (- (sp-count-request $new-template))
         (+ (sp-walk $new-template (($new-template) ()) 0))
         (+ (exec (freq f516 p08) $wp $wt)))))))

(DEF sp-walk-fn
  (, (DEF sp-classify-fn $cp $ct)
     (DEF sp-walk-fn $wp $wt))
  (O
    (+ (exec (freq f516 p09)
      (, (sp-walk $done-template () $done-n))
      (O (- (sp-walk $done-template () $done-n))
         (+ (sp-total $done-template $done-n)))))
    (+ (exec (freq f516 p10)
      (, (sp-walk $pop-template (() $stack-rest) $pop-n))
      (O (- (sp-walk $pop-template (() $stack-rest) $pop-n))
         (+ (sp-walk $pop-template $stack-rest $pop-n))
         (+ (exec (freq f516 p08) $wp $wt)))))
    (+ (exec (freq f516 p11)
      (, (sp-walk $walk-template ($todo $stack) $n))
      (O (- (sp-walk $walk-template ($todo $stack) $n))
         (pure (sp-head $walk-template ($todo $stack) $n $head) $head (car-atom (' $todo)))
         (pure (sp-tail $walk-template ($todo $stack) $n ($tail $stack)) $tail (cdr-atom (' $todo)))
         (+ (exec (freq f516 p12) $cp $ct)))))))

(DEF sp-classify-fn
  (, (sp-head $template $todo $n $head)
     (sp-tail $template $todo $n $tail)
     (DEF sp-walk-branch-fn $bp $bt))
  (O
    (- (sp-head $template $todo $n $head))
    (- (sp-tail $template $todo $n $tail))
    (pure (sp-var $template $n $tail $head $flag) $flag (i8_to_string (is_var (' $head))))
    (pure (sp-exp $template $n $tail $head $flag) $flag (i8_to_string (is_exp (' $head))))
    (+ (exec (freq f516 p13) $bp $bt))))

(DEF sp-walk-branch-fn
  (, (DEF sp-walk-fn $wp $wt))
  (O
    (+ (exec (freq f516 p14)
      (, (sp-var $vt $vn $vr $vh 1) (sp-exp $vt $vn $vr $vh 0))
      (O (- (sp-var $vt $vn $vr $vh 1)) (- (sp-exp $vt $vn $vr $vh 0))
         (pure (sp-walk $vt $vr $next-n) $next-n
           (i32_to_string (sum_i32 (i32_from_string $vn) (i32_one))))
         (+ (exec (freq f516 p08) $wp $wt)))))
    (+ (exec (freq f516 p15)
      (, (sp-var $et $en $er $eh 0) (sp-exp $et $en $er $eh 1))
      (O (- (sp-var $et $en $er $eh 0)) (- (sp-exp $et $en $er $eh 1))
         (+ (sp-walk $et ($eh $er) $en))
         (+ (exec (freq f516 p08) $wp $wt)))))
    (+ (exec (freq f516 p16)
      (, (sp-var $at $an $ar $ah 0) (sp-exp $at $an $ar $ah 0))
      (O (- (sp-var $at $an $ar $ah 0)) (- (sp-exp $at $an $ar $ah 0))
         (+ (sp-walk $at $ar $an))
         (+ (exec (freq f516 p08) $wp $wt)))))))

;; MORK tuples have at most 63 items. substitute takes a flat value tuple, so
;; reject larger occurrence counts explicitly before padding. Stage size-atom
;; separately because quotes in non-final arguments do not advance this
;; evaluator's input cursor correctly.
(DEF sp-fill-start-fn
  (, (sp-input $key $template $values) (sp-total $template $total)
     (sp-used $key $used) (sp-length $key $length)
     (DEF sp-fill-validate-fn $vp $vt))
  (O
    (- (sp-input $key $template $values)) (- (sp-used $key $used))
    (- (sp-length $key $length))
    (pure (sp-valid $key $template $values $total $used $valid) $valid
      (le_f64 (f64_from_string $length) (f64_from_string $total)))
    (pure (sp-limit $key $supported) $supported
      (le_f64 (f64_from_string $total) (f64_from_string 63)))
    (+ (exec (freq f516 p31) $vp $vt))))

(DEF sp-fill-validate-fn
  (, (DEF sp-fill-fn $fp $ft))
  (O
    (+ (exec (freq f516 p32)
      (, (sp-valid $ok-key $ok-template $ok-values $ok-total $ok-used true)
         (sp-limit $ok-key true))
      (O (- (sp-valid $ok-key $ok-template $ok-values $ok-total $ok-used true))
         (- (sp-limit $ok-key true))
         (+ (sp-template $ok-key $ok-template))
         (+ (sp-fill $ok-key $ok-values $ok-total $ok-used 0))
         (+ (exec (freq f516 p40) $fp $ft)))))
    (+ (exec (freq f516 p33)
      (, (sp-valid $bad-key $bad-template $bad-values $bad-total $bad-used false)
         (sp-limit $bad-key true))
      (O (- (sp-valid $bad-key $bad-template $bad-values $bad-total $bad-used false))
         (- (sp-limit $bad-key true))
         (+ (specialization-prefix-error $bad-key too-many-values)))))
    (+ (exec (freq f516 p34)
      (, (sp-valid $wide-key $wide-template $wide-values $wide-total $wide-used $valid)
         (sp-limit $wide-key false))
      (O (- (sp-valid $wide-key $wide-template $wide-values $wide-total $wide-used $valid))
         (- (sp-limit $wide-key false))
         (+ (specialization-prefix-error $wide-key too-many-occurrences)))))))

(DEF sp-fill-fn
  (, (sp-fill $key $values $total $used $cursor)
     (DEF sp-fill-branch-fn $bp $bt))
  (O
    (- (sp-fill $key $values $total $used $cursor))
    (pure (sp-done $key $values $total $used $cursor $done) $done
      (le_f64 (f64_from_string $total) (f64_from_string (size-atom (' $values)))))
    (+ (exec (freq f516 p41) $bp $bt))))

(DEF sp-fill-branch-fn
  (, (DEF sp-fresh-fn $fp $ft))
  (O
    (+ (exec (freq f516 p42)
      (, (sp-done $done-key $done-values $done-total $done-used $done-cursor true)
         (sp-template $done-key $done-template))
      (O (- (sp-done $done-key $done-values $done-total $done-used $done-cursor true))
         (- (sp-template $done-key $done-template))
         (pure (specialization-prefix-result $done-key $result) $result
           (substitute (' ($done-template $done-values)))))))
    (+ (exec (freq f516 p43)
      (, (sp-done $more-key $more-values $more-total $more-used $more-cursor false))
      (O (- (sp-done $more-key $more-values $more-total $more-used $more-cursor false))
         (pure (sp-member $more-key $more-values $more-total $more-used $more-cursor $member) $member
           (size-atom (intersection-atom (' (((var $more-cursor)) $more-used)))))
         (pure (sp-next $more-key $more-cursor $next) $next
           (i32_to_string (sum_i32 (i32_from_string $more-cursor) (i32_one))))
         (+ (exec (freq f516 p44) $fp $ft)))))))

;; The cursor advances even when a marker collides. Generated markers can never
;; collide with one another, so membership only needs the original chosen values.
(DEF sp-fresh-fn
  (, (DEF sp-fill-fn $fp $ft))
  (O
    (+ (exec (freq f516 p45)
      (, (sp-member $hit-key $hit-values $hit-total $hit-used $hit-cursor 1)
         (sp-next $hit-key $hit-cursor $hit-next))
      (O (- (sp-member $hit-key $hit-values $hit-total $hit-used $hit-cursor 1))
         (- (sp-next $hit-key $hit-cursor $hit-next))
         (+ (sp-fill $hit-key $hit-values $hit-total $hit-used $hit-next))
         (+ (exec (freq f516 p40) $fp $ft)))))
    (+ (exec (freq f516 p46)
      (, (sp-member $new-key $new-values $new-total $new-used $new-cursor 0)
         (sp-next $new-key $new-cursor $new-next))
      (O (- (sp-member $new-key $new-values $new-total $new-used $new-cursor 0))
         (- (sp-next $new-key $new-cursor $new-next))
         (pure (sp-fill $new-key $next-values $new-total $new-used $new-next) $next-values
           (append (' ($new-values ((var $new-cursor))))))
         (+ (exec (freq f516 p40) $fp $ft)))))))


(DEF specialization-prefix-restore-fn
  (, (specialization-prefix-indexed $id $before $after $indexed))
  (O
    (- (specialization-prefix-indexed $id $before $after $indexed))
    (pure (specialization-prefix-query $id $before $after $query) $query
      (indices_to_vars (' $indexed)))))

(DEF specialization-prefix-match-fn
  (, (specialization-prefix-query $id $before $after $pattern)
     (specialization-matches $id $before $pattern))
  (O (+ (specialization-matches $id $after $pattern))))

(DEF specialization-prefix-count-fn
  (, (specialization-wait $id $rest $prefix)
     (specialization-matches $id $prefix $fact))
  (O (count (specialization-prefix-support $id $rest $prefix $support)
       $support $fact)))

(DEF specialization-prefix-check-fn
  (, (specialization-prefix-support $id $rest $prefix $support)
     (INPUT MIN-SUPPORT $min))
  (O
    (- (specialization-prefix-support $id $rest $prefix $support))
    (pure (specialization-prefix-decision $id $rest $prefix $passes) $passes
      (le_f64 (f64_from_string $min) (f64_from_string $support)))))

(DEF specialization-prefix-accept-fn
  (, (specialization-prefix-decision $id $rest $prefix true)
     (DEF specialization-extend $extend-p $extend-t))
  (O
    (- (specialization-prefix-decision $id $rest $prefix true))
    (- (specialization-wait $id $rest $prefix))
    (+ (specialization-partial $id $rest $prefix))
    (+ (exec (freq f510 specialization-extend) $extend-p $extend-t))))

; Scheduled after accept. Zero-match prefixes have no count result and are
; dropped here too. The public support counter likewise publishes only matches.
(DEF specialization-prefix-drop-fn
  (, (specialization-wait $id $rest $prefix))
  (O (- (specialization-wait $id $rest $prefix))))

(DEF specialization-proposal-fn
  (, (DEF specialization-exhaustive-proposal-fn $all-p $all-t)
     (DEF specialization-prefix-prepare-fn $prep-p $prep-t)
     (DEF specialization-prefix-restore-fn $restore-p $restore-t)
     (DEF specialization-prefix-match-fn $match-p $match-t)
     (DEF specialization-prefix-count-fn $count-p $count-t)
     (DEF specialization-prefix-check-fn $check-p $check-t)
     (DEF specialization-prefix-accept-fn $accept-p $accept-t)
     (DEF specialization-prefix-drop-fn $drop-p $drop-t))
  (O
    (+ (exec (freq f516 specialization-exhaustive-proposal) $all-p $all-t))
    (+ (exec (freq f516 specialization-prefix-prepare) $prep-p $prep-t))
    (+ (exec (freq f517 specialization-prefix-restore) $restore-p $restore-t))
    (+ (exec (freq f518 specialization-prefix-match) $match-p $match-t))
    (+ (exec (freq f519 specialization-prefix-count) $count-p $count-t))
    (+ (exec (freq f520 specialization-prefix-check) $check-p $check-t))
    (+ (exec (freq f521 specialization-prefix-accept) $accept-p $accept-t))
    (+ (exec (freq f522 specialization-prefix-drop) $drop-p $drop-t))))

(DEF specialization-pruning-cleanup-fn
  (, (run-frequent-miner $id $pattern))
  (O
    (+ (cleanup (specialization-mode $id $mode)))
    (+ (cleanup (specialization-template $id $template)))
    (+ (cleanup (specialization-matches $id $prefix $fact)))
    (+ (cleanup (specialization-prefix-query $id $before $prefix $query)))
    (+ (cleanup (specialization-prefix-support $id $rest $prefix $support)))
    (+ (cleanup (specialization-prefix-decision $id $rest $prefix $passes)))
    (+ (cleanup (specialization-wait $id $rest $prefix)))))

; specialization cross-product smoke
; (run-specialization spec-test (Inheritance $x $y))

; (shallow-abstraction-binding spec-test (root (arg 1)) (var 0) Allen)
; (shallow-abstraction-binding spec-test (root (arg 1)) (var 0) Lily)
; (shallow-abstraction-binding spec-test (root (arg 1)) (var 0) (var 0))
; (shallow-abstraction-binding spec-test (root (arg 2)) (var 1) human)
; (shallow-abstraction-binding spec-test (root (arg 2)) (var 1) sodaDrinker)
; (shallow-abstraction-binding spec-test (root (arg 2)) (var 1) (var 1))

; (exec (freq f000 call-specialization-combinations)
;   (, (run-specialization spec-test (Inheritance $x $y))
;      (DEF specialization-combinations-fn $spec-p $spec-t))
;   (O (+ (exec (freq f001 run-specialization-combinations) $spec-p $spec-t))))


; candidate patterns
;
; This stage turns specialization results into frequent candidate patterns.
; `specialization-result` is still indexed, so `var-conversion-fn` first
; converts it back to variables for FACT matching. `support-count-fn` counts
; matching facts and keeps the original display pattern with the count.
; `candidate-pattern-check-fn` compares the support against `INPUT MIN-SUPPORT`.
; Passing patterns are normalized through indices_to_vars/vars_to_indices before
; emitting `candidate-pattern`; that canonicalization collapses equivalent
; variable-renamed candidates before iterative mining sees them.
;
; Request:
;   (specialization-result $id $specialized-pattern)
;   (INPUT MIN-SUPPORT $min-support)
;
; Result:
;   (candidate-pattern $id $indexed-pattern $support)

(DEF var-conversion-fn
  (, (specialization-result $id $specialized-pattern))
  (O
    (pure (candidate-specialization $id $specialized-pattern $converted-pattern) $converted-pattern
      (indices_to_vars (' $specialized-pattern)))))

(DEF support-count-fn
  (, (candidate-specialization $id $display-pattern $match-pattern)
     (FACT $match-pattern))
  (O
    (- (candidate-specialization $id $display-pattern $match-pattern))
    (count (support-count-result $id $display-pattern $count) $count $match-pattern)
    ))

(DEF candidate-pattern-check-fn
  (, (support-count-result $id $pattern $support)
     (INPUT MIN-SUPPORT $min-support)
     (DEF minimum-support-reject-fn $reject-p $reject-t))
  (O
    (pure (minimum-support-check-result $id $pattern $support $min-support $passes) $passes
      (le_f64 (f64_from_string $min-support) (f64_from_string $support)))
    (+ (exec (freq f630 minimum-support-pass)
         (, (minimum-support-check-result $pass-id $pass-pattern $pass-support $pass-min true))
         (O (- (minimum-support-check-result $pass-id $pass-pattern $pass-support $pass-min true))
            (+ (candidate-pattern $pass-id $pass-pattern $pass-support)))))
    (+ (exec (freq f640 minimum-support-reject) $reject-p $reject-t))))

(DEF minimum-support-reject-fn
  (, (minimum-support-check-result $id $pattern $support $min false))
  (O (- (minimum-support-check-result $id $pattern $support $min false))))

(DEF candidate-pattern-fn
  (, (DEF var-conversion-fn $conv-p $conv-t)
     (DEF support-count-fn $support-p $support-t)
     (DEF candidate-pattern-check-fn $min-p $min-t))
  (O
    (+ (exec (freq f610 run-var-conversion) $conv-p $conv-t))
    (+ (exec (freq f620 run-support-count) $support-p $support-t))
    (+ (exec (freq f621 run-candidate-pattern-check) $min-p $min-t))))


; (exec (freq f600 call-candidate-pattern)
;   (, (support-count support-smoke $pattern)
;      (DEF candidate-pattern-fn $candidate-p $candidate-t))
;   (O
;     (+ (exec (freq f601 run-candidate-pattern) $candidate-p $candidate-t))))


; (support-count support-smoke (Inheritance $x sodaDrinker))

; (FACT (Inheritance Allen sodaDrinker))
; (FACT (Inheritance Abe sodaDrinker))
; (FACT (Inheritance Cason sodaDrinker))
; (FACT (Inheritance Casogn sodaDrinker))
; (FACT (Inheritance Casogcn sodaDrinker))
; (FACT (Inheritance Lily ugly))

; (INPUT MIN-SUPPORT 3)

(DEF frequent-miner-cleanup-blocks
  (, (run-frequent-miner $id $pattern))
  (O
    (+ (cleanup (support-count-result $id $support-pattern $support-count)))
    (+ (cleanup (candidate-specialization $id $display-pattern $match-pattern)))
    (+ (cleanup (specialization-result $id $specialized-pattern)))
    (+ (cleanup (specialization-combination $id $combination)))
    (+ (cleanup (specialization-position $id $pos $var)))
    (+ (cleanup (shallow-abstraction-binding $id $path $shallow-var $value)))
    (+ (cleanup (shallow-abstract-expression $sae-id $var $expr)))
    (+ (cleanup (shallow-abstraction-request-expr $id $path $var $value $is-exp)))
    (+ (cleanup (shallow-abstraction-request-var $id $path $var $value $is-var)))
    (+ (cleanup (valuation-binding $id $binding-path $binding-var $binding-value)))
    (+ (cleanup (valuation-pattern $id $valuation-pattern)))
    (+ (cleanup (run-shallow-abstraction $id)))
    (+ (cleanup (run-specialization $id $run-pattern)))
    (+ (cleanup (run-frequent-miner $id $run-pattern)))))

(DEF frequent-miner-cleanup-all-at-once-fn
    (, (cleanup $intermediate-result) $intermediate-result)
    (O
        (- (cleanup $intermediate-result))
        (- $intermediate-result)
        ))

(DEF frequent-miner-cleanup-target-task-fn
  (, (cleanup $fact))
  (O
    (- (cleanup $fact))))

;; Remove the generic cleanup tasks after they are no longer useful.
(DEF frequent-miner-cleanup-all-fn
    (, (DEF specialization-pruning-cleanup-fn $prune-p $prune-t)
       (DEF frequent-miner-cleanup-blocks $blocks-p $blocks-t)
       (DEF frequent-miner-cleanup-all-at-once-fn $all-p $all-t)
       (DEF frequent-miner-cleanup-target-task-fn $target-p $target-t))
    (O
        (+ (exec (freq f700 specialization-pruning-cleanup) $prune-p $prune-t))
        (+ (exec (freq f701 frequent-miner-cleanup-blocks) $blocks-p $blocks-t))
        (+ (exec (freq f702 frequent-miner-cleanup-all-at-once) $all-p $all-t))
        (+ (exec (freq f703 frequent-miner-cleanup-target-task) $target-p $target-t))))

; frequent miner integration
;
; Request:
;   (run-frequent-miner $id $pattern)
;
; Result:
;   (candidate-pattern $id $pattern $support)

(DEF frequent-miner-fn
  (, (run-frequent-miner $id $pattern)
     (DEF valuation-fn $valuation-p $valuation-t)
     (DEF shallow-abstraction-fn $shallow-p $shallow-t)
     (DEF pruned-specialization-combinations-fn $specialization-p $specialization-t)
     (DEF candidate-pattern-fn $candidate-p $candidate-t)
     (DEF frequent-miner-cleanup-all-fn $cleanup-p $cleanup-t))
  (O
    (+ (valuation $id $pattern))
    (+ (run-shallow-abstraction $id))
    (+ (run-specialization $id $pattern))
    (+ (exec (freq f200 frequent-valuation) $valuation-p $valuation-t))
    (+ (exec (freq f350 frequent-shallow-abstraction) $shallow-p $shallow-t))
    (+ (exec (freq f500 frequent-specialization) $specialization-p $specialization-t))
    (+ (exec (freq f600 frequent-candidate-patterns) $candidate-p $candidate-t))
    (+ (exec (freq f700 frequent-miner-cleanup) $cleanup-p $cleanup-t))))

; (exec (freq f000 call-frequent-miner)
;   (, (run-frequent-miner fm-test (Inheritance $x $y))
;      (DEF frequent-miner-fn $freq-p $freq-t))
;   (O
;     (+ (exec (freq f001 run-frequent-miner) $freq-p $freq-t))))

; Compatibility export: preserve the historical public component boundary.
; The iterative implementation remains identical to the optimized module.
;; Recursive frequent-candidate generation.
;;
;; This module consumes `frequent-miner-fn` from candidate-patterns.metta. It keeps
;; generation state private and exposes candidates under the caller's run id.

; nested-expression depth checker
;
; Positive-only continuation check for the iterative miner.
;
; Request:
;   (has-nested-expression-with-respect-to $id $parent $candidate)
;
; Result, emitted only when a deeper candidate position is found:
;   (has-nested-expression-result $id $parent $candidate true)
;
; Stop behavior:
;   Every step requires (hne-active $id). The first true removes hne-active,
;   so remaining queued checks for the same id cannot continue.
(DEF has-nested-expression-step
  (, (hne-active $id)
     (DEF has-nested-expression-dispatch $dispatch-p $dispatch-t))
  (O
    (+ (exec (freq f800 hne-empty-parent)
         (, (hne-active $empty-id)
            (hne-check $empty-id () $empty-candidate))
         (O
           (- (hne-check $empty-id () $empty-candidate)))))

    (+ (exec (freq f801 hne-split)
         (, (hne-active $split-id)
            (hne-check $split-id $parent $candidate))
         (O
           (- (hne-check $split-id $parent $candidate))
           (pure (hne-parent-head $split-id $parent $candidate $parent-head)
             $parent-head (car-atom (' $parent)))
           (pure (hne-candidate-head $split-id $parent $candidate $candidate-head)
             $candidate-head (car-atom (' $candidate)))
           (pure (hne-parent-tail $split-id $parent $candidate $parent-tail)
             $parent-tail (cdr-atom (' $parent)))
           (pure (hne-candidate-tail $split-id $parent $candidate $candidate-tail)
             $candidate-tail (cdr-atom (' $candidate)))
           (+ (hne-dispatch $split-id $parent $candidate))
           (+ (exec (freq f810 hne-dispatch) $dispatch-p $dispatch-t)))))))

(DEF has-nested-expression-dispatch
  (, (hne-active $id)
     (hne-dispatch $id $parent $candidate)
     (hne-parent-head $id $parent $candidate $parent-head)
     (hne-candidate-head $id $parent $candidate $candidate-head)
     (hne-parent-tail $id $parent $candidate $parent-tail)
     (hne-candidate-tail $id $parent $candidate $candidate-tail)
     (DEF has-nested-expression-decide $decide-p $decide-t))
  (O
    (- (hne-dispatch $id $parent $candidate))
    (- (hne-parent-head $id $parent $candidate $parent-head))
    (- (hne-candidate-head $id $parent $candidate $candidate-head))
    (- (hne-parent-tail $id $parent $candidate $parent-tail))
    (- (hne-candidate-tail $id $parent $candidate $candidate-tail))
    (pure (hne-parent-head-var $id $parent $candidate $parent-head $is-parent-var)
      $is-parent-var (i8_to_string (is_var (' $parent-head))))
    (pure (hne-parent-head-exp $id $parent $candidate $parent-head $is-parent-exp)
      $is-parent-exp (i8_to_string (is_exp (' $parent-head))))
    (pure (hne-candidate-head-exp $id $parent $candidate $candidate-head $is-candidate-exp)
      $is-candidate-exp (i8_to_string (is_exp (' $candidate-head))))
    (+ (hne-decision $id $parent $candidate $parent-head $candidate-head $parent-tail $candidate-tail))
    (+ (exec (freq f820 hne-decide) $decide-p $decide-t))))

(DEF has-nested-expression-decide
  (, (DEF has-nested-expression-step $step-p $step-t))
  (O
    (+ (exec (freq f820 hne-found)
         (, (hne-active $found-id)
            (hne-decision $found-id $found-parent $found-candidate $found-parent-head $found-candidate-head $found-parent-tail $found-candidate-tail)
            (hne-parent-head-var $found-id $found-parent $found-candidate $found-parent-head 1)
            (hne-candidate-head-exp $found-id $found-parent $found-candidate $found-candidate-head 1)
            (hne-top $found-id $top-parent $top-candidate))
         (O
           (- (hne-active $found-id))
           (- (hne-decision $found-id $found-parent $found-candidate $found-parent-head $found-candidate-head $found-parent-tail $found-candidate-tail))
           (- (hne-parent-head-var $found-id $found-parent $found-candidate $found-parent-head 1))
           (- (hne-candidate-head-exp $found-id $found-parent $found-candidate $found-candidate-head 1))
           (- (hne-top $found-id $top-parent $top-candidate))
           (+ (has-nested-expression-result $found-id $top-parent $top-candidate true)))))

    (+ (exec (freq f821 hne-var-flat-continue-tail)
         (, (hne-active $flat-id)
            (hne-decision $flat-id $flat-parent $flat-candidate $flat-parent-head $flat-candidate-head $flat-parent-tail $flat-candidate-tail)
            (hne-parent-head-var $flat-id $flat-parent $flat-candidate $flat-parent-head 1)
            (hne-candidate-head-exp $flat-id $flat-parent $flat-candidate $flat-candidate-head 0))
         (O
           (- (hne-decision $flat-id $flat-parent $flat-candidate $flat-parent-head $flat-candidate-head $flat-parent-tail $flat-candidate-tail))
           (- (hne-parent-head-var $flat-id $flat-parent $flat-candidate $flat-parent-head 1))
           (- (hne-candidate-head-exp $flat-id $flat-parent $flat-candidate $flat-candidate-head 0))
           (+ (hne-check $flat-id $flat-parent-tail $flat-candidate-tail))
           (+ (exec (freq f800 hne-step) $step-p $step-t)))))

    (+ (exec (freq f822 hne-expression-recurse-and-tail)
         (, (hne-active $expr-id)
            (hne-decision $expr-id $expr-parent $expr-candidate $expr-parent-head $expr-candidate-head $expr-parent-tail $expr-candidate-tail)
            (hne-parent-head-var $expr-id $expr-parent $expr-candidate $expr-parent-head 0)
            (hne-parent-head-exp $expr-id $expr-parent $expr-candidate $expr-parent-head 1)
            (hne-candidate-head-exp $expr-id $expr-parent $expr-candidate $expr-candidate-head 1))
         (O
           (- (hne-decision $expr-id $expr-parent $expr-candidate $expr-parent-head $expr-candidate-head $expr-parent-tail $expr-candidate-tail))
           (- (hne-parent-head-var $expr-id $expr-parent $expr-candidate $expr-parent-head 0))
           (- (hne-parent-head-exp $expr-id $expr-parent $expr-candidate $expr-parent-head 1))
           (- (hne-candidate-head-exp $expr-id $expr-parent $expr-candidate $expr-candidate-head 1))
           (+ (hne-check $expr-id $expr-parent-head $expr-candidate-head))
           (+ (hne-check $expr-id $expr-parent-tail $expr-candidate-tail))
           (+ (exec (freq f800 hne-step) $step-p $step-t)))))

    (+ (exec (freq f824 hne-atom-continue-tail)
         (, (hne-active $atom-id)
            (hne-decision $atom-id $atom-parent $atom-candidate $atom-parent-head $atom-candidate-head $atom-parent-tail $atom-candidate-tail)
            (hne-parent-head-var $atom-id $atom-parent $atom-candidate $atom-parent-head 0)
            (hne-parent-head-exp $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
         (O
           (- (hne-decision $atom-id $atom-parent $atom-candidate $atom-parent-head $atom-candidate-head $atom-parent-tail $atom-candidate-tail))
           (- (hne-parent-head-var $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
           (- (hne-parent-head-exp $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
           (+ (hne-check $atom-id $atom-parent-tail $atom-candidate-tail))
           (+ (exec (freq f800 hne-step) $step-p $step-t)))))))

(DEF has-nested-expression-with-respect-to-fn
  (, (has-nested-expression-with-respect-to $id $parent $candidate)
     (DEF has-nested-expression-step $step-p $step-t))
  (O
    (- (has-nested-expression-with-respect-to $id $parent $candidate))
    (+ (hne-active $id))
    (+ (hne-top $id $parent $candidate))
    (+ (hne-check $id $parent $candidate))
    (+ (exec (freq f800 hne-step) $step-p $step-t))))

; Remove HNE scratch facts after an iterative candidate has been checked.
; The positive result is intentionally kept for the iterator continuation stage.
(DEF hne-cleanup-blocks
  (, (hne-cleanup $id))
  (O
    (- (hne-cleanup $id))
    (+ (hne-cleanup-target (hne-active $id)))
    (+ (hne-cleanup-target (hne-top $id $parent $candidate)))
    (+ (hne-cleanup-target (hne-check $id $parent $candidate)))
    (+ (hne-cleanup-target (hne-dispatch $id $parent $candidate)))
    (+ (hne-cleanup-target (hne-decision $id $parent $candidate $parent-head $candidate-head $parent-tail $candidate-tail)))
    (+ (hne-cleanup-target (hne-parent-head $id $parent $candidate $parent-head)))
    (+ (hne-cleanup-target (hne-candidate-head $id $parent $candidate $candidate-head)))
    (+ (hne-cleanup-target (hne-parent-tail $id $parent $candidate $parent-tail)))
    (+ (hne-cleanup-target (hne-candidate-tail $id $parent $candidate $candidate-tail)))
    (+ (hne-cleanup-target (hne-parent-head-var $id $parent $candidate $parent-head $is-parent-var)))
    (+ (hne-cleanup-target (hne-parent-head-exp $id $parent $candidate $parent-head $is-parent-exp)))
    (+ (hne-cleanup-target (hne-candidate-head-exp $id $parent $candidate $candidate-head $is-candidate-exp)))))

(DEF hne-cleanup-target-fn
  (, (hne-cleanup-target $fact) $fact)
  (O
    (- (hne-cleanup-target $fact))
    (- $fact)))

(DEF hne-cleanup-target-task-fn
  (, (hne-cleanup-target $fact))
  (O
    (- (hne-cleanup-target $fact))))

(DEF hne-cleanup-fn
  (, (DEF hne-cleanup-blocks $blocks-p $blocks-t)
     (DEF hne-cleanup-target-fn $target-p $target-t)
     (DEF hne-cleanup-target-task-fn $task-p $task-t))
  (O
    (+ (exec (freq f910 hne-cleanup-blocks) $blocks-p $blocks-t))
    (+ (exec (freq f911 hne-cleanup-targets) $target-p $target-t))
    (+ (exec (freq f912 hne-cleanup-target-tasks) $task-p $task-t))))

; iterative miner
;
; Runs one frequent-miner generation, checks each candidate against its parent,
; then recursively mines candidates that introduce nested depth.
;
; Public request:
;   (run-iterative-miner $id $pattern)
;
; Public results:
;   (iterative-candidate-pattern $id $parent $candidate $support)
;   (iterative-recursive-candidate $id $parent $candidate $support)
;
; Each generation uses an indexed parent in its internal id. This keeps
; candidate facts from different recursive parents isolated while preserving
; the caller-owned run id in public results.
(DEF iterative-miner-candidate-step
  (, (iter-parent $id $parent $indexed-parent $miner-id)
     (candidate-pattern $miner-id $candidate $support)
     (DEF has-nested-expression-with-respect-to-fn $hne-p $hne-t)
     (DEF iterative-miner-continue-fn $continue-p $continue-t)
     (DEF hne-cleanup-fn $cleanup-p $cleanup-t))
  (O
    (- (candidate-pattern $miner-id $candidate $support))
    (+ (iterative-candidate-pattern $id $parent $candidate $support))
    (+ (has-nested-expression-with-respect-to
      (HNE $miner-id $candidate) $indexed-parent $candidate))
    (+ (hne-cleanup (HNE $miner-id $candidate)))
    (+ (exec (freq f900 iterative-check-depth) $hne-p $hne-t))
    (+ (exec (freq f950 iterative-continue) $continue-p $continue-t))
    (+ (exec (freq f960 iterative-hne-cleanup) $cleanup-p $cleanup-t))))

(DEF iterative-miner-continue-fn
  (, (iter-parent $id $parent $indexed-parent $miner-id)
     (iterative-candidate-pattern $id $parent $candidate $support)
     (has-nested-expression-result
       (HNE $miner-id $candidate) $indexed-parent $candidate true)
     (DEF iterative-miner-fn $iter-p $iter-t))
  (O
    (- (has-nested-expression-result
      (HNE $miner-id $candidate) $indexed-parent $candidate true))
    (+ (iterative-recursive-candidate $id $parent $candidate $support))
    (pure (run-iterative-miner $id $next-pattern) $next-pattern
      (indices_to_vars (' $candidate)))
    (+ (exec (freq f000 iterative-run-next) $iter-p $iter-t))))

(DEF iterative-parent-cleanup-fn
  (, (iter-parent $id $parent $indexed-parent $miner-id))
  (O
    (- (iter-parent $id $parent $indexed-parent $miner-id))))

(DEF iterative-miner-generation-start-fn
  (, (iter-generation-ready $id $indexed-parent $parent)
     (DEF frequent-miner-fn $freq-p $freq-t)
     (DEF iterative-miner-candidate-step $candidate-p $candidate-t)
     (DEF iterative-parent-cleanup-fn $parent-cleanup-p $parent-cleanup-t))
  (O
    (- (iter-generation-ready $id $indexed-parent $parent))
    (+ (iter-parent
      $id $parent $indexed-parent (ITER $id $indexed-parent)))
    (+ (run-frequent-miner (ITER $id $indexed-parent) $parent))
    (+ (exec (freq f100 iterative-run-generation) $freq-p $freq-t))
    (+ (exec (freq f850 iterative-check-candidates) $candidate-p $candidate-t))
    (+ (exec (freq f970 iterative-parent-cleanup)
      $parent-cleanup-p $parent-cleanup-t))))

;; Rebuild the display/matching pattern in its own pure step. Keeping raw MORK
;; variables out of iter-generation makes the generation key stable and ground.
(DEF iterative-miner-generation-restore-fn
  (, (iter-generation $id $indexed-parent)
     (DEF iterative-miner-generation-start-fn $start-p $start-t))
  (O
    (- (iter-generation $id $indexed-parent))
    (pure (iter-generation-ready $id $indexed-parent $parent) $parent
      (indices_to_vars (' $indexed-parent)))
    (+ (exec (freq f095 iterative-start-generation) $start-p $start-t))))

(DEF iterative-miner-fn
  (, (run-iterative-miner $id $pattern)
     (DEF iterative-miner-generation-restore-fn $restore-p $restore-t))
  (O
    (- (run-iterative-miner $id $pattern))
    (pure (iter-generation $id $indexed-pattern) $indexed-pattern
      (vars_to_indices (' $pattern)))
    (+ (exec (freq f090 iterative-restore-generation)
      $restore-p $restore-t))))
