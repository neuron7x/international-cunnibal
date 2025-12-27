# Architecture Enforcement

## Clean Architecture Boundaries
- **Domain** (`lib/core/`): pure math only, no framework imports.
- **CV engines**: behind strict interfaces (`CvEngine`).
- **UI** (`lib/screens/`, `lib/widgets/`): pure function of state.

## MVI / Unidirectional Data Flow
- UI renders from state; state mutates only via intents/actions.

## Gate Hooks
- `tool/ci/check_architecture_boundaries.py` enforces forbidden imports.
