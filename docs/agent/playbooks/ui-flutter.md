# Playbook: UI And Flutter

## When To Load
- Flutter screen, navigation, state, resources, or UI test changes.

## Procedure
1. Model screen state as immutable `UiState`.
2. Keep long-running work, validation, and side effects in ViewModel/use case layers.
3. Keep widgets small enough to scan; split repeated sections into private components.
4. Use Material 3 and `core:designsystem` tokens.
5. Keep touch targets accessible and text responsive in Korean and English.
6. Store user-visible copy in localized resources.
7. Update UI tests for plan selection, exercise detail, workout logging, and progress summary when those flows change.

## Visual Standards
- Prefer calm, dense, gym-utility UI over marketing-style hero sections.
- Exercise imagery should clearly show step-by-step movement states.
- Avoid layout shifts caused by dynamic labels, counters, or loading states.

## Validation
- `./Melosw :feature:training:impl:lintDebug`
- `./Melosw :app:assembleDebug`
- `./Melosw connectedDebugFlutterTest` for core journey changes.
