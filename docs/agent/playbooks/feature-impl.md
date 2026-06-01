# Playbook: Feature Implementation

## When To Load
- Adding or changing user-facing app behavior.
- Changing ViewModel, use case, repository contract, or feature UI together.

## Procedure
1. Identify affected modules and read their `AGENTS.md` files.
2. Define the domain behavior in `core:domain` before wiring UI behavior.
3. Keep repository implementation details in `core:data`.
4. Expose immutable `UiState` from the ViewModel.
5. Send user events to the ViewModel; keep widgets render-only.
6. Put strings in `values` and `values-ko`.
7. Add focused unit tests before broad integration checks.
8. Add or update UI tests when the core user journey changes.

## Smart Trainner Notes
- Training is split from the start into `:feature:training:api`, `:feature:training:entry`, and `:feature:training:impl`.
- `app` consumes the API contract and entry binding only; implementation details stay in `impl`.
- If future features become independently reusable, follow the same `api`/`entry`/`impl` pattern before adding cross-feature dependencies.

## Done Criteria
- Changed modules named in PR.
- Tests/lint/build commands recorded.
- Rollback impact is clear.
