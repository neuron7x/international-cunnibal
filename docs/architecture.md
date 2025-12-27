# Architecture Enforcement

## Clean Architecture Boundaries
- **Domain** (`lib/core/`): pure math only, no framework imports.
- **Domain metrics invariants**: calculations must be deterministic, sanitize
  non-finite inputs, and clamp outputs to documented ranges.
- **Services** (`lib/services/`, `lib/services/ui/`): orchestration and business logic;
  no raw file I/O in UI-facing services.
- **CV engines**: behind strict interfaces (`CvEngine`).
- **UI** (`lib/screens/`, `lib/widgets/`): pure function of state.

## MVI / Unidirectional Data Flow
- UI renders from state; state mutates only via intents/actions.

## Gate Hooks
- `tool/ci/check_architecture_boundaries.py` enforces forbidden imports.
