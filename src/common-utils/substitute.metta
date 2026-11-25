; =============================================================================
; Recursive Pattern Substitution Engine
;
; Input Format:
;   (SUBSTITUTE <id> <pattern> <values>)
;   - <id>: Unique name or identifier (e.g. p1, p2)
;   - <pattern>: Expression with variables to replace (e.g. (Inheritance $a $b))
;   - <values>: List of values to plug into variables (e.g. (nati bob))
;   Example:
;     (SUBSTITUTE p1 (Inheritance $a $b) (nati bob))
;
; Output Format:
;   (SUBSTITUTED <id> <result>)
;   - <id>: The matching identifier from the input
;   - <result>: The pattern with its variables replaced by values
;   Example:
;     (SUBSTITUTED p1 (Inheritance nati bob))
;
; =============================================================================

(exec (f000)
    (, (DEF run-substitute $run-substitute $rs-t))
    (O
        (+ (exec (f005) $run-substitute $rs-t))
    )
)

(DEF run-substitute
    (, (SUBSTITUTE $id $ptrn $values)
        (DEF take-first $take-first-p $tf-t)
        (DEF validate-vals $validate-vals-p $vv-t)
        (DEF validate-ptrn $validate-ptrn-p $vp-t)
    )
    (O
        (+ (WALK $id $ptrn $values () ()))

        (+ (exec (f010) $validate-vals-p $vv-t))
        (+ (exec (f011) $validate-ptrn-p $vp-t))
        (+ (exec (f012) $take-first-p $tf-t))
    )
)

(DEF validate-vals
    (, (WALK $id $ptrn () () ())
    )
    (O  
        ; check if values are empty in matching
        (+ (SUBSTITUTED $id $ptrn))
        (- (WALK $id $ptrn () () ()))
    )
)

(DEF validate-ptrn
    (, (WALK $id () $any () ())
    )
    (O  
        ; check if values are empty in matching
        (+ (SUBSTITUTED $id ()))
        (- (WALK $id () $any () ()))
    )
)

