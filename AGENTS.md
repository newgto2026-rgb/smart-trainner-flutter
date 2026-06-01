# Smart Trainner Flutter Agent Guide

## Source Of Truth
- GitHub app repo: `newgto2026-rgb/smart-trainner-flutter`.
- The `origin` remote for this checkout should point to `https://github.com/newgto2026-rgb/smart-trainner-flutter.git`.
- Local Flutter checkout: `/Users/kimtaenyun/Documents/smart-trainner-flutter`.
- Original Android reference repo: latest public `main` of `newgto2026-rgb/smart-trainner-public`; the current refreshed local reference is `/Users/kimtaenyun/.codex/worktrees/64a0/smart-trainner`.

## New Task Workflow
- Start new implementation work from the latest Flutter `origin/main`.
- Use a dedicated branch under `codex/<task-name>`.
- If you create a worktree manually, fetch first and base the branch on `origin/main`, not on a stale local `main`.

```sh
git fetch origin main
git worktree add -b codex/<task-name> "$HOME/.codex/worktrees/<task-name>/smart-trainner-flutter" origin/main
```

## Required Pre-Change Checks
1. Confirm the current branch is not `main` or `master`.
2. Confirm new work is based on fresh `origin/main`.
3. Identify affected Melos packages.
4. Open affected package-local `AGENTS.md` files when they exist.
5. Check package boundaries and dependency direction before editing.
6. For UI/UX changes, compare against the original Android reference before choosing Flutter-specific behavior.

## Required Pre-PR Checks
1. Run affected package unit or widget tests.
2. Run affected package analysis.
3. Run app build or integration tests when the change crosses package boundaries.
4. Run the real Android emulator UI harness before PR updates when core user flows or UI test harnesses changed.
5. Record validation commands and results in the PR description.

## Architecture And Dependencies
- Keep package boundaries and dependency direction intact.
- `core/*` must not depend on `feature/*`.
- `feature/*` depends on domain use cases and public models, not data implementations.
- Repository interfaces live in `core/domain`; implementations live in `core/data`.
- DTO, database, and DataStore models are not domain models.
- Network contracts belong in `core/network`; local store contracts belong in `core/database`.
- Flutter widgets render `UiState` and send user events. Keep business and application logic out of widgets.
- Button enablement, section grouping, empty states, dialog state, and navigation side effects should be prepared by controllers/UI mappers.

## UI And Resources
- User-visible strings belong in feature/app localization or feature constants, except explicit seed/domain content.
- Match Android Compose UX semantics unless the user explicitly approves a Flutter-specific deviation.
- Dialogs should behave like Compose `Dialog`: modal over the full app surface, including the bottom navigation bar.
- Top-level tabs must map only to implemented feature routes and use explicit icons/assets.
- Launcher icons, adaptive icons, splash resources, and app labels live under `app/android/app/src/main/res`.

## Verification Commands
- Bootstrap: `dart pub get && dart run melos bootstrap`
- All analysis: `dart run melos run analyze`
- All tests: `dart run melos run test`
- Format check: `dart run melos run format`
- App build: `dart run melos run build:android`
- Final Melos gate: `dart run melos run final-gate`
- App widget tests: `cd app && flutter test`
- Real Android emulator UI tests: `cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/training_smoke_test.dart -d emulator-5554`
- Package test: `cd <package> && dart test` or `cd <package> && flutter test`
- Package analysis: `cd <package> && dart analyze .` or `cd <package> && flutter analyze`

## Review Guidelines
- Prioritize real behavior bugs, regression risk, architecture/package boundary violations, and missing tests.
- Treat `core/* -> feature/*` dependencies as P1.
- Treat missing tests for controller/use case/domain/data changes as P1 unless explicitly justified.
- Treat core user-flow UI changes without widget or emulator UI tests as P1 unless explicitly justified.
- Treat side effects implemented directly inside widgets as P1.
- Treat local store key or network API contract changes without compatibility verification as P1.
- Do not block on style-only preferences when behavior and maintainability are not affected.

