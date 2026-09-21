;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; emp-prob-pbs without sampling
;;
;; Source PeTTa function:
;;
;;   (emp-prob-pbs $pattern $db $prob-estimate $db-ratio)
;;
;; Requested MM2 scope:
;;
;;   Do not implement the PeTTa sampling / bootstrap branch. Always use the
;;   direct empirical probability:
;;
;;     emp-prob(pattern) = support(pattern) / universe-count(pattern)
;;     universe-count(pattern) = DB-SIZE ^ number-of-conjuncts(pattern)
;;
;; MM2 public result:
;;
;;   (emp-prob-pbs-of $pattern $prob)
;;   (emp-prob-pbs-universe-count $pattern $universe-count)
;;
;; Required input facts:
;;
;;   (INPUT DB-SIZE $db-size)
;;   (isurp-pattern $pattern $support)
;;
;; `prob-estimate` and `db-ratio` are intentionally ignored here because the
;; sampling branch is intentionally not ported.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s110 emp-prob-pbs-pattern-size)
    (, (isurp-pattern $pattern $support))
    (O
        (pure
            (emp-prob-pbs-pattern-size-of $pattern $size)
            $size
            (size-atom
                (' $pattern)))))


(exec (surp s111 emp-prob-pbs-universe)
    (, (INPUT DB-SIZE $db-size)
       (emp-prob-pbs-pattern-size-of $pattern $size))
    (O
        (pure
            (emp-prob-pbs-universe-count $pattern $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string $size))))))


(exec (surp s112 emp-prob-pbs-strength)
    (, (isurp-pattern $pattern $support)
       (emp-prob-pbs-universe-count $pattern $universe-count))
    (O
        (pure
            (emp-prob-pbs-of $pattern $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $universe-count))))))
