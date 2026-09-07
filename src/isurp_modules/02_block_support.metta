;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Block support
;;
;; Current ISurp modules need support counts for each generated partition block:
;;
;;   (block-support $partition $indexed-block $support)
;;
;; `05_pro_prob_wout_joint.metta` uses this to compute independent block
;; probabilities.  `03_abstractness_sort.metta` uses it as the support/value
;; fallback after selecting the most abstract block for a joint variable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 040 block-support-request)
    (, (INPUT PATTERN ($pattern $pattern-support))
       (block $partition $indexed-block))
    (, (block-support-gate-request $partition $indexed-block)))

;; All block support goes through the shared common-utils cache gate. Partition
;; identity is carried only as result context, so the same block appearing in
;; several partitions is counted once and delivered to each partition.
(exec (surp 041 block-support-gate)
    (, (block-support-gate-request $partition $indexed-block)
       ((support-cache-gate
          (block-support-gate-request $partition $indexed-block)
          $partition
          $indexed-block
          (surp 042 block-support-cache-hit)
          (surp 043 count-block-support)
          (surp 044 deliver-block-support)
          -> block-support)
        $gate-p $gate-t))
    (O
        (+ (exec (surp 041 run-block-support-gate) $gate-p $gate-t))))
