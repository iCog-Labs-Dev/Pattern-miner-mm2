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


(exec (surp 170 pro-tv-start)
    (, (partition $partition)
       (DEF pro-tv-step $step-p $step-t))
    (O
        (+ (pro-tv-acc $partition $partition ()))
        (+ (exec (surp 171 pro-tv-step) $step-p $step-t))))


(DEF pro-tv-step
    (, (pro-tv-acc $partition $remaining $tv-list)
       (DEF pro-tv-resolve $resolve-p $resolve-t))
    (O
        (pure
            (pro-tv-current $partition $remaining $block)
            $block
            (car-atom (' $remaining)))
        (pure
            (pro-tv-rest $partition $remaining $rest)
            $rest
            (cdr-atom (' $remaining)))
        (- (pro-tv-acc $partition $remaining $tv-list))
        (+ (pro-tv-pending $partition $remaining $tv-list))
        (+ (exec (surp 172 pro-tv-resolve) $resolve-p $resolve-t))))


(DEF pro-tv-resolve
    (, (pro-tv-pending $partition $remaining $tv-list)
       (pro-tv-current $partition $remaining $block)
       (pro-tv-rest $partition $remaining $rest)
       (block-tv-of $partition $block $tv)
       (DEF pro-tv-step $step-p $step-t)
       (DEF pro-tv-final $final-p $final-t))
    (O
        (pure
            (pro-tv-acc $partition $rest $new-tv-list)
            $new-tv-list
            (append (' ($tv-list ($tv)))))
        (- (pro-tv-pending $partition $remaining $tv-list))
        (- (pro-tv-current $partition $remaining $block))
        (- (pro-tv-rest $partition $remaining $rest))
        (+ (exec (surp 170 pro-tv-final) $final-p $final-t))
        (+ (exec (surp 171 pro-tv-step) $step-p $step-t))))


(DEF pro-tv-final
    (, (pro-tv-acc $partition () $tv-list))
    (O
        (- (pro-tv-acc $partition () $tv-list))
        (+ (pro-tv-request $partition $tv-list))
        (+ (avrg-tv-request $tv-list))))


(exec (surp 193 pro-tv-assemble)
    (, (pro-tv-request $partition $tv-list)
       (avrg-tv-of $tv-list $stv))
    (, (pro-tv-wout-joint-of $partition $stv)))
