;;===============================================================
;; Function definitions
;;===============================================================

;; Count all db facts in the main db.
((count-db $db-name -> $out)
    (, ($db-name $fact))
    (O
        (count ($out $db-name $count) $count $fact)))

;; Count conjuncts in a pattern.
((count-conjuncts $pattern -> $out)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            ($out $pattern $count)
            $count
            (size-atom
                (cdr-atom (' $pattern))))))

;; Count matches for an indexed conjunction. The caller supplies both an
;; opaque context value and the complete three-field priority for the count
;; exec, so this template does not own any pipeline scheduling.
((count-indexed-conjunction-support $context $candidate $priority -> $out)
    (, (count-indexed-conjunction-support-request
           $context $candidate $priority $out))
    (O
        (pure
            (exec $priority
                $query
                (O
                    (count
                        ($out $context $candidate $support)
                        $support
                        $query)))
            $query
            (indices_to_vars
                (cons , (' $candidate))))
        (- (count-indexed-conjunction-support-request
            $context $candidate $priority $out))))

;; Shared support cache gate.
;;
;; Every pipeline uses this same callable and supplies:
;;   - the request fact to consume;
;;   - an opaque context copied to the result;
;;   - a canonical indexed conjunction;
;;   - ordered priorities for cache lookup, counting, and delivery;
;;   - its desired output predicate.
;;
;; Public cache:
;;   (support-cache $canonical-candidate $support)
;;
;; Output:
;;   ($out $context $canonical-candidate $support)
;;
;; The candidate must already be canonical. Keeping this contract at the gate
;; makes the cache reusable by miners whose patterns are canonicalized at
;; different stages. `canonicalize-indexed-conjunction` below is the shared
;; utility for callers that still have a raw candidate.
;;
;; `support-cache-work` intentionally contains only the candidate. Atomspace
;; fact deduplication therefore coalesces simultaneous requests from unrelated
;; callers into one database count.
((support-cache-drop-hit -> removed)
    (, (support-cache-work $candidate)
       (support-cache $candidate $support))
    (O (- (support-cache-work $candidate))))

((support-cache-count-miss $priority -> counted)
    (, (support-cache-work $candidate))
    (O
        ;; Seed zero before running the query. MORK's count sink only fires
        ;; when the generated query has matches, so this is also the negative
        ;; cache entry for an unsupported pattern.
        (+ (support-cache $candidate 0))
        (pure
            (exec $priority
                $query
                (O
                    (count
                        (support-cache $candidate $support)
                        $support
                        $query)
                    (- (support-cache $candidate 0))))
            $query
            (indices_to_vars
                (cons , (' $candidate))))
        (- (support-cache-work $candidate))))

((support-cache-deliver -> delivered)
    (, (support-cache-wait $out $context $candidate)
       (support-cache $candidate $support))
    (O
        (+ ($out $context $candidate $support))
        (- (support-cache-wait $out $context $candidate))))

;; Mode-selectable support gate used by production pipelines.
;;
;; Callers read `(INPUT SUPPORT-MODE $mode)` and pass either `cached` or
;; `uncached` here.  The mode is part of the callable signature so dispatch
;; happens while the source/sink pair is generated; no extra exec layer is
;; introduced around the scheduled gate.
((support-gate
    cached
    $fact
    $context
    $candidate
    $hit-priority
    $count-priority
    $deliver-priority
    -> $out)
    (, $fact
       ((support-cache-drop-hit -> removed) $hit-p $hit-t)
       ((support-cache-count-miss $count-priority -> counted)
        $count-p $count-t)
       ((support-cache-deliver -> delivered) $deliver-p $deliver-t))
    (O
        (+ (support-cache-wait $out $context $candidate))
        (+ (support-cache-work $candidate))
        (+ (exec $hit-priority $hit-p $hit-t))
        (+ (exec $count-priority $count-p $count-t))
        (+ (exec $deliver-priority $deliver-p $deliver-t))
        (- $fact)))

;; Always count this request.  Seed a zero result first because MORK's count
;; sink only runs when the query matches; a positive count replaces that zero.
;; This branch never reads or writes `(support-cache ...)` facts.
((support-gate
    uncached
    $fact
    $context
    $candidate
    $hit-priority
    $count-priority
    $deliver-priority
    -> $out)
    (, $fact)
    (O
        (+ ($out $context $candidate 0))
        (pure
            (exec $count-priority
                $query
                (O
                    (count
                        ($out $context $candidate $support)
                        $support
                        $query)
                    (- ($out $context $candidate 0))))
            $query
            (indices_to_vars
                (cons , (' $candidate))))
        (- $fact)))

;; Compare a support value against a caller-provided threshold. The opaque
;; context keeps the decision associated with the fact that requested it.
((support-at-least $context $support $threshold -> $out)
    (, (support-at-least-request $context $support $threshold $out))
    (O
        (pure
            ($out $context $support $passes)
            $passes
            (ge_i32
                (i32_from_string $support)
                (i32_from_string $threshold)))
        (- (support-at-least-request
            $context $support $threshold $out))))

;; Specialize this callable with any fact pattern, then schedule the returned
;; source and sink at the stage where matching facts are safe to remove.
((drop-matched $fact -> removed)
    (, $fact)
    (O (- $fact)))

;; Replace one matched fact with a caller-provided fact.
((replace-matched $fact $replacement -> replaced)
    (, $fact)
    (O
        (+ $replacement)
        (- $fact)))

;; Emit a caller-provided fact after all supplied facts have matched. Separate
;; arities keep the matched facts explicit instead of passing executable code.
((emit-from-matches-2 $first $second $result -> emitted)
    (, $first
       $second)
    (O (+ $result)))

((emit-from-matches-3 $first $second $third $result -> emitted)
    (, $first
       $second
       $third)
    (O (+ $result)))

((emit-from-matches-4 $first $second $third $fourth $result -> emitted)
    (, $first
       $second
       $third
       $fourth)
    (O (+ $result)))

;; Canonicalization stays staged because quoted list results cannot safely be
;; nested. The caller schedules the returned rule at its sort priority and
;; supplies the priorities of the two remaining stages.
(DEF canonicalize-indexed-to-vars-fn
    (, (canonicalize-indexed-sorted $context $out $sorted))
    (O
        (pure
            (canonicalize-indexed-vars $context $out $as-vars)
            $as-vars
            (indices_to_vars (' $sorted)))
        (- (canonicalize-indexed-sorted $context $out $sorted))))

(DEF canonicalize-indexed-to-indices-fn
    (, (canonicalize-indexed-vars $context $out $as-vars))
    (O
        (pure
            ($out $context $candidate)
            $candidate
            (vars_to_indices (' $as-vars)))
        (- (canonicalize-indexed-vars $context $out $as-vars))))

((canonicalize-indexed-conjunction
    $fact $context $candidate $vars-priority $indices-priority -> $out)
    (, $fact
       (DEF canonicalize-indexed-to-vars-fn $vars-p $vars-t)
       (DEF canonicalize-indexed-to-indices-fn $indices-p $indices-t))
    (O
        (pure
            (canonicalize-indexed-sorted $context $out $sorted)
            $sorted
            (sort-atom (' $candidate)))
        (+ (exec $vars-priority $vars-p $vars-t))
        (+ (exec $indices-priority $indices-p $indices-t))
        (- $fact)))

;; Measure a conjunction while allowing the caller to choose both its input
;; fact and output predicate.
((conjunction-size $fact $context $conjunction -> $out)
    (, $fact)
    (O
        (pure
            ($out $context $conjunction $size)
            $size
            (size-atom (' $conjunction)))
        (- $fact)))

;; How many ways can we choose k items from n items, without caring about order.
;; total-counts(pattern, db) = db_size! / (num_conjuncts! * (db_size - num_conjuncts)!)
;; C(n, k) = falling_factorial(n, k) / k!
((total-counts $db $pattern -> $out)
    (, (INPUT DB-SIZE $n)
       (num-of-conjuncts $pattern $k))
    (O
        (pure
            (total-count-of $pattern $total)
            $total
            (i64_to_string
                (div_i64
                    (falling_factorial
                        (i64_from_string $n)
                        (i64_from_string $k))
                    (factorial
                        (i64_from_string $k)))))))
                        

;; Compute the probability of a pattern by dividing the support by total counts.
((prob $pattern $db -> $out)
    (, (INPUT PATTERN ($pattern $support))
       (total-count-of $pattern $count))
    (O
        (pure
            ($out $pattern $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $count))))))

;; Distance from an empirical value to an interval [emin, emax].
((dst-from-interval $pattern $emin $emax $emp -> $out)
    (, (dst-request $pattern $emin $emax $emp $out))
    (O
        (pure
            (dst-above? $pattern $emin $emax $emp $out $above)
            $above
            (gt_f64
                (f64_from_string $emp)
                (f64_from_string $emax)))
        (pure
            (dst-below? $pattern $emin $emax $emp $out $below)
            $below
            (lt_f64
                (f64_from_string $emp)
                (f64_from_string $emin)))
        (pure
            (dst-inside? $pattern $emin $emax $emp $out $inside)
            $inside
            (and_bool
                (le_f64
                    (f64_from_string $emin)
                    (f64_from_string $emp))
                (le_f64
                    (f64_from_string $emp)
                    (f64_from_string $emax))))))
