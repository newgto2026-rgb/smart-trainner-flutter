# Core Data Agent Guide

## Responsibility
- Own repository implementations, DTO/entity/preference mapping, local/remote coordination, seed exercise content, and cache/sync behavior.

## Boundaries
- Implement `core/domain` contracts without inventing hidden business policy.
- Data sources, mappers, and persistence details stay here or in `core/database`, `core/datastore`, and `core/network`.
- UI state, screen copy, and navigation behavior belong to feature/app layers.

## Implementation Rules
- Validate every seed exercise/template id for uniqueness and referential integrity.
- Keep generated weekly plans deterministic unless a randomization feature is explicitly requested.
- Mapper changes need regression tests that prove round-trip or domain-facing behavior.
- Handle local/remote failure explicitly and keep fallback behavior visible in tests.

## Validation
- Data change: `cd core/data && dart test && dart analyze .`
- Seed content change: include `SeedTrainingContentTest`.
- Contract-impacting change: also run affected domain and feature controller tests.
