;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Beta(alpha, beta) cumulative distribution function  ==  regularized
;; incomplete beta  I_x(alpha, beta)  ==  boost::math::cdf(beta_distribution,x)
;;
;; Source (C++):    boost::math::cdf(beta_distribution(alpha,beta),
;;                                   std::min(1.0, x))
;; Source (Python): hyperon-miner/experiments/utils/boost/main.py
;;                  (scipy.stats.beta.cdf)
;; Source (MeTTa):  hyperon-miner/experiments/utils/surp-utils/boost-petta.metta
;;                  (Numerical Recipes betai / betacf / gammln)
;;
;; Pure MM2, MORK pure.rs primitives only -- no mm2-stdlib, no MM2-Helper, no
;; py-call, no rebuild. Method is "Numerical Recipes in C", 2nd ed:
;;
;;   betai(a,b,x):
;;     x == 0 or x == 1        -> x
;;     lbeta = lnG(a) + lnG(b) - lnG(a+b)
;;     bt    = exp( a*ln(x) + b*ln(1-x) - lbeta )
;;     x < (a+1)/(a+b+2)       -> bt * betacf(a,b,x) / a
;;     otherwise              -> 1 - bt * betacf(b,a,1-x) / b
;;
;;   lnG(z)  -- gammln, Lanczos g=5, 6 coefficients, unrolled (no loop),
;;              z > 0 (miner always has alpha,beta > 0).
;;
;;   betacf(a,b,x)  -- modified Lentz continued fraction, FIXED 200 iterations
;;              (convergence for miner inputs is ~10-20 iterations; the extra
;;              passes are harmless, h has stabilised).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MM2 EXECUTION NOTES (verified by running this on the local vanilla `mork`)
;;
;;  * A plain `exec` fires ONCE, at its priority, over every match then live.
;;    It never re-fires for facts that appear later. A linear pipeline works
;;    only because each stage's priority is above the previous one's and every
;;    input already exists when the stage fires.
;;
;;  * A self-rescheduling `exec` (matches `(exec <p> $s $t)` in its own source
;;    and re-adds it) keeps running ONLY while, on every selection, its data
;;    trigger is present AND that trigger's content changed since last firing.
;;      - the first selection with no match  -> consumed, loop dead;
;;      - `(- X) (+ X)` of an unchanged fact -> cancels, X gone, loop dead.
;;    So the loop is ONE rule; its whole mutable state lives in ONE fact that
;;    always changes (the iteration counter is inside it); constants sit in a
;;    separate fact that is referenced but never modified.
;;
;;  * One betacf iteration is a single firing. The state fact is
;;      (bc-cf $id ($m $c $d $h))
;;    and the next one is written whole by:
;;      (pure $w $w (tuple PRED $id (tuple m+1 c2 d2 h2)))
;;    where PRED is `(ifnz COND then bc-cf else bc-cf-fin)` -- once m reaches
;;    200 the fact is written under `bc-cf-fin`, the loop stops matching, and
;;    stage 250 finalises. c2/d2/h2 are fully inlined nested expressions over
;;    the OLD c,d,h,m plus the constants; deep nesting is fine on this build.
;;
;;  * Every constant goes through `f64_from_string`; passing a bare numeric
;;    literal into an f64 op silently produces nothing.
;;
;;  * Comparisons (no lt_f64/ge_i32 in pure.rs): signum_f64 gives +1/-1/(+1 at
;;    exactly 0); max_f64(0.0, signum_f64(p - q)) is 1.0 when p >= q, 0.0 when
;;    p < q, and `ifnz` routes 0.0 -> else. Ties -> then; the two places that
;;    matters (x == threshold, m == 199.5) are numerically safe.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC INTERFACE
;;
;;   Request fact (caller writes it):
;;       (beta-cdf? $id $alpha $beta $x)
;;         $id                unique tag chosen by the caller
;;         $alpha $beta $x    decimal-string numbers, e.g. 5.0 2.0 0.5
;;
;;   Result fact (this file produces it):
;;       (beta-cdf-of $id $cdf)        $cdf = decimal string in [0, 1]
;;
;;   x is clamped to [0, 1] first (matches std::min(1.0, x) plus a low guard).
;;   boost-math-cdf(alpha, beta, x)  ==  (beta-cdf? $id alpha beta x)
;;
;;   Every other fact uses the `bc-` prefix and is private state, removed by the
;;   29x cleanup stages once (bc-done $id) appears.
;;
;; Primitives used, all from MORK pure.rs:
;;   f64_from_string f64_to_string sum_f64 sub_f64 product_f64 div_f64
;;   neg_f64 abs_f64 ln_f64 exp_f64 signum_f64 max_f64 clamp_f64 ifnz tuple
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;===============================================================
;; Stage 200 -- intake: clamp x into [0, 1]
;;===============================================================
(exec (surp 200 bc-intake)
    (, (beta-cdf? $id $alpha $beta $x))
    (O
        (+ (bc-params $id $alpha $beta $x))
        (pure
            (bc-xc $id $xc)
            $xc
            (clamp_f64
                (f64_from_string $x)
                (f64_from_string 0.0)
                (f64_from_string 1.0)))
        (- (beta-cdf? $id $alpha $beta $x))))


