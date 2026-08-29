;; Standalone conjunction expansion for triplet patterns.
;;
;; Inputs:
;;   (INPUT MIN-SUPPORT n)
;;   (INPUT MAX-SIZE n)
;;   (pattern 0 ($predicate $left $right))
;;
;; Database triplets are active facts in the same atomspace.
;;
;; Public output:
;;   (expanded-conjunct $size $indexed-candidate $support)
;;
;; Flow:
;;   normalize seeds -> count support -> filter -> build connected variants
;;   -> canonicalize -> queue the next size
;;
;; All `ce-*` facts are private pipeline state. This file has no dependency on
;; frequent-miner.metta; it uses the shared `freq` priority namespace required
;; by docs/data-model.md.

;; Count a queued candidate through common-utils, then install the later stages
;; needed by the same cycle. Splitting request/count scheduling from the
;; remaining stages keeps substituted DEF bodies below MORK's 64-variable limit.
(DEF ce-support-fn
  (, (ce-pending $size $candidate)
     (DEF ce-request-count-fn $request-p $request-t)
     (DEF ce-schedule-cycle-fn $cycle-p $cycle-t))
  (O
    (- (ce-pending $size $candidate))
    (+ (ce-count-work $size $candidate))
    (+ (ce-support-cycle $size $candidate))
    (+ (exec (freq 105 request-count) $request-p $request-t))
    (+ (exec (freq 106 schedule-cycle) $cycle-p $cycle-t))))

(DEF ce-request-count-fn
  (, (ce-count-work $size $candidate)
     ((count-indexed-conjunction-support
        $size $candidate (freq 111 count-support) -> ce-support)
       $count-p $count-t))
  (O
    (+ (count-indexed-conjunction-support-request
      $size $candidate (freq 111 count-support) ce-support))
    (+ (exec (freq 110 build-count-query) $count-p $count-t))
    (- (ce-count-work $size $candidate))))

(DEF ce-schedule-cycle-fn
  (, (ce-support-cycle $size $candidate)
     (DEF ce-schedule-filter-fn $filter-p $filter-t)
     (DEF ce-schedule-depth-fn $depth-p $depth-t)
     (DEF ce-build-fn $build-p $build-t)
     (DEF ce-schedule-candidate-fn $candidate-p $candidate-t))
  (O
    (+ (exec (freq 120 schedule-filter) $filter-p $filter-t))
    (+ (exec (freq 200 schedule-depth) $depth-p $depth-t))
    (+ (exec (freq 300 schedule-build) $build-p $build-t))
    (+ (exec (freq 500 schedule-candidate) $candidate-p $candidate-t))
    (- (ce-support-cycle $size $candidate))))

;; Support filtering.
(DEF ce-schedule-filter-fn
  (, (ce-support $size $candidate $support)
     (DEF ce-support-pass-fn $pass-p $pass-t)
     (DEF ce-save-pass-fn $save-p $save-t)
     ((drop-matched
        (ce-support-pass (ce-candidate $size $candidate) $support false)
        -> removed)
      $drop-p $drop-t))
  (O
    (+ (exec (freq 130 check-support) $pass-p $pass-t))
    (+ (exec (freq 140 save-frequent) $save-p $save-t))
    (+ (exec (freq 141 drop-infrequent) $drop-p $drop-t))))

(DEF ce-support-pass-fn
  (, (ce-support $size $candidate $support)
     (INPUT MIN-SUPPORT $threshold)
     ((support-at-least
        (ce-candidate $size $candidate) $support $threshold -> ce-support-pass)
       $pass-p $pass-t))
  (O
    (+ (support-at-least-request
      (ce-candidate $size $candidate) $support $threshold ce-support-pass))
    (+ (exec (freq 131 evaluate-support) $pass-p $pass-t))
    (- (ce-support $size $candidate $support))))

(DEF ce-save-pass-fn
  (, (ce-support-pass (ce-candidate $size $candidate) $support true))
  (O
    (+ (expanded-conjunct $size $candidate $support))
    (+ (ce-expand-check $size $candidate))
    (- (ce-support-pass (ce-candidate $size $candidate) $support true))))

;; Only frequent candidates below MAX-SIZE are expanded.
(DEF ce-schedule-depth-fn
  (, (ce-expand-check $size $candidate)
     (DEF ce-expand-pass-fn $pass-p $pass-t)
     ((replace-matched
        (ce-expand-pass $size $candidate true)
        (ce-expand-todo $size $candidate) -> replaced)
      $todo-p $todo-t)
     ((drop-matched (ce-expand-pass $size $candidate false) -> removed)
      $drop-p $drop-t))
  (O
    (+ (exec (freq 210 check-depth) $pass-p $pass-t))
    (+ (exec (freq 220 queue-expansion) $todo-p $todo-t))
    (+ (exec (freq 221 stop-expansion) $drop-p $drop-t))))

