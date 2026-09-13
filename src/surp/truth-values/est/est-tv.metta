;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Top-level estimated truth value.
;;
;; Source PeTTa function:
;;
;;   do-ji-tv-est
;;
;; MM2 public result:
;;
;;   (est-tv-of $pattern (STV $strength $confidence))
;;
;; This module connects the existing ISurp partition pipeline upward into the
;; truth-value estimate.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 125 est-tv-request)
    (, (INPUT PATTERN ($pattern $support))
       (indexed-pattern-of $pattern $indexed-pattern)
       (ji-prob-partitions-of $indexed-pattern $partitions))
    (, (do-ji-tv-est-request $partitions)
       (est-tv-request $pattern $partitions)))


(exec (surp 240 est-tv-final)
    (, (est-tv-request $pattern $partitions)
       (do-ji-tv-est-of $partitions $stv))
    (, (est-tv-of $pattern $stv)))
