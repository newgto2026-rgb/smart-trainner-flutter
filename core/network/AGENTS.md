# Core Network Agent Guide

## Responsibility
- Own remote API contracts, DTOs, serialization configuration, and client setup.

## Boundaries
- DTOs are wire models, not domain models.
- Network code should not decide training policy, presentation text, or persistence strategy.
- Mapping from DTOs to domain objects belongs in `core/data`.

## Implementation Rules
- Keep request/response DTOs explicit and compatible with the server API.
- Model nullable and optional fields deliberately; avoid silent defaults that hide API drift.
- Add tests or sample payload checks when changing API contracts.
- Keep base URL and client configuration injectable for tests.

## Validation
- Network change: `cd core/network && dart test && dart analyze .`
- API contract change: also run server tests and Flutter data/feature checks that consume it.
