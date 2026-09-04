;; TEST-AUX src/jsd_modules/eq-prob.metta
;; TEST-AUX data/ugly-sodaDrinker.metta


(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly)) (var 0))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker) (Inheritance (var 0) ugly)) (var 0))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker) (Inheritance (var 0) ugly)) (var 1))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker)) (var 0))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 0))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 1))
(eq-block-has-var TEST ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 2))
(eq-block-has-var TEST ((Inheritance (var 0) man)) (var 0))
(eq-block-has-var TEST ((Inheritance (var 0) (var 1))) (var 1))

(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) (var 1))) (var 1) 5))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man)) (var 0) 10))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker)) (var 0) 10))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 0) 10))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 1) 4))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1))) (var 2) 20))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) ugly)) (var 0) 5))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker) (Inheritance (var 0) ugly)) (var 0) 5))
(EXPECTED-RESULT value-count (value-count ((Inheritance (var 0) man) (Inheritance (var 1) sodaDrinker) (Inheritance (var 0) ugly)) (var 1) 10))

