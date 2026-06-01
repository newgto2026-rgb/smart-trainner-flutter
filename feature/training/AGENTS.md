# Training Feature Family Agent Guide

## Responsibility
- Own the training feature family contract and implementation split.
- Keep app-facing contracts in `feature/training/api`, app wiring in `feature/training/entry`, and screen implementation in `feature/training/impl`.

## Boundaries
- `app` must not depend on `feature/training/impl`.
- `feature/training/api` must not depend on `feature/training/impl` or domain/data implementation.
- `feature/training/entry` contains wiring only.
- `feature/training/impl` may depend on domain use cases, shared models, and design system primitives.
- No training feature package may depend on `core/data` directly except `entry` composition wiring.

## Implementation Rules
- Read the subpackage guide before editing `api`, `entry`, or `impl`.
- Public contracts should stay narrow and stable.
- Implementation details should not leak through app imports, tests, or docs.

## Validation
- Contract change: `cd feature/training/api && flutter analyze`
- Entry wiring change: `cd feature/training/entry && flutter analyze`
- Implementation change: `cd feature/training/impl && flutter test && flutter analyze`
- Core flow change: `cd app && flutter test integration_test`
