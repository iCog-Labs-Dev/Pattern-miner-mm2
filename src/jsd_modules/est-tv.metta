;; ========================================================================
;; Label: universe-count
;; Purpose: Get total relevant items for the expanded blocks of a pattern 
;;          from its partitions
;; ========================================================================

(exec (est-tv 150 universe-count)
    (, (INPUT DB-SIZE $db-size) (block $partition $block))
    (O
        (pure
            (universe-count-of $block $uc)
            $uc
            (i64_to_string (pow_i64 (i64_from_string $db-size) (i64_from_string (size-atom (' $block)))))
        )
    )
)
;; ========================================================================
;; Label: emp-tv
;; Purpose: Calculate empirical truth value for the blocks expanded from a 
;;          pattern's partitions in database. 
;; 1. Calculate a confidence value based on a universe-count using a smoothing constant (DEFAULT_K).
;;      - confidence = (x / (x + Default_k) * 0.1)
;; 2. Calculate a mean value based on the support and universe-count.
;;      - mean = (support / universe-count)
;; 3. Return the empirical truth value as a pair of mean and confidence.
;; ========================================================================

(exec (est-tv 151 emp-tv-confidence)
    (, (universe-count-of $block $uc) (CONSTANT DEFAULT_K $k))
    (O
        (pure
            (emp-tv-confidence $block $conf)
            $conf
            (f32_to_string ( product_f32 
                (f32_from_string 0.1) 
                (div_f32 (f32_from_string $uc) (sum_f32 (f32_from_string $uc) (f32_from_string $k)))))
        )
    )
)
(exec (est-tv 152 emp-tv-mean)
    (, (universe-count-of $block $uc) (block-support $block $support))
    (O
        (pure
            (emp-tv-mean $block $mean)
            $mean
            (f32_to_string (div_f32 (f32_from_string $support) (f32_from_string $uc)))
        )
    )
)

(exec (est-tv 153 emp-tv)
    (, (emp-tv-confidence $block $conf) (emp-tv-mean $block $mean))
    (, (EMPTV $block ($mean $conf)))
)


;; =============================================================================================
;; Label: conf-to-count
;; Purpose: Convert confidence to count using the formula
;;          count = (confidence * default_k) / (1 - confidence)
;; =============================================================================================
(exec (est-tv 154 conf-to-count)
    (, (EMPTV $block ($mean $conf)) (CONSTANT default_k $k))
    (O
        (pure
            (exec (est-tv 154 conf-to-count) (,) (O (pure
                (emp-conf-to-count $conf $count)
                $count
                (f32_to_string (div_f32 
                    (product_f32 (f32_from_string $min) (f32_from_string $k)) 
                    (sub_f32 (f32_from_string 1) (f32_from_string $min))))
            )))
            $min
            (min-atom (tuple $conf 0.9999998))
        )
    )
)

;; =============================================================================================
;; Label: beta-distribution
;; Purpose: Calculate the parameters of a Beta distribution based on the given empirical TV (emptv) data.
;; 
;; - Extracts the strength, confidence, and count from the empirical data, then computes the positive count
;; and uses prior alpha and beta values (both set to 1.0) to calculate the final alpha and beta parameters
;; for the Beta distribution. The final alpha is the sum of the prior alpha and the positive count, while the
;; final beta is the sum of the prior beta and the difference between the count and the positive count.
;; ============================================================================================

(exec (est-tv 155 emp-alpha)
    (, (EMPTV $block ($mean $conf)) (emp-conf-to-count $conf $count) (CONSTANT prior-alpha $pa))
    (O
        
        (pure
            (emp-alpha $block $alpha)
            $alpha
            (f32_to_string (sum_f32 
                (f32_from_string $pa)
                (product_f32 (f32_from_string $mean) (f32_from_string $count))))
        )
    )
)

(exec (est-tv 156 emp-beta)
    (, (EMPTV $block ($mean $conf)) (emp-conf-to-count $conf $count) (CONSTANT prior-beta $pb))
    (O
        (pure
            (emp-beta $block $beta)
            $beta
            (f32_to_string (sub_f32 
                (sum_f32 (f32_from_string $count) (f32_from_string $pb))
                (product_f32 (f32_from_string $mean) (f32_from_string $count))))
        )
    )
)


(exec (est-tv 157 beta-mean)
    (, (emp-beta $block $beta) (emp-alpha $block $alpha))
    (O
        (pure
            (beta-mean $beta $alpha $b-mean)
            $b-mean
            (f32_to_string (div_f32
                (f32_from_string $alpha)
                (sum_f32 (f32_from_string $alpha) (f32_from_string $beta))))
        )
    )
)
(exec (est-tv 158 beta-var)
    (, (emp-beta $block $beta) (emp-alpha $block $alpha))
    (O
        (pure
            (beta-var $beta $alpha $b-var)
            $b-var
            (f32_to_string (div_f32
                (product_f32 (f32_from_string $alpha) (f32_from_string $beta))
                (product_f32 
                    (product_f32 (sum_f32 (f32_from_string $alpha) (f32_from_string $beta)) (sum_f32 (f32_from_string $alpha) (f32_from_string $beta)))
                    (sum_f32 (f32_from_string 1) (f32_from_string $alpha) (f32_from_string $beta)))
            ))
        )
    )
)

(exec (est-tv 159 beta-distribution)
    (, (emp-alpha $block $alpha) (emp-beta $block $beta) (beta-var $beta $alpha $b-var) (beta-mean $beta $alpha $b-mean))
    (, (mk-distribution $block ($b-mean $b-var)))
)



;; --------------------------------------------------------------------------------------------
;; Calculate the mean for each Beta distribution.
;; --------------------------------------------------------------------------------------------
(exec (est-tv 160 mean-acc) 
    (, (mk-distribution $block ($b-mean $b-var)) (block $partition $block))
    (, (mean-acc $partition 0))
)



(exec (est-tv 161 mean-acc-loop) 
    (, (mean-acc $partition $acc) (exec (est-tv 161 mean-acc-loop)  $src (O (pure $out $var (car $p)))))
    (O
        (pure
            (exec (est-tv 161 mean-acc) 
                (, (mk-distribution $block ($b-mean $b-var)))
                (O 
                    (pure
                        (mean-acc $partition $new-acc)
                        $new-acc
                        (f32_to_string (sum_f32 (f32_from_string $b-mean) (f32_from_string $acc)))
                    )
                    (- (mean-acc $partition $acc))
                    (+ (exec (est-tv 161 mean-acc-loop) $src (O (pure $out $var (car (cdr $p))))))
                )
            )
            $block
            (car (' $partition))
        )
    )
)


;; --------------------------------------------------------------------------------------------
;; Calculate the overall average mean from the individual means.
;; --------------------------------------------------------------------------------------------

(exec (est-tv 162 mean)
    (, (mean-acc $partition $acc) (partition $partitions $partition))
    (O
        (pure
            (mk-stv-mean $partition $mean)
            $mean
            (f32_to_string (div_f32 (f32_from_string $acc) (f32_from_string (length (' $partition)))))
        )
    )
)

;; ----------------------------------------------------------------------------------------------------------------------
;; Calculate the relative variances using the individual means, variances, and the overall average mean.
;; ----------------------------------------------------------------------------------------------------------------------

(exec (est-tv 163 rel-var)
    (, (block $partition $block) (mk-distribution $block ($b-mean $b-var)) (mk-stv-mean $partition $mean))
    (O
        (pure
            (mk-rel-var $partition $block ($b-mean $b-var) $rel-var)
            $rel-var
            (f32_to_string (sum_f32 (f32_from_string $b-var)
                (powf_f32 
                    (sub_f32 (f32_from_string $b-mean) (f32_from_string $mean)) (f32_from_string 2))))
        )
    )
)


;; --------------------------------------------------------------------------------------------
;; Calculate the average variance from the combined variances.
;; --------------------------------------------------------------------------------------------

(exec (est-tv 163 rel-var-acc) 
    (, (mk-rel-var $partition $block ($b-mean $b-var) $rel-var) (block $partition $block))
    (, (var-acc $partition 0))
)

(exec (est-tv 164 var-acc) 
    (, (var-acc $partition $acc) (exec (est-tv 164 var-acc)   $src (O (pure $out $var (car $p)))))
    (O
        (pure
            (exec (est-tv 164 var-acc) 
                (, (mk-rel-var $partition $block ($b-mean $b-var) $rel-var))
                (O 
                    (pure
                        (var-acc $partition $new-acc)
                        $new-acc
                        (f32_to_string (sum_f32 (f32_from_string $rel-var) (f32_from_string $acc)))
                    )
                    (- (var-acc $partition $acc))
                    (+ (exec (est-tv 164 var-acc) $src (O (pure $out $var (car (cdr $p))))))
                )
            )
            $block
            (car (' $partition))
        )
    )
)


(exec (est-tv 165 mk-stv-var)
    (, (var-acc $partition $acc))
    (O
        (pure
            (mk-stv-var $partition $var)
            $var
            (f32_to_string (div_f32 (f32_from_string $acc) (f32_from_string (length (' $partition)))))
        )
    )
)

;; ==========================================================================================================================
;; Label: mk-stv
;; Purpose: Creates a standard truth value (STV) using the provided mean and variance.
;; 
;; ==========================================================================================================================


;; --------------------------------------------------------------------------------------------------------------------------
;; Calculate the alpha and beta parameters based on the mean and variance.
;; --------------------------------------------------------------------------------------------------------------------------

(exec (est-tv 166 avrg-tv)
    (, (mk-stv-var $partition $var) (mk-stv-mean $partition $mean))
    (O
        (pure
            (found-beta $mean $var $f-beta)
            $f-beta
            (f32_to_string (product_f32  
                (sub_f32 (f32_from_string 1) (f32_from_string $mean)) 
                (sub_f32 
                    (div_f32
                        (product_f32 (f32_from_string $mean)
                            (sub_f32 (f32_from_string 1) (f32_from_string $mean)))
                        (f32_from_string $var))  
                    (f32_from_string 1)
            )))
        )
    )
)

(exec (est-tv 167 avrg-tv)
    (, (mk-stv-var $partition $var) (mk-stv-mean $partition $mean))
    (O
        (pure
            (found-alpha $mean $var $f-alpha)
            $f-alpha
            (f32_to_string (product_f32  
                (f32_from_string $mean) 
                (sub_f32 
                    (div_f32
                        (product_f32 (f32_from_string $mean)
                            (sub_f32 (f32_from_string 1) (f32_from_string $mean)))
                        (f32_from_string $var))  
                    (f32_from_string 1))))
        )
    )
)

;; --------------------------------------------------------------------------------------------------------------------------
;; Calculate the count and confidence values using these parameters.
;; --------------------------------------------------------------------------------------------------------------------------

(exec (est-tv 169 mk-stv)
    (,  (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (CONSTANT prior-beta $pb) (CONSTANT prior-alpha $pa))
    (O
        (pure
            (mk-stv-count $mean $var $count)
            $count
            (f32_to_string (max_f32    
                (sub_f32
                    (sum_f32 (f32_from_string $f-alpha) (f32_from_string $f-beta))
                    (sum_f32 (f32_from_string $pa) (f32_from_string $pb)))
                (f32_from_string 0.1)))
        )
    )
)

(exec (est-tv 170 mk-stv-confidence)
    (, (mk-stv-count $mean $var $count) (CONSTANT default_k $k))
    (O
        (pure
            (mk-stv-confidence $mean $var $confidence)
            $confidence
            (f32_to_string (div_f32 
                (f32_from_string $count) 
                (sum_f32 (f32_from_string $count) (f32_from_string $k))))
        )
    )
)


;; --------------------------------------------------------------------------------------------------------------------------
;; Calculate mode which is determined based on the values of alpha and beta, following specific conditions.
;; --------------------------------------------------------------------------------------------------------------------------



;; compare the values of alpha and beta to determine the mode based on the conditions.

(exec (est-tv 171 comparisons)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha))
    (O
        (pure
            (is-gt $f-alpha 1 $bool)
            $bool
            (gt_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-gt $f-beta 1 $bool)
            $bool
            (gt_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
        (pure
            (is-eq $f-beta 1 $bool)
            $bool
            (eq_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
        (pure
            (is-le $f-alpha 1 $bool)
            $bool
            (le_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-lt $f-alpha 1 $bool)
            $bool
            (lt_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-lt $f-beta 1 $bool)
            $bool
            (lt_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
    )
)

;; ------------------------------------------------------------------------------------------------------------------------------------------
;; Conditions: 
;; $mode = 
;;   if (and (> $alpha 1) (> $beta 1)) (alpha - 1) / (alpha + beta - 2)
;;   else if (and (<= $alpha 1) (> $beta 1)) 0
;;   else if (and (== $beta 1) (< $alpha 1)) 1
;;   else if (and (< $alpha 1) (< $beta 1)) $mean
;; ------------------------------------------------------------------------------------------------------------------------------------------

(exec (est-tv 172 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha))
    (, (mk-stv-mode $mean $var 1))  
)
;; Condition: if (and (< $alpha 1) (< $beta 1)) then mode = $mean
(exec (est-tv 173 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-lt $f-beta 1 true) (is-lt $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) (+ (mk-stv-mode $mean $var $mean)))  
)
;; Condition: if (and (<= $alpha 1) (> $beta 1)) then mode = 0
(exec (est-tv 174 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-gt $f-beta 1 true) (is-le $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) (+ (mk-stv-mode $mean $var 0)))  
)
;; Condition: if (and (> $alpha 1) (> $beta 1)) then mode = (alpha - 1) / (alpha + beta - 2)
(exec (est-tv 175 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-gt $f-beta 1 true) (is-gt $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) 
        (pure (mk-stv-mode $mean $var $mode)
            $mode 
            (f32_to_string (div_f32 
                (sub_f32 (f32_from_string $f-alpha) (f32_from_string 1))
                (sum_f32 
                    (f32_from_string $f-alpha)
                    (sub_f32 (f32_from_string $f-beta) (f32_from_string 2))
                )
            ))
        )
    )  
)


;; Combine the mean, variance, mode, and confidence into a single standard truth value (STV) representation.

(exec (est-tv 176 mk-stv)
    (, (mk-stv-mode $mean $var $mode) (mk-stv-confidence $mean $var $confidence))
    (, (mk-stv $mean $var ($mode $confidence)))
)


;; --------------------------------------------------------------------------------------------------------------
;; Label: pro-prob-without-joint
;; Purpose: This function calculates the product of the probability over subpatterns
;;          without considering the joint variables. It estimates the empirical truth value
;;          for each subpattern and then computes the average of these truth values to derive
;;          the final product of the probabilities.
;;
;; --------------------------------------------------------------------------------------------------------------
(exec (est-tv 177 pro-prob-without-joint)
    (, (mk-stv $mean $var ($mode $confidence)) (mk-stv-var $partition $var) (mk-stv-mean $partition $mean))
    (, (pro-prob-without-joint $partition ($mode $confidence)))
)



;; ---------------------------------------------------------------------------------------------------------------
;; Label: ji-est-tv
;; Purpose: Calculates the joint-independent truth value estimate (JITVE) for a pattern
;;          based on a given partition. It assumes all blocks are independent but accounts
;;          for joint variables shared across them.
;;
;; --------------------------------------------------------------------------------------------------------------

(exec (est-tv 178 ji-est-tv)
    (, (pro-prob-without-joint $partition ($mode $confidence)) (eq-prob-of $partition $prob))
    (O
        (pure
            (ji-est-tv-strength $partition $strength)
            $strength
            (f32_to_string (product_f32 (f32_from_string $mode) (f32_from_string $prob)))
        )
        (pure
            (ji-est-tv-confidence $partition $je-confidence)
            $je-confidence
            (f32_to_string (product_f32 (f32_from_string $confidence) (f32_from_string 0.1)))
        )
    )
)

(exec (est-tv 179 ji-est-tv)
    (,  (ji-est-tv-confidence $partition $je-confidence) (ji-est-tv-strength $partition $strength))
    (, (ji-est-tv $partition ($strength $je-confidence)))
)





;; =============================================================================================
;; Label: conf-to-count (for partitions)
;; Purpose: Convert confidence to count using the formula
;;          count = (confidence * default_k) / (1 - confidence)
;;          Applied to joint-independent truth value estimates for partitions.
;; =============================================================================================
(exec (est-tv 180 conf-to-count)
    (, (ji-est-tv $partition ($strength $conf)) (CONSTANT default_k $k))
    (O
        (pure
            (exec (est-tv 180 conf-to-count) (,) (O (pure
                (est-conf-to-count $conf $count)
                $count
                (f32_to_string (div_f32 
                    (product_f32 (f32_from_string $min) (f32_from_string $k)) 
                    (sub_f32 (f32_from_string 1) (f32_from_string $min))))
            )))
            $min
            (min-atom (tuple $conf 0.9999998))
        )
    )
)

;; =============================================================================================
;; Label: est-alpha (for partitions)
;; Purpose: Calculate the alpha parameter of a Beta distribution based on the joint-independent 
;;          truth value estimate. Uses the formula:
;;          alpha = prior-alpha + (strength * count)
;;          where count is derived from the confidence using the conf-to-count conversion.
;; =============================================================================================
(exec (est-tv 181 est-alpha)
    (, (ji-est-tv $partition ($strength $conf)) (est-conf-to-count $conf $count) (CONSTANT prior-alpha $pa))
    (O
        
        (pure
            (est-alpha $partition $alpha)
            $alpha
            (f32_to_string (sum_f32 
                (f32_from_string $pa)
                (product_f32 (f32_from_string $strength) (f32_from_string $count))))
        )
    )
)

;; =============================================================================================
;; Label: est-beta (for partitions)
;; Purpose: Calculate the beta parameter of a Beta distribution based on the joint-independent
;;          truth value estimate. Uses the formula:
;;          beta = (count + prior-beta) - (strength * count)
;;          where count is derived from the confidence using the conf-to-count conversion.
;; =============================================================================================
(exec (est-tv 182 est-beta)
    (, (ji-est-tv $partition ($strength $conf)) (est-conf-to-count $conf $count) (CONSTANT prior-beta $pb))
    (O
        (pure
            (est-beta $partition $beta)
            $beta
            (f32_to_string (sub_f32 
                (sum_f32 (f32_from_string $count) (f32_from_string $pb))
                (product_f32 (f32_from_string $strength) (f32_from_string $count))))
        )
    )
)

;; =============================================================================================
;; Label: est-beta-mean (for partitions)
;; Purpose: Calculate the mean of a Beta distribution from its alpha and beta parameters.
;;          Uses the formula:
;;          beta-mean = alpha / (alpha + beta)
;;          This represents the expected value of the Beta distribution.
;; =============================================================================================
(exec (est-tv 183 est-beta-mean)
    (, (est-beta $partition $beta) (est-alpha $partition $alpha))
    (O
        (pure
            (est-beta-mean $beta $alpha $b-mean)
            $b-mean
            (f32_to_string (div_f32
                (f32_from_string $alpha)
                (sum_f32 (f32_from_string $alpha) (f32_from_string $beta))))
        )
    )
)

;; =============================================================================================
;; Label: est-beta-var (for partitions)
;; Purpose: Calculate the variance of a Beta distribution from its alpha and beta parameters.
;;          Uses the formula:
;;          beta-var = (alpha * beta) / ((alpha + beta)^2 * (alpha + beta + 1))
;;          This represents the spread/uncertainty of the Beta distribution.
;; =============================================================================================
(exec (est-tv 184 est-beta-var)
    (, (est-beta $partition $beta) (est-alpha $partition $alpha))
    (O
        (pure
            (est-beta-var $beta $alpha $b-var)
            $b-var
            (f32_to_string (div_f32
                (product_f32 (f32_from_string $alpha) (f32_from_string $beta))
                (product_f32 
                    (product_f32 (sum_f32 (f32_from_string $alpha) (f32_from_string $beta)) (sum_f32 (f32_from_string $alpha) (f32_from_string $beta)))
                    (sum_f32 (f32_from_string 1) (f32_from_string $alpha) (f32_from_string $beta)))
            ))
        )
    )
)



(exec (est-tv 185 est-beta-distribution)
    (,  (est-beta $partition $beta) (est-alpha $partition $alpha) (est-beta-var $beta $alpha $b-var) (est-beta-mean $beta $alpha $b-mean))
    (, (est-beta-distribution ($beta $alpha) ($b-mean $b-var)))
)

(exec (est-tv 186 est-mk-distribution)
    (, (est-beta-distribution ($beta $alpha) ($b-mean $b-var)) (est-alpha $partition $alpha) (est-beta $partition $beta))
    (, (est-mk-distribution $partition ($b-mean $b-var)))
)



(exec (est-tv 187 mean-acc) 
    (, (est-mk-distribution $partition ($b-mean $b-var)) (partition $partitions $partition) (partitions-of $pattern $partitions))
    (, (mean-acc $pattern 0))
)


(exec (est-tv 188 mean-acc) 
    (, (mean-acc $pattern $acc) (partitions-of $pattern $partitions) (exec (est-tv 188 mean-acc)  $src (O (pure $out $var (car $p)))))
    (O
        (pure
            (exec (est-tv 188 mean-acc) 
                (, (est-mk-distribution $partition ($b-mean $b-var)))
                (O 
                    (pure
                        (mean-acc $pattern $new-acc)
                        $new-acc
                        (f32_to_string (sum_f32 (f32_from_string $b-mean) (f32_from_string $acc)))
                    )
                    (- (mean-acc $pattern $acc))
                    (+ (exec (est-tv 188 mean-acc) $src (O (pure $out $var (car (cdr $p))))))
                )
            )
            $partition
            (car (' $partitions))
        )
    )
)

(exec (est-tv 189 mean)
    (, (mean-acc $pattern $acc) (partitions-of $pattern $partitions))
    (O
        (pure
            (est-mk-stv-mean $pattern $mean)
            $mean
            (f32_to_string (div_f32 (f32_from_string $acc) (f32_from_string (length (' $partitions)))))
        )
    )
)


(exec (est-tv 190 rel-var)
    (, (partition $partitions $partition) (partitions-of $pattern $partitions) (est-mk-distribution $partition ($b-mean $b-var)) (est-mk-stv-mean $pattern $mean))
    (O
        (pure
            (est-mk-rel-var $pattern $partition ($b-mean $b-var) $rel-var)
            $rel-var
            (f32_to_string (sum_f32 (f32_from_string $b-var)
                (powf_f32 
                    (sub_f32 (f32_from_string $b-mean) (f32_from_string $mean)) (f32_from_string 2))))
        )
    )
)

;; =============================================================================================
;; Label: mk-stv-var
;; Purpose: Convert accumulated variance into the final STV variance estimate.
;; ============================================================================================

(exec (est-tv 191 rel-var-acc) 
    (, (est-mk-rel-var $pattern $partition ($b-mean $b-var) $rel-var) (partitions-of $pattern $partitions))
    (, (var-acc $pattern 0))
)

(exec (est-tv 192 var-acc) 
    (, (var-acc $pattern $acc) (partitions-of $pattern $partitions) (exec (est-tv 192 var-acc)   $src (O (pure $out $var (car $p)))))
    (O
        (pure
            (exec (est-tv 192 var-acc) 
                (, (est-mk-rel-var $pattern $partition ($b-mean $b-var) $rel-var))
                (O 
                    (pure
                        (var-acc $pattern $new-acc)
                        $new-acc
                        (f32_to_string (sum_f32 (f32_from_string $rel-var) (f32_from_string $acc)))
                    )
                    (- (var-acc $pattern $acc))
                    (+ (exec (est-tv 192 var-acc) $src (O (pure $out $var (car (cdr $p))))))
                )
            )
            $partition
            (car (' $partitions))
        )
    )
)


(exec (est-tv 193 mk-stv-var)
    (, (var-acc $pattern $acc) (partitions-of $pattern $partitions))
    (O
        (pure
            (est-mk-stv-var $pattern $var)
            $var
            (f32_to_string (div_f32 (f32_from_string $acc) (f32_from_string (length (' $partitions)))))
        )
    )
)

;; =============================================================================================
;; Label: avrg-tv
;; Purpose: Derive beta and alpha parameters from the STV mean and variance.
;; =============================================================================================


(exec (est-tv 194 avrg-tv)
    (, (est-mk-stv-var $pattern $var) (est-mk-stv-mean $pattern $mean))
    (O
        (pure
            (found-beta $mean $var $f-beta)
            $f-beta
            (f32_to_string (product_f32  
                (sub_f32 (f32_from_string 1) (f32_from_string $mean)) 
                (sub_f32 
                    (div_f32
                        (product_f32 (f32_from_string $mean)
                            (sub_f32 (f32_from_string 1) (f32_from_string $mean)))
                        (f32_from_string $var))  
                    (f32_from_string 1)
            )))
        )
    )
)

(exec (est-tv 195 avrg-tv)
    (, (est-mk-stv-var $pattern $var) (est-mk-stv-mean $pattern $mean))
    (O
        (pure
            (found-alpha $mean $var $f-alpha)
            $f-alpha
            (f32_to_string (product_f32  
                (f32_from_string $mean) 
                (sub_f32 
                    (div_f32
                        (product_f32 (f32_from_string $mean)
                            (sub_f32 (f32_from_string 1) (f32_from_string $mean)))
                        (f32_from_string $var))  
                    (f32_from_string 1))))
        )
    )
)

;; =============================================================================================
;; Label: mk-stv
;; Purpose: Build STV count and confidence values from beta/alpha estimates.
;; =============================================================================================

(exec (est-tv 196 mk-stv)
    (,  (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (CONSTANT prior-beta $pb) (CONSTANT prior-alpha $pa))
    (O
        (pure
            (mk-stv-count $mean $var $count)
            $count
            (f32_to_string (max_f32    
                (sub_f32
                    (sum_f32 (f32_from_string $f-alpha) (f32_from_string $f-beta))
                    (sum_f32 (f32_from_string $pa) (f32_from_string $pb)))
                (f32_from_string 0.1)))
        )
    )
)

(exec (est-tv 197 mk-stv-confidence)
    (, (mk-stv-count $mean $var $count) (CONSTANT default_k $k))
    (O
        (pure
            (mk-stv-confidence $mean $var $confidence)
            $confidence
            (f32_to_string (div_f32 
                (f32_from_string $count) 
                (sum_f32 (f32_from_string $count) (f32_from_string $k))))
        )
    )
)

;; =============================================================================================
;; Label: comparisons
;; Purpose: Compute comparison predicates used by the STV mode rules.
;; =============================================================================================

(exec (est-tv 198 comparisons)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha))
    (O
        (pure
            (is-gt $f-alpha 1 $bool)
            $bool
            (gt_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-gt $f-beta 1 $bool)
            $bool
            (gt_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
        (pure
            (is-eq $f-beta 1 $bool)
            $bool
            (eq_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
        (pure
            (is-le $f-alpha 1 $bool)
            $bool
            (le_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-lt $f-alpha 1 $bool)
            $bool
            (lt_f32 (f32_from_string $f-alpha) (f32_from_string 1))
        )
        (pure
            (is-lt $f-beta 1 $bool)
            $bool
            (lt_f32 (f32_from_string $f-beta) (f32_from_string 1))
        )
    )
)

; ;; Start with the base tree

(exec (est-tv 199 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha))
    (, (mk-stv-mode $mean $var 1))  
)
(exec (est-tv 200 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-lt $f-beta 1 true) (is-lt $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) (+ (mk-stv-mode $mean $var $mean)))  
)
(exec (est-tv 201 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-gt $f-beta 1 true) (is-le $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) (+ (mk-stv-mode $mean $var 0)))  
)
(exec (est-tv 202 mk-stv-mode)
    (, (found-beta $mean $var $f-beta) (found-alpha $mean $var $f-alpha) (mk-stv-mode $mean $var 1) (is-gt $f-beta 1 true) (is-gt $f-alpha 1 true))
    (O (- (mk-stv-mode $mean $var 1)) 
        (pure (mk-stv-mode $mean $var $mode)
            $mode 
            (f32_to_string (div_f32 
                (sub_f32 (f32_from_string $f-alpha) (f32_from_string 1))
                (sum_f32 
                    (f32_from_string $f-alpha)
                    (sub_f32 (f32_from_string $f-beta) (f32_from_string 2))
                )
            ))
        )
    )  
)

;; =============================================================================================
;; Label: mk-stv-mode
;; Purpose: Determine the STV mode from alpha and beta shape conditions.
;; =============================================================================================

(exec (est-tv 203 mk-stv)
    (, (mk-stv-mode $mean $var $mode) (mk-stv-confidence $mean $var $confidence))
    (, (mk-stv $mean $var ($mode $confidence)))
)

;; =============================================================================================
;; Label: do-ji-tv-est
;; Purpose: Finalize the estimated STV for the given pattern and database.
;; =============================================================================================

(exec (est-tv 204 do-ji-tv-est)
    (, (mk-stv $mean $var ($mode $confidence)) (est-mk-stv-var $pattern $var) (est-mk-stv-mean $pattern $mean))
    (, (STV $pattern ($mode $confidence)))
)