;;===============================================================
;; Stage 201 -- interior vs boundary
;;   xc*(1-xc) == 0  iff  xc is 0 or 1  ->  boundary
;;===============================================================
(exec (surp 201 bc-edge-test)
    (, (bc-xc $id $xc))
    (O
        (pure
            (bc-edge $id $e)
            $e
            (ifnz
                (product_f64 $xc (sub_f64 (f64_from_string 1.0) $xc))
                then interior else boundary))))


;;===============================================================
;; Stage 202 -- boundary case: CDF(0) = 0, CDF(1) = 1, i.e. result = x
;;===============================================================
(exec (surp 202 bc-edge-emit)
    (, (bc-edge $id boundary)
       (bc-xc $id $xc))
    (O
        (pure (beta-cdf-of $id $r) $r (f64_to_string $xc))
        (+ (bc-done $id))
        (- (bc-edge $id boundary))))


;;===============================================================
;; Stage 203 -- interior case: start the three ln_gamma evaluations
;;   sa = lnG(alpha)   sb = lnG(beta)   sab = lnG(alpha + beta)
;;===============================================================
(exec (surp 203 bc-interior-start)
    (, (bc-edge $id interior)
       (bc-params $id $alpha $beta $x)
       (bc-xc $id $xc))
    (O
        (pure (bc-lg-in $id sa $z)  $z (f64_from_string $alpha))
        (pure (bc-lg-in $id sb $z)  $z (f64_from_string $beta))
        (pure (bc-lg-in $id sab $z) $z
            (sum_f64 (f64_from_string $alpha) (f64_from_string $beta)))
        (+ (bc-ab $id $alpha $beta))
        (- (bc-edge $id interior))
        (- (bc-params $id $alpha $beta $x))))


;;===============================================================
;; Stages 210-213 -- ln_gamma(z)  (NR gammln, Lanczos, generic over slot)
;;
;;   ser = 1.000000000190015
;;         + 76.18009172947146     / (z+1)
;;         - 86.50532032941677     / (z+2)
;;         + 24.01409824083091     / (z+3)
;;         -  1.231739572450155    / (z+4)
;;         +  0.001208650973866179 / (z+5)
;;         -  0.000005395239384953 / (z+6)
;;   tmp = z + 5.5
;;   lnG = (z + 0.5)*ln(tmp) + ln( 2.5066282746310005 * ser / z ) - tmp
;;===============================================================

(exec (surp 210 bc-lg-terms)
    (, (bc-lg-in $id $slot $z))
    (O
        (pure (bc-lg-t $id $slot 1 $v) $v
            (div_f64 (f64_from_string 76.18009172947146)
                     (sum_f64 $z (f64_from_string 1.0))))
        (pure (bc-lg-t $id $slot 2 $v) $v
            (div_f64 (neg_f64 (f64_from_string 86.50532032941677))
                     (sum_f64 $z (f64_from_string 2.0))))
        (pure (bc-lg-t $id $slot 3 $v) $v
            (div_f64 (f64_from_string 24.01409824083091)
                     (sum_f64 $z (f64_from_string 3.0))))
        (pure (bc-lg-t $id $slot 4 $v) $v
            (div_f64 (neg_f64 (f64_from_string 1.231739572450155))
                     (sum_f64 $z (f64_from_string 4.0))))
        (pure (bc-lg-t $id $slot 5 $v) $v
            (div_f64 (f64_from_string 0.001208650973866179)
                     (sum_f64 $z (f64_from_string 5.0))))
        (pure (bc-lg-t $id $slot 6 $v) $v
            (div_f64 (neg_f64 (f64_from_string 0.000005395239384953))
                     (sum_f64 $z (f64_from_string 6.0))))
        (+ (bc-lg-z $id $slot $z))
        (- (bc-lg-in $id $slot $z))))

