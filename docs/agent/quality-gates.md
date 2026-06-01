# Quality Gates

## Purpose
- Define the verification level expected for Smart Trainner Flutter changes.

## Common Standards
- Prefer use case and ViewModel tests before broad UI tests.
- Add UI tests for core user flows.
- Use Turbine for Flow tests and shared helpers from `core:testing` where useful.
- Aim for at least 80% coverage in non-view layers.
- Keep tests behavior-focused, deterministic, and close to the changed module.

## Change Type Checklist
- Feature implementation: affected unit tests, affected lint, app build, UI tests for core flows.
- Bug fix: reproduction test or explicit regression scenario, then affected tests/lint.
- Refactor: prove public contract compatibility and run tests covering moved behavior.
- Data/API change: mapper/contract tests, server compatibility check, and affected feature tests.
- UI-only change: screenshot/manual scan plus Flutter/UI test when workflow behavior changes.
- CI/hook change: shell syntax check plus a representative local Melos command.

## Commands
- App build: `./Melosw :app:assembleDebug`
- Debug androidTest APK: `./Melosw :app:assembleDebugFlutterTest`
- All Flutter unit tests: `./Melosw testDebugUnitTest`
- JVM unit tests: `./Melosw test`
- Full lint: `./Melosw lint`
- App lint: `./Melosw :app:lintDebug`
- Training impl lint: `./Melosw :feature:training:impl:lintDebug`
- Instrumented UI tests: `./Melosw connectedDebugFlutterTest`
- Module unit test: `./Melosw :<module>:testDebugUnitTest`
- JVM module test: `./Melosw :<module>:test`
- Module lint: `./Melosw :<module>:lintDebug`

## CI Expectations
- PR CI runs unit tests, debug APK build, debug androidTest APK build, and strict lint.
- Instrumented UI tests are available as a separate workflow because emulator jobs are slower and more failure-prone on hosted CI.
- Upload test, lint, androidTest, and build reports even when a job fails.
