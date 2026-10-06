# Bernoulli Jensen–Shannon Distance for I-Surprisingness

## 1. Background and motivation

The original I-Surprisingness method compares a pattern’s observed probability, `p`, with the expected interval `[E_min, E_max]` obtained from probabilities for partitions of the pattern’s clauses. It assigns zero distance inside the interval and measures the distance to the nearest edge outside it. With normalization enabled, the score is


s = min(1, d_{old} / max(E_{max}, p)),

where


d_{old}= max(E_{min} - p, p - E_{max}, 0).


This measure is simple, but it has limitations:

1. It uses a linear probability gap. The same absolute gap receives the same distance even when the baseline probabilities differ substantially.
2. In the old method, normalized scores are clipped at `1`, which can cause distinct patterns to tie when probabilities are sparse. This clipping claim applies to the old method; the JSD score is inherently bounded in `[0,1]`.
3. The score is a geometric distance rather than a divergence between probability distributions.

### equal absolute gaps, different Bernoulli JSD distances

Compare the same absolute probability change, `0.01`, at two baselines:

| Probabilities `(p, q)` | Absolute gap | JSD | Implemented score `sqrt(JSD)` |
|---|---:|---:|---:|
| `(0.01, 0.02)` | `0.01` | `0.00124387` | `0.0352686` |
| `(0.50, 0.51)` | `0.01` | `0.0000721432` | `0.00849371` |

The linear gap is identical in both rows. Bernoulli JSD also accounts for the probability of non-occurrence (`1-p` and `1-q`), so the rare-event pair gets a larger value: its JSD is about `17.2` times as large. Since this implementation returns `sqrt(JSD)`, its score is about `4.15` times as large. These ratios describe this example; they are not universal multipliers or a guarantee that JSD ranks every pattern better.

## 2. Bernoulli Jensen–Shannon distance

The alternative keeps the interval semantics and changes the distance calculation. It represents the observed and expected probabilities as Bernoulli distributions:


P = {Bernoulli}(p), Q = {Bernoulli}(q).


The expected probability `q` is the nearest interval bound:

q = {
    E_{max},                  p > E_{max}, 
    E_{min},                  p < E_{min},
    undefined(score = 0),     E_{min} <= p <= E_{max}
    }

If `p` is inside `[E_min,E_max]`, the score is zero. Outside the interval, define the mixture probability

m = {p + q} / {2}.


The Bernoulli Jensen–Shannon divergence is


{JSD}(P,Q) = 1 // 2 {D_{KL}(P|M) + D_{KL}(Q\|M)},


where the Bernoulli KL divergence, using base-2 logarithms, is


D_{KL}(P|Q) = p * log_2({p}/ {q}) + (1-p) * log_2({1-p} / {1-q}).

The score is the metric square root:


s_{JSD} = sqrt{{JSD}(P,Q)}.


## 3. Design choices

| Choice | Reason |
|---|---|
| Bernoulli distributions `(p, 1-p)` and `(q, 1-q)` | Models both occurrence and non-occurrence, producing a valid two-outcome distribution. |
| Jensen–Shannon divergence | It is symmetric and finite, including at probability boundaries. With base-2 logarithms, JSD is bounded by 1. |
| Square root of JSD | The square root is a metric between Bernoulli distributions and remains bounded in `[0,1]`. |
| Nearest interval bound | Preserves the original rule that every `p` inside the expected interval scores zero. |
| Exact boundary handling | Avoids an arbitrary smoothing parameter. |

This method does not add a Beta model or confidence adjustment. Those would require separate assumptions about the sampling process and uncertainty in the expected probability.

## 4. Differences from the original measure

| Property | Original interval distance | Bernoulli `sqrt(JSD)` |
|---|---|---|
| Inside the expected interval | Score is zero | Score is zero |
| Outside the interval | Normalized linear distance to the nearest bound | Square root of JSD between observed and nearest-bound Bernoulli distributions |
| Symmetry | Not a comparison between two distributions; it measures distance to an interval | Yes: swapping observed and expected Bernoulli distributions leaves JSD unchanged |
| Score range and normalization | `[0,1]`; `NORMALIZATION=True` divides by `max(E_max,p)` before clipping, while `False` uses the capped raw distance | `[0,1]` by construction with base-2 JSD; `NORMALIZATION=True` gates output but does not rescale the score |
| Probability dependence | Based on the linear gap and optional normalization | Uses both event and non-event probabilities and changes nonlinearly with their probabilities |

The two methods have different definitions and score scales, so compare their rankings and behavior on relevant data rather than comparing raw score magnitudes.

## 5. Empirical comparison

The benchmark uses 10 three-clause patterns from `data/ugly-sodaDrinker.metta`.

- The highest-ranked pattern is `man + sodaDrinker + ugly` for both methods.
- The other five patterns with support 5 tie at rank 2 for both methods.
- Among the four patterns with support 0, the original method ties all four at rank 7. The JSD ranking places `human + man + woman` at rank 7 and the other three at rank 8.

  **Why they split:** all four have observed probability `p = 0`, but their minimum expected probabilities differ. Since `p < E_min`, the JSD formula compares `Bernoulli(0)` with `Bernoulli(E_min)`. For `human + man + woman`, MORK emitted `E_min = 4.991027698382799e-11`; for each of the other three patterns it emitted `E_min = 2.495513849191399e-11`. The first expected probability is about twice as large, producing a larger `sqrt(JSD)` score. This explains the ranking split under this formula; 

