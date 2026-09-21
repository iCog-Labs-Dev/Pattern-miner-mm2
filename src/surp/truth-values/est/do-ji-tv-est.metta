;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Collect and average JI truth value estimates.
;;
;; Source PeTTa function:
;;
;;   do-ji-tv-est
;;
;; MM2 public result:
;;
;;   (do-ji-tv-est-of $pattern $partitions (STV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s196 do-ji-tv-start-empty)
    (, (do-ji-tv-est-request $pattern ()))
    (, (do-ji-tv-est-list-of $pattern () ())
       (do-ji-tv-est-of $pattern () ())))


(exec (surp s196 do-ji-tv-start)
    (, (do-ji-tv-est-request $pattern $partitions)
       (DEF do-ji-tv-step $step-p $step-t))
    (O
        (+ (do-ji-tv-acc $pattern $partitions $partitions ()))
        (+ (exec (surp s197 do-ji-tv-step) $step-p $step-t))))


(DEF do-ji-tv-step
    (, (do-ji-tv-acc $pattern $partitions $remaining $tv-list)
       (DEF do-ji-tv-resolve $resolve-p $resolve-t))
    (O
        (pure
            (do-ji-tv-current $pattern $partitions $remaining $partition)
            $partition
            (car-atom (' $remaining)))
        (pure
            (do-ji-tv-rest $pattern $partitions $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (do-ji-tv-acc $pattern $partitions $remaining $tv-list))
        (+ (do-ji-tv-pending $pattern $partitions $remaining $tv-list))
        (+ (exec (surp s198 do-ji-tv-resolve) $resolve-p $resolve-t))))


(DEF do-ji-tv-resolve
    (, (do-ji-tv-pending $pattern $partitions $remaining $tv-list)
       (do-ji-tv-current $pattern $partitions $remaining $partition)
       (do-ji-tv-rest $pattern $partitions $remaining $rest)
       (ji-tv-est-of $pattern $partition $tv)
       (DEF do-ji-tv-step $step-p $step-t)
       (DEF do-ji-tv-final-request $final-p $final-t))
    (O
        (pure
            (do-ji-tv-acc $pattern $partitions $rest $new-tv-list)
            $new-tv-list
            (append (' ($tv-list ($tv)))))
        (- (do-ji-tv-pending $pattern $partitions $remaining $tv-list))
        (- (do-ji-tv-current $pattern $partitions $remaining $partition))
        (- (do-ji-tv-rest $pattern $partitions $remaining $rest))
        (+ (exec (surp s196 do-ji-tv-final-request) $final-p $final-t))
        (+ (exec (surp s197 do-ji-tv-step) $step-p $step-t))))


(DEF do-ji-tv-final-request
    (, (do-ji-tv-acc $pattern $partitions () $tv-list))
    (O
        (- (do-ji-tv-acc $pattern $partitions () $tv-list))
        (+ (do-ji-tv-est-list-of $pattern $partitions $tv-list))
        (+ (avrg-tv-request $tv-list))))


(exec (surp s230 do-ji-tv-final)
    (, (do-ji-tv-est-list-of $pattern $partitions $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (do-ji-tv-est-of $pattern $partitions $stv)))
