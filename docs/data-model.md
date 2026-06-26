# Pattern Miner MM2 Data Model

This document defines the shared data conventions for the MM2 Pattern Miner implementation. It covers both the frequent-miner pipeline and the surprisingness-scoring pipeline.

The goal is to make facts, intermediate values, final results, function definitions, dummy/debug data, and identifiers predictable across the project.

## Core Model

MM2 programs are data-space programs.

Everything is stored as facts in the same space:

```metta
(Inheritance Allen man)
(INPUT DB db)
(exec 0 $sources $sinks)
((count-conjuncts $pattern -> num-of-conjuncts) $src $sink)
```

An `exec` is also a fact. During execution, MORK selects an `exec`, removes it, matches its sources against the current space, then writes its sinks.

Because of this, every data model should answer three questions:

- What facts does this stage consume?
- What facts does this stage produce?
- Which produced facts are final, and which are temporary?

## Fact Categories

Use explicit predicates to make each fact type clear.

| Category | Purpose | Example |
| --- | --- | --- |
| Input facts | User-provided configuration | `(INPUT DB db)` |
| Database facts | Facts being mined | `(Inheritance Allen man)` |
| Function definitions | Reusable pipeline definitions | `((count-conjuncts ... -> ...) $src $sink)` |
| Intermediate facts | Temporary pipeline state | `(block-support $partition $block $support)` |
| Final results | Intended output | `(surprisingness-of $pattern $score)` |
| Debug facts | Temporary inspection facts | `(DEBUG stage value)` |
| Dummy facts | Development-only facts | `(DUMMY ...)` |

Intermediate and debug facts should not be confused with final output. If they are not intentionally preserved, cleanup execs should remove them.

## Database Model

### Recommended Two-Layer DB Model

For support counting and conjunction matching, raw database facts are the easiest representation:

```metta
(Inheritance Allen sodaDrinker)
(Inheritance Lily sodaDrinker)
(Inheritance Cason sodaDrinker)

(Inheritance Lily ugly)
(Inheritance Allen ugly)
(Inheritance Abe ugly)

(Inheritance Lily man)
(Inheritance Allen man)
(Inheritance Cason man)
```

This allows patterns like this to match directly:

```metta
(, (Inheritance $x sodaDrinker)
   (Inheritance $x ugly)
   (Inheritance $x man))
```

However, raw facts do not carry DB ownership. If multiple DBs are needed, use a stored DB layer plus an active matching layer.

Stored DB facts:

```metta
(db-fact db (Inheritance Allen sodaDrinker))
(db-fact db (Inheritance Lily ugly))
(db-fact db (Inheritance Allen man))
```

Active matching facts:

```metta
(Inheritance Allen sodaDrinker)
(Inheritance Lily ugly)
(Inheritance Allen man)
```

The stored layer keeps ownership. The active layer keeps support counting simple.

### Why Not Only Use Wrapped DB Facts?

This shape is clean:

```metta
(DB db (Inheritance Allen man))
```

But it makes conjunction matching harder. A normal pattern like this:

```metta
(, (Inheritance $x man)
   (Inheritance $x ugly))
```

will not directly match wrapped facts. It would need to be rewritten into this shape:

```metta
(, (DB db (Inheritance $x man))
   (DB db (Inheritance $x ugly)))
```

That rewrite is possible, but it adds complexity to every support-counting path.

Project convention:

- Use raw active facts for the currently selected DB.
- Use `db-fact` only when DB ownership or multiple DBs matter.
- Do not use `(DB db <fact>)` directly for support counting unless the pattern is also rewritten into DB-wrapped conjuncts.

## Input Facts

Use `INPUT` facts for user-controlled configuration.

```metta
(INPUT DB db)
(INPUT PATTERN ((, (Inheritance $a sodaDrinker)
                   (Inheritance $a ugly)
                   (Inheritance $a man)) 4))
(INPUT NORMALIZATION TRUE)
```

Recommended input predicates:

| Fact | Meaning |
| --- | --- |
| `(INPUT DB $db)` | Selected database identifier |
| `(INPUT PATTERN ($pattern $support))` | Pattern and known support |
| `(INPUT NORMALIZATION TRUE)` | Return normalized surprisingness |
| `(INPUT NORMALIZATION FALSE)` | Return raw surprisingness distance |
| `(INPUT MIN-SUPPORT $n)` | Frequent-miner minimum support, if used |

