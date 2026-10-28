;; =============================================================================
;;  ISurp-Old Algorithm (MM2 / MORK)
;; =============================================================================


  ;;  Public Entry Point: isurp-old
;; Index free variables to ground representation to prevent unbound variable scope issues.
(exec (freq 080 isurp-old-start)
  (, (isurp-old $pat $db $norm))
  (O
    (pure (isurp-init $ctx $db $norm) $ctx
      (vars_to_indices (' $pat)))
    (- (isurp-old $pat $db $norm))))

  ;;  Extract clauses and length k
(exec (freq 081 isurp-extract)
  (, (isurp-init $ctx $db $norm))
  (O
    (pure (isurp-clauses $ctx $db $norm $clauses) $clauses
      (cdr-atom (' $ctx)))
    (pure (isurp-k $ctx $db $norm $k) $k
      (size-atom (cdr-atom (' $ctx))))
    (- (isurp-init $ctx $db $norm))))


  ;; Trivial length edge cases (k = 0 or 1) -> surprisingness is 0.0
(exec (freq 082 isurp-start-trivial-0)
  (, (isurp-k $ctx $db $norm 0)
     (isurp-clauses $ctx $db $norm $clauses))
  (O
    (+ (0.0))
    (- (isurp-k $ctx $db $norm 0))
    (- (isurp-clauses $ctx $db $norm $clauses))))

(exec (freq 082 isurp-start-trivial-1)
  (, (isurp-k $ctx $db $norm 1)
     (isurp-clauses $ctx $db $norm $clauses))
  (O
    (+ (0.0))
    (- (isurp-k $ctx $db $norm 1))
    (- (isurp-clauses $ctx $db $norm $clauses))))


  ;; Non-trivial patterns (k >= 2): wrap clauses with database prefix ($db clause)
(exec (freq 083 isurp-init-start)
  (, (isurp-k $ctx $db $norm $k)
     (isurp-clauses $ctx $db $norm $clauses)
     (DEF isurp-wrap-step $step-p $step-t))
  (O
    (+ (isurp-wrap-acc $ctx $db $clauses ()))
    (+ (isurp-meta $ctx $db $norm $k))
    (+ (exec (freq 083 isurp-run-wrap) $step-p $step-t))
    (- (isurp-k $ctx $db $norm $k))
    (- (isurp-clauses $ctx $db $norm $clauses))))

(DEF isurp-wrap-step
  (, (isurp-wrap-acc $ctx $db $remaining $acc)
     (DEF isurp-wrap-resolve $res-p $res-t))
  (O
    (pure (isurp-wrap-head $ctx $db $remaining $acc $head) $head (car-atom (' $remaining)))
    (pure (isurp-wrap-rest $ctx $db $remaining $acc $rest) $rest (cdr-atom (' $remaining)))
    (- (isurp-wrap-acc $ctx $db $remaining $acc))
    (+ (isurp-wrap-pending $ctx $db $remaining $acc))
    (+ (exec (freq 083 isurp-run-wrap-res) $res-p $res-t))))

(DEF isurp-wrap-resolve
  (, (isurp-wrap-pending $ctx $db $remaining $acc)
     (isurp-wrap-head $ctx $db $remaining $acc $head)
     (isurp-wrap-rest $ctx $db $remaining $acc $rest)
     (DEF isurp-wrap-step $step-p $step-t)
     (DEF isurp-wrap-final $final-p $final-t))
  (O
    (pure (isurp-wrap-wh $ctx $db $rest $acc $wh) $wh (cons $db (' ($head))))
    (- (isurp-wrap-pending $ctx $db $remaining $acc))
    (- (isurp-wrap-head $ctx $db $remaining $acc $head))
    (- (isurp-wrap-rest $ctx $db $remaining $acc $rest))
    (+ (exec (freq 083 isurp-run-wrap-append)
        (, (isurp-wrap-wh $c $d $r $a $w))
        (O
          (pure (isurp-wrap-acc $c $d $r $new_acc) $new_acc (append (' ($a ($w)))))
          (- (isurp-wrap-wh $c $d $r $a $w))
          (+ (exec (freq 082 isurp-run-wrap-fin) $final-p $final-t))
          (+ (exec (freq 083 isurp-run-wrap) $step-p $step-t)))))))

(DEF isurp-wrap-final
  (, (isurp-wrap-acc $ctx $db () $acc)
     (isurp-meta $ctx $db $norm $k))
  (O
    (+ (isurp-ready $ctx $db $norm $k $acc))
    (- (isurp-wrap-acc $ctx $db () $acc))
    (- (isurp-meta $ctx $db $norm $k))))


  ;; Database Count (isurp-old-db-count)
(exec (freq 084 isurp-old-db-seed)
  (, (isurp-ready $ctx $db $norm $k $db_clauses))
  (O
    (+ (isurp-db-cnt $ctx $db $norm $k $db_clauses 0))
    (- (isurp-ready $ctx $db $norm $k $db_clauses))))

(exec (freq 085 isurp-old-db-count)
  (, (isurp-db-cnt $ctx $db $norm $k $db_clauses 0)
     ($db $atom))
  (O
    (count (isurp-db-cnt $ctx $db $norm $k $db_clauses $n) $n $atom)
    (- (isurp-db-cnt $ctx $db $norm $k $db_clauses 0))))


  ;; Binomial Denominator: tot = C(n, k) = falling_factorial(n, k) / k!
(exec (freq 086 isurp-calc-denom)
  (, (isurp-db-cnt $ctx $db $norm $k $db_clauses $n))
  (O
    (pure (isurp-tot-count $ctx $db $norm $db_clauses $tot) $tot
      (i64_to_string
        (div_i64
          (falling_factorial (i64_from_string $n) (i64_from_string $k))
          (factorial (i64_from_string $k)))))
    (- (isurp-db-cnt $ctx $db $norm $k $db_clauses $n))))


  ;; Joint Pattern Support Count (isurp-old-joint-count)
(exec (freq 087 isurp-old-joint-start)
  (, (isurp-tot-count $ctx $db $norm $db_clauses $tot))
  (O
    (+ (isurp-joint-cnt $ctx 0))
    (+ (isurp-active $ctx $norm $db_clauses $tot))
    (pure
      (exec (freq 088 isurp-old-joint-count)
        $q
        (O
          (count (isurp-joint-cnt $ctx $j) $j ($q))
          (- (isurp-joint-cnt $ctx 0))))
      $q
      (indices_to_vars (cons , (' $db_clauses))))
    (- (isurp-tot-count $ctx $db $norm $db_clauses $tot))))


  ;;  Empirical Joint Probability (isurp-old-joint-prob)
(exec (freq 089 isurp-old-joint-prob)
  (, (isurp-active $ctx $norm $db_clauses $tot)
     (isurp-joint-cnt $ctx $j))
  (O
    (pure (isurp-ppat $ctx $norm $db_clauses $tot $ppat) $ppat
      (f64_to_string
        (div_f64 (f64_from_string $j) (f64_from_string $tot))))
    (- (isurp-joint-cnt $ctx $j))
    (- (isurp-active $ctx $norm $db_clauses $tot))))


  ;; Generate Partitions (isurp-old-gen-partitions) and Expand into Blocks
(exec (freq 090 isurp-old-gen-partitions)
  (, (isurp-ppat $ctx $norm $db_clauses $tot $ppat))
  (O
    (pure (isurp-partitions-list $ctx $norm $ppat $tot $parts) $parts
      (partitions (' $db_clauses)))
    (pure (isurp-parts-rem $ctx $tot $parts) $parts
      (partitions (' $db_clauses)))
    (+ (exec (freq 090 isurp-old-partition-iter)
        (, (isurp-parts-rem $c $t $p)
           (exec (freq 090 isurp-old-partition-iter) $src $sink))
        (O
          (pure (isurp-part-first $c $t $first) $first (car-atom (' $p)))
          (pure (isurp-parts-rem $c $t $rest) $rest (cdr-atom (' $p)))
          (- (isurp-parts-rem $c $t $p))
          (+ (exec (freq 090 isurp-old-partition-iter) $src $sink)))))
    (- (isurp-ppat $ctx $norm $db_clauses $tot $ppat))))

(exec (freq 091 isurp-part-emit)
  (, (isurp-part-first $ctx $tot $part))
  (O
    (+ (isurp-partition $ctx $part))
    (+ (isurp-blocks-rem $ctx $tot $part $part))
    (+ (exec (freq 091 isurp-old-block-iter)
        (, (isurp-blocks-rem $c $t $pt $blks)
           (exec (freq 091 isurp-old-block-iter) $src $sink))
        (O
          (pure (isurp-block-first $c $t $b) $b (car-atom (' $blks)))
          (pure (isurp-blocks-rem $c $t $pt $rest) $rest (cdr-atom (' $blks)))
          (- (isurp-blocks-rem $c $t $pt $blks))
          (+ (exec (freq 091 isurp-old-block-iter) $src $sink)))))
    (- (isurp-part-first $ctx $tot $part))))

(exec (freq 092 isurp-block-emit)
  (, (isurp-block-first $ctx $tot $b))
  (O
    (+ (isurp-block-req $ctx $tot $b))
    (- (isurp-block-first $ctx $tot $b))))


  ;; Block Support Count and Probability (isurp-old-block-count / isurp-old-block-prob)
(exec (freq 092 isurp-old-block-start)
  (, (isurp-block-req $ctx $tot $block))
  (O
    (+ (isurp-block-cnt $ctx $block 0))
    (+ (isurp-block-eval $ctx $tot $block))
    (pure
      (exec (freq 093 isurp-old-block-count)
        $q
        (O
          (count (isurp-block-cnt $ctx $block $sup) $sup ($q))
          (- (isurp-block-cnt $ctx $block 0))))
      $q
      (indices_to_vars (cons , (' $block))))
    (- (isurp-block-req $ctx $tot $block))))

(exec (freq 094 isurp-old-block-prob)
  (, (isurp-block-eval $ctx $tot $block)
     (isurp-block-cnt $ctx $block $sup))
  (O
    (pure (isurp-block-prob $ctx $block $bprob) $bprob
      (f64_to_string
        (div_f64 (f64_from_string $sup) (f64_from_string $tot))))
    (- (isurp-block-eval $ctx $tot $block))
    (- (isurp-block-cnt $ctx $block $sup))))


  ;;  Partition Probability Reduction (isurp-old-partition-prob)
(exec (freq 096 isurp-old-partition-start)
  (, (isurp-partition $ctx $part)
     (DEF isurp-part-step $step-p $step-t))
  (O
    (+ (isurp-part-acc $ctx $part $part 1.0))
    (+ (exec (freq 096 isurp-part-run-step) $step-p $step-t))
    (- (isurp-partition $ctx $part))))

(DEF isurp-part-step
  (, (isurp-part-acc $ctx $part $rem $acc)
     (DEF isurp-part-res $res-p $res-t))
  (O
    (pure (isurp-part-cur $ctx $part $rem $block) $block (car-atom (' $rem)))
    (pure (isurp-part-rest $ctx $part $rem $rest) $rest (cdr-atom (' $rem)))
    (- (isurp-part-acc $ctx $part $rem $acc))
    (+ (isurp-part-pending $ctx $part $rem $acc))
    (+ (exec (freq 096 isurp-part-run-res) $res-p $res-t))))

(DEF isurp-part-res
  (, (isurp-part-pending $ctx $part $rem $acc)
     (isurp-part-cur $ctx $part $rem $block)
     (isurp-part-rest $ctx $part $rem $rest)
     (isurp-block-prob $ctx $block $bprob)
     (DEF isurp-part-step $step-p $step-t)
     (DEF isurp-part-fin $fin-p $fin-t))
  (O
    (pure (isurp-part-acc $ctx $part $rest $new_acc) $new_acc
      (f64_to_string
        (product_f64 (f64_from_string $acc) (f64_from_string $bprob))))
    (- (isurp-part-pending $ctx $part $rem $acc))
    (- (isurp-part-cur $ctx $part $rem $block))
    (- (isurp-part-rest $ctx $part $rem $rest))
    (+ (exec (freq 095 isurp-part-run-fin) $fin-p $fin-t))
    (+ (exec (freq 096 isurp-part-run-step) $step-p $step-t))))

(DEF isurp-part-fin
  (, (isurp-part-acc $ctx $part () $pprob))
  (O
    (+ (isurp-partition-prob $ctx $part $pprob))
    (- (isurp-part-acc $ctx $part () $pprob))))


  ;; Collect Partition Probabilities and Compute Min/Max (isurp-old-minmax)
(exec (freq 098 isurp-old-minmax-start)
  (, (isurp-partitions-list $ctx $norm $ppat $tot $parts)
     (DEF isurp-col-step $step-p $step-t))
  (O
    (+ (isurp-col-acc $ctx $parts $parts ()))
    (+ (exec (freq 098 isurp-col-run-step) $step-p $step-t))
    (+ (isurp-col-meta $ctx $norm $ppat))
    (- (isurp-partitions-list $ctx $norm $ppat $tot $parts))))

(DEF isurp-col-step
  (, (isurp-col-acc $ctx $parts $rem $acc)
     (DEF isurp-col-res $res-p $res-t))
  (O
    (pure (isurp-col-cur $ctx $parts $rem $part) $part (car-atom (' $rem)))
    (pure (isurp-col-rest $ctx $parts $rem $rest) $rest (cdr-atom (' $rem)))
    (- (isurp-col-acc $ctx $parts $rem $acc))
    (+ (isurp-col-pending $ctx $parts $rem $acc))
    (+ (exec (freq 098 isurp-col-run-res) $res-p $res-t))))

(DEF isurp-col-res
  (, (isurp-col-pending $ctx $parts $rem $acc)
     (isurp-col-cur $ctx $parts $rem $part)
     (isurp-col-rest $ctx $parts $rem $rest)
     (isurp-partition-prob $ctx $part $pprob)
     (DEF isurp-col-step $step-p $step-t)
     (DEF isurp-col-fin $fin-p $fin-t))
  (O
    (pure (isurp-col-acc $ctx $parts $rest $new_acc) $new_acc
      (append (' ($acc ($pprob)))))
    (- (isurp-col-pending $ctx $parts $rem $acc))
    (- (isurp-col-cur $ctx $parts $rem $part))
    (- (isurp-col-rest $ctx $parts $rem $rest))
    (- (isurp-partition-prob $ctx $part $pprob))
    (+ (exec (freq 097 isurp-col-run-fin) $fin-p $fin-t))
    (+ (exec (freq 098 isurp-col-run-step) $step-p $step-t))))

(DEF isurp-col-fin
  (, (isurp-col-acc $ctx $parts () $prob_list))
  (O
    (pure (isurp-emin $ctx $emin) $emin (min-atom (' $prob_list)))
    (pure (isurp-emax $ctx $emax) $emax (max-atom (' $prob_list)))
    (- (isurp-col-acc $ctx $parts () $prob_list))))


  ;;  Distance to Interval: Raw and Normalized (isurp-old-distance / isurp-old-normalize)
;; Raw distance: min(|ppat - clamp(ppat, emin, emax)|, 1.0)
(exec (freq 099 isurp-old-distance-raw)
  (, (isurp-col-meta $ctx False $ppat)
     (isurp-emin $ctx $emin)
     (isurp-emax $ctx $emax))
  (O
    (pure ($res) $res
      (f64_to_string
        (min_f64
          (abs_f64
            (sub_f64
              (f64_from_string $ppat)
              (clamp_f64
                (f64_from_string $ppat)
                (f64_from_string $emin)
                (f64_from_string $emax))))
          (f64_from_string 1.0))))
    (- (isurp-col-meta $ctx False $ppat))
    (- (isurp-emin $ctx $emin))
    (- (isurp-emax $ctx $emax))))

;; Normalized zero-division guard
(exec (freq 099 isurp-old-distance-norm-zero)
  (, (isurp-col-meta $ctx True 0.0)
     (isurp-emin $ctx 0.0)
     (isurp-emax $ctx 0.0))
  (O
    (+ (0.0))
    (- (isurp-col-meta $ctx True 0.0))
    (- (isurp-emin $ctx 0.0))
    (- (isurp-emax $ctx 0.0))))

;; Normalized distance: min(|ppat - clamp(ppat, emin, emax)| / max(emax, ppat), 1.0)
(exec (freq 099 isurp-old-normalize)
  (, (isurp-col-meta $ctx True $ppat)
     (isurp-emin $ctx $emin)
     (isurp-emax $ctx $emax))
  (O
    (pure ($res) $res
      (f64_to_string
        (min_f64
          (div_f64
            (abs_f64
              (sub_f64
                (f64_from_string $ppat)
                (clamp_f64
                  (f64_from_string $ppat)
                  (f64_from_string $emin)
                  (f64_from_string $emax))))
            (max_f64 (f64_from_string $emax) (f64_from_string $ppat)))
          (f64_from_string 1.0))))
    (- (isurp-col-meta $ctx True $ppat))
    (- (isurp-emin $ctx $emin))
    (- (isurp-emax $ctx $emax))))



  ;; Cleanup intermediate block probabilities
(exec (freq 100 isurp-cleanup)
  (, (isurp-block-prob $ctx $block $bprob))
  (O (- (isurp-block-prob $ctx $block $bprob))))
