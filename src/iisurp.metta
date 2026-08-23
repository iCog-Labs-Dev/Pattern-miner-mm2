;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/common-utils/surp-components.metta

;; Interesting I-surprisingness (IISurp), LEGACY-NUMERIC profile.
;;
;; Public entry point:
;;   (iisurp $comma-pattern $support)
;;
;; The public entry point selects the supported legacy-numeric, extensional,
;; normalized behavior. The database size remains application configuration:
;;   (INPUT DB-SIZE $fact-count)
;;
;; Required inputs:
;;   (INPUT DB $db)
;;   (INPUT DB-SIZE $fact-count)
;;   (INPUT PATTERN (($comma-pattern) $support))
;;   (INPUT IISURP-PROFILE LEGACY-NUMERIC)
;;   (INPUT IISURP-CONCEPT-SOURCE EXTENSIONAL)
;;   (INPUT IISURP-NORMALIZATION TRUE|FALSE)
;; Optional:
;;   (INPUT IISURP-TRACE FALSE) ; remove IISurp intermediates
;;
;; Result: (iisurp-of $pattern-id $indexed-pattern $score)
;; Details and numeric provenance: src/iisurp-README.md

(iisurp-supported-profile LEGACY-NUMERIC)
(iisurp-supported-probability-model LEGACY-BINOMIAL)
(iisurp-supported-concept-source EXTENSIONAL)

;; Consumer-facing start adapter. Keep the algorithm's configuration labels
;; behind this boundary so another component only supplies its pattern and the
;; support it has already computed. The active atomspace is the database.
(exec (surp 001 iisurp-public-entry)
    (, (iisurp $pattern $support))
    (O
        (+ (INPUT DB db))
        (+ (INPUT PATTERN ($pattern $support)))
        (+ (INPUT IISURP-PROFILE LEGACY-NUMERIC))
        (+ (INPUT IISURP-CONCEPT-SOURCE EXTENSIONAL))
        (+ (INPUT IISURP-NORMALIZATION TRUE))
        (- (iisurp $pattern $support))))

;; IISurp owns its public error predicate; the shared base stays ISurp-neutral.
(exec (surp 200 iisurp-forward-base-errors)
    (, (isurp-error $pid $stage $reason))
    (, (iisurp-error $pid $stage $reason)))