## Quick Workflow
1. Read this root guide.
2. Identify affected Melos packages.
3. Read only the affected package guides.
4. Compare original Android behavior for user-visible UX.
5. Make the smallest useful change.
6. Run targeted checks.
7. Run broad Melos and emulator gates before PR updates.

## Package Index
| Melos package | Guide | Responsibility |
|---|---|---|
| `app` | `app/AGENTS.md` | App shell, Flutter entry point, platform resources, top-level composition |
| `core/model` | `core/model/AGENTS.md` | Shared pure Dart models |
| `core/domain` | `core/domain/AGENTS.md` | Use cases and repository contracts |
| `core/data` | `core/data/AGENTS.md` | Repository implementations, seed content, mappers |
| `core/database` | `core/database/AGENTS.md` | Local store entities/DAO abstractions |
| `core/datastore` | `core/datastore/AGENTS.md` | User preference/session data sources |
| `core/network` | `core/network/AGENTS.md` | Remote API contracts |
| `core/designsystem` | `core/designsystem/AGENTS.md` | Theme, colors, typography, design tokens |
| `core/ui` | `core/ui/AGENTS.md` | Shared screen chrome, surfaces, common widgets |
| `core/exercise_media` | `core/exercise_media/AGENTS.md` | Exercise image asset registry and step media |
| `core/testing` | `core/testing/AGENTS.md` | Shared test fakes, fixtures, helpers |
| `feature/training/api` | `feature/training/api/AGENTS.md` | Public training feature entry contract |
| `feature/training/entry` | `feature/training/entry/AGENTS.md` | App wiring for training feature entry |
| `feature/training/impl` | `feature/training/impl/AGENTS.md` | Integrated training UI, controller, assets, presentation state |
| `feature/analysis/api` | `feature/analysis/api/AGENTS.md` | Public analysis feature contract |
| `feature/analysis/domain` | `feature/analysis/domain/AGENTS.md` | Analysis use cases/policies |
| `feature/analysis/data` | `feature/analysis/data/AGENTS.md` | Analysis data adapters |
| `feature/analysis/impl` | `feature/analysis/impl/AGENTS.md` | Analysis presentation implementation |
| `feature/exercise/api` | `feature/exercise/api/AGENTS.md` | Public exercise feature contract |
| `feature/exercise/domain` | `feature/exercise/domain/AGENTS.md` | Exercise use cases/policies |
| `feature/exercise/impl` | `feature/exercise/impl/AGENTS.md` | Exercise catalog/detail presentation implementation |
| `feature/routine/api` | `feature/routine/api/AGENTS.md` | Public routine feature contract |
| `feature/routine/domain` | `feature/routine/domain/AGENTS.md` | Routine policy and command use cases |
| `feature/routine/data` | `feature/routine/data/AGENTS.md` | Routine data adapters |
| `feature/routine/impl` | `feature/routine/impl/AGENTS.md` | Routine presentation implementation |
| `feature/workout/api` | `feature/workout/api/AGENTS.md` | Public workout feature contract |
| `feature/workout/domain` | `feature/workout/domain/AGENTS.md` | Workout recording use cases |
| `feature/workout/data` | `feature/workout/data/AGENTS.md` | Workout data adapters |
| `feature/workout/impl` | `feature/workout/impl/AGENTS.md` | Workout recording presentation implementation |

## Current Dependency Shape
- `app -> feature/training/api + feature/training/entry + core/*`
- `feature/training/entry -> feature/training/api + feature/training/impl`
- `feature/training/impl -> feature/training/api + feature/routine/domain + core/domain + core/model + core/designsystem + core/ui + core/exercise_media`
- `feature/*/impl -> matching feature api/domain + core/model + core/designsystem + core/ui`
- `feature/*/data -> matching feature domain + core/domain + core/database + core/datastore`
- `core/data -> core/domain + core/database + core/datastore + core/network`
- `core/*` does not depend on `feature/*`
