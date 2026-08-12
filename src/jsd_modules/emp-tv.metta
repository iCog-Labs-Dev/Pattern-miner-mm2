;; ========================================================================
;; Label: universe-count
;; Purpose: Get total relevant items
;; ========================================================================

(exec (jsd 112 universe-count)
    (, (INPUT DB $db-name) (INPUT PATTERN ($pattern $support))
         ((universe-count $db-name $pattern -> universe-count-of) $src-of-uvc $sink-of-uvc))
         
    (,
        (exec (jsd 114 universe-count) $src-of-uvc $sink-of-uvc)
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


(exec (jsd 115 emp-tv-confidence)
    (, (universe-count-of $pattern $db $uc) (CONSTANT DEFAULT_K $k))
    (O
        (pure
            (emp-tv-confidence $pattern $db $conf)
            $conf
            (f32_to_string ( product_f32 
                (f32_from_string 0.1) 
                (div_f32 (f32_from_string $uc) (sum_f32 (f32_from_string $uc) (f32_from_string $k)))))
        )
    )
)
(exec (jsd 116 emp-tv-mean)
    (, (universe-count-of $pattern $db $uc) (INPUT PATTERN ($pattern $support)))
    (O
        (pure
            (emp-tv-mean $pattern $db $mean)
            $mean
            (f32_to_string (div_f32 (f32_from_string $support) (f32_from_string $uc)))
        )
    )
)
(exec (jsd 117 emp-tv)
    (, (emp-tv-confidence $pattern $db $conf) (emp-tv-mean $pattern $db $mean))
    (, (EMPTV $pattern $db ($mean $conf)))
)