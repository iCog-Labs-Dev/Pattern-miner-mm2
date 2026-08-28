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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 100 do-ji-prob-start-empty)
    (, (do-ji-prob-request ()))
    (, (do-ji-prob-of () ())))


(exec (surp 100 do-ji-prob-start)
    (, (do-ji-prob-request $partitions)
       (DEF do-ji-prob-step $step-p $step-t))
    (O
        (+ (do-ji-prob-acc $partitions $partitions ()))
        (+ (exec (surp 101 do-ji-prob-step) $step-p $step-t))))


(DEF do-ji-prob-step
    (, (do-ji-prob-acc $partitions $remaining $prob-list)
       (DEF do-ji-prob-resolve $resolve-p $resolve-t))
    (O
        (pure
            (do-ji-prob-current $partitions $remaining $partition)
            $partition
            (car-atom (' $remaining)))
        (pure
            (do-ji-prob-rest $partitions $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (do-ji-prob-acc $partitions $remaining $prob-list))
        (+ (do-ji-prob-pending $partitions $remaining $prob-list))
        (+ (exec (surp 102 do-ji-prob-resolve) $resolve-p $resolve-t))))


(DEF do-ji-prob-resolve
    (, (do-ji-prob-pending $partitions $remaining $prob-list)
       (do-ji-prob-current $partitions $remaining $partition)
       (do-ji-prob-rest $partitions $remaining $rest)
       (ji-prob-est-of $partition $prob)
       (DEF do-ji-prob-step $step-p $step-t)
       (DEF do-ji-prob-final $final-p $final-t))
    (O
        (pure
            (do-ji-prob-acc $partitions $rest $new-prob-list)
            $new-prob-list
            (append (' ($prob-list ($prob)))))
        (- (do-ji-prob-pending $partitions $remaining $prob-list))
        (- (do-ji-prob-current $partitions $remaining $partition))
        (- (do-ji-prob-rest $partitions $remaining $rest))
        (+ (exec (surp 100 do-ji-prob-final) $final-p $final-t))
        (+ (exec (surp 101 do-ji-prob-step) $step-p $step-t))))


(DEF do-ji-prob-final
    (, (do-ji-prob-acc $partitions () $prob-list))
    (O
        (- (do-ji-prob-acc $partitions () $prob-list))
        (+ (do-ji-prob-of $partitions $prob-list))))