## Pattern Model

A pattern should be represented as a conjunction using comma:

```metta
(, (Inheritance $a sodaDrinker)
   (Inheritance $a ugly)
   (Inheritance $a man))
```

A single atom pattern may be represented directly:

```metta
(Inheritance $a man)
```

When a function expects a conjunctive pattern, it should explicitly handle whether the input is:

- a comma conjunction
- a single atom
- a tuple/list of atoms produced by helper functions

Recommended normalized pattern fact:

```metta
(pattern $pattern-id $pattern)
```

Example:

```metta
(pattern p1 (, (Inheritance $a sodaDrinker)
               (Inheritance $a ugly)
               (Inheritance $a man)))
```

If the structural pattern itself is already used as the identifier, avoid introducing another ID unless a later stage requires stable names.

## Identifier Naming

Use stable and readable identifiers.

Recommended forms:

```metta
(DB db)
(pattern p1 $pattern)
(partition-id p1 part-1)
(block-id part-1 block-1)
```

Guidelines:

- DB identifiers should be lowercase or hyphenated: `db`, `sample-db`, `db1`.
- Pattern identifiers should use `p1`, `p2`, or `pattern-1`.
- Partition identifiers should include the pattern ID if they are persisted.
- Block identifiers should include the partition ID if they are persisted.
- Temporary identifiers should be scoped by stage when possible.

Avoid ambiguous identifiers like:

```metta
(id x)
(temp a)
(result r)
```

Prefer:

```metta
(pattern-id p1)
(block-temp p1 part-1 block-1)
```

## Function Definition Model

There are two useful function styles in this project.

### Public Pipeline Functions

Public pipeline functions should use this callable shape:

```metta
((function-name $arg1 $arg2 -> output-predicate) $src $sink)
```

Example:

```metta
((count-conjuncts $pattern -> num-of-conjuncts) $src $sink)
```

A caller can specialize it by matching the definition and spawning the returned exec:

```metta
(exec 0
    (, ((count-conjuncts $pattern -> num-of-conjuncts) $src $sink))
    (O
        (+ (exec 0 $src $sink))))
```

Use this style when the function is part of the pipeline API.

Recommended public functions:

```metta
((count-db $db -> db-size) $src $sink)
((count-conjuncts $pattern -> num-of-conjuncts) $src $sink)
((total-counts $db $pattern -> total-count-of) $src $sink)
((prob $pattern $db -> prob-of) $src $sink)
((dst-from-interval $emin $emax $emp -> dst-value) $src $sink)
((compute-support $pattern -> support-of) $src $sink)
```

### Internal Reusable Definitions

Use `DEF` for internal reusable rule bodies, recursive walkers, helper expansion, or macro-like code.

Example:

```metta
(DEF gv-expand
  (, (gv-visit $id $path $node))
  (O
    ...))
```

Use `DEF` when another rule needs to reuse a source/sink body internally.

Do not use active examples inside library files:

```metta
; Avoid this in library files.
(get-vars-for-tree sample (Inheritance $x $y))
(exec 0 ...)
```

If examples are needed, put them in a test file.

### Function Convention

Project convention:

- Use callable `((name args -> out) $src $sink)` definitions for public pipeline functions.
- Use `DEF` for private/internal reusable logic.
- Do not mix both styles for the same function unless there is a clear wrapper.
- Keep function names lowercase and hyphenated.



### Support Count

Use one final support fact per pattern:

```metta
(support-of $pattern $support)
```

or, when a stable ID exists:

```metta
(pattern-support $pattern-id $support)
```

Recommended convention:

```metta
(support-of $pattern $support)
```

because it can be reused by surprisingness blocks without requiring an ID.

### Frequent Pattern Result

```metta
(frequent-pattern $pattern $support)
```

or:

```metta
(frequent-pattern $pattern-id $pattern $support)
```

If the pipeline has stable IDs, prefer the second form.



### Final Surprisingness

Use this spelling consistently:

```metta
(surprisingness-of $pattern $value)
```

Avoid the misspelled form:

```metta
(surprisingess-of $pattern $value)
```

Normalized mode:

```metta
(INPUT NORMALIZATION TRUE)
(surprisingness-of $pattern $normalized-value)
```

Raw mode:

```metta
(INPUT NORMALIZATION FALSE)
(surprisingness-of $pattern $distance)
```

## Intermediate Facts To Keep

