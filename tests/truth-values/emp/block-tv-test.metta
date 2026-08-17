;; TEST-AUX src/truth-values/emp/01_block_tv.metta

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Block empirical truth value component test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(INPUT DB-SIZE 4)

(partition (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))))

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) man))
    2)

(block-support
    (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly)))
    ((Inheritance (var 0) ugly))
    2)

(EXPECTED-RESULT block-tv-man (block-tv-of (((Inheritance (var 0) man)) ((Inheritance (var 0) ugly))) ((Inheritance (var 0) man)) (EMPTV 0.5 0.0004975124378109452)))

(partition
    (((Inheritance (var 0) man)
      (Inheritance (var 0) ugly)
      (Inheritance (var 0) sodaDrinker)
      (Inheritance (var 0) human))))

(block-support
    (((Inheritance (var 0) man)
      (Inheritance (var 0) ugly)
      (Inheritance (var 0) sodaDrinker)
      (Inheritance (var 0) human)))
    ((Inheritance (var 0) man)
     (Inheritance (var 0) ugly)
     (Inheritance (var 0) sodaDrinker)
     (Inheritance (var 0) human))
    1)

(EXPECTED-RESULT block-tv-four-universe (pro-block-universe-count (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human))) ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)) 256))

(EXPECTED-RESULT block-tv-four (block-tv-of (((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human))) ((Inheritance (var 0) man) (Inheritance (var 0) ugly) (Inheritance (var 0) sodaDrinker) (Inheritance (var 0) human)) (EMPTV 0.00390625 0.024242424242424246)))