(exec (surp 211 bc-lg-ser)
    (, (bc-lg-t $id $slot 1 $t1)
       (bc-lg-t $id $slot 2 $t2)
       (bc-lg-t $id $slot 3 $t3)
       (bc-lg-t $id $slot 4 $t4)
       (bc-lg-t $id $slot 5 $t5)
       (bc-lg-t $id $slot 6 $t6))
    (O
        (pure (bc-lg-ser $id $slot $ser) $ser
            (sum_f64 (f64_from_string 1.000000000190015)
                     $t1 $t2 $t3 $t4 $t5 $t6))
        (- (bc-lg-t $id $slot 1 $t1))
        (- (bc-lg-t $id $slot 2 $t2))
        (- (bc-lg-t $id $slot 3 $t3))
        (- (bc-lg-t $id $slot 4 $t4))
        (- (bc-lg-t $id $slot 5 $t5))
        (- (bc-lg-t $id $slot 6 $t6))))

(exec (surp 212 bc-lg-parts)
    (, (bc-lg-ser $id $slot $ser)
       (bc-lg-z $id $slot $z))
    (O
        (pure (bc-lg-tmp $id $slot $tmp) $tmp
            (sum_f64 $z (f64_from_string 5.5)))
        (pure (bc-lg-p1 $id $slot $p1) $p1
            (product_f64
                (sum_f64 $z (f64_from_string 0.5))
                (ln_f64 (sum_f64 $z (f64_from_string 5.5)))))
        (pure (bc-lg-p2 $id $slot $p2) $p2
            (ln_f64
                (div_f64
                    (product_f64 (f64_from_string 2.5066282746310005) $ser)
                    $z)))
        (- (bc-lg-ser $id $slot $ser))))

(exec (surp 213 bc-lg-final)
    (, (bc-lg-p1 $id $slot $p1)
       (bc-lg-p2 $id $slot $p2)
       (bc-lg-tmp $id $slot $tmp))
    (O
        (pure (bc-lgamma $id $slot $g) $g
            (sub_f64 (sum_f64 $p1 $p2) $tmp))
        (- (bc-lg-p1 $id $slot $p1))
        (- (bc-lg-p2 $id $slot $p2))
        (- (bc-lg-tmp $id $slot $tmp))))


;;===============================================================
;; Stages 220-222 -- prefactor
;;   lbeta = lnG(a) + lnG(b) - lnG(a+b)
;;   thr   = (a + 1) / (a + b + 2)
;;   bt    = exp( a*ln(xc) + b*ln(1-xc) - lbeta )
;;===============================================================
(exec (surp 220 bc-prefactor)
    (, (bc-lgamma $id sa $la)
       (bc-lgamma $id sb $lb)
       (bc-lgamma $id sab $lab)
       (bc-xc $id $xc)
       (bc-ab $id $alpha $beta))
    (O
        (pure (bc-lbeta $id $v) $v
            (sub_f64 (sum_f64 $la $lb) $lab))
        (pure (bc-lx $id $v) $v
            (ln_f64 $xc))
        (pure (bc-l1x $id $v) $v
            (ln_f64 (sub_f64 (f64_from_string 1.0) $xc)))
        (pure (bc-thr $id $v) $v
            (div_f64
                (sum_f64 (f64_from_string $alpha) (f64_from_string 1.0))
                (sum_f64 (f64_from_string $alpha)
                         (f64_from_string $beta)
                         (f64_from_string 2.0))))
        (- (bc-lgamma $id sa $la))
        (- (bc-lgamma $id sb $lb))
        (- (bc-lgamma $id sab $lab))))

