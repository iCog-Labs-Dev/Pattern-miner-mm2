;; ========================================================================
;; Label: universe-count
;; Purpose: Get total relevant items
;; ========================================================================

(exec (emp-tv 112 universe-count)
    (, (INPUT DB-SIZE $db-size) (num-of-conjuncts $indexed-pattern $conjuncts))
    (O
        (pure
            (universe-count-of $indexed-pattern $uc)
            $uc
            (i64_to_string (pow_i64 (i64_from_string $db-size) (i64_from_string $conjuncts)))
        )
    )
)


;; ========================================================================
;; Label: emp-tv
;; Purpose: Calculate empirical truth value for a pattern in database
;; 1. Calculate a confidence value based on a universe-count using a smoothing constant (DEFAULT_K).
;;      - confidence = (x / (x + Default_k) * 0.1)
;; 2. Calculate a mean value based on the support and universe-count.
;;      - mean = (support / universe-count)
;; 3. Return the empirical truth value as a pair of mean and confidence.
;; ========================================================================


(exec (emp-tv 115 emp-tv-confidence)
    (, (universe-count-of $indexed-pattern $uc) (CONSTANT DEFAULT_K $k))
    (O
        (pure
            (emp-tv-confidence $indexed-pattern $conf)
            $conf
            (f32_to_string ( product_f32 
                (f32_from_string 0.1) 
                (div_f32 (f32_from_string $uc) (sum_f32 (f32_from_string $uc) (f32_from_string $k)))))
        )
    )
)
(exec (emp-tv 116 emp-tv-mean)
    (, (universe-count-of $indexed-pattern $uc) (indexed-pattern ($indexed-pattern $support)))
    (O
        (pure
            (emp-tv-mean $indexed-pattern $mean)
            $mean
            (f32_to_string (div_f32 (f32_from_string $support) (f32_from_string $uc)))
        )
    )
)
(exec (emp-tv 117 emp-tv)
    (, (emp-tv-confidence $indexed-pattern $conf) (emp-tv-mean $indexed-pattern $mean))
    (, (EMPTV $indexed-pattern ($mean $conf)))
)