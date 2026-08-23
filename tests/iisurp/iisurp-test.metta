;; TEST-AUX data/iisurp-state-count.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/common-utils/surp-components.metta
;; TEST-AUX src/iisurp.metta

;; One corpus run covers the paper example, pattern isolation, semantic
;; estimates, the shared ISurp base, and two-/three-conjunct output.

;; The fixture contains 158 facts, which defines the legacy probability universe.
(INPUT DB-SIZE 158)
;; Public entry-point case: test whether USA-like abstraction explains California surfers.
(iisurp (, (Inheritance $x California) (Inheritance $x surfer)) 2)
;; Contrast case: coffee drinking is better predicted by the abstraction.
(iisurp (, (Inheritance $x California) (Inheritance $x coffeeDrinker)) 3)
;; A longer pattern checks that partition and semantic estimates still combine.
(iisurp (, (Inheritance $x California) (Inheritance $x coffeeDrinker) (Inheritance $x techWorker)) 2)
;; Retain intermediate facts so this golden test can verify the calculation.
(INPUT IISURP-TRACE TRUE)

;; C(158, 2) is the common universe for all two-clause probabilities.
(EXPECTED-RESULT surfer-universe (isurp-universe-count ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) 12403))
;; Empirical probability is the supplied support 2 divided by that universe.
(EXPECTED-RESULT surfer-empirical (isurp-empirical-probability ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) 0.0001612513101668951))
;; The independent partition supplies the ordinary ISurp baseline estimate.
(EXPECTED-RESULT surfer-partition (isurp-partition-estimate ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) (((Inheritance (var 0) California)) ((Inheritance (var 0) surfer))) 2.8602183533594227e-7))
;; USA members have this average feature overlap in the legacy coherence rule.
(EXPECTED-RESULT usa-coherence (iisurp-coherence ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) (candidate 0 arg/2 California USA) 0.484199134199134))
;; Coherence squared produces the lower semantic expectation for USA.
(EXPECTED-RESULT surfer-lower (iisurp-semantic-estimate ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) (candidate 0 arg/2 California USA) lower 1.3747336879446526e-5))
;; The legacy 0.4/coherence factor produces the upper semantic expectation.
(EXPECTED-RESULT surfer-upper (iisurp-semantic-estimate ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) (candidate 0 arg/2 California USA) upper 4.844026840954562e-5))
;; Raw IISurp is the empirical probability's distance above the full interval.
(EXPECTED-RESULT surfer-raw (iisurp-raw-of ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) 0.00011281104175734949))
;; Normalization turns the raw distance into the public surfer score.
(EXPECTED-RESULT surfer-score (iisurp-of ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) 0.6995976754582028))
;; The same value must also appear through the canonical consumer-facing fact.
(EXPECTED-RESULT canonical-score (surprisingness-of (, (Inheritance $a California) (Inheritance $a surfer)) 0.6995976754582028))
;; Coffee has a larger semantic upper bound because USA predicts it better.
(EXPECTED-RESULT coffee-upper (iisurp-semantic-estimate ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker)) (candidate 0 arg/2 California USA) upper 0.00019376107363818247))
;; Better semantic prediction leaves a smaller unexplained raw distance.
(EXPECTED-RESULT coffee-raw (iisurp-raw-of ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker)) 4.8115891612160184e-5))
;; Consequently the normalized coffee score is lower than the surfer score.
(EXPECTED-RESULT coffee-score (iisurp-of ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker)) ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker)) 0.19892713455520758))
;; C(158, 3) proves that the probability universe follows conjunction size.
(EXPECTED-RESULT three-conjunct-universe (isurp-universe-count ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker) (Inheritance (var 0) techWorker)) 644956))
;; All partition and semantic estimates reduce to this three-clause interval.
(EXPECTED-RESULT three-conjunct-interval (iisurp-expected-interval ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker) (Inheritance (var 0) techWorker)) 0.0000000000000009840420676830754 0.000001397315434890739))
;; The remaining distance verifies end-to-end scoring beyond two clauses.
(EXPECTED-RESULT three-conjunct-raw (iisurp-raw-of ((Inheritance (var 0) California) (Inheritance (var 0) coffeeDrinker) (Inheritance (var 0) techWorker)) 1.7036712990880131e-6))
