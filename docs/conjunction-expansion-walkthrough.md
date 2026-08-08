# Standalone Conjunction Expansion

`src/conjunction-expansion-triplet.metta` expands connected triplet patterns
without modifying or loading `src/frequent-miner.metta`. Its caller also loads
`src/common-utils/utils.metta`.

## Contract

Inputs:

```metta
(INPUT MIN-SUPPORT 2)
(INPUT MAX-SIZE 3)
(pattern 0 (Parent $x $y))
```

Database triplets are active facts in the same atomspace:

```metta
(Parent Alice Bob)
(Parent Bob Carol)
```

Output:

```metta
(expanded-conjunct 2
  ((Parent (var 0) (var 1))
   (Parent (var 1) (var 2)))
  4)
```

The output stores a canonical indexed conjunction, its size, and its support.
All `ce-*` facts are temporary and are consumed before execution finishes.

## Pipeline

```text
seed pattern
  -> indexed base and singleton candidate
  -> support count
  -> MIN-SUPPORT filter
  -> connected base variants
  -> union with the current conjunction
  -> canonicalize and measure
  -> growth and MAX-SIZE filter
  -> next support cycle
```

The implementation uses the project’s `(freq NNN label)` priority convention.
Small scheduler definitions are retained because MORK consumes an `exec` after
running it and large substituted rules can exceed its variable limit.

## Indexed Patterns

Seeds are converted with `vars_to_indices`:

```text
(Parent $x $y)
  -> (Parent (var 0) (var 1))
```

Indexed markers are durable data. Support counting temporarily converts the
candidate back to real variables so it can match active database facts.

## Support And Depth

The shared `count-indexed-conjunction-support` callable counts candidate
matches. `support-at-least` compares the result with `MIN-SUPPORT`.

A frequent candidate is expanded only when:

```text
current size < MAX-SIZE
```

A constructed candidate is queued only when:

```text
new size <= MAX-SIZE
new size > old size
```

The growth check rejects a union when the selected base was already present.

## Connected Variants

For a current conjunction containing `(var 0)` and `(var 1)`, the next fresh
choice is `(var 2)`. A generated base remains connected only when at least one
variable slot uses an existing choice.

The mapping cases are:

- repeated source variable: use one existing choice in both slots;
- distinct variables: left existing/right any, or left fresh/right existing;
- one variable and one constant: the variable must use an existing choice;
- two constants: no connected mapping is generated.

Disconnected variants are never created, so no later connectivity filter is
required.

## Canonicalization

The shared `canonicalize-indexed-conjunction` callable performs three staged
operations:

1. `sort-atom`;
2. `indices_to_vars`;
3. `vars_to_indices`.

They remain separate because quoted list results cannot safely be nested.
Alpha-equivalent candidates then become identical facts and deduplicate
naturally. The shared `conjunction-size` callable measures the result.

## Reused Rule Shapes

The expansion also specializes these common callables:

- `drop-matched` for cleanup;
- `replace-matched` for one-fact state transitions;
- `emit-from-matches-2/3/4` for join-and-emit rules.

## Test

`tests/frequent-miner/conjunction-expansion-test.metta` loads the existing
`data/ugly-sodaDrinker.metta` fixture, common utilities, and the standalone
source.

```sh
scripts/run-tests.sh tests/frequent-miner/conjunction-expansion-test.metta
```

The current component accepts triplet atoms. `MAX-SIZE` limits conjunct count,
not seed arity.
