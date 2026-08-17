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
;;
;; This implementation iterates over any number of partitions.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp 196 do-ji-tv-start-empty)
    (, (do-ji-tv-est-request ()))
    (, (do-ji-tv-est-list-of () ())
       (do-ji-tv-est-of () ())))


(exec (surp 196 do-ji-tv-start)
    (, (do-ji-tv-est-request $partitions)
       (DEF do-ji-tv-step $step-p $step-t))
    (O
        (+ (do-ji-tv-acc $partitions $partitions ()))
        (+ (exec (surp 197 do-ji-tv-step) $step-p $step-t))))


(DEF do-ji-tv-step
    (, (do-ji-tv-acc $partitions $remaining $tv-list)
       (DEF do-ji-tv-resolve $resolve-p $resolve-t))
    (O
        (pure
            (do-ji-tv-current $partitions $remaining $partition)
            $partition
            (car-atom (' $remaining)))
        (pure
            (do-ji-tv-rest $partitions $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (do-ji-tv-acc $partitions $remaining $tv-list))
        (+ (do-ji-tv-pending $partitions $remaining $tv-list))
        (+ (exec (surp 198 do-ji-tv-resolve) $resolve-p $resolve-t))))


(DEF do-ji-tv-resolve
    (, (do-ji-tv-pending $partitions $remaining $tv-list)
       (do-ji-tv-current $partitions $remaining $partition)
       (do-ji-tv-rest $partitions $remaining $rest)
       (ji-tv-est-of $partition $tv)
       (DEF do-ji-tv-step $step-p $step-t)
       (DEF do-ji-tv-final-request $final-p $final-t))
    (O
        (pure
            (do-ji-tv-acc $partitions $rest $new-tv-list)
            $new-tv-list
            (append (' ($tv-list ($tv)))))
        (- (do-ji-tv-pending $partitions $remaining $tv-list))
        (- (do-ji-tv-current $partitions $remaining $partition))
        (- (do-ji-tv-rest $partitions $remaining $rest))
        (+ (exec (surp 196 do-ji-tv-final-request) $final-p $final-t))
        (+ (exec (surp 197 do-ji-tv-step) $step-p $step-t))))


(DEF do-ji-tv-final-request
    (, (do-ji-tv-acc $partitions () $tv-list))
    (O
        (- (do-ji-tv-acc $partitions () $tv-list))
        (+ (do-ji-tv-est-list-of $partitions $tv-list))
        (+ (avrg-tv-request $tv-list))))


(exec (surp 230 do-ji-tv-final)
    (, (do-ji-tv-est-list-of $partitions $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (do-ji-tv-est-of $partitions $stv)))