(exec (surp 221 bc-bt-parts)
    (, (bc-lx $id $lx)
       (bc-l1x $id $l1x)
       (bc-ab $id $alpha $beta))
    (O
        (pure (bc-bt-pa $id $v) $v
            (product_f64 (f64_from_string $alpha) $lx))
        (pure (bc-bt-pb $id $v) $v
            (product_f64 (f64_from_string $beta) $l1x))
        (- (bc-lx $id $lx))
        (- (bc-l1x $id $l1x))))

(exec (surp 222 bc-bt)
    (, (bc-bt-pa $id $pa)
       (bc-bt-pb $id $pb)
       (bc-lbeta $id $lbeta))
    (O
        (pure (bc-bt $id $bt) $bt
            (exp_f64 (sub_f64 (sum_f64 $pa $pb) $lbeta)))
        (- (bc-bt-pa $id $pa))
        (- (bc-bt-pb $id $pb))
        (- (bc-lbeta $id $lbeta))))


;;===============================================================
;; Stages 230-232 -- pick the continued-fraction branch
;;   xc < thr :  lo  ->  betacf(a, b, xc)       finalize  bt*cf/a
;;   else     :  hi  ->  betacf(b, a, 1-xc)     finalize  1 - bt*cf/b
;;===============================================================
(exec (surp 230 bc-branch)
    (, (bc-xc $id $xc)
       (bc-thr $id $thr))
    (O
        (pure (bc-branch $id $b) $b
            (ifnz
                (max_f64 (f64_from_string 0.0)
                         (signum_f64 (sub_f64 $thr $xc)))
                then lo else hi))
        (- (bc-thr $id $thr))))

(exec (surp 231 bc-branch-lo)
    (, (bc-branch $id lo)
       (bc-ab $id $alpha $beta))
    (O
        (+ (bc-cf-run $id lo $alpha $beta))
        (+ (bc-which $id lo))
        (- (bc-branch $id lo))))

(exec (surp 232 bc-branch-hi)
    (, (bc-branch $id hi)
       (bc-ab $id $alpha $beta))
    (O
        (+ (bc-cf-run $id hi $beta $alpha))
        (+ (bc-which $id hi))
        (- (bc-branch $id hi))))


;;===============================================================
;; Stages 235-238 -- betacf initialisation
;;   qab = A+B   qap = A+1   qam = A-1
;;   d0  = 1 / (1 - qab*X/qap)
;;   state seed:  (bc-cf $id (1.0 1.0 d0 d0))       ($m $c $d $h)
;;   constants:   (bc-cf-args $id A B X qab qap qam)  (static, never modified)
;;   X = xc      for lo
;;   X = 1 - xc  for hi
;;===============================================================
(exec (surp 235 bc-cf-args-lo)
    (, (bc-cf-run $id lo $As $Bs)
       (bc-xc $id $xc))
    (O
        (pure (bc-cf-A $id lo $A) $A (f64_from_string $As))
        (pure (bc-cf-B $id lo $B) $B (f64_from_string $Bs))
        (+ (bc-cf-X $id lo $xc))
        (- (bc-cf-run $id lo $As $Bs))))

(exec (surp 235 bc-cf-args-hi)
    (, (bc-cf-run $id hi $As $Bs)
       (bc-xc $id $xc))
    (O
        (pure (bc-cf-A $id hi $A) $A (f64_from_string $As))
        (pure (bc-cf-B $id hi $B) $B (f64_from_string $Bs))
        (pure (bc-cf-X $id hi $X) $X
            (sub_f64 (f64_from_string 1.0) $xc))
        (- (bc-cf-run $id hi $As $Bs))))

(exec (surp 236 bc-cf-q)
    (, (bc-cf-A $id $which $A)
       (bc-cf-B $id $which $B)
       (bc-cf-X $id $which $X))
    (O
        (pure (bc-cf-qab $id $which $v) $v (sum_f64 $A $B))
        (pure (bc-cf-qap $id $which $v) $v (sum_f64 $A (f64_from_string 1.0)))
        (pure (bc-cf-qam $id $which $v) $v (sub_f64 $A (f64_from_string 1.0)))
        (+ (bc-cf-abx $id $which $A $B $X))
        (- (bc-cf-A $id $which $A))
        (- (bc-cf-B $id $which $B))
        (- (bc-cf-X $id $which $X))))

