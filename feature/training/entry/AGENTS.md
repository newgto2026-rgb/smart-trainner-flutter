# Training Entry Package Agent Guide

## Responsibility
- Own app composition wiring for the training feature.

## Boundaries
- Wiring only.
- Do not add UI implementation, business logic, use case calls beyond object composition, or presentation mapping here.
- This package may depend on `feature/training/api` and `feature/training/impl` to bind implementation to public contract.

## Implementation Rules
- Keep binding/composition code narrow and deterministic.
- When the API entry contract changes, update the binding and app injection path in the same PR.
- Do not expose `impl` types to `app`.

## Validation
- `cd feature/training/entry && flutter analyze`
- Entry contract change: also run `cd app && flutter test`.
