# Local optimized versus server baseline — 2026-10-03

This is the canonical benchmark report. It compares the local optimized
production miner with the server baseline measurements recorded on `test-data`
commit `3150eaf` at
`snet-research-cpu-epyc9654-3tb-node-04`.

The local runs used the rebuilt optimized MORK binary and the same benchmark
harness, with three repetitions unless noted. Percentage improvement is
`(server - local) / server * 100`; a negative value means the local run was
slower. Wall time and RSS are medians across repetitions.

The initial local raw artifacts are under `/tmp/mm2-local-20261003/`; they
predate candidate-variable normalization and contain incorrect conjunction
counts for the affected prefix workloads. The corrected rerun artifacts are
under `/tmp/mm2-fixed-{edges10k-s2,edges10k-s3,edges100k-s2,freq-regulates-s2,galaxy-feeds-s2}/`.
The server raw artifacts are under `/tmp/baseline-test-data-3150eaf-*` on the server.
The earlier session notes were consolidated into this file; this is the only
benchmark report to maintain.

## Results

| Workload | Stage | Server wall | Local wall | Time improvement | Server RSS | Local RSS | RSS improvement | Server output | Local output |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| edges 10K, `regulates`, s=100, k=2 | candidates | 62.43s | 7.41s | **88.1%** | 272,248 KiB | 16,496 KiB | **93.9%** | 9 | 9 |
| edges 10K, `regulates`, s=100, k=2 | full | 62.98s | 9.51s | **84.9%** | 272,248 KiB | 16,284 KiB | **94.0%** | 6 conjuncts | 6 conjuncts |
| edges 10K, `regulates`, s=100, k=3 | candidates | 64.89s | 9.31s | **85.7%** | 273,356 KiB | 16,484 KiB | **94.0%** | 9 | 9 |
| edges 10K, `regulates`, s=100, k=3 | full | 65.89s | 21.12s | **67.9%** | 266,880 KiB | 16,752 KiB | **93.7%** | 20 conjuncts | 20 conjuncts |
| edges 100K, `regulates`, s=100, k=2 | candidates | 780.78s | 112.81s | **85.6%** | 3,331,040 KiB | 110,972 KiB | **96.7%** | 73 | 73 |
| edges 100K, `regulates`, s=100, k=2 | full | 826.92s | 125.85s | **84.8%** | 3,336,444 KiB | 120,708 KiB | **96.4%** | 77 conjuncts | 77 conjuncts |
| Galaxy, `FEEDS_INTO`, s=10, k=2 | candidates | 169.95s | 4.20s | **97.5%** | 1,901,568 KiB | 18,024 KiB | **99.1%** | 3 | 3 |
| Galaxy, `FEEDS_INTO`, s=10, k=2 | full | 177.02s | 7.51s | **95.8%** | 1,901,568 KiB | 19,412 KiB | **99.0%** | 10 conjuncts | 10 conjuncts |
| Galaxy, `FEEDS_INTO`, s=5, k=3 | candidates | 169.85s | 9.81s | **94.2%** | 1,901,568 KiB | 49,164 KiB | **97.4%** | 43 | 43 |
| Galaxy, `FEEDS_INTO`, s=5, k=3 | full | 298.76s | 428.17s | **−43.3%** | 1,901,568 KiB | 88,432 KiB | **95.4%** | 386 conjuncts | 386 conjuncts |
| FREQ 10K, `regulates`, s=100, k=2 | candidates | 63.25s | 8.21s | **87.0%** | 270,612 KiB | 16,204 KiB | **94.0%** | 9 | 9 |
| FREQ 10K, `regulates`, s=100, k=2 | full | 63.70s | 9.81s | **84.6%** | 270,612 KiB | 16,520 KiB | **93.9%** | 6 conjuncts | 6 conjuncts |
| FREQ 10K, `database`, s=100, k=2 | candidates | — | 64.26s | — | — | 59,664 KiB | — | — | 123 |
| FREQ 10K, `database`, s=100, k=2 | full | — | 100.71s | — | — | 59,992 KiB | — | — | 22 conjuncts |
| Ugly Soda 10K, `Inheritance`, s=100, k=2 | candidates | 7.88s | 10.72s | **−36.0%** | 36,864 KiB | 32,060 KiB | **13.0%** | 6 | 17 |
| Ugly Soda 10K, `Inheritance`, s=100, k=2 | full | 41.87s | 54.47s | **−30.1%** | 36,864 KiB | 32,804 KiB | **11.0%** | 16 conjuncts | 59 conjuncts |

The corrected Galaxy `FEEDS_INTO`, support 5, max-size 3 run completed three
times locally: median candidate time 9.81s and median full time 428.17s. Both
stages produced the same 43 candidates and 386 conjunctions as the server.

## Reading the comparison

- The largest directly matching result is Galaxy size 2: about 96–98% lower
  wall time and about 99% lower peak RSS locally, with identical output counts.
- The 10K and 100K edge runs now have identical candidate and conjunction
  counts, with 84–88% lower wall time and about 94–97% lower RSS locally.
- FREQ `regulates` also now has identical output counts, with 85–87% lower
  wall time and about 94% lower RSS locally.
- Ugly Soda is not a valid apples-to-apples result yet. The server fixture
  produced 6 candidates / 16 conjunctions, while the local 10K fixture copied
  from `../newminer/data` produced 17 / 59. The local checked-in
  `data/ugly-sodaDrinker.metta` is a small fixture and produced no matches at
  support 100, so it was not used for this comparison. The server fixture and
  local 10K file have different SHA-256 hashes.

## Important limitations

The server and local machines, MORK builds, and some fixture files differ.
Therefore these are directional performance comparisons, not controlled
hardware benchmarks. For a formal optimization claim, run both the baseline
and optimized commits on the same host, with the same MORK binary, dataset,
parameters, and expected public records.

## Earlier local lookup comparison

For context, on the local 10K `regulates`, support-100, max-size-2 workload,
the native helper lookup measured 4.11s for candidates and 4.41s for the full
miner. The pure-MM2 `get-value-at-position` implementation measured 7.41s and
8.21s respectively, with identical output counts in that local comparison.
The native `value_at_path` and unused `specialization_prefix` helpers were
subsequently removed; the production implementation is pure MM2.

The NewMiner benchmark data was not used in this report and no NewMiner source
or benchmark files were modified.
