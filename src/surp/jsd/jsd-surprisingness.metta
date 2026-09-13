;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pattern-level JSD surprisingness.
;;
;; Public fact:
;;
;;   (jsd-surp-of $pattern $jsd)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 297 jsd-surp-request)
    (, (emp-tv-of $pattern $emp-tv)
       (est-tv-of $pattern $est-tv))
    (, (do-jsd-request $emp-tv $est-tv)))


(exec (surp 326 jsd-surp-result)
    (, (emp-tv-of $pattern $emp-tv)
       (est-tv-of $pattern $est-tv)
       (do-jsd-of $emp-tv $est-tv $jsd))
    (, (jsd-surp-of $pattern $jsd)))