(DEF ce-expand-pass-fn
  (, (ce-expand-check $size $candidate)
     (INPUT MAX-SIZE $max-size))
  (O
    (pure
      (ce-expand-pass $size $candidate $pass)
      $pass
      (lt_i32 (i32_from_string $size) (i32_from_string $max-size)))
    (- (ce-expand-check $size $candidate))))

;; Candidate construction is split into small schedulers because inlining all
;; DEF bodies into one rule exceeds MORK's variable limit.
(DEF ce-build-fn
  (, (ce-expand-todo $old-size $conjunct)
     (DEF ce-schedule-scan-fn $scan-p $scan-t)
     (DEF ce-schedule-classify-fn $classify-p $classify-t)
     (DEF ce-schedule-choice-fn $choice-p $choice-t)
     (DEF ce-schedule-map-fn $map-p $map-t))
  (O
    (+ (exec (freq 310 schedule-scan) $scan-p $scan-t))
    (+ (exec (freq 350 schedule-classify) $classify-p $classify-t))
    (+ (exec (freq 370 schedule-choice) $choice-p $choice-t))
    (+ (exec (freq 400 schedule-map) $map-p $map-t))))

;; Pair each expandable conjunction with every normalized base, start its
;; shape classification, and scan the conjunction's atoms.
(DEF ce-schedule-scan-fn
  (, (ce-expand-todo $old-size $conjunct)
     ((emit-from-matches-2
        (ce-expand-todo $old-size $conjunct)
        (ce-base $base)
        (ce-expand-pair $old-size $conjunct $base) -> emitted)
      $pair-p $pair-t)
     (DEF ce-pair-details-fn $details-p $details-t)
     (DEF ce-scan-fn $scan-p $scan-t))
  (O
    (+ (exec (freq 320 pair-base) $pair-p $pair-t))
    (+ (exec (freq 330 inspect-pair) $details-p $details-t))
    (+ (exec (freq 340 scan-conjunct) $scan-p $scan-t))))

