# Standalone Expansion Definition Map

This is a compact map of the facts transformed by
`src/conjunction-expansion-triplet.metta`. Generic operations come from
`src/common-utils/utils.metta`.

## Support Cycle

```text
ce-pending
  -> ce-support
  -> ce-support-pass
  -> expanded-conjunct + ce-expand-check
```

- `ce-support-fn` starts one candidate cycle.
- `count-indexed-conjunction-support` produces the support.
- `support-at-least` applies `MIN-SUPPORT`.
- `ce-save-pass-fn` emits the public result and requests expansion.

## Expansion Decision

```text
ce-expand-check
  -> ce-expand-pass
  -> ce-expand-todo
```

`ce-expand-pass-fn` checks `size < MAX-SIZE`. The passing state is promoted
with `replace-matched`; the failed state is removed with `drop-matched`.

## Pair And Scan

```text
ce-expand-todo + ce-base
  -> ce-expand-pair
  -> ce-scan
  -> ce-conjunct-atom
  -> ce-var-choice ... existing
```

- `emit-from-matches-2` pairs each conjunction with every base.
- `ce-pair-details-fn` starts the cursor and base-shape classification.
- `ce-scan-fn` walks every conjunct.
- left and right variable choices use specialized `emit-from-matches-2`
  callables.

## Fresh Choice

```text
existing v0 -> propose v1 -> remove because existing
existing v1 -> propose v2 -> save as fresh
```

- `ce-fresh-candidate-fn` proposes successors.
- `ce-drop-used-fresh-fn` removes already-used successors.
- `replace-matched` promotes the remaining successor to a fresh choice.
- `ce-source-relation-fn` preserves repeated-variable equality.

## Connected Mapping

`emit-from-matches-3/4` produces `ce-connected-base` facts for:

| Case | Accepted assignment |
| --- | --- |
| repeated source | one existing output in both slots |
| distinct sources, left branch | left existing; right existing or fresh |
| distinct sources, right branch | left fresh; right existing |
| variable plus constant | variable existing; constant unchanged |

An all-fresh assignment is not generated.

## Candidate Route

```text
ce-connected-base
  -> ce-raw-candidate
  -> ce-candidate
  -> ce-candidate-size
  -> ce-candidate-pass
  -> ce-pending
```

- `ce-build-candidate-fn` unions the base and current conjunction.
- `canonicalize-indexed-conjunction` sorts and alpha-normalizes it.
- `conjunction-size` measures it.
- `ce-candidate-pass-fn` checks growth and `MAX-SIZE`.
- `ce-queue-candidate-fn` starts the next support cycle.

## Shared Callables

| Repeated rule shape | Utility |
| --- | --- |
| count indexed support | `count-indexed-conjunction-support` |
| compare support and threshold | `support-at-least` |
| match and remove | `drop-matched` |
| replace one fact | `replace-matched` |
| join facts and emit one fact | `emit-from-matches-2/3/4` |
| canonicalize an indexed conjunction | `canonicalize-indexed-conjunction` |
| measure a conjunction | `conjunction-size` |

Temporary `ce-*`, cleanup-wrapper, request, and canonicalization facts are
consumed before the run finishes.
