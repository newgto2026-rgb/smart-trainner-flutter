# Global Agent Rules

## Worktree And Branch
- Work only in `/Users/kimtaenyun/workspace/smart-trainner` for the Flutter app.
- Do not commit or push directly to `main` or `master`.
- Use PR branches and keep commits focused.

## Scope And Quality
- Keep changes minimal, testable, and aligned with the current module shape.
- Add automated tests with implementation changes whenever practical.
- Do not introduce broad refactors while making feature or harness updates.
- Record validation commands and any skipped checks in the PR.

## Architecture
- Preserve dependency direction: `app -> feature -> core`, and never `core -> feature`.
- Repository interfaces live in `core:domain`; implementations live in `core:data`.
- DTOs, entities, and preference models stay out of `core:model`.
- Business policy belongs in domain/use cases, not repositories or widgets.

## UI And Resources
- User-visible strings belong in localized resource files.
- Flutter UI renders `UiState` and emits events.
- Side effects belong in ViewModel/use case layers.
- Navigation should point only to implemented feature routes.

## Review Priorities
- P1: module boundary violation, missing tests for non-view logic, user-flow UI change without UI test, hardcoded user-facing strings, unsafe persistence/API contract change.
- P2: confusing ownership, avoidable duplication, unclear failure handling, incomplete PR validation notes.