(exec (surp 237 bc-cf-d0)
    (, (bc-cf-abx $id $which $A $B $X)
       (bc-cf-qab $id $which $qab)
       (bc-cf-qap $id $which $qap)
       (bc-cf-qam $id $which $qam))
    (O
        (pure (bc-cf-d0 $id $which $d0) $d0
            (div_f64
                (f64_from_string 1.0)
                (sub_f64
                    (f64_from_string 1.0)
                    (div_f64 (product_f64 $qab $X) $qap))))))

(exec (surp 238 bc-cf-seed)
    (, (bc-cf-abx $id $which $A $B $X)
       (bc-cf-qab $id $which $qab)
       (bc-cf-qap $id $which $qap)
       (bc-cf-qam $id $which $qam)
       (bc-cf-d0 $id $which $d0))
    (O
        (+ (bc-cf-args $id $A $B $X $qab $qap $qam))
        (pure $w $w
            (tuple bc-cf $id
                (tuple (f64_from_string 1.0) (f64_from_string 1.0) $d0 $d0)))
        (- (bc-cf-abx $id $which $A $B $X))
        (- (bc-cf-qab $id $which $qab))
        (- (bc-cf-qap $id $which $qap))
        (- (bc-cf-qam $id $which $qam))
        (- (bc-cf-d0 $id $which $d0))))


;;===============================================================
;; Stage 240 -- betacf, one modified-Lentz iteration per firing
;;
;;   2m  = 2*m
;;   aa1 = m*(B-m)*X / ((qam+2m)*(A+2m))
;;   aa2 = -(A+m)*(qab+m)*X / ((A+2m)*(qap+2m))
;;   d1  = 1/(1 + aa1*d)          c1 = 1 + aa1/c
;;   d2  = 1/(1 + aa2*d1)         c2 = 1 + aa2/c1
;;   h_new = h * d1 * c1 * d2 * c2
;;   m_new = m + 1
;;
;; The next state fact is written whole; its predicate is `bc-cf` while
;; m <= 199 and `bc-cf-fin` once m reaches 200, which stops the loop.
;;===============================================================
(exec (surp 240 bc-cf-loop)
    (, (bc-cf $id ($m $c $d $h))
       (bc-cf-args $id $A $B $X $qab $qap $qam)
       (exec (surp 240 bc-cf-loop) $s $t))
    (O
        (pure $w $w
            (tuple
                (ifnz (max_f64 (f64_from_string 0.0) (signum_f64 (sub_f64 (f64_from_string 199.5) $m))) then bc-cf else bc-cf-fin)
                $id
                (tuple
                    (sum_f64 $m (f64_from_string 1.0))
                    (sum_f64 (f64_from_string 1.0) (div_f64 (div_f64 (product_f64 (neg_f64 (sum_f64 $A $m)) (sum_f64 $qab $m) $X) (product_f64 (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $qap (product_f64 (f64_from_string 2.0) $m)))) (sum_f64 (f64_from_string 1.0) (div_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $c))))
                    (div_f64 (f64_from_string 1.0) (sum_f64 (f64_from_string 1.0) (product_f64 (div_f64 (product_f64 (neg_f64 (sum_f64 $A $m)) (sum_f64 $qab $m) $X) (product_f64 (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $qap (product_f64 (f64_from_string 2.0) $m)))) (div_f64 (f64_from_string 1.0) (sum_f64 (f64_from_string 1.0) (product_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $d))))))
                    (product_f64 $h (div_f64 (f64_from_string 1.0) (sum_f64 (f64_from_string 1.0) (product_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $d))) (sum_f64 (f64_from_string 1.0) (div_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $c)) (div_f64 (f64_from_string 1.0) (sum_f64 (f64_from_string 1.0) (product_f64 (div_f64 (product_f64 (neg_f64 (sum_f64 $A $m)) (sum_f64 $qab $m) $X) (product_f64 (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $qap (product_f64 (f64_from_string 2.0) $m)))) (div_f64 (f64_from_string 1.0) (sum_f64 (f64_from_string 1.0) (product_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $d)))))) (sum_f64 (f64_from_string 1.0) (div_f64 (div_f64 (product_f64 (neg_f64 (sum_f64 $A $m)) (sum_f64 $qab $m) $X) (product_f64 (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $qap (product_f64 (f64_from_string 2.0) $m)))) (sum_f64 (f64_from_string 1.0) (div_f64 (div_f64 (product_f64 $m (sub_f64 $B $m) $X) (product_f64 (sum_f64 $qam (product_f64 (f64_from_string 2.0) $m)) (sum_f64 $A (product_f64 (f64_from_string 2.0) $m)))) $c))))))))
        (- (bc-cf $id ($m $c $d $h)))
        (+ (exec (surp 240 bc-cf-loop) $s $t))))


