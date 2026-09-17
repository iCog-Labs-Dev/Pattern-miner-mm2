;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Block support
;;
;; Current ISurp modules need support counts for each generated partition block:
;;
;;   (block-support $pattern $partition $indexed-block $support)
;;
;; `pro-prob-wout-joint.metta` uses this to compute independent block
;; probabilities.  `abstractness-sort.metta` uses it as the support/value
;; fallback after selecting the most abstract block for a joint variable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s040 block-support-request)
    (, (isurp-pattern $pattern $pattern-support)
       (block $pattern $partition $indexed-block))
    (, (block-support-gate-request $pattern $partition $indexed-block)))

;; All block support goes through the shared common-utils cache gate. Partition
;; identity is carried only as result context, so the same block appearing in
;; several partitions is counted once and delivered to each partition.
(exec (surp s041 block-support-gate)
    (, (block-support-gate-request $pattern $partition $indexed-block)
       (INPUT SUPPORT-MODE $support-mode)
       ((support-gate
          $support-mode
          (block-support-gate-request $pattern $partition $indexed-block)
          ($pattern $partition)
          $indexed-block
          (surp s042 block-support-cache-hit)
          (surp s043 count-block-support)
          (surp s044 deliver-block-support)
          -> block-support-result)
        $gate-p $gate-t))
    (O
        (+ (exec (surp s041 run-block-support-gate) $gate-p $gate-t))))


(exec (surp s045 block-support-result)
    (, (block-support-result ($pattern $partition) $indexed-block $support))
    (, (block-support $pattern $partition $indexed-block $support)))
