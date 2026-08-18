;;===============================================================
;; Empirical truth value for ONE hardcoded 2-conjunct pattern.
;;
;; This file holds RULES ONLY and cannot be run standalone — with
;; no facts in the space nothing matches and you get
;; "dumping 0 expressions". The dataset must be supplied as an aux
;; space.
;;
;; From anywhere (absolute, WSL paths — mork is a Linux binary, so
;; C:\... does NOT resolve, use /mnt/c/...):
;;
;;   mork run --aux-path /mnt/c/Users/tewob/mm2/Pattern-miner-mm2/data/ugly-sodaDrinker.metta /mnt/c/Users/tewob/mm2/Pattern-miner-mm2/src/emperical-truth-value.metta
;;
;; Or cd to the project root first, then the short form:
;;
;;   cd /mnt/c/Users/tewob/mm2/Pattern-miner-mm2
;;   mork run --aux-path data/ugly-sodaDrinker.metta src/emperical-truth-value.metta
;;
;; Keep each invocation on ONE line. A trailing "\" only continues
;; a line when it is the last character before a real newline; if
;; it ends up mid-line it is parsed as its own argument and mork
;; dies with NotFound.
;;
;; --aux-path may be repeated; each file is add_all_sexpr'd into
;; the same space before the calculus starts. There is no in-file
;; import/include form in MORK.
;;
;;---------------------------------------------------------------
;; EXEC ORDERING — read before renumbering anything.
;;
;; metta_calculus walks the `exec` subtrie with to_next_val(),
;; i.e. LEXICOGRAPHIC BYTE ORDER of the serialized location, not
;; numeric order. A symbol serializes as (0xC0|len) followed by
;; its bytes, so the length byte is compared FIRST:
;;
;;   "9"   -> C1 39        fires before
;;   "99"  -> C2 39 39     fires before
;;   "100" -> C3 31 30 30
;;
;; So 9 fires before 100, and 007 fires AFTER 9. Byte order only
;; agrees with numeric order when every priority has the SAME
;; DIGIT WIDTH. All priorities below are 3 digits — keep it that
;; way, and keep each producer numbered below its consumer.
;;===============================================================

;;---------------------------------------------------------------
;; sup_num / db_size — pattern IS the trigger conjunct
;;---------------------------------------------------------------
(exec (0 900)
    (, (Inheritance $x woman)
       (Inheritance $x sodaDrinker))
    (O
        (count (sup-counted $k) $k $x)))

(exec (0 910)
    (, (Inheritance $x $y))
    (O
        (count (db-counted $k) $k ($x $y))))

;;---------------------------------------------------------------
;; Combine sup/db. n_conjuncts fixed at 2 for this pattern.
;;---------------------------------------------------------------
(exec (0 920)
    (, (sup-counted $sup)
       (db-counted $dbn))
    (O
        (+ (universe-count-request target $dbn 2))
        (+ (pending-emp target $sup))
        (- (sup-counted $sup))
        (- (db-counted $dbn))))

;;---------------------------------------------------------------
;; universe_count = powi_f64(db_size_as_f64, n_conjuncts_i32)
;;---------------------------------------------------------------
(exec (0 940)
    (, (universe-count-request $pattern $dbn $nc))
    (O
        (pure (uc-dbn-i32 $pattern $dbn-i32)
            $dbn-i32 (i32_from_string $dbn))
        (pure (uc-nc-i32 $pattern $nc-i32)
            $nc-i32 (i32_from_string $nc))
        (- (universe-count-request $pattern $dbn $nc))))

(exec (0 950)
    (, (uc-dbn-i32 $pattern $dbn-i32)
       (uc-nc-i32 $pattern $nc-i32))
    (O
        (pure (uc-dbn-f64 $pattern $nc-i32 $dbn-f64)
            $dbn-f64 (i32_as_f64 $dbn-i32))
        (- (uc-dbn-i32 $pattern $dbn-i32))
        (- (uc-nc-i32 $pattern $nc-i32))))

(exec (0 960)
    (, (uc-dbn-f64 $pattern $nc-i32 $dbn-f64))
    (O
        (pure (universe-count-result $pattern $uc)
            $uc (powi_f64 $dbn-f64 $nc-i32))
        (- (uc-dbn-f64 $pattern $nc-i32 $dbn-f64))))

;;---------------------------------------------------------------
;; Launch emp-tv once pending-emp and universe-count-result exist
;;---------------------------------------------------------------
(exec (0 970)
    (, (pending-emp target $sup)
       (universe-count-result target $uc))
    (O
        (+ (emp-tv-request target $sup $uc))
        (- (pending-emp target $sup))
        (- (universe-count-result target $uc))))

;;---------------------------------------------------------------
;; count_to_confidence = 0.1 * (uc / (uc + 800.0))
;; This exact 4-stage chain was independently confirmed working.
;; Numbered above 990 because (0 990) is what emits the
;; confidence-request these consume. See ordering note at top.
;;---------------------------------------------------------------
(exec (0 992)
    (, (confidence-request $pattern $uc))
    (O
        (pure (ctc-threshold $pattern $uc $threshold)
            $threshold (f64_from_string 800.0))
        (pure (ctc-scale $pattern $uc $scale)
            $scale (f64_from_string 0.1))
        (- (confidence-request $pattern $uc))))

(exec (0 993)
    (, (ctc-threshold $pattern $uc $threshold)
       (ctc-scale $pattern $uc $scale))
    (O
        (pure (ctc-denom $pattern $uc $scale $denom)
            $denom (sum_f64 $uc $threshold))
        (- (ctc-threshold $pattern $uc $threshold))
        (- (ctc-scale $pattern $uc $scale))))

(exec (0 994)
    (, (ctc-denom $pattern $uc $scale $denom))
    (O
        (pure (ctc-ratio $pattern $scale $ratio)
            $ratio (div_f64 $uc $denom))
        (- (ctc-denom $pattern $uc $scale $denom))))

(exec (0 995)
    (, (ctc-ratio $pattern $scale $ratio))
    (O
        (pure (confidence-result $pattern $confidence)
            $confidence (product_f64 $scale $ratio))
        (- (ctc-ratio $pattern $scale $ratio))))

;;---------------------------------------------------------------
;; emp-tv: strength = sup / uc (as f64)
;;---------------------------------------------------------------
(exec (0 990)
    (, (emp-tv-request $pattern $sup $uc))
    (O
        (pure (emp-tv-sup-f64 $pattern $uc $sup-f64)
            $sup-f64 (f64_from_string $sup))
        (+ (confidence-request $pattern $uc))
        (- (emp-tv-request $pattern $sup $uc))))

(exec (0 991)
    (, (emp-tv-sup-f64 $pattern $uc $sup-f64))
    (O
        (pure (emp-tv-strength $pattern $strength)
            $strength (div_f64 $sup-f64 $uc))
        (- (emp-tv-sup-f64 $pattern $uc $sup-f64))))

;;---------------------------------------------------------------
;; Final join, with human-readable string conversion so the result
;; can actually be read directly instead of raw bytes.
;;---------------------------------------------------------------
(exec (0 996)
    (, (emp-tv-strength $pattern $strength)
       (confidence-result $pattern $confidence))
    (O
        (pure (EMPTV-strength-readable $pattern $s-str)
            $s-str (f64_to_string $strength))
        (pure (EMPTV-confidence-readable $pattern $c-str)
            $c-str (f64_to_string $confidence))
        (- (emp-tv-strength $pattern $strength))
        (- (confidence-result $pattern $confidence))))

