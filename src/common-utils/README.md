# Common MM2 Utilities

`utils.metta` contains reusable rule templates shared by the pattern-miner
pipelines. It does not define a third module or own exec priorities. A caller
matches a template, chooses its output predicate, and schedules the returned
source and sink.

Load it from a test with:

```metta
;; TEST-AUX src/common-utils/utils.metta
```

## Functions

### `count-db`

```metta
((count-db $db-name -> $out) $source $sink)
```

Counts facts stored as `($db-name $fact)` and writes:

```metta
($out $db-name $count)
```

### `count-conjuncts`

```metta
((count-conjuncts $pattern -> $out) $source $sink)
```

Reads `(INPUT PATTERN ($pattern $support))`, removes the leading comma from the
conjunction, and writes its number of atoms as:

```metta
($out $pattern $count)
```

### `count-indexed-conjunction-support`

```metta
((count-indexed-conjunction-support $context $candidate $priority -> $out) $source $sink)
```

Consumes a `count-indexed-conjunction-support-request`, converts the indexed
candidate into a query, and schedules a count at the caller-provided
`$priority`. It writes:

```metta
($out $context $candidate $support)
```

### `support-at-least`

```metta
((support-at-least $context $support $threshold -> $out) $source $sink)
```

Consumes a `support-at-least-request`, compares integer-string support and
threshold values, and writes:

```metta
($out $context $support true-or-false)
```

### `drop-matched`

```metta
((drop-matched $fact -> removed) $source $sink)
```

Specialize `$fact` with any complete fact pattern and schedule the returned
source and sink at the stage where matching facts are safe to remove.

### `replace-matched`

```metta
((replace-matched $fact $replacement -> replaced) $source $sink)
```

Consumes a matched fact and emits the caller-provided replacement fact.

### `emit-from-matches-2/3/4`

```metta
((emit-from-matches-2 $first $second $result -> emitted) $source $sink)
((emit-from-matches-3 $first $second $third $result -> emitted) $source $sink)
((emit-from-matches-4 $first $second $third $fourth $result -> emitted) $source $sink)
```

Emit `$result` when all two, three, or four caller-provided fact patterns
match. These helpers are useful for symmetric join rules whose only action is
adding one derived fact.

### `canonicalize-indexed-conjunction`

```metta
((canonicalize-indexed-conjunction
    $fact $context $candidate $vars-priority $indices-priority -> $out)
  $source $sink)
```

Consumes `$fact`, sorts the indexed conjunction, converts its indices to
variables, then alpha-normalizes it back to contiguous indices. Schedule the
returned rule at the sort priority; the caller supplies the later two
priorities. It writes:

```metta
($out $context $canonical-candidate)
```

### `conjunction-size`

```metta
((conjunction-size $fact $context $conjunction -> $out) $source $sink)
```

Consumes `$fact` and writes:

```metta
($out $context $conjunction $size)
```

### `total-counts`

```metta
((total-counts $db $pattern -> $out) $source $sink)
```

Reads `INPUT DB-SIZE` and a previously produced `num-of-conjuncts` fact. It
computes the binomial count:

```text
C(n, k) = falling_factorial(n, k) / factorial(k)
```

and writes `(total-count-of $pattern $total)`.

### `prob`

```metta
((prob $pattern $db -> $out) $source $sink)
```

Divides the support from `INPUT PATTERN` by `total-count-of` and writes:

```metta
($out $pattern $probability)
```

### `dst-from-interval`

```metta
((dst-from-interval $pattern $emin $emax $emp -> $out) $source $sink)
```

Consumes a `dst-request` and classifies the empirical value relative to the
closed interval `[emin, emax]`. It writes the three boolean branch facts used
by `surp.metta`:

```metta
(dst-above? ... true-or-false)
(dst-below? ... true-or-false)
(dst-inside? ... true-or-false)
```

## Dependencies

These utilities expect MORK to register:

- `mm2-stdlib` for list operations, numeric conversion, comparison, division,
  and boolean helpers;
- MM2-Helper for `factorial` and `falling_factorial`.

The current regression example is `tests/surp/isurp-old-test.metta`, which
loads this file through `TEST-AUX` before loading `src/surp.metta`.
