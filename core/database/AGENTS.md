# Core Database Agent Guide

## Responsibility
- Own local workout log store entities, DAO contracts, migration notes, and persistence-shaped boundaries.

## Boundaries
- Database entities are persistence models, not domain models.
- Do not add business rules beyond database constraints and persistence-safe normalization.
- Repository-facing mapping belongs in `core/data`.

## Implementation Rules
- Every schema-shape change needs a compatibility note and tests.
- DAO queries should be deterministic and covered when ordering or filtering matters.
- Keep destructive migrations out of production paths unless explicitly approved.
- Prefer stable primary keys that match domain identifiers when possible.

## Validation
- Database change: `cd core/database && dart test && dart analyze .`
- Schema/migration change: run data repository tests that consume the DAO.
