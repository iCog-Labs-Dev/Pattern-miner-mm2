;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Product truth value without joint-variable correction.
;;
;; Source PeTTa function:
;;
;;   pro_prob_without_joint
;;
;; The PeTTa name says probability, but the truth-value path returns an
;; averaged TV over empirical TVs of the partition blocks.
;;
;; MM2 public result:
;;
;;   (pro-tv-wout-joint-of $partition (STV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 170 pro-tv-request-1)
    (, (partition ($b1))
       (block-tv-of ($b1) $b1 $tv1))
    (, (avrg-tv-request ($tv1))
       (pro-tv-request ($b1) ($tv1))))


(exec (surp 170 pro-tv-request-2)
    (, (partition ($b1 $b2))
       (block-tv-of ($b1 $b2) $b1 $tv1)
       (block-tv-of ($b1 $b2) $b2 $tv2))
    (, (avrg-tv-request ($tv1 $tv2))
       (pro-tv-request ($b1 $b2) ($tv1 $tv2))))


(exec (surp 170 pro-tv-request-3)
    (, (partition ($b1 $b2 $b3))
       (block-tv-of ($b1 $b2 $b3) $b1 $tv1)
       (block-tv-of ($b1 $b2 $b3) $b2 $tv2)
       (block-tv-of ($b1 $b2 $b3) $b3 $tv3))
    (, (avrg-tv-request ($tv1 $tv2 $tv3))
       (pro-tv-request ($b1 $b2 $b3) ($tv1 $tv2 $tv3))))


(exec (surp 170 pro-tv-request-4)
    (, (partition ($b1 $b2 $b3 $b4))
       (block-tv-of ($b1 $b2 $b3 $b4) $b1 $tv1)
       (block-tv-of ($b1 $b2 $b3 $b4) $b2 $tv2)
       (block-tv-of ($b1 $b2 $b3 $b4) $b3 $tv3)
       (block-tv-of ($b1 $b2 $b3 $b4) $b4 $tv4))
    (, (avrg-tv-request ($tv1 $tv2 $tv3 $tv4))
       (pro-tv-request ($b1 $b2 $b3 $b4) ($tv1 $tv2 $tv3 $tv4))))


(exec (surp 193 pro-tv-final)
    (, (pro-tv-request $partition $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (pro-tv-wout-joint-of $partition $stv)))
