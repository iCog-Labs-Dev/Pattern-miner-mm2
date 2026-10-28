;; =============================================================================
;; ISurp-Old Generalized Test Suite (MORK)
;; =============================================================================
;; Validates the generalized ISurp-Old algorithm across:
;;   - Empty pattern: (), (,)
;;   - Single-conjunct pattern
;;   - 2-conjunct pattern (positive support, raw)
;;   - 3-conjunct pattern (coupled normalized, raw)
;;   - Zero support pattern
;;   - 4-conjunct nested pattern (normalized)
;;   - 5-conjunct pattern (raw)
;; =============================================================================

;; Importing datasets
;; TEST-AUX data/isurp-mock-coupled.metta
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/surp/isurp-old.metta

        ;; 1. Populate Database Spaces

;; &dbc: Coupled dataset (59 facts)
(exec (freq 001 import-coupled-facts-to-dbc)
  (, (Inheritance (Person $person) $trait))
  (O
    (+ (&dbc (Inheritance (Person $person) $trait)))))

;; &db: Combined dataset for existing tests (119 facts)
(exec (freq 002 import-ugly_man_sodaDrinker-to-db)
  (, (Inheritance $person $catagory))
  (O
    (+ (&db (Inheritance $person $catagory)))))


;; &dbn: True-nested dataset (25 facts) for 4-conjunct test
(&dbn (Inheritance (And (And (Person Allen) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Abe)   man) (Or human ugly))        (Or (And human man) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Mike)  man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Zac)   man) (Or human ugly))        (Or (And human man) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Breonna) woman) (Or human sodaDrinker)) (Or (And human woman) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Jenica)  woman) (Or human sodaDrinker)) (Or (And human woman) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Kecia)   woman) (Or human sodaDrinker)) (Or (And human woman) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Allen)   man) (Or human sodaDrinker)) (Or (And human man) (And human ugly))))
(&dbn (Inheritance (And (And (Person Cason)   man) (Or human ugly))        (Or (And human man) (And human ugly))))
(&dbn (Inheritance (And (And (Person Davion)  man) (Or human sodaDrinker)) (Or (And human man) (And human ugly))))
(&dbn (Inheritance (And (And (Person Hessley) man) (Or human ugly))        (Or (And human man) (And human ugly))))
(&dbn (Inheritance (And (And (Person Lily)   woman) (Or human ugly)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Emily)  woman) (Or human ugly)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Lucy)   woman) (Or human ugly)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Sophia) woman) (Or human ugly)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And human man)   (Or (Person Allen) (Person Mike)))   (Or (And human man)   (And human sodaDrinker))))
(&dbn (Inheritance (And (And human man)   (Or (Person Mike)  (Person Zac)))    (Or (And human man)   (And human sodaDrinker))))
(&dbn (Inheritance (And (And human woman) (Or (Person Breonna) (Person Kecia))) (Or (And human woman) (And human sodaDrinker))))
(&dbn (Inheritance (And (And human woman) (Or (Person Sophia)  (Person Lily)))  (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Allen) man) (Or human ugly))        (Or (And human man) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Abe)   man) (Or human sodaDrinker)) (Or (And human man) (And human ugly))))
(&dbn (Inheritance (And (And (Person Sophia) woman) (Or human ugly))     (Or (And human woman) (And human sodaDrinker))))
(&dbn (Inheritance (And (And (Person Breonna) woman) (Or human sodaDrinker)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Jenica) woman) (Or human sodaDrinker)) (Or (And human woman) (And human ugly))))
(&dbn (Inheritance (And (And (Person Davion)  man)  (Or human ugly))        (Or (And human man)   (And human sodaDrinker))))


;; &db5: 5-conjunct test database (15 facts)
(&db5 (P A 1))
(&db5 (P A 2))
(&db5 (P A 3))
(&db5 (P A 4))
(&db5 (P A 5))

(&db5 (P B 1))
(&db5 (P B 2))
(&db5 (P B 3))
(&db5 (P B 4))

(&db5 (P C 1))
(&db5 (P C 2))
(&db5 (P C 3))

(&db5 (P D 1))
(&db5 (P D 2))

(&db5 (P E 1))

;; =============================================================================
;; Test Cases
;; =============================================================================

;; Test 1: Empty pattern () -> Expected: 0.0
(isurp-old () &db False)

;; Test 2: Empty comma pattern (,) -> Expected: 0.0
(isurp-old (,) &db False)

;; Test 3: Single-conjunct pattern -> Expected: 0.0
(isurp-old (, (Inheritance $x man)) &db False)

;; Test 4: Three-conjunct pattern from &dbc database (Coupled Normalized)
;; Expected result: 0.999707773232028
(isurp-old
  (, (Inheritance (Person $x) man)
     (Inheritance (Person $x) ugly)
     (Inheritance (Person $x) sodaDrinker))
  &dbc
  True)

;; Test 5: Three-conjunct pattern from &db (Raw)
;; Expected result: 3.6517807714205046e-5 (with &db facts)
(isurp-old (, (Inheritance $x man)
              (Inheritance $x ugly)
              (Inheritance $x sodaDrinker))
           &db False)

;; Test 6: Two-conjunct pattern with matches in &db (Raw)
;; Expected result: 0.0014161840277284003
(isurp-old (, (Inheritance $x man)
              (Inheritance $x ugly))
           &db False)

;; Test 7: Empty-support case (second conjunct absent from &db) -> Expected: 0.0
(isurp-old (, (Inheritance $x man)
              (Inheritance $x noSuchTrait))
           &db False)

;; Test 8: Four-conjunct pattern with nested structure from &dbn (Normalized)
;; Expected result: 0.9996837944664032
(isurp-old (, (Inheritance (And (And (Person $x) man) (Or human sodaDrinker)) (Or (And human man) (And human sodaDrinker)))
              (Inheritance (And (And (Person $x)   man) (Or human sodaDrinker)) (Or (And human man) (And human ugly)))
              (Inheritance (And (And human man)   (Or (Person $x) (Person Mike)))   (Or (And human man)   (And human sodaDrinker)))
              (Inheritance (And (And (Person $x) man) (Or human ugly))        (Or (And human man) (And human sodaDrinker))))
           &dbn True)

;; Test 9: Five-conjunct pattern from &db5 (Raw)
;; Expected result: 0.0003324458868914413
(isurp-old
  (, (P $x 1)
     (P $x 2)
     (P $x 3)
     (P $x 4)
     (P $x 5))
  &db5
  False)



;; =============================================================================
;; Cleanup
;; =============================================================================
(exec (freq 110 clean_up_raw_facts_from_last_result)
  (, (Inheritance $human $catagory))
  (O (- (Inheritance $human $catagory))))

(exec (freq 111 clean_up_facts-with-space-last_result)
  (, ($db (Inheritance $human $catagory)))
  (O (- ($db (Inheritance $human $catagory)))))

(exec (freq 112 clean_up_true_nested_data_from_last_result)
  (, (&dbn (Inheritance $antecedent $consequent)))
  (O (- (&dbn (Inheritance $antecedent $consequent)))))

(exec (freq 112 clean_up_db5_facts)
  (, (&db5 $fact))
  (O (- (&db5 $fact))))

(exec (freq 113 clean-acc-defs)
  (, (DEF $name $p $t))
  (O (- (DEF $name $p $t))))
