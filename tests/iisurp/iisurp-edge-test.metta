;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/common-utils/surp-components.metta
;; TEST-AUX src/iisurp.metta
;; TEST-STEPS 1000000

;; One small run covers low evidence, no semantic candidate, invalid arity,
;; generic triplet links, five clauses, multiple patterns, and trace cleanup.

(Inheritance Alice California)
(Inheritance Alice USA)
(Inheritance Alice surfer)
(Inheritance Alice red)
(Inheritance Bob blue)

(Tagged alice Red)
(Tagged alice Warm)
(Tagged bob Red)
(Tagged bob Warm)
(Likes alice Tea)
(Likes bob Tea)

(Located City Region1)
(Located Country Region1)
(Located City Region2)
(Located Country Region2)
(HasCode Region1 Code)
(HasCode Region2 Code)

(INPUT DB db);; All 17 corpus facts share one legacy probability universe.
(INPUT DB-SIZE 17);; A single USA member exercises the 0.5 low-evidence coherence fallback.
(INPUT PATTERN ((, (Inheritance $x California) (Inheritance $x surfer)) 1));; Neither clause has support, so no semantic candidate can explain the pattern.
(INPUT PATTERN ((, (Inheritance $x blue) (Inheritance $x green)) 0));; Four unsupported clauses check sparse partition handling without candidates.
(INPUT PATTERN ((, (Inheritance $x red) (Inheritance $x blue) (Inheritance $x green) (Inheritance $x yellow)) 0));; Five clauses cross the former arity cap and exercise the generic product fold.
(INPUT PATTERN ((, (RelA $x A) (RelB $x B) (RelC $x C) (RelD $x D) (RelE $x E)) 0));; Tagged/Red -> Tagged/Warm tests an arbitrary link at arg/2.
(INPUT PATTERN ((, (Tagged $x Red) (Likes $x Tea)) 2));; Located/City -> Located/Country tests an arbitrary link at arg/1.
(INPUT PATTERN ((, (Located City $x) (HasCode $x Code)) 2));; One clause has no non-trivial partition and must produce a scoped error.
(INPUT PATTERN ((, (Inheritance $x red)) 1));; Keep the same legacy numeric contract used by the golden scenario.
(INPUT IISURP-PROFILE LEGACY-NUMERIC);; Candidate replacements are inferred from shared opposite-position values.
(INPUT IISURP-CONCEPT-SOURCE EXTENSIONAL);; Exercise public normalized outputs, including the zero-denominator branch.
(INPUT IISURP-NORMALIZATION TRUE);; Remove intermediates to prove that cleanup preserves only public results.
(INPUT IISURP-TRACE FALSE)

;; A one-clause request is rejected explicitly rather than silently stalling.
(EXPECTED-RESULT invalid-arity (iisurp-error ((Inheritance (var 0) red)) input (unsupported-pattern-arity 1)));; Low-evidence intermediate state must be removed after publishing its score.
(EXPECTED-RESULT low-evidence-cleanup (iisurp-cleanup-complete ((Inheritance (var 0) California) (Inheritance (var 0) surfer))));; The fallback coherence produces this stable normalized result.
(EXPECTED-RESULT low-evidence-score (iisurp-of ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) ((Inheritance (var 0) California) (Inheritance (var 0) surfer)) 0.2));; Cleanup must also finish when no semantic replacement is available.
(EXPECTED-RESULT no-candidate-cleanup (iisurp-cleanup-complete ((Inheritance (var 0) blue) (Inheritance (var 0) green))));; Zero empirical and expected probabilities take the safe zero-score path.
(EXPECTED-RESULT no-candidate-score (iisurp-of ((Inheritance (var 0) blue) (Inheritance (var 0) green)) ((Inheritance (var 0) blue) (Inheritance (var 0) green)) 0.0));; The same zero-safe behavior works with a four-clause partition set.
(EXPECTED-RESULT sparse-four-conjunct-score (iisurp-of ((Inheritance (var 0) red) (Inheritance (var 0) blue) (Inheritance (var 0) green) (Inheritance (var 0) yellow)) ((Inheritance (var 0) red) (Inheritance (var 0) blue) (Inheritance (var 0) green) (Inheritance (var 0) yellow)) 0.0));; A completed five-clause score proves there is no static maximum arity.
(EXPECTED-RESULT five-clause-score (iisurp-of ((RelA (var 0) A) (RelB (var 0) B) (RelC (var 0) C) (RelD (var 0) D) (RelE (var 0) E)) ((RelA (var 0) A) (RelB (var 0) B) (RelC (var 0) C) (RelD (var 0) D) (RelE (var 0) E)) 0.0));; Warm fully explains Red at arg/2, demonstrating link-name independence.
(EXPECTED-RESULT generic-arg-2-score (iisurp-of ((Tagged (var 0) Red) (Likes (var 0) Tea)) ((Tagged (var 0) Red) (Likes (var 0) Tea)) 0.0));; Country fully explains City at arg/1, demonstrating position independence.
(EXPECTED-RESULT generic-arg-1-score (iisurp-of ((Located City (var 0)) (HasCode (var 0) Code)) ((Located City (var 0)) (HasCode (var 0) Code)) 0.0))
