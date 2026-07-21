;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; emp-prob-pbs without sampling
;;
;; Source PeTTa function:
;;
;;   (emp-prob-pbs $pattern $db $prob-estimate $db-ratio)
;;
;; Requested MM2 scope:
;;
;;   Do not implement the PeTTa sampling / bootstrap branch.  Always use the
;;   direct empirical probability:
;;
;;     emp-prob(pattern) = support(pattern) / universe-count(pattern)
;;
;;   where:
;;
;;     universe-count(pattern) = DB-SIZE ^ number-of-conjuncts(pattern)
;;
;; MM2 public result:
;;
;;   (emp-prob-pbs-of $pattern $prob)
;;
;; Required input facts:
;;
;;   (INPUT DB-SIZE $db-size)
;;   (INPUT PATTERN ($pattern $support))
;;
;; `prob-estimate` and `db-ratio` are intentionally ignored here because the
;; sampling branch is intentionally not ported.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; One-conjunct pattern:
;;
;;   universe-count = DB-SIZE
(exec 17
    (, (INPUT DB-SIZE $db-size)
       (INPUT PATTERN ((, $c1) $support)))
    (O
        (pure
            (emp-prob-pbs-of (, $c1) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string $db-size))))))


;; Two-conjunct pattern:
;;
;;   universe-count = DB-SIZE ^ 2
(exec 17
    (, (INPUT DB-SIZE $db-size)
       (INPUT PATTERN ((, $c1 $c2) $support)))
    (O
        (pure
            (emp-prob-pbs-universe-count (, $c1 $c2) $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string 2))))
        (pure
            (emp-prob-pbs-of (, $c1 $c2) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (i64_from_string 2)))))))))


;; Three-conjunct pattern:
;;
;;   universe-count = DB-SIZE ^ 3
(exec 17
    (, (INPUT DB-SIZE $db-size)
       (INPUT PATTERN ((, $c1 $c2 $c3) $support)))
    (O
        (pure
            (emp-prob-pbs-universe-count (, $c1 $c2 $c3) $universe-count)
            $universe-count
            (i64_to_string
                (pow_i64
                    (i64_from_string $db-size)
                    (i64_from_string 3))))
        (pure
            (emp-prob-pbs-of (, $c1 $c2 $c3) $prob)
            $prob
            (f64_to_string
                (div_f64
                    (f64_from_string $support)
                    (f64_from_string
                        (i64_to_string
                            (pow_i64
                                (i64_from_string $db-size)
                                (i64_from_string 3)))))))))
