# Truth-Values Validation against PeTTa

This document records validation of the MM2 `emp-tv.metta` and `est-tv.metta` implementation against the PeTTa truth-values tests in:

```text
https://github.com/trueagi-io/hyperon-miner/experiments/truth-values/tests/test-emp-tv.metta
```
and
```text
https://github.com/trueagi-io/hyperon-miner/experiments/truth-values/tests/test-est-tv.metta
```

The MM2 implementation under test is:

```text
./pattern-miner-mm2/src/jsd_modules/emp-tv.metta
```
and
```text
./pattern-miner-mm2/src/jsd_modules/est-tv.metta
```


Validation was run by generating temporary MM2 files under `/tmp` with:

- the same PeTTa test pattern(s) from `tests/jsd/*.metta`
- the same dataset atoms (the PeTTa ugly-sodaDrinker-db, converted to `(db-fact $db $fact)` format)
- `INPUT PATTERN` (main and partition patterns)
- `INPUT DB db1` set to the converted PeTTa DB
- constants used in the tests: `default_k`, `DEFAULT_K`, `prior-alpha`, `prior-beta`, imported from the PeTTa test files.
 
The primary test files consulted were `tests/jsd/emp-tv-test.metta` and `tests/jsd/est-tv-test.metta`.

## Results

**emp-tv**

| Case | Function | MM2 result | PeTTa expected | Status | Notes |
|---|---|---:|---:|---:|---|
| `ugly_man_sodaDrinker` | `emp-tv` | `(EMPTV (, (inheritance (var 0) woman) (inheritance (var 0) sodaDrinker)) db1 (0.0013888889 0.081818186))` | `(EMPTV 0.001388888888888889 0.08181818181818183)` | Pass | Difference is floating-point precision only. |
| `ugly_man_sodaDrinker` | `mk-stv` | `(mk-stv 1.7689693569125715 1.0178393379503528 (0 0.00012498438))` | `(mk-stv 1.7689693569125715 1.0178393379503528 (0 0.0001249843769528809))` | Pass | Matches expected within rounding. |
| `ugly_man_sodaDrinker` | `do_emp_tv` | `None` | `(EMPTV 0.001388888888888889 0.08181818181818183)` | Fail | Blocked: requires bootstrap/subsample dataset (bootstrapping/subsampling not available on MM2). |

**est-tv**

| Case | Function | MM2 result | PeTTa expected | Status | Notes |
|---|---|---:|---:|---:|---|
| `ugly_man_sodaDrinker` (partitions) | `ji-est-tv` | `Matches expected (rounded)` | `(0.0 0.00019792297)` etc. | Pass | MM2 `ji-est-tv` implementation is precise enough; values rounded in test. |
| `ugly_man_sodaDrinker` | `stv` | `(STV ((inheritance (var 0) woman) (inheritance (var 0) ugly)) db1 (0.0027780589 0.0006976749))` | `(STV 0.0027780589 0.0006976749)` | Pass | `STV` is implemented and matches expected (rounded). |
| `ugly_man_sodaDrinker` | `pro-prob-without-joint` | `(0 0.0019792297)` | `(0 0.0019792297)` | Pass | Matches expected.


## Current blockers

### 1. Floating-point precision

MM2 has limited floating-point precision compared to the PeTTa reference outputs. Many test differences are only rounding differences (PeTTa prints ~17 decimal places; MM2 prints ~9–10). Examples from the tests:

- `0.001388888888888889` vs `0.0013888889`
- `0.08181818181818183` vs `0.081818186`

### 2. `eq-prob` currently provided only as test facts

The test files import `eq-prob` results as static facts (for example using `(eq-prob-of ... <value>)`) rather than relying on a callable `eq-prob` computation inside the `jsd/truth-values` pipeline. In other words, `eq-prob` is still only provided as facts by the tests and there is no implemented `eq-prob-of`/`eq-prob` function in `jsd/truth-values` to compute these values dynamically. Implementing a reusable `eq-prob` function would let MM2 compute and validate equality-probabilities directly instead of depending on test-provided facts.

## Summary

- The MM2 `emp-tv` and related `ji-est-tv` / `mk-stv` / `stv` computations match the PeTTa expected values for the tested `ugly_man_sodaDrinker` cases, modulo floating-point rounding.
- The only failing test in these files is `do_emp_tv`, which is blocked because bootstrapping/subsampling support.
- `eq-prob` is currently only imported as test facts and not implemented as a reusable function in `jsd/truth-values`; implementing it would improve validation and reduce reliance on static test facts.


