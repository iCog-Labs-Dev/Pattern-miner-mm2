# Testing Guide

Tests are written as runnable MM2 files. Each test file is the main input to
`mork run`, while implementation and data files are loaded through `TEST-AUX`
metadata comments.

## Test File Shape

Use this structure for each test:

```metta
;; TEST-AUX data/example-data.metta
;; TEST-AUX src/example-module.metta

(INPUT ...)

(EXPECTED-RESULT test-id expected-fact)
```

The runner reads `TEST-AUX` comments, runs MORK, then checks that every
`expected-fact` appears as a standalone fact in the final output.

## Adding A New Module Test

1. Create a test file under `tests/<module>/`.

```text
tests/frequent-miner/conjunction-expansion-test.metta
```

2. Add the required data and source files as aux paths.

```metta
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/common-utils/utils.metta
;; TEST-AUX src/conjunction-expansion-triplet.metta
```

List shared utilities before the implementation that calls them. The current
conjunction-expansion test uses the existing `ugly-sodaDrinker.metta` fixture;
it does not maintain a separate copy of the database.

3. Add the input facts expected by the module.

```metta
(INPUT DB db)
(INPUT MIN-SUPPORT 3)
```

4. Add one or more expected results.

```metta
(EXPECTED-RESULT conjunction-expansion-singleton
  (expanded-conjunct 1 ((Inheritance (var 0) human)) 10))
```

The first argument after `EXPECTED-RESULT` is the test identifier. The second
argument is the fact that must be present in the final MORK output.

The integrated frequent-miner coverage is intentionally kept in two files:

- `frequent-pattern-miner-test.metta` runs the real iterative miner and
  conjunction expansion through `frequent-pattern-miner-fn`. It checks flat
  candidates, calculated support, singleton-support reuse, and expanded
  conjunctions.
- `iterative-miner-nested-test.metta` covers the distinct recursive path by
  verifying that a nested candidate starts another mining generation.

The integrated test loads the shared fixture in raw form for conjunction
matching and materializes `(FACT ...)` wrappers for the frequent miner.

5. Run all tests.

```sh
scripts/run-tests.sh
```

6. Or run only the new test.

```sh
scripts/run-tests.sh tests/frequent-miner/conjunction-expansion-test.metta
```

Run the real end-to-end pipeline with:

```sh
scripts/run-tests.sh tests/frequent-miner/frequent-pattern-miner-test.metta
```

## Optional Step Limit

Most tests do not need to define a step limit. The runner has a default safety
limit so accidental loops do not run forever.

If a test needs a custom maximum number of MM2 execution transitions, add:

```metta
;; TEST-STEPS 50000
```

Use this only when the default runner behavior is not enough for that specific
test.
