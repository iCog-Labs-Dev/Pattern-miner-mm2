;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Collect and average JI truth value estimates.
;;
;; Source PeTTa function:
;;
;;   do-ji-tv-est
;;
;; MM2 public result:
;;
;;   (do-ji-tv-est-of $partitions (STV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 196 do-ji-tv-empty)
    (, (do-ji-tv-est-request ()))
    (, (do-ji-tv-est-list-of () ())))


(exec (surp 196 do-ji-tv-1)
    (, (do-ji-tv-est-request ($p1))
       (ji-tv-est-of $p1 $tv1))
    (, (do-ji-tv-est-list-of ($p1) ($tv1))
       (do-ji-tv-est-of ($p1) $tv1)))


(exec (surp 196 do-ji-tv-2)
    (, (do-ji-tv-est-request ($p1 $p2))
       (ji-tv-est-of $p1 $tv1)
       (ji-tv-est-of $p2 $tv2))
    (, (do-ji-tv-est-list-of ($p1 $p2) ($tv1 $tv2))
       (avrg-tv-request ($tv1 $tv2))))


(exec (surp 196 do-ji-tv-3)
    (, (do-ji-tv-est-request ($p1 $p2 $p3))
       (ji-tv-est-of $p1 $tv1)
       (ji-tv-est-of $p2 $tv2)
       (ji-tv-est-of $p3 $tv3))
    (, (do-ji-tv-est-list-of ($p1 $p2 $p3) ($tv1 $tv2 $tv3))
       (avrg-tv-request ($tv1 $tv2 $tv3))))


(exec (surp 196 do-ji-tv-4)
    (, (do-ji-tv-est-request ($p1 $p2 $p3 $p4))
       (ji-tv-est-of $p1 $tv1)
       (ji-tv-est-of $p2 $tv2)
       (ji-tv-est-of $p3 $tv3)
       (ji-tv-est-of $p4 $tv4))
    (, (do-ji-tv-est-list-of ($p1 $p2 $p3 $p4) ($tv1 $tv2 $tv3 $tv4))
       (avrg-tv-request ($tv1 $tv2 $tv3 $tv4))))


(exec (surp 197 do-ji-tv-final)
    (, (do-ji-tv-est-list-of $partitions $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (do-ji-tv-est-of $partitions $stv)))
