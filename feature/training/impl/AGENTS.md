# Training Impl Package Agent Guide

## Responsibility
- Own Smart Trainner's MVP user experience: weekly plan selection, exercise detail viewing, workout logging, and progress/analysis presentation.
- Own `TrainingController`, feature `UiState`, feature assets, generated exercise art usage, and Flutter screen assembly.

## Boundaries
- Depend on `feature/training/api`, domain use cases, shared models, and design system primitives.
- Do not depend on data implementation packages directly.
- Do not put business rules, repository calls, or cross-screen procedures in widgets.
- Keep generated exercise art and step display behavior feature-local unless reused elsewhere.

## Implementation Rules
- Prefer UDF shape: immutable `UiState`, user actions into controller, one-time effects for snackbars/navigation when needed.
- Controller owns presentation logic: selected tab/detail, form validation, section grouping, empty states, and save progress.
- Widgets render state and emit events only.
- Split screen files when a screen grows or repeated components become hard to scan.
- Add or update widget/integration tests for core flows: plan switch, exercise detail, workout save, and summary update.

## Validation
- Feature UI/controller change: `cd feature/training/impl && flutter test && flutter analyze`
- Asset/localization change: `cd feature/training/impl && flutter test test/exercise_step_images_test.dart`
- Core flow change: `cd app && flutter test`
- Real Android emulator UI change: `cd app && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/training_smoke_test.dart -d emulator-5554`
