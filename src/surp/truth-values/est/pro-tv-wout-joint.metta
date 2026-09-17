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
;;   (pro-tv-wout-joint-of $pattern $partition (STV $strength $confidence))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(exec (surp s170 pro-tv-start)
    (, (partition $pattern $partition)
       (DEF pro-tv-step $step-p $step-t))
    (O
        (+ (pro-tv-acc $pattern $partition $partition ()))
        (+ (exec (surp s171 pro-tv-step) $step-p $step-t))))


(DEF pro-tv-step
    (, (pro-tv-acc $pattern $partition $remaining $tv-list)
       (DEF pro-tv-resolve $resolve-p $resolve-t))
    (O
        (pure
            (pro-tv-current $pattern $partition $remaining $block)
            $block
            (car-atom (' $remaining)))
        (pure
            (pro-tv-rest $pattern $partition $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (pro-tv-acc $pattern $partition $remaining $tv-list))
        (+ (pro-tv-pending $pattern $partition $remaining $tv-list))
        (+ (exec (surp s172 pro-tv-resolve) $resolve-p $resolve-t))))


(DEF pro-tv-resolve
    (, (pro-tv-pending $pattern $partition $remaining $tv-list)
       (pro-tv-current $pattern $partition $remaining $block)
       (pro-tv-rest $pattern $partition $remaining $rest)
       (block-tv-of $pattern $partition $block $tv)
       (DEF pro-tv-step $step-p $step-t)
       (DEF pro-tv-final $final-p $final-t))
    (O
        (pure
            (pro-tv-acc $pattern $partition $rest $new-tv-list)
            $new-tv-list
            (append (' ($tv-list ($tv)))))
        (- (pro-tv-pending $pattern $partition $remaining $tv-list))
        (- (pro-tv-current $pattern $partition $remaining $block))
        (- (pro-tv-rest $pattern $partition $remaining $rest))
        (+ (exec (surp s170 pro-tv-final) $final-p $final-t))
        (+ (exec (surp s171 pro-tv-step) $step-p $step-t))))


(DEF pro-tv-final
    (, (pro-tv-acc $pattern $partition () $tv-list))
    (O
        (- (pro-tv-acc $pattern $partition () $tv-list))
        (+ (pro-tv-request $pattern $partition $tv-list))
        (+ (avrg-tv-request $tv-list))))


(exec (surp s193 pro-tv-assemble)
    (, (pro-tv-request $pattern $partition $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (pro-tv-wout-joint-of $pattern $partition $stv)))