(DEF ce-pair-details-fn
  (, (ce-expand-todo $old-size $conjunct)
     (ce-expand-pair $old-size $conjunct
       ($predicate $base-left $base-right)))
  (O
    (+ (ce-scan $old-size $conjunct
      ($predicate $base-left $base-right) $conjunct))
    (pure
      (ce-base-shape-left $old-size $conjunct
        ($predicate $base-left $base-right) $is-var)
      $is-var
      (i8_to_string (is_var (' $base-left))))
    (- (ce-expand-pair $old-size $conjunct
      ($predicate $base-left $base-right)))))

(DEF ce-scan-fn
  (, (ce-expand-todo $old-size $conjunct)
     (ce-scan $old-size $conjunct $base $remaining)
     (DEF ce-scan-fn $scan-p $scan-t))
  (O
    (pure
      (ce-conjunct-atom $old-size $conjunct $base $atom)
      $atom
      (car-atom (' $remaining)))
    (pure
      (ce-scan $old-size $conjunct $base $rest)
      $rest
      (cdr-atom (' $remaining)))
    (- (ce-scan $old-size $conjunct $base $remaining))
    (+ (exec (freq 340 scan-conjunct) $scan-p $scan-t))))

;; Indexed variables in either triplet slot become existing choices. Facts are
;; removed only after both slot rules have seen them.
(DEF ce-schedule-classify-fn
  (, (ce-expand-todo $old-size $conjunct)
     ((emit-from-matches-2
        (ce-expand-todo $old-size $conjunct)
        (ce-conjunct-atom $old-size $conjunct $base
          ($predicate (var $index) $right))
        (cleanup-wrapper
          (ce-var-choice $old-size $conjunct
            $base (var $index) existing)) -> emitted)
      $left-p $left-t)
     ((emit-from-matches-2
        (ce-expand-todo $old-size $conjunct)
        (ce-conjunct-atom $old-size $conjunct $base
          ($predicate $left (var $index)))
        (cleanup-wrapper
          (ce-var-choice $old-size $conjunct
            $base (var $index) existing)) -> emitted)
      $right-p $right-t)
     (DEF ce-complete-base-shape-fn $shape-p $shape-t)
     ((drop-matched
        (ce-conjunct-atom $old-size $conjunct $base $atom) -> removed)
      $drop-p $drop-t))
  (O
    (+ (exec (freq 351 left-choice) $left-p $left-t))
    (+ (exec (freq 352 right-choice) $right-p $right-t))
    (+ (exec (freq 353 complete-base-shape) $shape-p $shape-t))
    (+ (exec (freq 354 drop-scanned-atom) $drop-p $drop-t))))

(DEF ce-complete-base-shape-fn
  (, (ce-expand-todo $old-size $conjunct)
     (ce-base-shape-left $old-size $conjunct
       ($predicate $base-left $base-right) $left-is-var))
  (O
    (pure
      (cleanup-wrapper
        (ce-base-shape $old-size $conjunct
          ($predicate $base-left $base-right) $left-is-var $right-is-var))
      $right-is-var
      (i8_to_string (is_var (' $base-right))))
    (- (ce-base-shape-left $old-size $conjunct
      ($predicate $base-left $base-right) $left-is-var))))

;; Contiguous variable indices make max+1 available by proposing every
;; existing successor and deleting proposals that are already existing.
(DEF ce-schedule-choice-fn
  (, (ce-expand-todo $old-size $conjunct)
     (DEF ce-fresh-candidate-fn $fresh-p $fresh-t)
     (DEF ce-drop-used-fresh-fn $drop-p $drop-t)
     ((replace-matched
        (ce-fresh-candidate $old-size $conjunct $base $fresh)
        (cleanup-wrapper
          (ce-var-choice $old-size $conjunct
            $base $fresh fresh)) -> replaced)
      $save-p $save-t)
     (DEF ce-source-relation-fn $relation-p $relation-t))
  (O
    (+ (exec (freq 371 propose-fresh) $fresh-p $fresh-t))
    (+ (exec (freq 372 drop-used-fresh) $drop-p $drop-t))
    (+ (exec (freq 373 save-fresh) $save-p $save-t))
    (+ (exec (freq 374 source-relation) $relation-p $relation-t))))

(DEF ce-fresh-candidate-fn
  (, (ce-expand-todo $old-size $conjunct)
     (cleanup-wrapper
       (ce-var-choice $old-size $conjunct $base (var $index) existing)))
  (O
    (pure
      (ce-fresh-candidate $old-size $conjunct $base (var $next))
      $next
      (i32_to_string (sum_i32 (i32_from_string $index) (i32_one))))))

(DEF ce-drop-used-fresh-fn
  (, (ce-expand-todo $old-size $conjunct)
     (ce-fresh-candidate $old-size $conjunct $base $candidate)
     (cleanup-wrapper
       (ce-var-choice $old-size $conjunct $base $candidate existing)))
  (O (- (ce-fresh-candidate $old-size $conjunct $base $candidate))))

;; Repeated source variables must remain equal after mapping.
(DEF ce-source-relation-fn
  (, (ce-expand-todo $old-size $conjunct)
     (cleanup-wrapper
       (ce-base-shape $old-size $conjunct
         ($predicate (var $left) (var $right)) 1 1)))
  (O
    (pure
      (cleanup-wrapper (ce-source-same $old-size $conjunct
        ($predicate (var $left) (var $right)) $same))
      $same
      (eq_i32 (i32_from_string $left) (i32_from_string $right)))))

;; Generate only connected mappings. This avoids the previous truth table,
;; connectivity facts, pass/drop rules, and disconnected intermediates.
(DEF ce-schedule-map-fn
  (, (ce-expand-todo $old-size $conjunct)
     ((emit-from-matches-3
        (ce-expand-todo $old-size $conjunct)
        (cleanup-wrapper (ce-source-same $old-size $conjunct
          ($predicate $source-left $source-right) true))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source-left $source-right) $out existing))
        (ce-connected-base $old-size $conjunct
          ($predicate $out $out)) -> emitted)
      $same-p $same-t)
     ((emit-from-matches-4
        (ce-expand-todo $old-size $conjunct)
        (cleanup-wrapper (ce-source-same $old-size $conjunct
          ($predicate $source-left $source-right) false))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source-left $source-right) $left-out existing))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source-left $source-right) $right-out $right-kind))
        (ce-connected-base $old-size $conjunct
          ($predicate $left-out $right-out)) -> emitted)
      $left-p $left-t)
     ((emit-from-matches-4
        (ce-expand-todo $old-size $conjunct)
        (cleanup-wrapper (ce-source-same $old-size $conjunct
          ($predicate $source-left $source-right) false))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source-left $source-right) $left-out fresh))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source-left $source-right) $right-out existing))
        (ce-connected-base $old-size $conjunct
          ($predicate $left-out $right-out)) -> emitted)
      $right-p $right-t)
     ((emit-from-matches-3
        (ce-expand-todo $old-size $conjunct)
        (cleanup-wrapper (ce-base-shape $old-size $conjunct
          ($predicate $source $constant) 1 0))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $source $constant) $out existing))
        (ce-connected-base $old-size $conjunct
          ($predicate $out $constant)) -> emitted)
      $left-slot-p $left-slot-t)
     ((emit-from-matches-3
        (ce-expand-todo $old-size $conjunct)
        (cleanup-wrapper (ce-base-shape $old-size $conjunct
          ($predicate $constant $source) 0 1))
        (cleanup-wrapper (ce-var-choice $old-size $conjunct
          ($predicate $constant $source) $out existing))
        (ce-connected-base $old-size $conjunct
          ($predicate $constant $out)) -> emitted)
      $right-slot-p $right-slot-t)
     (DEF ce-build-candidate-fn $candidate-p $candidate-t)
     ((drop-matched (cleanup-wrapper $fact) -> removed)
      $clean-p $clean-t)
     ((drop-matched
        (ce-expand-todo $old-size $conjunct) -> removed)
      $finish-p $finish-t))
  (O
    (+ (exec (freq 410 map-same-source) $same-p $same-t))
    (+ (exec (freq 411 map-distinct-left) $left-p $left-t))
    (+ (exec (freq 412 map-distinct-right) $right-p $right-t))
    (+ (exec (freq 413 map-left-slot) $left-slot-p $left-slot-t))
    (+ (exec (freq 414 map-right-slot) $right-slot-p $right-slot-t))
    (+ (exec (freq 420 build-candidate) $candidate-p $candidate-t))
    (+ (exec (freq 430 cleanup-build) $clean-p $clean-t))
    (+ (exec (freq 431 finish-build) $finish-p $finish-t))))

