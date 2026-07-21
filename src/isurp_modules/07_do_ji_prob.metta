;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; do-ji-prob
;;
;; Source PeTTa function:
;;
;;   (do-ji-prob $partitions $pattern $db $db_ratio)
;;
;; Source meaning:
;;
;;   For each partition in a partition list:
;;
;;     ji-prob-est(partition, pattern, db, db_ratio)
;;
;;   Return the list of probabilities in the same order as the partitions.
;;
;; MM2 public result:
;;
;;   (do-ji-prob-of $partitions $prob-list)
;;
;; Input:
;;
;;   (do-ji-prob-request $partitions)
;;
;; Required intermediate facts:
;;
;;   (ji-prob-est-of $partition $prob)
;;
;; Current scope:
;;
;;   Explicit list-shape rules for 0, 1, 2, 3, and 4 partitions.  This follows
;;   the current MM2 implementation style.  A fully generic fold can replace it
;;   once the surrounding partition pipeline is generalized.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Empty partition list:
;;
;;   do-ji-prob(()) = ()
(exec 41
    (, (do-ji-prob-request ()))
    (, (do-ji-prob-of () ())))


;; One partition:
(exec 41
    (, (do-ji-prob-request ($p1))
       (ji-prob-est-of $p1 $j1))
    (, (do-ji-prob-of ($p1) ($j1))))


;; Two partitions:
(exec 41
    (, (do-ji-prob-request ($p1 $p2))
       (ji-prob-est-of $p1 $j1)
       (ji-prob-est-of $p2 $j2))
    (, (do-ji-prob-of ($p1 $p2) ($j1 $j2))))


;; Three partitions:
(exec 41
    (, (do-ji-prob-request ($p1 $p2 $p3))
       (ji-prob-est-of $p1 $j1)
       (ji-prob-est-of $p2 $j2)
       (ji-prob-est-of $p3 $j3))
    (, (do-ji-prob-of ($p1 $p2 $p3) ($j1 $j2 $j3))))


;; Four partitions:
(exec 41
    (, (do-ji-prob-request ($p1 $p2 $p3 $p4))
       (ji-prob-est-of $p1 $j1)
       (ji-prob-est-of $p2 $j2)
       (ji-prob-est-of $p3 $j3)
       (ji-prob-est-of $p4 $j4))
    (, (do-ji-prob-of ($p1 $p2 $p3 $p4) ($j1 $j2 $j3 $j4))))
