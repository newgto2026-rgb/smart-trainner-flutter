# Core DataStore Agent Guide

## Responsibility
- Own preference keys, preference data sources, and compatibility behavior for user settings.

## Boundaries
- Store raw preferences and simple preference mapping only.
- Do not put training policy, UI copy, or feature decisions in DataStore code.
- Domain/use case layers decide how preferences affect plans.

## Implementation Rules
- Treat preference key names as stable persisted API.
- Add migrations or compatibility fallbacks before renaming/removing keys.
- Keep default values explicit and tested when behavior depends on them.

## Validation
- DataStore change: `cd core/datastore && dart test && dart analyze .`
- Preference behavior change: also run affected domain/data tests.
