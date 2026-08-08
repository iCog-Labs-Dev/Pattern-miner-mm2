;; TEST-AUX src/isurp_modules/01_bootstrap_partitions.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Partition component test
;;
;; This test validates only partition generation:
;;
;;   indexed-pattern
;;   -> ji-prob-partitions-of
;;   -> partition
;;   -> block
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(indexed-pattern
    ((Inheritance (var 0) man)
     (Inheritance (var 0) ugly)
     (Inheritance (var 0) sodaDrinker)))

(EXPECTED-RESULT partition-list-3 (ji-prob-partitions-of ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) ((((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker))) (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly))) (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker))) (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker))))))

(EXPECTED-RESULT partition-first (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT partition-singletons (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT block-first-single (block (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker))) ((Inheritance (var 0) man))))

(EXPECTED-RESULT block-first-pair (block (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker))) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4-clause case
;;
;; PeTTa `partitions-wout-pattern` returns Bell(4) - 1 = 14 partitions for four
;; clauses.  Verify that MM2 materializes the same partition set.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(indexed-pattern
    ((Inheritance (var 0) man)
     (Inheritance (var 0) ugly)
     (Inheritance (var 0) sodaDrinker)
     (Inheritance (var 0) human)))

(EXPECTED-RESULT partition-4-1 (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-2 (partition (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-3 (partition (((Inheritance (var 0) man) (Inheritance (var 0) human)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT partition-4-4 (partition (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly) (Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-5 (partition (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) human)) ((Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT partition-4-6 (partition (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-7 (partition (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)) ((Inheritance (var 0) ugly)))))

(EXPECTED-RESULT partition-4-8 (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-9 (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) human)) ((Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT partition-4-10 (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-11 (partition (((Inheritance (var 0) man) (Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-12 (partition (((Inheritance (var 0) man) (Inheritance (var 0) human)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker)))))

(EXPECTED-RESULT partition-4-13 (partition (((Inheritance (var 0) man) (Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) human)))))

(EXPECTED-RESULT partition-4-14 (partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)) ((Inheritance (var 0) sodaDrinker)) ((Inheritance (var 0) human)))))
