;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ji-prob-est
;;
;; Source PeTTa function:
;;
;;   (ji-prob-est $partition $pattern $db $db_ratio)
;;
;; Source meaning:
;;
;;   ji-prob-est(partition)
;;     = pro-prob-wout-joint(partition, db, db_ratio, 1)
;;       * eq-prob(partition, pattern, db)
;;
;; MM2 public result:
;;
;;   (ji-prob-est-of $partition $prob)
;;
;; Required input/intermediate facts:
;;
;;   (pro-prob-wout-joint-of $partition $independent-prob)
;;   (eq-prob-of $partition $eq-prob)
;;
;; `pattern`, `db`, and `db_ratio` are not explicit fields in this materialized
;; fact yet.  The required context is already carried by the loaded Space:
;; partition facts, block support facts, DB size, and DB atoms.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec 40
    (, (pro-prob-wout-joint-of $partition $independent-prob)
       (eq-prob-of $partition $eq-prob))
    (O
        (pure
            (ji-prob-est-of $partition $prob)
            $prob
            (f64_to_string
                (product_f64
                    (f64_from_string $independent-prob)
                    (f64_from_string $eq-prob))))))
