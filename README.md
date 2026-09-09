# Hyperon Miner MM2

This repository is the MM2/MORK port of [`hyperon-miner`](https://github.com/iCog-Labs-Dev/hyperon-miner).
The goal is to port the full Hyperon Miner pipeline into MM2 programs that can
run in one MORK atomspace.

## Repository Layout

```text
docs/
  data-model.md              Shared MM2 data model and priority conventions
  isurp-old-validation.md    Validation notes against PeTTa isurp-old
  isurp-module-validation.md Modular newer ISurp implementation and validation
  testing.md                 Test file format and runner workflow

data/
  ugly-sodaDrinker.metta     Sample AtomSpace facts

src/
  common-utils/              Reusable MM2 callable definitions
  conjunction-expansion-triplet.metta
                             Standalone triplet conjunction expansion
  surp.metta                 Current MM2 implementation of isurp-old
  frequent-miner.metta       One-generation frequent candidate miner
  iterative-miner.metta      Recursive candidate generation and depth checks
  frequent-pattern-miner.metta
                             Integrated miner/expansion entry point
  dummy.metta                Scratch file

tests/
  frequent-miner/            Runnable frequent-miner test cases
  surp/                      Runnable surprisingness test cases

scripts/
  run-tests.sh               Test runner for *-test.metta files
  setup-mork-mm2-deps.sh     Wires MM2 helper and stdlib code into MORK

.github/workflows/
  tests.yml                  CI workflow for building MORK and running tests
```

## Dependencies

This project expects a MORK build with the local [`MM2-Helper`](https://github.com/iCog-Labs-Dev/MM2-Helper) extensions and
[`mm2-stdlib`](https://github.com/tezena/mm2-stdlib) helpers available.


## Running Tests

Run all test cases:

```sh
scripts/run-tests.sh
```

Run one test case:

```sh
scripts/run-tests.sh tests/frequent-miner/conjunction-expansion-test.metta
```

Use `MORK_BIN` when `mork` is not on `PATH`:

```sh
MORK_BIN=/path/to/mork scripts/run-tests.sh
```

Test files keep runner metadata in MM2 comments:

```metta
;; TEST-AUX data/ugly-sodaDrinker.metta
;; TEST-AUX src/surp.metta

(EXPECTED-RESULT test-id (...))
```

See `docs/testing.md` for the full test guide.

## Standalone Conjunction Expansion

The standalone expander accepts triplet seed patterns plus two configuration
facts:

```metta
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)
(INPUT SUPPORT-MODE cached)
(pattern 0 (Inheritance $x human))
```

`SUPPORT-MODE` is required by pipelines that count support through the shared
gate. Use `cached` for normal operation or `uncached` to benchmark the same
pipeline while forcing every support request to query the database.

`src/conjunction-expansion-triplet.metta` is independent of
`src/frequent-miner.metta`. Load `src/common-utils/utils.metta` alongside it.
Its public result is:

```metta
(expanded-conjunct size indexed-candidate support)
```

`src/frequent-miner.metta` contains variable extraction, positional lookup,
valuation, shallow abstraction, specialization, support filtering, and the
one-generation frequent-candidate driver.
See `docs/conjunction-expansion-walkthrough.md` for the expansion algorithm.

## Integrated Frequent Pattern Miner

Load the frequent miner, iterative miner, common utilities, conjunction
expansion, and integrated entry-point files into the same atomspace. Then issue:

```metta
(run-frequent-pattern-miner iter-smoke (Inheritance $a $b))
```

Specialize and run the public callable:

```metta
(exec (freq 001 call-frequent-pattern-miner)
  (, (run-frequent-pattern-miner iter-smoke (Inheritance $a $b))
     (DEF frequent-pattern-miner-fn $miner-p $miner-t))
  (O (+ (exec (freq 002 run-frequent-pattern-miner)
       $miner-p $miner-t))))
```

The orchestrator runs the iterative miner first and invokes conjunction
expansion at priority `999`, after candidate generation and cleanup. The
handoff uses this stable contract:

```metta
(iterative-candidate-pattern
  iter-smoke
  (Inheritance $a $b)
  (Inheritance (var 0) sodaDrinker)
  10)
```

Conjunction expansion uses the indexed candidate as a base and reuses `10` as
its singleton support. Support is counted normally for newly constructed
conjunctions. Source and dependency files remain caller-owned; tests load them
through `TEST-AUX` rather than imports inside the components.

The current private `ce-*` working state is not run-scoped, so invoke one
integrated run at a time in an atomspace.
