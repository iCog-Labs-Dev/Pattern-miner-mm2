# isurp-old validation against PeTTa

This document records validation of the MM2 `surp.metta` implementation against the PeTTa `isurp-old` tests in:

```text
/Users/tewodrosnibret/Documents/icog/hyperon-miner/experiments/surprisingness/tests/test-isurp-old.metta
```

The MM2 implementation under test is:

```text
/Users/tewodrosnibret/Documents/icog/hyperon-miner-mm2/src/surp.metta
```

Validation was run by generating temporary MM2 files under `/tmp` with:

- the same PeTTa test pattern
- the same dataset atoms
- `INPUT DB-SIZE` set to the number of atoms in the PeTTa dataset
- `INPUT PATTERN` support computed with MORK count before running `surp.metta`
- `INPUT NORMALIZATION TRUE/FALSE` set to match the PeTTa test

## Results

| Case | PeTTa expected | MM2 result | Status | Notes |
|---|---:|---:|---|---|
| `ugly_man_sodaDrinker`, normalization `False` | `0.00014607068574401354` | `0.00014607068574401343` | Pass | Difference is floating-point precision only. |
| `ugly_man_sodaDrinker`, normalization `True` | `0.999707773232028` | `0.999707773232028` | Pass | Matches PeTTa after denominator and normalization fixes. |
| `mock_coupled`, normalization `True` | `0.999707773232028` | `0.999707773232028` | Pass | Coupled `(Person $x)` pattern works. |
| `true_nested`, normalization `True` | `0.9996837944664032` | no final result | Blocked | Current MM2 product/range stage is hard-coded for 3 conjuncts. This PeTTa case has 4 conjuncts. |
| `dataset_for_n_arry_format`, Loves pattern, normalization `True` | `0.9886039886039886` | no final result | Blocked | N-ary raw support queries work, but the current generated block-support/product pipeline does not produce all required block products. |
| `dataset_for_n_arry_format`, Slice pattern, normalization `True` | `0.9981684981684982` | no final result | Blocked | Same N-ary block-support/product pipeline gap. |
| `dataset_for_n_arry_format`, Loves pattern, normalization `False` | `0.0036212600315164425` | no final result | Blocked | Same N-ary block-support/product pipeline gap. |
| `dataset_for_n_arry_format`, Slice pattern, normalization `False` | `0.0018281474325430374` | no final result | Blocked | Same N-ary block-support/product pipeline gap. |

## Confirmed fixes

Two formula differences were found and fixed before this validation:

1. `INPUT DB-SIZE` must match PeTTa `db_size`.

For `ugly_man_sodaDrinker`, PeTTa imports 60 atoms, so MM2 must use:

```lisp
(INPUT DB-SIZE 60)
```

2. `block-prob` must divide block support by the full pattern total count, not by DB size.

PeTTa `isurp-old` uses:

```lisp
(= (prob $pattern $db $total_count)
   (// (sup-num $db $pattern) $total_count))
```

and `blk-prob` passes the same `$total_count` into `prob`.

So MM2 must compute:

```text
block-prob = block-support / total-count-of(full-pattern)
```

not:

```text
block-prob = block-support / db-size
```

3. Normalized mode must match PeTTa:

```lisp
min (dst / max(emax, pattern_prob), 1.0)
```

The MM2 implementation now stages this as:

- `normalization-denom`
- `normalization-candidate`
- final capped `surprisingess-of`

## Current blockers

### 1. Four-conjunct nested pattern

The PeTTa nested test has 4 conjuncts. The current MM2 implementation has a 3-conjunct-specific min/max rule:

```lisp
(exec 9
    (, (indexed-pattern ($c1 $c2 $c3))
       ...)
    ...)
```

This means the pipeline can generate partitions and block supports for 4-conjunct patterns, but it cannot aggregate partition products into a final interval.

To support this test, MM2 needs a generic partition-product collection and min/max stage, or explicit 4-conjunct rules.

### 2. N-ary pattern block products

Direct support-count probes for N-ary facts work. For example:

```lisp
(Inheritance $x $Interest $Venue)
(, (Inheritance $x $Interest $Venue)
   (Inheritance $y $Interest $Venue))
```

produce counts in isolation.

However, the current MM2 `surp.metta` pipeline does not produce all required `block-support`, `block-prob`, and `partition-product` facts for the N-ary PeTTa cases. This blocks final `partition-product-range` and therefore final `surprisingess-of`.

The likely next area to inspect is the dynamic support query generated in `exec 6`:

```lisp
(indices_to_vars
    (cons , (' $indexed-block)))
```

especially for blocks whose atoms contain several variables and few or no constants.

## Summary

The MM2 implementation now matches PeTTa `isurp-old` for the simple 3-conjunct pattern and the coupled 3-conjunct pattern.

Remaining work is not the `isurp-old` formula itself. The remaining gaps are generality gaps in the MM2 pipeline:

- generic handling for 4 or more conjuncts
- reliable generated block-support/product handling for N-ary patterns
