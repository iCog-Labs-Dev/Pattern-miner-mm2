# IISurp

IISurp measures how surprising a frequent pattern remains after considering
both independent combinations of its clauses and broader patterns that may
explain it. A higher normalized score means the observed pattern is less well
explained by those expectations.

This MM2 implementation follows the legacy numeric `IIsurp-old-nary`
behavior. It supports patterns with two or more triplet clauses and discovers
broader concepts from shared instances in the active atomspace.

## Using IISurp

Load these files with the application:

```text
src/common-utils/utils.metta
src/common-utils/surp-components.metta
src/iisurp.metta
```

Declare the number of facts in the active database once:

```metta
(INPUT DB-SIZE 158)
```

Then provide a pattern and its already-computed support:

```metta
(iisurp
  (, (Inheritance $x California)
     (Inheritance $x surfer))
  2)
```

IISurp publishes the normalized result as:

```metta
(surprisingness-of
  (, (Inheritance $x California)
     (Inheritance $x surfer))
  0.6995976754582028)
```

The public call uses the supported legacy calculation automatically; callers
do not need to configure its internal probability or concept-discovery modes.

## Current scope

The implementation includes numeric IISurp scoring, extensional concept
discovery, raw and normalized calculations, and pattern-scoped diagnostics.
It does not include miner integration, ontology-driven abstraction,
TruthValue aggregation, subconcept combinations, or Jensen-Shannon divergence.

