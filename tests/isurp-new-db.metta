;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Newer ISurp integration test DB
;;
;; Pattern:
;;
;;   (, (Inheritance (var 0) man)
;;      (Inheritance (var 0) ugly))
;;
;; DB:
;;
;;   Allen is both man and ugly.
;;   Bob is man only.
;;   Lily is ugly only.
;;
;; Counts:
;;
;;   DB-SIZE = 4
;;   full pattern support = 1
;;   empirical probability = 1 / (4 ^ 2) = 0.0625
;;
;; Expected generated partition estimate:
;;
;;   `partitions-wout-pattern` excludes the original full pattern, so for this
;;   2-conjunct pattern only the two-block partition is used:
;;
;;     pro-prob-wout-joint = (2 / 4) * (2 / 4) = 0.25
;;     eq-prob = 1 / 2 = 0.5
;;     ji-prob-est = 0.125
;;
;; Interval:
;;
;;   [0.125, 0.125]
;;
;; Since empirical probability is below the interval, expected raw ISurp:
;;
;;   0.125 - 0.0625 = 0.0625
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB db)
(INPUT DB-SIZE 4)
(INPUT NORMALIZATION FALSE)

(INPUT PATTERN
    ((, (Inheritance (var 0) man)
        (Inheritance (var 0) ugly))
     1))

(Inheritance Allen man)
(Inheritance Bob man)
(Inheritance Allen ugly)
(Inheritance Lily ugly)
