;; Recursive frequent-candidate generation.
;;
;; This module consumes `frequent-miner-fn` from frequent-miner.metta. It keeps
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
    (+ (exec (freq 800 hne-empty-parent)
         (, (hne-active $empty-id)
            (hne-check $empty-id () $empty-candidate))
         (O
           (- (hne-check $empty-id () $empty-candidate)))))

    (+ (exec (freq 801 hne-split)
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
           (+ (exec (freq 810 hne-dispatch) $dispatch-p $dispatch-t)))))))

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
    (+ (exec (freq 820 hne-decide) $decide-p $decide-t))))

(DEF has-nested-expression-decide
  (, (DEF has-nested-expression-step $step-p $step-t))
  (O
    (+ (exec (freq 820 hne-found)
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

    (+ (exec (freq 821 hne-var-flat-continue-tail)
         (, (hne-active $flat-id)
            (hne-decision $flat-id $flat-parent $flat-candidate $flat-parent-head $flat-candidate-head $flat-parent-tail $flat-candidate-tail)
            (hne-parent-head-var $flat-id $flat-parent $flat-candidate $flat-parent-head 1)
            (hne-candidate-head-exp $flat-id $flat-parent $flat-candidate $flat-candidate-head 0))
         (O
           (- (hne-decision $flat-id $flat-parent $flat-candidate $flat-parent-head $flat-candidate-head $flat-parent-tail $flat-candidate-tail))
           (- (hne-parent-head-var $flat-id $flat-parent $flat-candidate $flat-parent-head 1))
           (- (hne-candidate-head-exp $flat-id $flat-parent $flat-candidate $flat-candidate-head 0))
           (+ (hne-check $flat-id $flat-parent-tail $flat-candidate-tail))
           (+ (exec (freq 800 hne-step) $step-p $step-t)))))

    (+ (exec (freq 822 hne-expression-recurse-and-tail)
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
           (+ (exec (freq 800 hne-step) $step-p $step-t)))))

    (+ (exec (freq 824 hne-atom-continue-tail)
         (, (hne-active $atom-id)
            (hne-decision $atom-id $atom-parent $atom-candidate $atom-parent-head $atom-candidate-head $atom-parent-tail $atom-candidate-tail)
            (hne-parent-head-var $atom-id $atom-parent $atom-candidate $atom-parent-head 0)
            (hne-parent-head-exp $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
         (O
           (- (hne-decision $atom-id $atom-parent $atom-candidate $atom-parent-head $atom-candidate-head $atom-parent-tail $atom-candidate-tail))
           (- (hne-parent-head-var $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
           (- (hne-parent-head-exp $atom-id $atom-parent $atom-candidate $atom-parent-head 0))
           (+ (hne-check $atom-id $atom-parent-tail $atom-candidate-tail))
           (+ (exec (freq 800 hne-step) $step-p $step-t)))))))

(DEF has-nested-expression-with-respect-to-fn
  (, (has-nested-expression-with-respect-to $id $parent $candidate)
     (DEF has-nested-expression-step $step-p $step-t))
  (O
    (- (has-nested-expression-with-respect-to $id $parent $candidate))
    (+ (hne-active $id))
    (+ (hne-top $id $parent $candidate))
    (+ (hne-check $id $parent $candidate))
    (+ (exec (freq 800 hne-step) $step-p $step-t))))

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
    (+ (exec (freq 910 hne-cleanup-blocks) $blocks-p $blocks-t))
    (+ (exec (freq 911 hne-cleanup-targets) $target-p $target-t))
    (+ (exec (freq 912 hne-cleanup-target-tasks) $task-p $task-t))))

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
    (+ (exec (freq 900 iterative-check-depth) $hne-p $hne-t))
    (+ (exec (freq 950 iterative-continue) $continue-p $continue-t))
    (+ (exec (freq 960 iterative-hne-cleanup) $cleanup-p $cleanup-t))))

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
    (+ (exec (freq 000 iterative-run-next) $iter-p $iter-t))))

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
    (+ (exec (freq 100 iterative-run-generation) $freq-p $freq-t))
    (+ (exec (freq 850 iterative-check-candidates) $candidate-p $candidate-t))
    (+ (exec (freq 970 iterative-parent-cleanup)
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
    (+ (exec (freq 095 iterative-start-generation) $start-p $start-t))))

(DEF iterative-miner-fn
  (, (run-iterative-miner $id $pattern)
     (DEF iterative-miner-generation-restore-fn $restore-p $restore-t))
  (O
    (- (run-iterative-miner $id $pattern))
    (pure (iter-generation $id $indexed-pattern) $indexed-pattern
      (vars_to_indices (' $pattern)))
    (+ (exec (freq 090 iterative-restore-generation)
      $restore-p $restore-t))))
