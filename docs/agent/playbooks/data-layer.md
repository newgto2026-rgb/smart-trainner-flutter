# Playbook: Data, Domain, And Network

## When To Load
- Repository, mapper, seed content, local store, preference store, HTTP client, DTO, or server contract changes.

## Procedure
1. Keep wire, persistence, preference, and domain models separate.
2. Put business/application decisions in `core:domain` use cases.
3. Implement data access and mapping in `core:data`.
4. Keep database migrations safe and schema exports current.
5. Treat preference store keys and network DTO fields as compatibility-sensitive API.
6. Add mapper, seed-integrity, and domain-facing behavior tests.
7. Run Flutter and server checks when API contracts change.

## Smart Trainner Checks
- Exercise ids referenced by templates must exist.
- Weekly plans should remain deterministic for the same selected template.
- Workout logs should preserve date, exercise, sets, reps, weight, and perceived effort without silent coercion.

## Validation
- `./Melosw :core:domain:test`
- `./Melosw :core:data:testDebugUnitTest`
- `./Melosw :core:database:lintDebug :core:network:lintDebug` when those modules change.
- Server: `npm run lint && npm test` when remote API behavior changes.
