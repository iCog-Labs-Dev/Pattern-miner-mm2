# ISurp Modular Run Command

MORK loads one main input file and any number of auxiliary files into the same
Space. The CLI argument is repeatable:

```bash
mork run <main-file> --aux-path <extra-file-1> --aux-path <extra-file-2>
```

For the split ISurp implementation, use `src/common-utils/utils.metta` as the
main file and load the ISurp implementation modules with `--aux-path`.

## Runner-Based Tests

The ISurp tests are regular project runner tests. Run all modular ISurp tests:

```bash
scripts/run-tests.sh src/surp/tests/isurp/components/abstractness-sort-test.metta \
  src/surp/tests/isurp/components/eq-prob-test.metta \
  src/surp/tests/isurp/components/pro-prob-wout-joint-test.metta \
  src/surp/tests/isurp/components/ji-prob-est-test.metta \
  src/surp/tests/isurp/components/do-ji-prob-test.metta \
  src/surp/tests/isurp/components/emp-prob-pbs-test.metta \
  src/surp/tests/truth-values/emp/emp-tv-test.metta \
  src/surp/tests/truth-values/emp/block-tv-test.metta \
  src/surp/tests/truth-values/est/truth-value-defs-test.metta \
  src/surp/tests/truth-values/est/est-tv-pipeline-test.metta \
  src/surp/tests/isurp/isurp-validation-test.metta \
  src/surp/tests/isurp/isurp-coupled-validation-test.metta \
  src/surp/tests/isurp/isurp-true-nested-validation-test.metta \
  src/surp/tests/isurp/isurp-pipeline-test.metta
```

Or run one component test:

```bash
scripts/run-tests.sh src/surp/tests/isurp/components/eq-prob-test.metta
```

## Full ISurp Pipeline

Use this shape when the input DB file provides the full ISurp input contract:

```metta
(INPUT DB db)
(INPUT DB-SIZE <db-size>)
(INPUT NORMALIZATION TRUE)
(INPUT PATTERN (<comma-pattern> <support>))
```

Run:

```bash
mork run Pattern-miner-mm2/src/common-utils/utils.metta \
  --aux-path Pattern-miner-mm2/src/surp/surp.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/bootstrap-partitions.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/block-support.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/abstractness-sort.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/eq-prob.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/pro-prob-wout-joint.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/ji-prob-est.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/do-ji-prob.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/components/emp-prob-pbs.metta \
  --aux-path Pattern-miner-mm2/src/surp/isurp/isurp.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/truth-value-defs.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/beta-distribution.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/average-tv.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/emp/emp-tv.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/emp/block-tv.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/pro-tv-wout-joint.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/ji-tv-est.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/do-ji-tv-est.metta \
  --aux-path Pattern-miner-mm2/src/surp/truth-values/est/est-tv.metta \
  --aux-path path/to/your-isurp-input-db.metta
```

Each component test keeps its fixture data and expected facts in one runnable
file under `src/surp/tests/isurp/components/`. Full-pipeline and validation tests
remain directly under `src/surp/tests/isurp/`.

## Module Map

ISurp rules use readable tuple priorities:

```metta
(exec (surp <priority> <function-name>) $sources $sinks)
```

`surp` is the module namespace, `<priority>` is the middle field for
surprisingness, and it must start with `s` followed by exactly three decimal
digits, such as `s010`. `<function-name>` describes the rule.

| File                           | Purpose                                                                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `src/common-utils/utils.metta` | Shared reusable function-definition facts such as `count-db`, `prob`, `total-counts`, and `dst-from-interval`.                       |
| `bootstrap-partitions.metta`   | Starts the ISurp pipeline, indexes variables, generates partitions, and expands partitions into blocks.                              |
| `block-support.metta`          | Computes `block-support` facts for generated partition blocks.                                                                       |
| `abstractness-sort.metta`      | Selects the most abstract connected block for each joint variable using triplet-level syntactic scoring and deterministic fallbacks. |
| `eq-prob.metta`                | Detects shared variables across blocks and computes `eq-prob-of`.                                                                    |
| `pro-prob-wout-joint.metta`    | Computes `pro-prob-wout-joint` product probability before joint-variable correction.                                                 |
| `ji-prob-est.metta`            | Multiplies `pro-prob-wout-joint-of` by `eq-prob-of` to produce `ji-prob-est-of`.                                                     |
| `do-ji-prob.metta`             | Collects `ji-prob-est-of` facts into an ordered probability list for a requested partition list.                                     |
| `emp-prob-pbs.metta`           | Computes direct empirical probability for the input pattern.                                                                         |
| `isurp.metta`                | Connects the newer helper facts into `ji-prob-est-interval-of`, distance, and final `isurp-of`.                                      |

The legacy monolithic `src/isurp.metta` has been removed. Use the modular
command above so each shared utility and ISurp stage is loaded explicitly.
