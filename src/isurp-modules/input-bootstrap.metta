;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0. Input bootstrap
;;
;; This module prepares facts that later ISurp modules consume, but it does not
;; generate partitions.
;;
;; Responsibilities:
;;
;;   1. Start common utility execs when their function definitions are loaded.
;;   2. Normalize raw pattern variables into indexed markers:
;;
;;        $x, $y, ... -> (var 0), (var 1), ...
;;
;; Generated partitions need stable variable identity across blocks.  Later,
;; `indices_to_vars` converts these markers back into real MM2 variables for
;; support-count queries.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 010 bootstrap-definitions)
    (, (INPUT DB $db-name)
       (INPUT PATTERN ($pattern $support))
       ((count-db $db-name -> db-size) $src-of-count $sink-of-count)
       ((count-conjuncts $pattern -> num-of-conjuncts) $src-of-cnj $sink-of-cnj)
       ((total-counts $db-name $pattern -> total-count-of) $src-of-tc $sink-of-tc)
       ((prob $pattern $db-name -> prob-of) $src-of-prob $sink-of-prob))
    (O
        ;; Optional DB-size count path.  The current `total-counts` definition
        ;; uses `INPUT DB-SIZE`, but this fact can help with debugging.
        (+ (exec (surp 011 count-db) $src-of-count $sink-of-count))

        ;; Count clauses in the input comma pattern.
        (+ (exec (surp 012 count-conjuncts) $src-of-cnj $sink-of-cnj))

        ;; Compute C(db_size, number_of_conjuncts).
        (+ (exec (surp 013 total-counts) $src-of-tc $sink-of-tc))

        ;; Compute empirical pattern probability from the provided support.
        (+ (exec (surp 014 prob) $src-of-prob $sink-of-prob))))


;; Normalize the raw comma pattern with the shared `vars_to_indices` helper.
;;
;; `vars_to_indices` preserves variable identity, but it returns the full comma
;; expression:
;;
;;   (, (Inheritance (var 0) man) ...)
;;
;; Partitioning expects only the clause list, so `cdr-atom` removes the leading
;; comma marker.
(exec (surp 020 index-pattern)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (indexed-comma-pattern $indexed-comma-pattern)
            $indexed-comma-pattern
            (vars_to_indices (' $pattern)))))

(exec (surp 021 index-pattern-list)
    (, (INPUT PATTERN ($pattern $support))
       (indexed-comma-pattern $indexed-comma-pattern))
    (O
        (pure
            (indexed-pattern-for $pattern $indexed-pattern)
            $indexed-pattern
            (cdr-atom (' $indexed-comma-pattern)))))

(exec (surp 022 expose-indexed-pattern)
    (, (indexed-pattern-for $pattern $indexed-pattern))
    (, (indexed-pattern $indexed-pattern)
       (indexed-pattern-of $pattern $indexed-pattern)))
