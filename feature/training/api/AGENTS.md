# Training API Package Agent Guide

## Responsibility
- Own the stable app-facing training feature contract.
- Keep this package small enough that `app` can depend on it without learning implementation details.

## Boundaries
- Must not depend on `feature/training/impl`, `feature/training/entry`, `core/data`, local store, network, or preference stores.
- Public API should contain only route/entry contracts and durable feature-level types.
- Do not put UI state, controller state, business policy, or screen copy here.

## Implementation Rules
- Keep `TrainingFeatureEntry` stable; changing it requires updating `entry`, `impl`, `app`, and app smoke tests together.
- If navigation contracts are added later, define them here before implementing screens.
- Avoid exposing implementation package names through API signatures.

## Validation
- `cd feature/training/api && flutter analyze`
- API contract change: also run `cd app && flutter test`.