;; Build the raw union. The shared canonicalization callable keeps the later
;; grounded transformations separate because quoted list results cannot safely
;; be piped through nested MM2 calls.
(DEF ce-build-candidate-fn
  (, (ce-expand-todo $old-size $conjunct)
     (ce-connected-base $old-size $conjunct $base))
  (O
    (pure
      (ce-raw-candidate $old-size $raw)
      $raw
      (union-atom (' (($base) $conjunct))))
    (- (ce-connected-base $old-size $conjunct $base))))

;; Durable build state stays inside generic cleanup wrappers. The shared
;; drop-matched callable removes those wrappers after mapping has completed.

;; Reject duplicate/non-growing or oversized candidates, then start the next
;; support cycle for every candidate that passed.
(DEF ce-schedule-candidate-fn
  (, (ce-raw-candidate $old-size $raw)
     ((canonicalize-indexed-conjunction
        (ce-raw-candidate $old-size $raw)
        $old-size $raw
        (freq 502 candidate-to-vars)
        (freq 503 alpha-normalize) -> ce-candidate)
      $canonical-p $canonical-t)
     ((conjunction-size
        (ce-candidate $old-size $candidate)
        $old-size $candidate -> ce-candidate-size)
      $size-p $size-t)
     (DEF ce-candidate-pass-fn $pass-p $pass-t)
     (DEF ce-queue-candidate-fn $queue-p $queue-t)
     ((drop-matched (ce-candidate-pass $candidate $size false) -> removed)
      $drop-p $drop-t))
  (O
    (+ (exec (freq 501 canonicalize-candidate) $canonical-p $canonical-t))
    (+ (exec (freq 510 candidate-size) $size-p $size-t))
    (+ (exec (freq 520 check-candidate) $pass-p $pass-t))
    (+ (exec (freq 530 queue-candidate) $queue-p $queue-t))
    (+ (exec (freq 531 drop-candidate) $drop-p $drop-t))))

(DEF ce-candidate-pass-fn
  (, (ce-candidate-size $old-size $candidate $size)
     (INPUT MAX-SIZE $max-size))
  (O
    (pure
      (ce-candidate-pass $candidate $size $pass)
      $pass
      (and_bool
        (le_i32 (i32_from_string $size) (i32_from_string $max-size))
        (gt_i32 (i32_from_string $size) (i32_from_string $old-size))))
    (- (ce-candidate-size $old-size $candidate $size))))

(DEF ce-queue-candidate-fn
  (, (ce-candidate-pass $candidate $size true)
     (DEF ce-support-fn $support-p $support-t))
  (O
    (+ (ce-pending $size $candidate))
    (+ (exec (freq 100 support-cycle) $support-p $support-t))
    (- (ce-candidate-pass $candidate $size true))))

;; Normalize all seed patterns before starting the first support cycle.
(exec (freq 010 normalize-seeds)
  (, (pattern 0 $pattern))
  (O
    (pure
      (ce-base $base)
      $base
      (vars_to_indices (' $pattern)))
    (pure
      (ce-pending 1 ($base))
      $base
      (vars_to_indices (' $pattern)))))

(exec (freq 020 start)
  (, (DEF ce-support-fn $support-p $support-t))
  (O (+ (exec (freq 100 support-cycle) $support-p $support-t))))

;; Bases are derived input, not output. Priority 900 runs only after all
;; recursively queued mining cycles have finished.
(exec (freq 900 cleanup-bases)
  (, (ce-base $base))
  (O (- (ce-base $base))))
