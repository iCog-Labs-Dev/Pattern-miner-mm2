# Pattern Miner MM2 Data Model

This document defines the shared data conventions for the MM2 Pattern Miner implementation. It covers both the frequent-miner pipeline and the surprisingness-scoring pipeline.

The goal is to make facts, intermediate values, final results, function definitions, dummy/debug data, and identifiers predictable across the project.

## Core Model

MM2 programs are data-space programs.

Everything is stored as facts in the same space:

```metta
(Inheritance Allen man)
(INPUT DB db)
(exec (freq 010 example) $sources $sinks)
((count-conjuncts $pattern -> num-of-conjuncts) $src $sink)
```

An `exec` is also a fact. During execution, MORK selects an `exec`, removes it, matches its sources against the current space, then writes its sinks.

Because of this, every data model should answer three questions:

- What facts does this stage consume?
- What facts does this stage produce?
- Which produced facts are final, and which are temporary?

## Exec Priority Convention

All project `exec` priorities must use a fixed three-field tuple:

```metta
(exec ($module $stage $label)
    $sources
    $sinks)
```

The fields are:

| Field | Purpose | Example |
| --- | --- | --- |
| `$module` | One of the two project modules that owns the rule | `surp`, `freq` |
| `$stage` | Primary ordering key inside the module; exactly three decimal digits | `010`, `020`, `100`, `900` |
| `$label` | Human-readable stage name | `init`, `index-pattern`, `cleanup` |

Example:

```metta
(exec (freq 010 normalize-seeds) ...)
(exec (freq 110 count-support) ...)
(exec (freq 900 cleanup-bases) ...)
(exec (surp 010 init) ...)
(exec (surp 020 index-pattern) ...)
(exec (surp 090 product-2) ...)
(exec (surp 091 product-3) ...)
(exec (surp 100 interval) ...)
(exec (surp 900 cleanup) ...)
```

The project has exactly two module namespaces:

- `freq` owns frequent mining, including connected conjunction expansion.
- `surp` owns surprisingness scoring.

`src/conjunction-expansion-triplet.metta` is a standalone development
component, not a third module namespace. It therefore follows the `freq`
priority convention while keeping its temporary facts under the `ce-` prefix.

Helpers, cleanup, tracing, and debugging remain stages inside their owning
module. They do not introduce `shared`, `debug`, `conj-exp`, or similar module
names.

Do not use bare natural priorities in project code:

```metta
;; Avoid
(exec 10 ...)
(exec 20 ...)
```

The `$stage` field must be exactly `three decimal digits`, from `000` through `999`. Use leading zeros when needed. MORK does not treat this field as an arithmetic integer; it orders priority expressions by their encoded path/symbol order. A fixed width of 3 makes that ordering match the numeric order we intend:

```text
010 < 020 < 090 < 100 < 900
```

Avoid mixed-width stages:

```metta
;; Avoid
(exec (surp 9 product-2) ...)
(exec (surp 90 product-2) ...)
(exec (surp 100 interval) ...)
```

The `$label` field is for readability. It can affect ordering only when `$module` and `$stage` are identical, so never rely on the label for important sequencing. If two rules must run in a specific order, give them different stage numbers:

```metta
;; Good
(exec (surp 090 product-2) ...)
(exec (surp 091 product-3) ...)

;; Avoid when ordering matters
(exec (surp 090 product-2) ...)
(exec (surp 090 product-3) ...)
```


## Fact Categories

Use explicit predicates to make each fact type clear.

| Category | Purpose | Example |
| --- | --- | --- |
| Input facts | User-provided configuration | `(INPUT DB db)` |
| Database facts | Facts being mined | `(Inheritance Allen man)` |
| Function definitions | Reusable pipeline definitions | `((count-conjuncts ... -> ...) $src $sink)` |
| Intermediate facts | Temporary pipeline state | `(block-support $partition $block $support)` |
| Final results | Intended output | `(frequent-pattern $pattern $support)`, `(expanded-conjunct $size $candidate $support)`, `(surprisingness-of $pattern $score)` |
| Debug facts | Temporary inspection facts | `(DEBUG stage value)` |
| Dummy facts | Development-only facts | `(DUMMY ...)` |

Intermediate and debug facts should not be confused with final output. If they are not intentionally preserved, cleanup execs should remove them.

## Database Model

### Fact Row Representation

For support counting and conjunction matching, raw database facts are the easiest active representation:

```metta
($link $concept-1 $concept-2)
```

Example:

```metta
(Inheritance Allen sodaDrinker)
```

This allows patterns like this to match directly:

```metta
(, (Inheritance $x sodaDrinker)
   (Inheritance $x ugly)
   (Inheritance $x man))
```

If the program uses only one knowledge base, raw facts may be loaded directly.

If the program uses more than one knowledge base, store facts with a DB predicate and materialize only the selected DB into raw active facts before support-counting stages run.

Stored DB facts:

```metta
(db-fact db1 (Inheritance Allen sodaDrinker))

(db-fact db2 (Inheritance Cason sodaDrinker))
```

Selected DB input:

```metta
(INPUT DB db1)
```

Early materialization step:

```metta
(exec (freq 010 materialize-db)
    (, (INPUT DB $db) (db-fact $db $fact))
    (O
        (+ $fact)))
```

After this step, downstream support-counting rules can match raw facts normally:

```metta
(, (Inheritance $x sodaDrinker)
   (Inheritance $x ugly)
   (Inheritance $x man))
```

Project convention:

- For a single knowledge base, raw facts are acceptable.
- For multiple knowledge bases, store facts as `(db-fact $db $fact)`.
- Do not keep permanent duplicate facts with and without the DB predicate.
- Use an early exec to extract facts from the selected DB into the active atomspace.
- Run support counting, pattern mining, and surprisingness scoring over the active raw facts.



## Input Facts

Use `INPUT` facts for miner configuration inputs.

```metta
(INPUT DB db)
(INPUT PATTERN ((, (Inheritance $a sodaDrinker)
                   (Inheritance $a ugly)
                   (Inheritance $a man)) 4))
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 3)
(INPUT MAX-SIZE 3)
```


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

## Naming Convention

Use consistent naming so facts can be scanned and debugged easily.

- For hyperparameters and configuration input values, use full capital letters.

```metta
(INPUT NORMALIZATION TRUE)
(INPUT MIN-SUPPORT 3)
```

- For variable names and function identifiers, use kebab-case.

```metta
(count-db $db-name -> $out)
(num-of-conjuncts $pattern-id $count)
```

- For intermediate values, also use kebab-case. If the intermediate value may not be unique by itself, include its immediate parent pattern or parent object as an identifier.

```metta
(block-support $pattern $block $support)
(partition-product $pattern $partition $value)
```

## Function Definitions

We use two function definition styles in this project.

### Common Functions

Globally common functions should use this callable shape:

```metta
((function-name $arg1 $arg2 -> output-predicate) $src $sink)
```

Example:

```metta
((count-conjuncts $pattern -> num-of-conjuncts) $src $sink)
```

Project-wide callable definitions live in `src/common-utils/utils.metta`.
Current examples include support counting and filtering, matched-fact
drop/replacement, joined fact emission, indexed-conjunction canonicalization,
and conjunction sizing.

A caller can specialize it by matching the definition and spawning the returned exec:

```metta
(exec (freq 020 call-count-conjuncts)
    (, ((count-conjuncts $pattern -> num-of-conjuncts) $src $sink))
    (O
        (+ (exec (freq 030 count-conjuncts) $src $sink))))
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
