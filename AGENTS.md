# Smart Trainner Flutter Agent Guide

## Purpose
- This is the single entry point for agent work in this Flutter repository.
- Read this first, then open only the `AGENTS.md` files for packages you will edit.

## Source Of Truth
- Flutter app repo: `/Users/kimtaenyun/workspace/smart-trainner-flutter`.
- Original Android app repo: `/Users/kimtaenyun/workspace/smart-trainner`.
- Server repo: `/Users/kimtaenyun/server/smart-trainner`.

## Required Pre-Change Checks
1. Confirm the current branch is not `main` or `master`, except while preparing the initial public repo history.
2. Identify the affected Melos packages.
3. Open the affected package `AGENTS.md` files.
4. Check package boundaries and dependency direction before editing.

## Required Pre-PR Checks
1. Run affected package unit or widget tests.
2. Run affected package analysis.
3. Run app build or integration tests when the change crosses package boundaries.
4. Run `flutter test integration_test` before PR updates when core user flows or UI test harnesses changed.
5. Record the commands and results in the PR description.

## Global Policies
### Branch And PR
- Use a dedicated branch for implementation after the initial repository seed exists.
- Do not push directly to `main` after the initial public repo bootstrap.
- Push changes through a PR.
- Keep commits structured by phase and explainable.

### Scope And Quality
- Keep changes minimal, testable, and feature-oriented.
- Every implementation change should include automated tests in the same PR when practical.
- Aim for at least 80% coverage in non-view layers.
- Prefer use case and controller tests before broader widget/integration tests.
- Add widget or integration tests for core user flows.
- Reuse `core/testing` for shared fake/helper code.
- Run broad checks such as `flutter test`, `flutter build apk --debug`, and integration tests as final gates; use targeted tests while iterating.

### Architecture And Dependencies
- Keep package boundaries and dependency direction intact.
- `core/*` must not depend on `feature/*`.
- `feature/*` depends on domain use cases and public models, not data implementations.
- Repository interfaces live in `core/domain`; implementations live in `core/data`.
- DTO/DB/DataStore models are not domain models.
- Network contracts belong in `core/network`; local store contracts belong in `core/database`.

### Logic Ownership
- Business logic means service rules, possible/impossible decisions, state transitions, and policy calculations.
- Application logic coordinates feature procedures, such as fetching data and applying domain rules.
- Presentation logic maps domain/use case results to `UiState`, `UiModel`, and side effects.
- Data logic reads/writes DTO, DB entity, and preference values and maps them to domain models.
- Repository implementations own data access, mapping, cache, and sync logic only.
- Entity/domain model may contain lightweight rules that use only its own fields.
- External I/O, repository calls, and cross-aggregate procedures belong in use cases/domain services.
- Flutter widgets render state and send user events. Do not put business or application logic in widgets.
- Button enablement, section grouping, empty states, toast text, and navigation side effects should be prepared by controllers/UI mappers.

### UI And Resources
- User-visible strings belong in feature/app localization or constants, except explicit seed/domain content.
- Top-level tabs must map only to implemented feature routes.
- Use explicit icons/assets for tabs/actions; do not substitute text glyphs.
- Split feature UI into screen assembly and smaller widgets when the feature grows.

### PR Description
- Follow `.github/pull_request_template.md`.
- Include changed packages, behavior changes, validation commands, coverage impact, and rollback notes.

## Review Guidelines
- Prioritize real behavior bugs, regression risk, architecture/package boundary violations, and missing tests.
- Treat `core/* -> feature/*` dependencies as P1.
- Treat missing tests for controller/use case/domain/data changes as P1 unless explicitly justified.
- Treat core user-flow UI changes without widget or integration tests as P1 unless explicitly justified.
- Treat user-visible hardcoded strings outside feature/app resources or seed content as P1.
- Treat side effects implemented directly inside widgets as P1.
- Treat local store key or network API contract changes without compatibility verification as P1.
- Do not block on style-only preferences when behavior and maintainability are not affected.

## Verification Commands
- Bootstrap: `dart pub get && dart run melos bootstrap`
- All analysis: `dart run melos run analyze`
- All tests: `dart run melos run test`
- App build: `dart run melos run build:android`
- Final Flutter gate: `dart run melos run final-gate`
- App integration tests: `cd app && flutter test integration_test`
- Package test: `cd <package> && dart test` or `cd <package> && flutter test`

## Quick Workflow
1. Read this root guide.
2. Identify affected Melos packages.
3. Read only the affected package guides.
4. Make the smallest useful change.
5. Run targeted checks.
6. Run final gates before PR updates.

## Detailed References
- Indexing rules: `docs/agent/indexing.md`
- Quality gates: `docs/agent/quality-gates.md`
- Feature implementation playbook: `docs/agent/playbooks/feature-impl.md`
- UI/Flutter playbook: `docs/agent/playbooks/ui-flutter.md`
- Data/Domain/Network playbook: `docs/agent/playbooks/data-layer.md`

## Technical Baseline
- Dart + Flutter
- Melos workspace
- ChangeNotifier/ValueNotifier controller shape for MVP state
- In-memory local store with Room/DataStore-shaped boundaries
- Public feature entry package mirroring the Android module split

## Package Index
| Melos package | Guide | Responsibility |
|---|---|---|
| `app` | `app/AGENTS.md` | App shell, Flutter entry point, top-level composition |
| `core/model` | `core/model/AGENTS.md` | Shared pure Dart models |
| `core/domain` | `core/domain/AGENTS.md` | Use cases and repository contracts |
| `core/data` | `core/data/AGENTS.md` | Repository implementations, seed content, mappers |
| `core/database` | `core/database/AGENTS.md` | Local workout log store entities/DAO |
| `core/datastore` | `core/datastore/AGENTS.md` | User preference/session data sources |
| `core/network` | `core/network/AGENTS.md` | Remote API contracts |
| `core/designsystem` | `core/designsystem/AGENTS.md` | Theme, colors, typography, design tokens |
| `core/testing` | `core/testing/AGENTS.md` | Shared test fakes, fixtures, helpers |
| `feature/training/api` | `feature/training/api/AGENTS.md` | Public training feature entry contract |
| `feature/training/entry` | `feature/training/entry/AGENTS.md` | App wiring for training feature entry |
| `feature/training/impl` | `feature/training/impl/AGENTS.md` | Training UI, controller, assets, presentation state |

## Current Dependency Shape
- `app -> feature/training/api + feature/training/entry + core/*`
- `feature/training/entry -> feature/training/api + feature/training/impl`
- `feature/training/impl -> feature/training/api + core/domain + core/model + core/designsystem`
- `core/data -> core/domain + core/database + core/datastore + core/network`
- `core/*` does not depend on `feature/*`