;; Walk an arbitrary-length conjunction. Each indexed triplet retains its
;; prefix and tail, so exact-position replacement is one append operation.
(DEF iisurp-scan-clause-fn
    (, (iisurp-clause-cursor $pid $prefix $remaining)
       (DEF iisurp-scan-clause-fn $scan-source $scan-sink)
       (DEF iisurp-save-clause-fn $save-source $save-sink))
    (O
        (pure (iisurp-clause-head $pid $prefix $remaining $clause)
              $clause (car-atom (' $remaining)))
        (pure (iisurp-clause-tail $pid $prefix $remaining $tail)
              $tail (cdr-atom (' $remaining)))
        (+ (exec (surp 301 iisurp-clause-scan)
             $save-source $save-sink))))

(DEF iisurp-save-clause-fn
    (, (iisurp-clause-cursor $pid $prefix $remaining)
       (iisurp-clause-head $pid $prefix $remaining $clause)
       (iisurp-clause-tail $pid $prefix $remaining $tail)
       (DEF iisurp-scan-clause-fn $scan-source $scan-sink))
    (O
        (pure (iisurp-clause $pid $index $clause $prefix $tail)
              $index (size-atom (' $prefix)))
        (pure (iisurp-clause-cursor $pid $next-prefix $tail)
              $next-prefix (append (' ($prefix ($clause)))))
        (- (iisurp-clause-cursor $pid $prefix $remaining))
        (- (iisurp-clause-head $pid $prefix $remaining $clause))
        (- (iisurp-clause-tail $pid $prefix $remaining $tail))
        (+ (exec (surp 301 iisurp-clause-scan)
             $scan-source $scan-sink))))

(exec (surp 300 iisurp-start-clause-scan)
    (, (INPUT IISURP-PROFILE LEGACY-NUMERIC)
       (INPUT IISURP-CONCEPT-SOURCE EXTENSIONAL)
       (isurp-complete $pid)
       (isurp-pattern $pid $pattern $indexed $support)
       (DEF iisurp-scan-clause-fn $scan-source $scan-sink))
    (, (iisurp-clause-cursor $pid () $indexed)
       (exec (surp 301 iisurp-clause-scan) $scan-source $scan-sink)))

(exec (surp 303 iisurp-drop-empty-clause-cursor)
    (, (iisurp-clause-cursor $pid $prefix ()))
    (O (- (iisurp-clause-cursor $pid $prefix ()))))

;; Every non-variable value in either argument of any triplet link is a
;; replaceable semantic position.
(exec (surp 310 iisurp-classify-triplet-values)
    (, (iisurp-clause $pid $index ($link $left $right) $prefix $tail))
    (O
        (pure (iisurp-value-position-check
                  $pid $index arg/1 ($link $left $right) $left $is-left-var)
              $is-left-var (i8_to_string (is_var (' $left))))
        (pure (iisurp-value-position-check
                  $pid $index arg/2 ($link $left $right) $right $is-right-var)
              $is-right-var (i8_to_string (is_var (' $right))))))

(exec (surp 311 iisurp-promote-triplet-value)
    (, (iisurp-value-position-check
            $pid $index $path $clause $value 0))
    (O
        (+ (iisurp-concept-position
                $pid $index $path $clause $value))
        (- (iisurp-value-position-check
                $pid $index $path $clause $value 0))))

(exec (surp 311 iisurp-drop-variable-position)
    (, (iisurp-value-position-check
            $pid $index $path $clause $value 1))
    (O (- (iisurp-value-position-check
            $pid $index $path $clause $value 1))))

;; Candidates are values observed at the same link and argument position with
;; at least one shared value in the opposite position.
(exec (surp 320 iisurp-propose-arg-1-replacements)
    (, (iisurp-concept-position
            $pid $index arg/1 ($link $value $right) $value)
       ($link $value $anchor)
       ($link $replacement $anchor))
    (, (iisurp-superconcept-proposal
            $pid (candidate $index arg/1 $value $replacement)
            $index arg/1 ($link $value $right) $value $replacement)))

(exec (surp 320 iisurp-propose-arg-2-replacements)
    (, (iisurp-concept-position
            $pid $index arg/2 ($link $left $value) $value)
       ($link $anchor $value)
       ($link $anchor $replacement))
    (, (iisurp-superconcept-proposal
            $pid (candidate $index arg/2 $value $replacement)
            $index arg/2 ($link $left $value) $value $replacement)))

(exec (surp 321 iisurp-drop-identity-candidate)
    (, (iisurp-superconcept-proposal
            $pid (candidate $index $path $value $value)
            $index $path $clause $value $value))
    (O (- (iisurp-superconcept-proposal
            $pid (candidate $index $path $value $value)
            $index $path $clause $value $value))))

(exec (surp 322 iisurp-promote-candidate)
    (, (iisurp-superconcept-proposal
            $pid $candidate $index $path $clause $value $replacement))
    (, (iisurp-superconcept-candidate
            $pid $candidate $index $path
            $clause $value $replacement extensional)))

(exec (surp 330 iisurp-build-arg-1-replacement)
    (, (iisurp-superconcept-candidate
            $pid $candidate $index arg/1
            ($link $value $right) $value $replacement extensional))
    (, (iisurp-replacement-clause
            $pid $candidate $index ($link $replacement $right))))

(exec (surp 330 iisurp-build-arg-2-replacement)
    (, (iisurp-superconcept-candidate
            $pid $candidate $index arg/2
            ($link $left $value) $value $replacement extensional))
    (, (iisurp-replacement-clause
            $pid $candidate $index ($link $left $replacement))))

(exec (surp 331 iisurp-rebuild-pattern)
    (, (iisurp-clause $pid $index $clause $prefix $tail)
       (iisurp-replacement-clause $pid $candidate $index $replacement))
    (O
        (pure (iisurp-replacement-prefix
                  $pid $candidate $tail $replacement-prefix)
              $replacement-prefix
              (append (' ($prefix ($replacement)))))))

(exec (surp 332 iisurp-finish-rebuilt-pattern)
    (, (iisurp-replacement-prefix
            $pid $candidate $tail $replacement-prefix))
    (O
        (pure (iisurp-replacement-pattern $pid $candidate $rebuilt)
              $rebuilt
              (append (' ($replacement-prefix $tail))))
        (- (iisurp-replacement-prefix
                $pid $candidate $tail $replacement-prefix))))

;; Four counts prove containment and provide the semantic estimate inputs.

(exec (surp 335 iisurp-build-arg-1-support-queries)
    (, (iisurp-superconcept-candidate
            $pid $candidate $index arg/1
            ($link $value $right) $value $replacement extensional)
       (iisurp-replacement-pattern $pid $candidate $replacement-pattern))
    (, (iisurp-support-query $pid $candidate original
            (($link $value (var 0))))
       (iisurp-support-query $pid $candidate super
            (($link $replacement (var 0))))
       (iisurp-support-query $pid $candidate overlap
            (($link $value (var 0))
             ($link $replacement (var 0))))
       (iisurp-support-query
            $pid $candidate replacement $replacement-pattern)))

(exec (surp 335 iisurp-build-arg-2-support-queries)
    (, (iisurp-superconcept-candidate
            $pid $candidate $index arg/2
            ($link $left $value) $value $replacement extensional)
       (iisurp-replacement-pattern $pid $candidate $replacement-pattern))
    (, (iisurp-support-query $pid $candidate original
            (($link (var 0) $value)))
       (iisurp-support-query $pid $candidate super
            (($link (var 0) $replacement)))
       (iisurp-support-query $pid $candidate overlap
            (($link (var 0) $value)
             ($link (var 0) $replacement)))
       (iisurp-support-query
            $pid $candidate replacement $replacement-pattern)))

(exec (surp 340 iisurp-request-support)
    (, (iisurp-support-query $pid $candidate $kind $query)
       ((count-indexed-conjunction-support
            (iisurp-support-context $pid $candidate $kind)
            $query (surp 342 iisurp-count-support)
            -> iisurp-counted-support)
        $source $sink))
    (O
        ;; Preserve a real zero result when the dynamic count has no matches.
        (+ (iisurp-support $pid $candidate $kind $query 0))
        (+ (count-indexed-conjunction-support-request
            (iisurp-support-context $pid $candidate $kind)
            $query (surp 342 iisurp-count-support)
            iisurp-counted-support))
        (+ (exec (surp 341 iisurp-build-support-query) $source $sink))
        (- (iisurp-support-query $pid $candidate $kind $query))))

(exec (surp 343 iisurp-save-support)
    (, (iisurp-counted-support
            (iisurp-support-context $pid $candidate $kind)
            $query $support))
    (, (iisurp-support $pid $candidate $kind $query $support)))

(exec (surp 344 iisurp-classify-positive-support)
    (, (iisurp-support $pid $candidate $kind $query $support))
    (O
        (pure (iisurp-positive-support?
                  $pid $candidate $kind $support $positive)
              $positive
              (gt_i64 (i64_from_string $support)
                      (i64_from_string 0)))))

(exec (surp 345 iisurp-drop-zero-support-fallback)
    (, (iisurp-positive-support?
            $pid $candidate $kind $support true)
       (iisurp-support $pid $candidate $kind $query 0))
    (O (- (iisurp-support $pid $candidate $kind $query 0))))

(exec (surp 346 iisurp-drop-support-classification)
    (, (iisurp-positive-support?
            $pid $candidate $kind $support $positive))
    (O (- (iisurp-positive-support?
            $pid $candidate $kind $support $positive))))

(exec (surp 350 iisurp-check-containment)
    (, (iisurp-support $pid $candidate original $query $original)
       (iisurp-support $pid $candidate overlap $overlap-query $overlap))
    (O
        (pure (iisurp-containment-result $pid $candidate $contained)
              $contained
              (eq_i64 (i64_from_string $original)
                      (i64_from_string $overlap)))))

(exec (surp 351 iisurp-accept-superconcept)
    (, (iisurp-containment-result $pid $candidate true)
       (iisurp-superconcept-candidate
            $pid $candidate $index $path $clause
            $concept $superconcept extensional)
       (iisurp-replacement-pattern $pid $candidate $replacement)
       (iisurp-support $pid $candidate original $oq $original)
       (iisurp-support $pid $candidate super $sq $super)
       (iisurp-support $pid $candidate overlap $iq $overlap)
       (iisurp-support $pid $candidate replacement $rq $replacement-support))
    (, (iisurp-accepted-superconcept
            $pid $candidate $index $concept $superconcept
            $original $super $replacement-support)))

(exec (surp 351 iisurp-reject-candidate)
    (, (iisurp-containment-result $pid $candidate false))
    (, (iisurp-rejected-candidate
            $pid $candidate extension-not-contained)))

;; Coherence is the mean Dice similarity of all unordered instance profiles.

(exec (surp 400 iisurp-classify-coherence-evidence)
    (, (iisurp-accepted-superconcept
            $pid $candidate $index $concept $superconcept
            $original $super $replacement))
    (O
        (pure (iisurp-low-coherence-evidence? $pid $candidate $low)
              $low
              (le_i64 (i64_from_string $super) (i64_from_string 1)))
        (pure (iisurp-pair-coherence-evidence? $pid $candidate $pairs)
              $pairs
              (gt_i64 (i64_from_string $super) (i64_from_string 1)))))

(exec (surp 401 iisurp-low-evidence-fallback)
    (, (iisurp-low-coherence-evidence? $pid $candidate true))
    (, (iisurp-coherence $pid $candidate 0.5)
       (iisurp-coherence-provenance
            $pid $candidate legacy-low-evidence-fallback)))

(exec (surp 410 iisurp-materialize-arg-1-instances)
    (, (iisurp-pair-coherence-evidence? $pid $candidate true)
       (iisurp-accepted-superconcept
            $pid $candidate $index $concept $superconcept
            $original $super $replacement)
       (iisurp-superconcept-candidate
            $pid $candidate $index arg/1
            ($link $concept $right) $concept $superconcept extensional)
       ($link $superconcept $instance))
    (, (iisurp-candidate-instance $pid $candidate $instance)))

(exec (surp 410 iisurp-materialize-arg-2-instances)
    (, (iisurp-pair-coherence-evidence? $pid $candidate true)
       (iisurp-accepted-superconcept
            $pid $candidate $index $concept $superconcept
            $original $super $replacement)
       (iisurp-superconcept-candidate
            $pid $candidate $index arg/2
            ($link $left $concept) $concept $superconcept extensional)
       ($link $instance $superconcept))
    (, (iisurp-candidate-instance $pid $candidate $instance)))

;; Relation-aware incoming and outgoing triplets form schema-free profiles.
(exec (surp 411 iisurp-materialize-outgoing-profiles)
    (, (iisurp-candidate-instance $pid $candidate $instance)
       ($link $instance $value))
    (, (iisurp-instance-feature
            $pid $candidate $instance (out $link $value))))

(exec (surp 411 iisurp-materialize-incoming-profiles)
    (, (iisurp-candidate-instance $pid $candidate $instance)
       ($link $value $instance))
    (, (iisurp-instance-feature
            $pid $candidate $instance (in $link $value))))

(exec (surp 420 iisurp-count-profile-size)
    (, (iisurp-instance-feature $pid $candidate $instance $feature))
    (O
        (count (iisurp-instance-profile-size
                   $pid $candidate $instance $size)
               $size $feature)))

(exec (surp 430 iisurp-canonicalize-pairs)
    (, (iisurp-candidate-instance $pid $candidate $left)
       (iisurp-candidate-instance $pid $candidate $right))
    (O
        (pure (iisurp-instance-pair-key $pid $candidate $pair)
              $pair
              (sort-atom (' ($left $right))))))

(exec (surp 431 iisurp-drop-self-pairs)
    (, (iisurp-instance-pair-key
            $pid $candidate ($instance $instance)))
    (O (- (iisurp-instance-pair-key
            $pid $candidate ($instance $instance)))))

(exec (surp 432 iisurp-promote-pairs)
    (, (iisurp-instance-pair-key $pid $candidate ($left $right)))
    (, (iisurp-instance-pair $pid $candidate $left $right)))

(exec (surp 440 iisurp-count-pair-intersection)
    (, (iisurp-instance-pair $pid $candidate $left $right)
       (iisurp-instance-feature $pid $candidate $left $feature)
       (iisurp-instance-feature $pid $candidate $right $feature))
    (O
        (count (iisurp-pair-intersection-size
                   $pid $candidate $left $right $size)
               $size $feature)))

(exec (surp 450 iisurp-calculate-pair-coherence)
    (, (iisurp-instance-pair $pid $candidate $left $right)
       (iisurp-instance-profile-size $pid $candidate $left $left-size)
       (iisurp-instance-profile-size $pid $candidate $right $right-size)
       (iisurp-pair-intersection-size
            $pid $candidate $left $right $intersection))
    (O
        (pure (iisurp-pair-coherence
                  $pid $candidate $left $right $coherence)
              $coherence
              (f64_to_string
                  (div_f64
                      (product_f64 (f64_from_string 2)
                                   (f64_from_string $intersection))
                      (sum_f64 (f64_from_string $left-size)
                               (f64_from_string $right-size)))))))

(exec (surp 460 iisurp-count-pair-coherences)
    (, (iisurp-pair-coherence $pid $candidate $left $right $coherence))
    (O
        (count (iisurp-pair-coherence-count $pid $candidate $count)
               $count ($left $right))))

(exec (surp 465 iisurp-copy-coherences-for-fold)
    (, (iisurp-pair-coherence $pid $candidate $left $right $coherence))
    (, (iisurp-pending-pair-coherence
            $pid $candidate $left $right $coherence)))

;; The fold consumes facts one by one so equal values retain multiplicity.

(DEF iisurp-coherence-fold-selector
    (, (iisurp-pending-pair-coherence
            $pid $candidate $left $right $coherence)
       (iisurp-coherence-fold-sum $pid $candidate $sum)
       (iisurp-coherence-fold-count $pid $candidate $count))
    (O
        (head 1 (iisurp-selected-pair-coherence
                    $pid $candidate $left $right $coherence))))

(DEF iisurp-coherence-fold-handler
    (, (iisurp-selected-pair-coherence
            $pid $candidate $left $right $coherence)
       (iisurp-pending-pair-coherence
            $pid $candidate $left $right $coherence)
       (iisurp-coherence-fold-sum $pid $candidate $sum)
       (iisurp-coherence-fold-count $pid $candidate $count)
       (DEF iisurp-coherence-fold-selector $selector-source $selector-sink)
       (DEF iisurp-coherence-fold-handler $handler-source $handler-sink))
    (O
        (pure (iisurp-coherence-fold-sum $pid $candidate $next-sum)
              $next-sum
              (f64_to_string
                  (sum_f64 (f64_from_string $sum)
                           (f64_from_string $coherence))))
        (pure (iisurp-coherence-fold-count $pid $candidate $next-count)
              $next-count
              (i64_to_string
                  (sum_i64 (i64_from_string $count)
                           (i64_from_string 1))))
        (- (iisurp-selected-pair-coherence
                $pid $candidate $left $right $coherence))
        (- (iisurp-pending-pair-coherence
                $pid $candidate $left $right $coherence))
        (- (iisurp-coherence-fold-sum $pid $candidate $sum))
        (- (iisurp-coherence-fold-count $pid $candidate $count))
        (+ (exec (surp 471 iisurp-coherence-fold)
             $selector-source $selector-sink))
        (+ (exec (surp 471 iisurp-coherence-fold)
             $handler-source $handler-sink))))

(exec (surp 470 iisurp-start-coherence-fold)
    (, (iisurp-pair-coherence-count $pid $candidate $pair-count)
       (DEF iisurp-coherence-fold-selector $selector-source $selector-sink)
       (DEF iisurp-coherence-fold-handler $handler-source $handler-sink))
    (, (iisurp-coherence-fold-sum $pid $candidate 0.0)
       (iisurp-coherence-fold-count $pid $candidate 0)
       (exec (surp 471 iisurp-coherence-fold)
             $selector-source $selector-sink)
       (exec (surp 471 iisurp-coherence-fold)
             $handler-source $handler-sink)))

(exec (surp 480 iisurp-finish-coherence-fold)
    (, (iisurp-pair-coherence-count $pid $candidate $pair-count)
       (iisurp-coherence-fold-count $pid $candidate $pair-count)
       (iisurp-coherence-fold-sum $pid $candidate $sum))
    (O
        (pure (iisurp-coherence $pid $candidate $coherence)
              $coherence
              (f64_to_string
                  (div_f64 (f64_from_string $sum)
                           (f64_from_string $pair-count))))
        (+ (iisurp-coherence-provenance
                $pid $candidate legacy-mean-of-unique-unordered-pairs))))

;; Super/subconcept estimates from the recovered legacy prototype.

(exec (surp 500 iisurp-calculate-scaled-estimate)
    (, (isurp-universe-count $pid $universe)
       (iisurp-accepted-superconcept
            $pid $candidate $index $concept $superconcept
            $original $super $replacement)
       (iisurp-coherence $pid $candidate $coherence))
    (O
        (pure (iisurp-semantic-estimate $pid $candidate scaled $scaled)
              $scaled
              (f64_to_string
                  (product_f64
                      (div_f64 (f64_from_string $replacement)
                               (f64_from_string $universe))
                      (div_f64 (f64_from_string $original)
                               (f64_from_string $super)))))))

(exec (surp 501 iisurp-calculate-semantic-bounds)
    (, (iisurp-coherence $pid $candidate $coherence)
       (iisurp-semantic-estimate $pid $candidate scaled $scaled))
    (O
        (pure (iisurp-semantic-estimate $pid $candidate lower $lower)
              $lower
              (f64_to_string
                  (product_f64
                      (product_f64 (f64_from_string $coherence)
                                   (f64_from_string $coherence))
                      (f64_from_string $scaled))))
        (pure (iisurp-semantic-estimate $pid $candidate upper $upper)
              $upper
              (f64_to_string
                  (product_f64
                      (div_f64 (f64_from_string 0.4)
                               (f64_from_string $coherence))
                      (f64_from_string $scaled))))
        (+ (iisurp-semantic-heuristics
                $pid $candidate
                (lower coherence-squared)
                (upper 0.4-divided-by-coherence)))))

(exec (surp 502 iisurp-complete-semantic-candidate)
    (, (iisurp-semantic-estimate $pid $candidate lower $lower)
       (iisurp-semantic-estimate $pid $candidate upper $upper))
    (, (iisurp-semantic-candidate-complete $pid $candidate)))

;; Combined interval = partition estimates plus all semantic bounds.

(exec (surp 520 iisurp-include-partition-estimates)
    (, (isurp-partition-estimate $pid $partition $estimate))
    (, (iisurp-combined-estimate
            $pid partition $partition $estimate)))

(exec (surp 521 iisurp-include-lower-estimates)
    (, (iisurp-semantic-candidate-complete $pid $candidate)
       (iisurp-semantic-estimate $pid $candidate lower $estimate))
    (, (iisurp-combined-estimate
            $pid semantic-lower $candidate $estimate)))

(exec (surp 521 iisurp-include-upper-estimates)
    (, (iisurp-semantic-candidate-complete $pid $candidate)
       (iisurp-semantic-estimate $pid $candidate upper $estimate))
    (, (iisurp-combined-estimate
            $pid semantic-upper $candidate $estimate)))

(exec (surp 530 iisurp-reduce-combined-estimates)
    (, (iisurp-combined-estimate $pid $kind $source $estimate))
    (O
        (fmin (iisurp-expected-min $pid $minimum) $minimum $estimate)
        (fmax (iisurp-expected-max $pid $maximum) $maximum $estimate)))

(exec (surp 531 iisurp-publish-expected-interval)
    (, (iisurp-expected-min $pid $minimum)
       (iisurp-expected-max $pid $maximum))
    (, (iisurp-expected-interval $pid $minimum $maximum)))

(exec (surp 540 iisurp-request-distance)
    (, (iisurp-expected-interval $pid $minimum $maximum)
       (isurp-empirical-probability $pid $empirical)
       ((interval-distance
            $pid $minimum $maximum $empirical -> iisurp-raw-of)
        $source $sink))
    (O
        (+ (interval-distance-request
                $pid $minimum $maximum $empirical iisurp-raw-of))
        (+ (exec (surp 541 iisurp-calculate-distance) $source $sink))))

(exec (surp 550 iisurp-normalization-denominator)
    (, (iisurp-raw-of $pid $raw)
       (iisurp-expected-interval $pid $minimum $maximum)
       (isurp-empirical-probability $pid $empirical))
    (O
        (pure (iisurp-normalization-denominator $pid $denominator)
              $denominator
              (f64_to_string
                  (max_f64 (f64_from_string $empirical)
                           (f64_from_string $maximum))))
        (pure (iisurp-positive-denominator? $pid $positive)
              $positive
              (gt_f64
                  (max_f64 (f64_from_string $empirical)
                           (f64_from_string $maximum))
                  (f64_from_string 0)))))

(exec (surp 551 iisurp-normalize-positive-distance)
    (, (iisurp-raw-of $pid $raw)
       (iisurp-normalization-denominator $pid $denominator)
       (iisurp-positive-denominator? $pid true))
    (O
        (pure (iisurp-normalized-of $pid $normalized) $normalized
              (f64_to_string
                  (min_f64
                      (div_f64 (f64_from_string $raw)
                               (f64_from_string $denominator))
                      (f64_from_string 1))))))

(exec (surp 551 iisurp-normalize-zero-distance)
    (, (iisurp-raw-of $pid 0.0)
       (iisurp-positive-denominator? $pid false))
    (, (iisurp-normalized-of $pid 0.0)))

(exec (surp 560 iisurp-publish-normalized)
    (, (INPUT IISURP-NORMALIZATION TRUE)
       (isurp-pattern $pid $pattern $indexed $support)
       (iisurp-normalized-of $pid $score))
    (, (iisurp-of $pid $indexed $score)
       (surprisingness-of $pattern $score)))

(exec (surp 561 iisurp-publish-raw)
    (, (INPUT IISURP-NORMALIZATION FALSE)
       (isurp-pattern $pid $pattern $indexed $support)
       (iisurp-raw-of $pid $score))
    (, (iisurp-of $pid $indexed $score)
       (surprisingness-of $pattern $score)))

;; Compact, pattern-scoped cleanup. The marker is finalized only after every
;; selected IISurp fact and any unmatched cleanup task have been removed.

(exec (surp 900 iisurp-plan-cleanup)
    (, (INPUT IISURP-TRACE FALSE)
       (iisurp-of $pid $indexed $score))
    (,
        (iisurp-cleanup-pending $pid)
        (iisurp-clean $pid (iisurp-clause $pid $a $b $c $d))
        (iisurp-clean $pid (iisurp-concept-position $pid $a $b $c $d))
        (iisurp-clean $pid (iisurp-superconcept-proposal $pid $a $b $c $d $e $f))
        (iisurp-clean $pid (iisurp-superconcept-candidate $pid $a $b $c $d $e $f $g))
        (iisurp-clean $pid (iisurp-replacement-clause $pid $a $b $c))
        (iisurp-clean $pid (iisurp-replacement-pattern $pid $a $b))
        (iisurp-clean $pid
            (iisurp-counted-support
                (iisurp-support-context $pid $a $b) $c $d))
        (iisurp-clean $pid (iisurp-support $pid $a $b $c $d))
        (iisurp-clean $pid (iisurp-containment-result $pid $a $b))
        (iisurp-clean $pid (iisurp-rejected-candidate $pid $a $b))
        (iisurp-clean $pid (iisurp-accepted-superconcept $pid $a $b $c $d $e $f $g))
        (iisurp-clean $pid (iisurp-low-coherence-evidence? $pid $a $b))
        (iisurp-clean $pid (iisurp-pair-coherence-evidence? $pid $a $b))
        (iisurp-clean $pid (iisurp-candidate-instance $pid $a $b))
        (iisurp-clean $pid (iisurp-instance-feature $pid $a $b $c))
        (iisurp-clean $pid (iisurp-instance-profile-size $pid $a $b $c))
        (iisurp-clean $pid (iisurp-instance-pair-key $pid $a $b))
        (iisurp-clean $pid (iisurp-instance-pair $pid $a $b $c))
        (iisurp-clean $pid (iisurp-pair-intersection-size $pid $a $b $c $d))
        (iisurp-clean $pid (iisurp-pair-coherence $pid $a $b $c $d))
        (iisurp-clean $pid (iisurp-pair-coherence-count $pid $a $b))
        (iisurp-clean $pid (iisurp-coherence-fold-sum $pid $a $b))
        (iisurp-clean $pid (iisurp-coherence-fold-count $pid $a $b))
        (iisurp-clean $pid (iisurp-coherence $pid $a $b))
        (iisurp-clean $pid (iisurp-coherence-provenance $pid $a $b))
        (iisurp-clean $pid (iisurp-semantic-estimate $pid $a $b $c))
        (iisurp-clean $pid (iisurp-semantic-heuristics $pid $a $b $c))
        (iisurp-clean $pid (iisurp-semantic-candidate-complete $pid $a))
        (iisurp-clean $pid (iisurp-combined-estimate $pid $a $b $c))
        (iisurp-clean $pid (iisurp-expected-min $pid $a))
        (iisurp-clean $pid (iisurp-expected-max $pid $a))
        (iisurp-clean $pid (iisurp-expected-interval $pid $a $b))
        (iisurp-clean $pid (iisurp-normalization-denominator $pid $a))
        (iisurp-clean $pid (iisurp-positive-denominator? $pid $a))
        (iisurp-clean $pid (iisurp-raw-of $pid $a))
        (iisurp-clean $pid (iisurp-normalized-of $pid $a))))

(exec (surp 901 iisurp-schedule-cleanup)
    (, (iisurp-clean $pid $fact)
       ((drop-matched $fact -> removed) $source $sink))
    (O (+ (exec (surp 902 iisurp-clean-fact) $source $sink))))

(exec (surp 903 iisurp-drop-cleanup-task)
    (, (iisurp-clean $pid $fact))
    (O (- (iisurp-clean $pid $fact))))

(exec (surp 904 iisurp-finish-cleanup)
    (, (iisurp-cleanup-pending $pid))
    (O (- (iisurp-cleanup-pending $pid))
       (+ (iisurp-cleanup-complete $pid))))
