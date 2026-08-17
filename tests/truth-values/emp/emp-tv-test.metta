;; TEST-AUX src/truth-values/emp/00_emp_tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Empirical truth value component test.
;;
;; Also mirrors the deterministic PeTTa validation cases from:
;;   hyperon-miner/experiments/validation/empirical-tv-validation.metta
;;
;; The PeTTa cases using `db_ratio 0.02` are sampling/bootstrap cases and are
;; not asserted here because the current MM2 port intentionally keeps empirical
;; TV deterministic and does not implement bootstrap sampling.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(INPUT PATTERN
    ((, (Inheritance (var 0) man)
        (Inheritance (var 0) ugly))
     1))

(EXPECTED-RESULT emp-tv (emp-tv-of (, (Inheritance (var 0) man) (Inheritance (var 0) ugly)) (EMPTV 0.0625 0.00196078431372549)))

(INPUT DB-SIZE 60)

(INPUT PATTERN
    ((, (Inheritance $x ugly)
        (Inheritance $x man)
        (Inheritance $x sodaDrinker))
     5))

(INPUT PATTERN
    ((, (Inheritance $x ugly)
        (Inheritance $x man))
     5))

(INPUT PATTERN
    ((, (Inheritance $x ugly)
        (Inheritance $x man)
        (Inheritance $x sodaDrinker)
        (Inheritance $x human))
     5))

(EXPECTED-RESULT petta-emp-tv-three (emp-tv-of (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker)) (EMPTV 2.3148148148148147e-5 0.09963099630996311)))

(EXPECTED-RESULT petta-emp-tv-two (emp-tv-of (, (Inheritance $a ugly) (Inheritance $a man)) (EMPTV 0.001388888888888889 0.08181818181818183)))

(EXPECTED-RESULT emp-tv-four-size (emp-tv-pattern-size-of (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker) (Inheritance $a human)) 4))

(EXPECTED-RESULT emp-tv-four-universe (emp-prob-pbs-universe-count (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker) (Inheritance $a human)) 12960000))

(EXPECTED-RESULT emp-tv-four (emp-tv-of (, (Inheritance $a ugly) (Inheritance $a man) (Inheritance $a sodaDrinker) (Inheritance $a human)) (EMPTV 3.8580246913580245e-7 0.09999382754150979)))
