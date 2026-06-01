# Core Domain Agent Guide

## Responsibility
- Own use cases, repository contracts, domain services, and business/application rules.
- Decide what is valid, possible, recommended, or complete for training plans and workout records.

## Boundaries
- No Flutter framework, concrete local store, network, or data implementation dependency.
- Repository interfaces live here; repository implementations live in `core/data`.
- Do not format user-visible UI copy or make navigation decisions here.

## Implementation Rules
- Keep use cases small, composable, and focused on one procedure.
- Prefer explicit result/domain error types for operations that can fail.
- Business policy belongs here, not in repositories or widgets.
- When adding rules for plans, workouts, progression, or analysis, cover them with unit tests first.

## Validation
- Domain change: `cd core/domain && dart test && dart analyze .`
- Repository contract change: also run `cd core/data && dart test`.
