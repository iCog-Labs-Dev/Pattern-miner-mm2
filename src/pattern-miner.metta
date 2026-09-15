;; Pattern-miner orchestration for the frequent-to-surprisingness handoff.
;;
;; Required modules in the same atomspace:
;;   src/common-utils/utils.metta
;;   src/freq/frequent-miner.metta
;;   src/freq/iterative-miner.metta
;;   src/freq/conjunction-expansion-triplet.metta
;;   src/freq/frequent-pattern-miner.metta
;;   selected surprisingness module, such as src/surp/isurp-old.metta
;;
;; Public request:
;;   (run-pattern-miner $root-pattern)
;;
;; Configuration:
;;   (INPUT SURPRISINGNESS-MODE isurp-old)
;;   (INPUT SURPRISINGNESS-MODE isurp)
;;   (INPUT SURPRISINGNESS-SCOPE all)
;;   (INPUT SURPRISINGNESS-SCOPE selected)
;;   (INPUT SURPRISINGNESS-PATTERN $indexed-pattern)
;;
;; Public surprisingness result:
;;   (pattern-miner-surprisingness $pattern-id $pattern $support $score)

(DEF pattern-miner-fn
  (, (run-pattern-miner $root-pattern)
     (INPUT SURPRISINGNESS-MODE isurp-old)
     (DEF frequent-pattern-miner-fn $freq-p $freq-t)
     (DEF pattern-miner-isurp-old-input-fn $input-p $input-t)
     (DEF pattern-miner-collect-surprisingness-fn $collect-p $collect-t))
  (O
    (- (run-pattern-miner $root-pattern))
    (+ (run-frequent-pattern-miner pattern-miner $root-pattern))
    (+ (pattern-miner-score isurp-old))
    (+ (exec (freq f000 materialize-pattern-miner-facts)
        (, $root-pattern)
        (O (+ (FACT $root-pattern)))))
    (+ (exec (freq f010 run-frequent-pattern-miner) $freq-p $freq-t))
    (+ (exec (surp s000 materialize-isurp-old-inputs) $input-p $input-t))
    (+ (exec (surp s930 collect-surprisingness-results) $collect-p $collect-t))))

(DEF pattern-miner-fn
  (, (run-pattern-miner $root-pattern)
     (INPUT SURPRISINGNESS-MODE isurp)
     (DEF frequent-pattern-miner-fn $freq-p $freq-t)
     (DEF pattern-miner-isurp-input-fn $input-p $input-t)
     (DEF pattern-miner-collect-isurp-fn $collect-p $collect-t))
  (O
    (- (run-pattern-miner $root-pattern))
    (+ (run-frequent-pattern-miner pattern-miner $root-pattern))
    (+ (pattern-miner-score isurp))
    (+ (exec (freq f000 materialize-pattern-miner-facts)
        (, $root-pattern)
        (O (+ (FACT $root-pattern)))))
    (+ (exec (freq f010 run-frequent-pattern-miner) $freq-p $freq-t))
    (+ (exec (surp s000 materialize-isurp-inputs) $input-p $input-t))
    (+ (exec (surp s930 collect-isurp-results) $collect-p $collect-t))))

;; Current isurp-old scoring supports three-conjunct inputs. The frequent miner
;; emits canonical indexed conjunction lists, while isurp-old consumes comma
;; conjunctions through INPUT PATTERN.
(DEF pattern-miner-isurp-old-input-fn
  (, (pattern-miner-score isurp-old)
     (expanded-conjunct 3 $indexed-conjunction $support))
  (O
    (pure
      (INPUT SCOPED-PATTERN ($indexed-conjunction $pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-collect-surprisingness-fn
  (, (pattern-miner-pattern $pattern-id $pattern $support)
     (surprisingess-of (isurp-pattern $pattern-id) $pattern $score))
  (O
    (+ (pattern-miner-surprisingness $pattern-id $pattern $support $score))))

(DEF pattern-miner-isurp-input-fn
  (, (pattern-miner-score isurp)
     (INPUT SURPRISINGNESS-SCOPE all)
     (expanded-conjunct 2 $indexed-conjunction $support))
  (O
    (pure
      (INPUT PATTERN ($pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-isurp-input-fn
  (, (pattern-miner-score isurp)
     (INPUT SURPRISINGNESS-SCOPE all)
     (expanded-conjunct 3 $indexed-conjunction $support))
  (O
    (pure
      (INPUT PATTERN ($pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-isurp-input-fn
  (, (pattern-miner-score isurp)
     (INPUT SURPRISINGNESS-SCOPE selected)
     (INPUT SURPRISINGNESS-PATTERN $indexed-conjunction)
     (expanded-conjunct 2 $indexed-conjunction $support))
  (O
    (pure
      (INPUT PATTERN ($pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-isurp-input-fn
  (, (pattern-miner-score isurp)
     (INPUT SURPRISINGNESS-SCOPE selected)
     (INPUT SURPRISINGNESS-PATTERN $indexed-conjunction)
     (expanded-conjunct 3 $indexed-conjunction $support))
  (O
    (pure
      (INPUT PATTERN ($pattern $support))
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))
    (pure
      (pattern-miner-pattern $indexed-conjunction $pattern $support)
      $pattern
      (indices_to_vars
        (cons , (' $indexed-conjunction))))))

(DEF pattern-miner-collect-isurp-fn
  (, (pattern-miner-pattern $pattern-id $pattern $support)
     (isurp-new-of $pattern-id $score))
  (O
    (+ (pattern-miner-surprisingness $pattern-id $pattern $support $score))))