(DEF take-first
    (, (WALK $id $ptrn $vals $coll $stack)
        (DEF substitute $substitute-p $s-t)
        (DEF substitute-end-vals $substitute-end-vals-p $sev-t)
    )
    (O
        (pure (p-head $id $head) $head (car-atom (' $ptrn)))
        (pure (p-tail $id $tail) $tail (cdr-atom (' $ptrn)))
        (pure (is-head-var $id $is-var) $is-var (i8_to_string (is_var (car-atom (' $ptrn)))))
        (pure (is-p-nested $id $is-it) $is-it (i8_to_string (is_exp (car-atom (' $ptrn)))))
        
        (+ (p-state $id $vals $coll $stack))
        (- (WALK $id $ptrn $vals $coll $stack))

        (+ (exec (f015) $substitute-end-vals-p $sev-t))
        (+ (exec (f016) $substitute-p $s-t))
    )
)

; ptrn empty, check stack empty if empty finish else subsitute the rest.
(DEF end-case-ptrn
    (, (WALK $id () $vals $coll $stack)
       (DEF end-case-done $done-p $done-t)
       (DEF end-case-pop $pop-p $pop-t)
    )
    (O
        (+ (end-case-state $id $vals $coll $stack))
        (- (WALK $id () $vals $coll $stack))

        (+ (exec (f013) $done-p $done-t))
        (+ (exec (f014) $pop-p $pop-t))
    )
)

; stack is empty substitute is finished
(DEF end-case-done
    (, (end-case-state $id $vals $coll ())
    )
    (O
        (pure (SUBSTITUTED $id $subs) $subs
            (reverse (' $coll))
        )
        (- (end-case-state $id $vals $coll ()))
    )
)

; stack is not empty. put the previous tail to finish walk
(DEF end-case-pop
    (, (end-case-state $id $vals $coll ($prev-state $rest-stack))
    )
    (O
        (pure (parent-tail $id $pt) $pt (car-atom (' $prev-state)))
        (pure (parent-coll $id $pc) $pc (car-atom (cdr-atom (' $prev-state))))
        (pure (cur-coll $id $cc) $cc (reverse (' $coll)))

        (+ (exec (f017)
            (, (parent-tail $id $pt)
               (parent-coll $id $pc)
               (cur-coll $id $cc)
               (DEF take-first $take-first-p $tf-t)
               (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
            )
            (O
                (pure (WALK $id $pt $vals $new-parent-coll $rest-stack) $new-parent-coll
                    (cons (' ($cc $pc)))
                )
                (- (parent-tail $id $pt))
                (- (parent-coll $id $pc))
                (- (cur-coll $id $cc))

                (+ (exec (f010) $end-case-ptrn-p $ecp-t))
                (+ (exec (f012) $take-first-p $tf-t))
            )
        ))

        (- (end-case-state $id $vals $coll ($prev-state $rest-stack)))
    )
)

; matches target variable. var & not nested
(DEF substitute
    (, (p-head $id $head)
       (p-tail $id $tail)
       (is-head-var $id 1)
       (is-p-nested $id 0)
       (p-state $id $vals $coll $stack)
    )
    (O  
        ; pop first value
        (pure (val-tail $id $vals-tail) $vals-tail
            (cdr-atom (' $vals))
        )

        ; get first value
        (pure (val-head $id $val-head) $val-head
            (car-atom (' $vals)) 
        )

        (+ (exec (f016)
            (,
                (val-tail $id $vals-tail)
                (val-head $id $val-head)
                (p-tail $id $tail)
                (p-state $id $vals $coll $stack)
                (DEF take-first $take-first-p $tf-t)
                (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
            )
            (O
                (pure (WALK $id $tail $vals-tail $new-coll $stack) $new-coll
                    (cons (' ($val-head $coll)))
                )

                (- (val-tail $id $vals-tail))
                (- (val-head $id $val-head))
                (- (p-tail $id $tail))
                (- (p-state $id $vals $coll $stack))

                (+ (exec (f010) $end-case-ptrn-p $ecp-t))
                (+ (exec (f012) $take-first-p $tf-t))
            )
        ))

        (- (p-head $id $head))
        (- (is-head-var $id 1))
        (- (is-p-nested $id 0))
    )
)

; matches constant. neither var nor nested
(DEF substitute
    (, (p-head $id $head)
       (p-tail $id $tail)
       (is-head-var $id 0)
       (is-p-nested $id 0)
       (p-state $id $vals $coll $stack)
       (DEF take-first $take-first-p $tf-t)
       (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
    )
    (O
        (pure (WALK $id $tail $vals $new-coll $stack) $new-coll
            (cons (' ($head $coll)))
        )

        (- (p-head $id $head))
        (- (p-tail $id $tail))
        (- (is-head-var $id 0))
        (- (is-p-nested $id 0))
        (- (p-state $id $vals $coll $stack))

        (+ (exec (f010) $end-case-ptrn-p $ecp-t))
        (+ (exec (f012) $take-first-p $tf-t))
    )
)

; matches nested
(DEF substitute
    (, (p-head $id $head)
       (p-tail $id $tail)
       (is-head-var $id 0)
       (is-p-nested $id 1)
       (p-state $id $vals $coll $stack)
       (DEF take-first $take-first-p $tf-t)
       (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
    )
    (O  
        ; push current collector to stack with current tail: ($tail $coll)
        ; also push the previous stack if any. (($tail $coll) $stack)
        ; empty collector for new nested expression
        (+ (WALK $id $head $vals () (($tail $coll) $stack)))

        (- (p-head $id $head))
        (- (p-tail $id $tail))
        (- (is-head-var $id 0))
        (- (is-p-nested $id 1))
        (- (p-state $id $vals $coll $stack))

        (+ (exec (f010) $end-case-ptrn-p $ecp-t))
        (+ (exec (f012) $take-first-p $tf-t))
    )
)

; matches if values empty before ptrn, substitute to end either var, constant, or nested
(DEF substitute-end-vals
    (, (p-head $id $head)
       (p-tail $id $tail)
       (is-head-var $id $any-var)
       (is-p-nested $id $any-nest)
       (p-state $id () $coll $stack)
       (DEF take-first $take-first-p $tf-t)
       (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
    )
    (O
        (pure (WALK $id $tail () $new-coll $stack) $new-coll
            (cons (' ($head $coll)))
        )

        (- (p-head $id $head))
        (- (p-tail $id $tail))
        (- (is-head-var $id $any-var))
        (- (is-p-nested $id $any-nest))
        (- (p-state $id () $coll $stack))

        (+ (exec (f010) $end-case-ptrn-p $ecp-t))
        (+ (exec (f012) $take-first-p $tf-t))
    )
)

; cleanup
(exec (f100)
    (, (DEF run-substitute $run-substitute $rs-t)
        (DEF take-first $take-first-p $tf-t)
        (DEF substitute $substitute-p $s-t)
        (DEF end-case-ptrn $end-case-ptrn-p $ecp-t)
        (DEF end-case-done $done-p $done-t)
        (DEF end-case-pop $pop-p $pop-t)
        (DEF substitute-end-vals $substitute-end-vals-p $sev-t)
        (DEF validate-vals $validate-vals-p $vv-t)
        (DEF validate-ptrn $validate-ptrn-p $vp-t)
    )
    (O
        (- (DEF run-substitute $run-substitute $rs-t))
        (- (DEF take-first $take-first-p $tf-t))
        (- (DEF substitute $substitute-p $s-t))
        (- (DEF end-case-ptrn $end-case-ptrn-p $ecp-t))
        (- (DEF end-case-done $done-p $done-t))
        (- (DEF end-case-pop $pop-p $pop-t))
        (- (DEF substitute-end-vals $substitute-end-vals-p $sev-t))
        (- (DEF validate-vals $validate-vals-p $vv-t))
        (- (DEF validate-ptrn $validate-ptrn-p $vp-t))
    )
)