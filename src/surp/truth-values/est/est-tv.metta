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


(exec (surp s125 est-tv-request)
    (, (isurp-pattern $pattern $support)
       (ji-prob-partitions-of $pattern $partitions))
    (, (do-ji-tv-est-request $pattern $partitions)
       (est-tv-request $pattern $partitions)))


(exec (surp s240 est-tv-final)
    (, (est-tv-request $pattern $partitions)
       (do-ji-tv-est-of $pattern $partitions $stv))
    (, (est-tv-of $pattern $stv)))