These facts are useful for inspection and should normally remain after a successful surprisingness run:

```metta
(db-size $db $size)
(num-of-conjuncts $pattern $n)
(total-count-of $pattern $total)
(prob-of $pattern $probability)
(partitions-of $pattern $partitions)
(surprisingness-of $pattern $value)
```

If the frequent miner is running, these may also remain:

```metta
(candidate-pattern $pattern-id $pattern)
(support-of $pattern $support)
(frequent-pattern $pattern-id $pattern $support)
```

## Intermediate Facts To Clean

These facts are temporary and should usually be removed before final output:

```metta
(copy-of-partition $partition $remaining)
(block $partition $block)
(block-of-partition $partition $block)
(block-support $partition $block $support)
(block-probability $partition $block $probability)
(partition-product $partition $value)
(dst-request $emin $emax $emp $out)
(dst-above? $emin $emax $emp $out $flag)
(dst-below? $emin $emax $emp $out $flag)
(dst-inside? $emin $emax $emp $out $flag)
(gv-visit $id $path $node)
(gv-var-check $id $path $node $is-var)
```

Cleanup should be explicit. Do not assume temporary facts disappear automatically.

## Dummy And Debug Facts

Use `DEBUG` for temporary inspection facts:

```metta
(DEBUG stage-name $value)
(DEBUG block-support $block $support)
```

Use `DUMMY` only for local experiments:

```metta
(DUMMY example $value)
```

Project convention:

- `DEBUG` facts may exist during development but should be removed or gated before merging.
- `DUMMY` facts should not be committed in production pipeline files.
- Example inputs should live in test files, not library files.

## Naming Conventions

Use lowercase hyphenated names for predicates:

```metta
block-support
partition-product
num-of-conjuncts
```

Avoid mixed styles:

```metta
blockSupport
BlockSupport
block_support
```

Use `-of` when the fact is a computed value about an object:

```metta
(prob-of $pattern $probability)
(support-of $pattern $support)
(total-count-of $pattern $total)
```

Use plural names when the value is a collection:

```metta
(partitions-of $pattern $partitions)
```

Use `copy-of-*` only for temporary recursion state:

```metta
(copy-of-partition $partition $remaining)
```

## Complete Mini Example

Input:

```metta
(INPUT DB db)
(INPUT PATTERN ((, (Inheritance $a sodaDrinker)
                   (Inheritance $a ugly)
                   (Inheritance $a man)) 4))
(INPUT NORMALIZATION TRUE)
```

Core derived facts:

```metta
(db-size db 60)
(num-of-conjuncts (, (Inheritance $a sodaDrinker)
                     (Inheritance $a ugly)
                     (Inheritance $a man)) 3)
(total-count-of (, (Inheritance $a sodaDrinker)
                   (Inheritance $a ugly)
                   (Inheritance $a man)) 34220)
(prob-of (, (Inheritance $a sodaDrinker)
            (Inheritance $a ugly)
            (Inheritance $a man)) 0.00011689070718877849)
```

Partition facts:

```metta
(partitions-of $pattern $partitions)
(block-of-partition $partition $block)
(block-support $partition $block $support)
(block-probability $partition $block $probability)
(partition-product $partition $product)
(partition-product-range $emin $emax)
```

Final result:

```metta
(surprisingness-of (, (Inheritance $a sodaDrinker)
                     (Inheritance $a ugly)
                     (Inheritance $a man)) 0.00014607068574401354)
```

## Anti-Patterns

Avoid unpredicated intermediate values:

```metta
$value
($pattern $support)
```

Prefer explicit facts:

```metta
(support-of $pattern $support)
```

Avoid active examples inside reusable files:

```metta
(get-vars-for-tree sample ...)
(exec 0 ...)
```

Avoid relying on textual order. MM2 execution order is controlled by `exec` priority and the facts currently in the space.

Avoid keeping cleanup too implicit. If a fact must disappear, add a cleanup rule and verify it actually matches.

Avoid mixing final outputs and temporary pipeline state under the same predicate.

## Open Decisions

These should be finalized as the implementation matures:

- Whether the frequent miner should always assign stable pattern IDs.
- Whether raw DB facts should always be generated from `db-fact` before support counting.
- Whether final frequent-miner results should be keyed by pattern ID, structural pattern, or both.
- Whether validation facts should live in source files or separate test files.
- Whether partition IDs should be introduced or structural partition values are enough.
