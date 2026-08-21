# ISurp Modular Run Command

MORK loads one main input file and any number of auxiliary files into the same
Space.  The CLI argument is repeatable:

```bash
mork run <main-file> --aux-path <extra-file-1> --aux-path <extra-file-2>
```

For the split ISurp implementation, use `src/common-utils/utils.metta` as the
main file and load the ISurp implementation modules with `--aux-path`.

## Runner-Based Tests

The ISurp tests are regular project runner tests.  Run all modular ISurp tests:

```bash
scripts/run-tests.sh tests/isurp/abstractness-sort-test.metta \
  tests/isurp/eq-prob-test.metta \
  tests/isurp/pro-prob-wout-joint-test.metta \
  tests/isurp/ji-prob-est-test.metta \
  tests/isurp/do-ji-prob-test.metta \
  tests/isurp/emp-prob-pbs-test.metta \
  tests/isurp/isurp-validation-test.metta \
  tests/isurp/isurp-coupled-validation-test.metta \
  tests/isurp/isurp-true-nested-validation-test.metta \
  tests/isurp/isurp-pipeline-test.metta
```

Or run one component test:

```bash
scripts/run-tests.sh tests/isurp/eq-prob-test.metta
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
  --aux-path Pattern-miner-mm2/src/isurp-modules/input-bootstrap.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/bootstrap-partitions.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/block-support.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/abstractness-sort.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/eq-prob.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/pro-prob-wout-joint.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/ji-prob-est.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/do-ji-prob.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/emp-prob-pbs.metta \
  --aux-path Pattern-miner-mm2/src/isurp-modules/isurp-new.metta \
  --aux-path path/to/your-isurp-input-db.metta
```

Each component test keeps its fixture data and expected facts in one runnable
file under `tests/isurp/`.

## Module Map

ISurp stages use readable tuple priorities:

```metta
(exec (surp <priority> <function-name>) $sources $sinks)
```

`surp` is the module namespace, `<priority>` controls execution order, and
`<function-name>` describes the rule.

| File | Purpose |
| --- | --- |
| `src/common-utils/utils.metta` | Shared reusable function-definition facts such as `count-db`, `prob`, `total-counts`, and `dst-from-interval`. |
| `bootstrap-partitions.metta` | Starts the ISurp pipeline, indexes variables, generates partitions, and expands partitions into blocks. |
| `block-support.metta` | Computes `block-support` facts for generated partition blocks. |
| `abstractness-sort.metta` | Selects the most abstract connected block for each joint variable using triplet-level syntactic scoring and deterministic fallbacks. |
| `eq-prob.metta` | Detects shared variables across blocks and computes `eq-prob-of`. |
| `pro-prob-wout-joint.metta` | Computes `pro-prob-wout-joint` product probability before joint-variable correction. |
| `ji-prob-est.metta` | Multiplies `pro-prob-wout-joint-of` by `eq-prob-of` to produce `ji-prob-est-of`. |
| `do-ji-prob.metta` | Collects `ji-prob-est-of` facts into an ordered probability list for a requested partition list. |
| `emp-prob-pbs.metta` | Computes direct empirical probability for the input pattern. |
| `isurp-new.metta` | Connects the newer helper facts into `ji-prob-est-interval-of`, distance, and final `isurp-new-of`. |

The legacy monolithic `src/isurp.metta` has been removed.  Use the modular
command above so each shared utility and ISurp stage is loaded explicitly.
