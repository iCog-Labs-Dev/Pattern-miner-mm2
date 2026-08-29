;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Block support
;;
;; Current ISurp modules need support counts for each generated partition block:
;;
;;   (block-support $partition $indexed-block $support)
;;
;; `pro-prob-wout-joint.metta` uses this to compute independent block
;; probabilities.  `abstractness-sort.metta` uses it as the support/value
;; fallback after selecting the most abstract block for a joint variable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 040 block-support-query)
    (, (INPUT PATTERN ($pattern $pattern-support))
       (block $partition $indexed-block))
    (O
        ;; Keep the generated query visible for debugging.
        (pure
            (debug-block-query $partition $indexed-block $query)
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))

        ;; Create a real exec from the generated query.  When that exec runs it
        ;; counts support for this block.
        (pure
            (exec (surp 041 count-block-support)
                $query
                (O
                    (count
                        (block-support $partition $indexed-block $support)
                        $support
                        $query)))
            $query
            (indices_to_vars
                (cons , (' $indexed-block))))))


;; Direct fallback for common one-clause binary predicate blocks:
;;
;;   ((Inheritance (var 0) man))
;;
;; Some current MORK/helper combinations do not materialize the dynamic
;; `indices_to_vars` query above for already-indexed input patterns.  This
;; fallback keeps support counting available for the common binary predicate
;; shape used in the ISurp integration tests.
(exec (surp 040 block-support-fallback)
    (, (block $partition (($rel (var $n) $arg))))
    (,
        (exec (surp 041 count-block-support)
            (, ($rel $x $arg))
            (O
                (count
                    (block-support $partition (($rel (var $n) $arg)) $support)
                    $support
                    ($rel $x $arg))))))
