;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Surprisingness dispatcher and input normalization
;;
;; This module selects the configured surprisingness implementation, prepares
;; its input, and exposes a common result consumed by pattern-miner.
;;
;; Responsibilities:
;;
;;   1. Dispatch `(do-surp)` according to `INPUT SURP-MODE`.
;;   2. Accept indexed patterns from the frequent miner without indexing them
;;      again.
;;   3. Normalize raw standalone pattern variables into indexed markers:
;;
;;        $x, $y, ... -> (var 0), (var 1), ...
;;
;; Generated partitions need stable variable identity across blocks.  Later,
;; `indices_to_vars` converts these markers back into real MM2 variables for
;; support-count queries.
;;
;; The canonical indexed pattern is the owner id for all intermediate values
;; produced by the modular ISurp pipeline. Integrated callers should provide
;; the selected mode together with:
;;
;;   (INPUT INDEXED-PATTERN ($indexed-pattern $support))
;;
;; Standalone callers may continue to provide `INPUT PATTERN`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Public dispatcher. Pattern-miner starts this definition after frequent
;; mining. The selected result adapter is looked up by mode, so adding a mode
;; does not require another pattern-miner orchestration branch.
(DEF do-surp-fn
    (, (do-surp)
       (INPUT SURP-MODE $mode)
       (DEF do-surp-input-fn $input-p $input-t)
       (DEF do-surp-result-fn $mode $result-p $result-t))
    (O
        (- (do-surp))
        (+ (do-surp-active $mode))
        (+ (exec (surp s001 materialize-surp-inputs) $input-p $input-t))
        (+ (exec (surp s930 collect-surp-result) $result-p $result-t))))


;; Score every frequent pattern, regardless of tuple size.
(DEF do-surp-input-fn
    (, (do-surp-active $mode)
       (expanded-conjunct $size $indexed-pattern $support))
    (O
        (+ (INPUT INDEXED-PATTERN ($indexed-pattern $support)))
        (pure
            (pattern-miner-pattern $indexed-pattern $pattern $support)
            $pattern
            (indices_to_vars
                (cons , (' $indexed-pattern))))))


;; Mode-specific outputs are normalized into one dispatcher result shape.
(DEF do-surp-result-fn
    isurp-old
    (, (isurp-old-of $pattern-id $pattern $score))
    (O
        (+ (surprisingess-of isurp-old $pattern-id $score))))

(DEF do-surp-result-fn
    isurp
    (, (isurp-of $pattern-id $score))
    (O
        (+ (surprisingess-of isurp $pattern-id $score))))

(DEF do-surp-result-fn
    jsd
    (, (jsd-surp-of $pattern-id $score))
    (O
        (+ (surprisingess-of jsd $pattern-id $score))))



;; Normalize the raw comma pattern with the shared `vars_to_indices` helper.
;;
;; `vars_to_indices` preserves variable identity, but it returns the full comma
;; expression:
;;
;;   (, (Inheritance (var 0) man) ...)
;;
;; Partitioning expects only the clause list, so `cdr-atom` removes the leading
;; comma marker.
(exec (surp s020 index-pattern)
    (, (INPUT PATTERN ($raw-pattern $support)))
    (O
        (pure
            (indexed-comma-pattern $indexed-comma-pattern $support)
            $indexed-comma-pattern
            (vars_to_indices (' $raw-pattern)))))

;; The frequent miner already emits canonical indexed conjunction lists. This
;; path exposes that list directly to ISurp and bypasses `vars_to_indices`.
(exec (surp s020 accept-indexed-isurp-pattern)
    (, (INPUT SURP-MODE isurp)
       (INPUT INDEXED-PATTERN ($indexed-pattern $support)))
    (, (isurp-pattern $indexed-pattern $support)))

(exec (surp s020 accept-indexed-jsd-pattern)
    (, (INPUT SURP-MODE jsd)
       (INPUT INDEXED-PATTERN ($indexed-pattern $support)))
    (, (isurp-pattern $indexed-pattern $support)))

(exec (surp s021 index-pattern-list)
    (, (indexed-comma-pattern $indexed-comma-pattern $support))
    (O
        (pure
            (isurp-pattern $indexed-pattern $support)
            $indexed-pattern
            (cdr-atom (' $indexed-comma-pattern)))))

(exec (surp s022 expose-indexed-pattern)
    (, (isurp-pattern $pattern $support))
    (, (indexed-pattern $pattern)
       (indexed-pattern-of $pattern $pattern)))
