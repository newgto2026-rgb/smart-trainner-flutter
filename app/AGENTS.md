# App Package Agent Guide

## Responsibility
- Own Flutter entry points, app shell composition, platform wrappers, launcher resources, and top-level navigation.
- Compose feature routes here only through public feature entry points. Do not reach into feature internals to assemble business behavior.

## Boundaries
- May depend on feature packages and `core/*` packages.
- Must not contain repository implementations, seed exercise policy, workout plan generation rules, or feature-specific presentation mapping.
- Keep app-level strings and visual shell concerns here. Feature copy belongs in that feature package.

## Implementation Rules
- `main.dart` should stay thin: composition root, theme setup, and root content only.
- Add top-level destinations only when the route is implemented and tested.
- Use explicit icons/assets for navigation and app actions.

## Validation
- App shell change: `cd app && flutter analyze && flutter test`
- Navigation/root UI change: `cd app && flutter test test integration_test`
- Build change: `cd app && flutter build apk --debug`