### Zero-support score verification

The MORK run emitted the probabilities and divergence components below. Applying the implementation formula `sqrt(0.5 * (Dpm + Dqm))` gives the listed score:

| Pattern | `p` | `E_min` (`q`) | `Dpm` | `Dqm` | `sqrt(JSD)` |
|---|---:|---:|---:|---:|---:|
| `human + man + woman` | `0` | `4.991027698382799e-11` | `3.6002669790625874e-11` | `1.390760719410057e-11` | `4.99551183487e-06` |
| `man + sodaDrinker + woman` | `0` | `2.495513849191399e-11` | `1.8001334895425243e-11` | `6.953803596713367e-12` | `3.53236029392e-06` |
| `man + ugly + woman` | `0` | `2.495513849191399e-11` | `1.8001334895425243e-11` | `6.953803596713367e-12` | `3.53236029392e-06` |
| `sodaDrinker + ugly + woman` | `0` | `2.495513849191399e-11` | `1.8001334895425243e-11` | `6.953803596713367e-12` | `3.53236029392e-06` |


- JSD scores are small on this dataset (about `0.0085` for support-5 patterns), because the observed and expected probabilities are both small.


## 6. Conclusion

Bernoulli `sqrt(JSD)` preserves the original expected-interval behavior while measuring the deviation with a symmetric, bounded information-theoretic distance. On this small benchmark, both methods agree on the top six patterns; JSD adds some separation among zero-support patterns. The fixture has no ground-truth labels for which patterns are truly surprising, so it cannot establish that one method is generally more accurate. A stronger evaluation should use larger, representative datasets and labeled or simulated surprising patterns.


---

# Appendix: Detailed Method Rankings

## Shared-pattern ranking comparison: Old Interval vs. Metric sqrt(JSD)

Both scorers ran over the same 10 three-clause patterns from `data/ugly-sodaDrinker.metta`.
Supports were counted from the facts. Each method is ranked independently, highest score first.
Equal scores share a competition rank; scores are rounded to 12 decimal places for tie detection.

| Pattern | Support | Old rank (score) | Metric sqrt(JSD) rank (score) |
|---|---:|---:|---:|
| `human + man + sodaDrinker` | 5 | 2 (`0.999415546464`) | 2 (`0.00851956640604`) |
| `human + man + ugly` | 5 | 2 (`0.999415546464`) | 2 (`0.00851956640604`) |
| `human + man + woman` | 0 | 7 (`0.000584453535944`) | 7 (`4.99551183487e-06`) |
| `human + sodaDrinker + ugly` | 5 | 2 (`0.999415546464`) | 2 (`0.00851956640604`) |
| `human + sodaDrinker + woman` | 5 | 2 (`0.999415546464`) | 2 (`0.00851956640604`) |
| `human + ugly + woman` | 5 | 2 (`0.999415546464`) | 2 (`0.00851956640604`) |
| `man + sodaDrinker + ugly` | 5 | 1 (`0.999707773232`) | 1 (`0.00853231694238`) |
| `man + sodaDrinker + woman` | 0 | 7 (`0.000584453535944`) | 8 (`3.53236029392e-06`) |
| `man + ugly + woman` | 0 | 7 (`0.000584453535944`) | 8 (`3.53236029392e-06`) |
| `sodaDrinker + ugly + woman` | 0 | 7 (`0.000584453535944`) | 8 (`3.53236029392e-06`) |

## Method orderings

### Old interval

1. **man + sodaDrinker + ugly** — support 5, score 0.999707773232
2. **human + man + sodaDrinker** — support 5, score 0.999415546464
2. **human + man + ugly** — support 5, score 0.999415546464
2. **human + sodaDrinker + ugly** — support 5, score 0.999415546464
2. **human + sodaDrinker + woman** — support 5, score 0.999415546464
2. **human + ugly + woman** — support 5, score 0.999415546464
7. **human + man + woman** — support 0, score 0.000584453535944
7. **man + sodaDrinker + woman** — support 0, score 0.000584453535944
7. **man + ugly + woman** — support 0, score 0.000584453535944
7. **sodaDrinker + ugly + woman** — support 0, score 0.000584453535944

### Metric sqrt(JSD)

1. **man + sodaDrinker + ugly** — support 5, score 0.00853231694238
2. **human + man + sodaDrinker** — support 5, score 0.00851956640604
2. **human + man + ugly** — support 5, score 0.00851956640604
2. **human + sodaDrinker + ugly** — support 5, score 0.00851956640604
2. **human + sodaDrinker + woman** — support 5, score 0.00851956640604
2. **human + ugly + woman** — support 5, score 0.00851956640604
7. **human + man + woman** — support 0, score 4.99551183487e-06
8. **man + sodaDrinker + woman** — support 0, score 3.53236029392e-06
8. **man + ugly + woman** — support 0, score 3.53236029392e-06
8. **sodaDrinker + ugly + woman** — support 0, score 3.53236029392e-06
