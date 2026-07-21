;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ISurp in MM2
;;
;; This file contains reusable definitions for the modular ISurp pipeline
;; translated from:
;;
;;   ../../hyperon-miner/experiments/surprisingness/isurp-old.metta
;;
;; The implementation is split across `src/isurp_modules/*.metta` as staged MM2
;; `exec` transactions.  A MeTTa function call becomes a dataflow pipeline:
;;
;;   input pattern/support
;;   -> total count
;;   -> empirical pattern probability
;;   -> partitions of the conjuncts
;;   -> block probabilities
;;   -> partition probability products
;;   -> expected interval [emin, emax]
;;   -> distance from interval
;;   -> optional normalization
;;
;; Required grounded helpers:
;;
;;   From MM2-Helper:
;;     partitions, vars_to_indices, indices_to_vars, factorial,
;;     falling_factorial
;;
;;   From mm2-stdlib / MORK pure helpers:
;;     size-atom, car-atom, cdr-atom, min-atom, max-atom,
;;     bool and numeric conversions/operators
;;
;; Input contract:
;;
;;   A caller must provide:
;;
;;     (INPUT DB db)
;;     (INPUT DB-SIZE <number-of-db-atoms>)
;;     (INPUT NORMALIZATION TRUE)    ; or FALSE
;;     (INPUT PATTERN (<comma-pattern> <support>))
;;
;;   Example:
;;
;;     (INPUT DB db)
;;     (INPUT DB-SIZE 60)
;;     (INPUT NORMALIZATION TRUE)
;;     (INPUT PATTERN ((, (Inheritance $x man)
;;                        (Inheritance $x ugly)
;;                        (Inheritance $x sodaDrinker)) 5))
;;
;; Final modular output:
;;
;;     (isurp-new-of $pattern $value)
;;
;; Important:
;;
;;   Running this file by itself is only a syntax/load check.  Because this file
;;   intentionally contains no `(INPUT ...)` facts or DB atoms, it will finish
;;   with only the reusable function definitions in the result space.
;;
;; This file only holds reusable definitions.  Load it with the remaining
;; modules to run the full pipeline.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Reusable function definitions
;;
;; MM2 does not call these definitions directly.  Each definition is stored as
;; data with the shape:
;;
;;   ((name args -> output-predicate) source-pattern sink-template)
;;
;; Later stages match the definition and spawn a real `(exec ... source sink)`.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; count-db
;;
;; Source MeTTa idea:
;;   db_size($db)
;;
;; MM2 implementation:
;;   Count all facts predicated by the chosen DB name, for example `(db fact)`.
;;
;; In the current public input contract, `INPUT DB-SIZE` is authoritative because
;; temporary MM2 facts can otherwise pollute automatic DB-size counting.  This
;; definition is still kept here because it documents and supports a future
;; fully data-driven DB-size path.
((count-db $db-name -> $out)
    (, ($db-name $fact))
    (O
        (count ($out $db-name $count) $count $fact)))


;; count-conjuncts
;;
;; Source MeTTa equivalent:
;;   (n_conjuncts_new $pattern)
;;
;; A conjunctive pattern has the shape:
;;
;;   (, clause-1 clause-2 clause-3)
;;
;; `(cdr-atom pattern)` removes the leading comma and leaves the clause list.
;; `size-atom` then counts that list.
((count-conjuncts $pattern -> $out)
    (, (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            ($out $pattern $count)
            $count
            (size-atom
                (cdr-atom (' $pattern))))))


;; total-counts
;;
;; Source MeTTa equivalent:
;;
;;   (total_counts $pattern $db)
;;   = C(db_size, n_conjuncts)
;;
;; The source implementation uses binomial count, not db_size^n.
;;
;; Formula:
;;
;;   C(n, k) = falling_factorial(n, k) / factorial(k)
;;
;; Result fact:
;;
;;   (total-count-of $pattern $total)
((total-counts $db $pattern -> $out)
    (, (INPUT DB-SIZE $n)
       (num-of-conjuncts $pattern $k))
    (O
        (pure
            ($out $pattern $total)
            $total
            (i64_to_string
                (div_i64
                    (falling_factorial
                        (i64_from_string $n)
                        (i64_from_string $k))
                    (factorial
                        (i64_from_string $k)))))))


;; prob
;;
;; Source MeTTa equivalent:
;;
;;   (prob $pattern $db $total_count)
;;   = sup-num($db, $pattern) / total_count
;;
;; In this MM2 file the full-pattern support is provided by:
;;
;;   (INPUT PATTERN ($pattern $support))
;;
;; This keeps the top-level pattern support explicit and makes validation easier.
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


;; dst-from-interval
;;
;; Source MeTTa equivalent:
;;
;;   (dst_from_interval $emin $emax $emp)
;;
;; Cases:
;;
;;   emp > emax            -> emp - emax
;;   emp < emin            -> emin - emp
;;   emin <= emp <= emax   -> 0.0
;;
;; MM2 materializes the three booleans as facts, then later execs select the
;; successful case.
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
