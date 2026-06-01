# Core Model Agent Guide

## Responsibility
- Own pure Dart domain-facing models shared by app, feature, domain, data, and tests.

## Boundaries
- No Flutter framework, local store, network, or data implementation dependencies.
- Do not add repository calls, I/O, cross-aggregate workflows, or presentation decisions.
- DTO, database entity, and preference models belong in their owning data packages, not here.

## Implementation Rules
- Prefer immutable value types with explicit units and stable identifiers.
- Lightweight rules are allowed only when they use the model's own fields.
- Keep names domain meaningful: exercise, muscle group, plan, workout log, summary, and related concepts.
- Preserve mapping compatibility when fields are added or renamed.

## Validation
- Model change: `cd core/model && dart test && dart analyze .`
- Cross-package model change: also run affected mapper/use case tests.
