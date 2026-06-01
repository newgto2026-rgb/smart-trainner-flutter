# Smart Trainner Flutter

Flutter port of the modular Smart Trainner Android app.

## Layout

- `app`: Flutter app shell and top-level composition.
- `core/model`: shared domain-facing models.
- `core/domain`: repository contracts, use cases, and business rules.
- `core/data`: repository implementations, seed content, and mappers.
- `core/database`: local workout log store contracts.
- `core/datastore`: preference/session store contracts.
- `core/network`: remote API contract placeholder.
- `core/designsystem`: Flutter theme and reusable visual primitives.
- `core/testing`: shared test fixtures.
- `feature/training/api`: public training feature contract.
- `feature/training/entry`: app wiring for the feature.
- `feature/training/impl`: training UI, presentation state, image metadata, and tests.

## Commands

```sh
dart pub get
dart run melos bootstrap
dart run melos run analyze
dart run melos run test
dart run melos run build:android
```