;;===============================================================
;; Stages 250-251 -- finalize (plain, fire once after the loop stops)
;;   lo :  cdf = bt * cf / alpha
;;   hi :  cdf = 1 - bt * cf / beta
;;   cf is the loop's final h (4th element of the bc-cf-fin tuple).
;;===============================================================
;; Result is rounded to 1e-12 (round(v * 1e12) / 1e12) so the output string is
;; deterministic: the fixed-iteration continued fraction leaves ~1e-14 noise in
;; the last digits, far below anything surprisingness needs. Drop the round_f64
;; wrapper if you want the raw ~15-digit value.

(exec (surp 250 bc-final-lo)
    (, (bc-cf-fin $id ($m $c $d $cf))
       (bc-which $id lo)
       (bc-bt $id $bt)
       (bc-ab $id $alpha $beta))
    (O
        (pure (beta-cdf-of $id $r) $r
            (f64_to_string
                (div_f64
                    (round_f64
                        (product_f64
                            (div_f64 (product_f64 $bt $cf) (f64_from_string $alpha))
                            (f64_from_string 1000000000000.0)))
                    (f64_from_string 1000000000000.0))))
        (+ (bc-done $id))
        (- (bc-cf-fin $id ($m $c $d $cf)))
        (- (bc-which $id lo))
        (- (bc-bt $id $bt))))

(exec (surp 251 bc-final-hi)
    (, (bc-cf-fin $id ($m $c $d $cf))
       (bc-which $id hi)
       (bc-bt $id $bt)
       (bc-ab $id $alpha $beta))
    (O
        (pure (beta-cdf-of $id $r) $r
            (f64_to_string
                (div_f64
                    (round_f64
                        (product_f64
                            (sub_f64
                                (f64_from_string 1.0)
                                (div_f64 (product_f64 $bt $cf) (f64_from_string $beta)))
                            (f64_from_string 1000000000000.0)))
                    (f64_from_string 1000000000000.0))))
        (+ (bc-done $id))
        (- (bc-cf-fin $id ($m $c $d $cf)))
        (- (bc-which $id hi))
        (- (bc-bt $id $bt))))


;;===============================================================
;; Stages 290-298 -- cleanup of private state once (bc-done $id) is present
;;===============================================================
(exec (surp 290 bc-cleanup-ab)
    (, (bc-done $id) (bc-ab $id $alpha $beta))
    (O (- (bc-ab $id $alpha $beta))))

(exec (surp 291 bc-cleanup-xc)
    (, (bc-done $id) (bc-xc $id $xc))
    (O (- (bc-xc $id $xc))))

(exec (surp 292 bc-cleanup-cf-args)
    (, (bc-done $id) (bc-cf-args $id $A $B $X $qab $qap $qam))
    (O (- (bc-cf-args $id $A $B $X $qab $qap $qam))))

(exec (surp 293 bc-cleanup-lg-z)
    (, (bc-done $id) (bc-lg-z $id $slot $z))
    (O (- (bc-lg-z $id $slot $z))))

(exec (surp 294 bc-cleanup-params)
    (, (bc-done $id) (bc-params $id $alpha $beta $x))
    (O (- (bc-params $id $alpha $beta $x))))

(exec (surp 298 bc-cleanup-done)
    (, (bc-done $id))
    (O (- (bc-done $id))))
