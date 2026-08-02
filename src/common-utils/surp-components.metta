;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Shared, pattern-scoped surprisingness probability component
;;
;; IISurp consumes this component. It owns normalization of the input pattern,
;; partition generation, support counting, and the independent probability
;; interval. Keeping these facts pattern-scoped prevents different active
;; patterns from cross-joining. The component is reusable by ISurp or another
;; caller if that component's owner chooses to adopt it later.
;;
;; Inputs:
;;   (INPUT DB $db)
;;   (INPUT DB-SIZE $size)
;;   (INPUT PATTERN ($pattern $support))
;;
;; Public facts:
;;   (isurp-pattern $pid $original-pattern $indexed-pattern $support)
;;   (isurp-probability-model $pid LEGACY-BINOMIAL)
;;   (isurp-universe-count $pid $count)
;;   (isurp-empirical-probability $pid $probability)
;;   (isurp-partition-estimate $pid $partition $estimate)
;;   (isurp-expected-interval $pid $emin $emax)
;;   (isurp-complete $pid)
;;
;; `$pid` is the indexed conjunction itself. It contains no executable
;; variables, so it is safe as a stable pattern-scoped key.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The indexed clause list is the stable pattern identifier.
(exec (surp 010 isurp-index-pattern)
    (, (INPUT DB $db)
       (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (isurp-pattern $indexed $pattern $indexed $support)
            $indexed
            (vars_to_indices
                (cdr-atom (' $pattern))))))


;; Count conjuncts without storing the original variable-bearing pattern.
(exec (surp 020 isurp-count-conjuncts)
    (, (isurp-pattern $pid $pattern $indexed $support))
    (O
        (pure
            (isurp-conjunct-count $pid $count)
            $count
            (size-atom (' $indexed)))))


;; A non-trivial partition needs at least two clauses. There is no static upper
;; arity bound; DB-SIZE >= arity keeps the legacy C(N,k) universe defined.
(exec (surp 021 isurp-validate-input-shape)
    (, (INPUT DB-SIZE $db-size)
       (isurp-conjunct-count $pid $count))
    (O
        (pure
            (isurp-supported-arity? $pid $count $supported)
            $supported
            (ge_i64
                (i64_from_string $count)
                (i64_from_string 2)))
        (pure
            (isurp-database-large-enough?
                $pid $db-size $count $large-enough)
            $large-enough
            (ge_i64
                (i64_from_string $db-size)
                (i64_from_string $count)))))


(exec (surp 022 isurp-reject-unsupported-arity)
    (, (isurp-supported-arity? $pid $count false))
    (,
        (isurp-error
            $pid input (unsupported-pattern-arity $count))))


(exec (surp 023 isurp-reject-small-database)
    (, (isurp-database-large-enough?
            $pid $db-size $count false))
    (,
        (isurp-error
            $pid input
            (database-smaller-than-pattern $db-size $count))))


;; Request the shared, context-scoped binomial universe.
(exec (surp 030 isurp-request-universe)
    (, (INPUT DB-SIZE $db-size)
       (isurp-conjunct-count $pid $count)
       (isurp-supported-arity? $pid $count true)
       (isurp-database-large-enough? $pid $db-size $count true)
       ((binomial-universe-count
            $pid $db-size $count -> isurp-universe-count)
        $source $sink))
    (O
        (+ (binomial-universe-count-request
            $pid $db-size $count isurp-universe-count))
        (+ (exec (surp 031 isurp-calculate-universe) $source $sink))))


;; All legacy base and IISurp semantic probabilities share this declaration.
(exec (surp 032 isurp-declare-probability-model)
    (, (isurp-universe-count $pid $universe))
    (,
        (isurp-probability-model $pid LEGACY-BINOMIAL)))


;; Empirical probability uses the input support and the declared universe.
(exec (surp 033 isurp-empirical-probability)
    (, (isurp-pattern $pid $pattern $indexed $support)
       (isurp-universe-count $pid $universe))
    (O
        (pure
            (isurp-empirical-probability $pid $probability)
            $probability
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe))))))


;; Generate every non-trivial set partition of the indexed clause list.
(exec (surp 040 isurp-generate-partitions)
    (, (isurp-pattern $pid $pattern $indexed $support)
       (isurp-probability-model $pid LEGACY-BINOMIAL))
    (O
        (pure
            (isurp-partition-cursor $pid $partitions)
            $partitions
            (partitions (' $indexed)))))


;; Iterate over the native partition tuple. The self fact serializes recursive
;; cursor creation without a PeTTa-style recursive function.
(exec (surp 041 isurp-expand-partitions)
    (, (isurp-partition-cursor $pid $partitions)
       (exec (surp 041 isurp-expand-partitions) $source $sink))
    (O
        (pure
            (isurp-partition $pid $partition)
            $partition
            (car-atom (' $partitions)))
        (pure
            (isurp-partition-cursor $pid $tail)
            $tail
            (cdr-atom (' $partitions)))
        (- (isurp-partition-cursor $pid $partitions))
        (+ (exec (surp 041 isurp-expand-partitions) $source $sink))))


;; Remove the exhausted cursor. The iterator exec remains harmlessly
;; unmatchable until another run adds a cursor.
(exec (surp 042 isurp-drop-empty-partition-cursor)
    (, (isurp-partition-cursor $pid ()))
    (O
        (- (isurp-partition-cursor $pid ()))))


;; Copy each partition before iterating through its blocks.
(exec (surp 050 isurp-copy-partition)
    (, (isurp-partition $pid $partition))
    (,
        (isurp-block-cursor $pid $partition $partition)))


(exec (surp 051 isurp-expand-blocks)
    (, (isurp-block-cursor $pid $partition $blocks)
       (exec (surp 051 isurp-expand-blocks) $source $sink))
    (O
        (pure
            (isurp-block $pid $partition $block)
            $block
            (car-atom (' $blocks)))
        (pure
            (isurp-block-cursor $pid $partition $tail)
            $tail
            (cdr-atom (' $blocks)))
        (- (isurp-block-cursor $pid $partition $blocks))
        (+ (exec (surp 051 isurp-expand-blocks) $source $sink))))


(exec (surp 052 isurp-drop-empty-block-cursor)
    (, (isurp-block-cursor $pid $partition ()))
    (O
        (- (isurp-block-cursor $pid $partition ()))))


;; Schedule one support count per unique indexed block and partition context.
(exec (surp 060 isurp-request-block-support)
    (, (isurp-block $pid $partition $block)
       ((count-indexed-conjunction-support
            (isurp-block-context $pid $partition)
            $block
            (surp 062 isurp-count-block-support)
            -> isurp-counted-block-support)
        $source $sink))
    (O
        ;; MORK count emits no result for an empty query. Seed zero, then
        ;; replace it below if the dynamic count produces a positive support.
        (+ (isurp-block-support $pid $partition $block 0))
        (+ (count-indexed-conjunction-support-request
            (isurp-block-context $pid $partition)
            $block
            (surp 062 isurp-count-block-support)
            isurp-counted-block-support))
        (+ (exec (surp 061 isurp-build-block-query) $source $sink))))


;; Flatten the generic common-utils output into an ISurp-owned fact.
(exec (surp 063 isurp-save-block-support)
    (, (isurp-counted-block-support
            (isurp-block-context $pid $partition)
            $block
            $support))
    (,
        (isurp-block-support $pid $partition $block $support)))

(exec (surp 064 isurp-classify-positive-block-support)
    (, (isurp-block-support $pid $partition $block $support))
    (O
        (pure
            (isurp-positive-block-support?
                $pid $partition $block $support $positive)
            $positive
            (gt_i64 (i64_from_string $support)
                    (i64_from_string 0)))))

(exec (surp 065 isurp-drop-zero-block-fallback)
    (, (isurp-positive-block-support?
            $pid $partition $block $support true)
       (isurp-block-support $pid $partition $block 0))
    (O (- (isurp-block-support $pid $partition $block 0))))

(exec (surp 066 isurp-drop-block-support-classification)
    (, (isurp-positive-block-support?
            $pid $partition $block $support $positive))
    (O (- (isurp-positive-block-support?
            $pid $partition $block $support $positive))))


;; Every block probability uses the full pattern universe, exactly as the
;; validated legacy implementation does.
(exec (surp 070 isurp-block-probability)
    (, (isurp-universe-count $pid $universe)
       (isurp-block-support $pid $partition $block $support))
    (O
        (pure
            (isurp-block-probability $pid $partition $block $probability)
            $probability
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe))))))


;; Walk each partition's block list in order and multiply one probability per
;; block. This preserves equal-value multiplicity and has no block-count cap.
(DEF isurp-product-step-fn
    (, (isurp-product-cursor $pid $partition $remaining $product)
       (DEF isurp-product-step-fn $step-source $step-sink)
       (DEF isurp-product-apply-fn $apply-source $apply-sink))
    (O
        (pure (isurp-product-head
                  $pid $partition $remaining $product $block)
              $block (car-atom (' $remaining)))
        (pure (isurp-product-tail
                  $pid $partition $remaining $product $tail)
              $tail (cdr-atom (' $remaining)))
        (+ (exec (surp 081 isurp-product-fold)
             $apply-source $apply-sink))))

(DEF isurp-product-apply-fn
    (, (isurp-product-cursor $pid $partition $remaining $product)
       (isurp-product-head
            $pid $partition $remaining $product $block)
       (isurp-product-tail
            $pid $partition $remaining $product $tail)
       (isurp-block-probability $pid $partition $block $probability)
       (DEF isurp-product-step-fn $step-source $step-sink)
       (DEF isurp-product-finish-fn $finish-source $finish-sink))
    (O
        (pure (isurp-product-cursor
                  $pid $partition $tail $next-product)
              $next-product
              (f64_to_string
                  (product_f64 (f64_from_string $product)
                               (f64_from_string $probability))))
        (- (isurp-product-cursor
                $pid $partition $remaining $product))
        (- (isurp-product-head
                $pid $partition $remaining $product $block))
        (- (isurp-product-tail
                $pid $partition $remaining $product $tail))
        (+ (exec (surp 081 isurp-product-fold)
             $step-source $step-sink))
        (+ (exec (surp 081 isurp-product-fold)
             $finish-source $finish-sink))))

(DEF isurp-product-finish-fn
    (, (isurp-product-cursor $pid $partition () $product))
    (O
        (+ (isurp-partition-estimate $pid $partition $product))
        (- (isurp-product-cursor $pid $partition () $product))))

(exec (surp 080 isurp-start-product-fold)
    (, (isurp-partition $pid $partition)
       (DEF isurp-product-step-fn $step-source $step-sink)
       (DEF isurp-product-finish-fn $finish-source $finish-sink))
    (, (isurp-product-cursor $pid $partition $partition 1.0)
       (exec (surp 081 isurp-product-fold) $step-source $step-sink)
       (exec (surp 081 isurp-product-fold) $finish-source $finish-sink)))


;; Reduce any number of partition estimates to the base interval.
(exec (surp 090 isurp-base-interval)
    (, (isurp-partition-estimate $pid $partition $estimate))
    (O
        (fmin
            (isurp-base-min $pid $minimum)
            $minimum
            $estimate)
        (fmax
            (isurp-base-max $pid $maximum)
            $maximum
            $estimate)))


(exec (surp 100 isurp-complete)
    (, (isurp-base-min $pid $minimum)
       (isurp-base-max $pid $maximum)
       (isurp-empirical-probability $pid $empirical)
       (isurp-probability-model $pid LEGACY-BINOMIAL)
       (isurp-universe-count $pid $universe))
    (,
        (isurp-expected-interval $pid $minimum $maximum)
        (isurp-complete $pid)))
