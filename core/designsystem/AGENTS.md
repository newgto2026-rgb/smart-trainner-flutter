# Core Design System Agent Guide

## Responsibility
- Own theme, color, typography, shape, spacing conventions, and reusable visual primitives.

## Boundaries
- No feature-specific training policy, screen workflows, repository access, or navigation decisions.
- Feature packages may consume design tokens and generic widgets, but feature copy and domain behavior stay outside this package.

## Implementation Rules
- Keep visual tokens consistent and named by purpose rather than one-off screen needs.
- Prefer reusable Flutter primitives only when at least two call sites or a clear design-system role exists.
- Preserve accessibility contrast and touch target sizes.
- Avoid changing global theme behavior as a side effect of a narrow feature edit.

## Validation
- Design system change: `cd core/designsystem && flutter analyze && flutter test`
- Global theme change: also run `cd app && flutter test && flutter build apk --debug` when visible flow behavior may shift.
