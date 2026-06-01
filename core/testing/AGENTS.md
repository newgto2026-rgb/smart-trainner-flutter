# Core Testing Agent Guide

## Responsibility
- Own shared fakes, fixtures, and reusable assertions.

## Boundaries
- Test helpers should be deterministic and lightweight.
- Fakes should model repository contracts without duplicating complex production policy.
- Keep feature-specific test fixtures in the feature package unless multiple packages need them.

## Implementation Rules
- Prefer explicit fixture builders for exercises, plans, and workout logs.
- Keep time control centralized so stream tests are stable.
- Shared helpers must not require Flutter widgets unless the helper clearly belongs to widget tests.

## Validation
- Testing helper change: run all tests that consume the helper.
- Generic helper change: `dart run melos run test`.
