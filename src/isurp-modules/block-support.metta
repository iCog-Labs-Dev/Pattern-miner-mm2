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
