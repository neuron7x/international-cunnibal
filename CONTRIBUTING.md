# Contributing to International Cunnibal

This repository enforces the 2025 Technical Constitution. All contributions
must comply with the gates below.

## Non-Negotiables
- Edge-first, on-device AI only.
- Metrics > UI > features.
- Delete before you optimize.
- Every system has an owner (see CODEOWNERS).
- Nothing exists without tests, benchmarks, and gates.

## Trunk-Based Development
- The only long-lived branch is `main`.
- All PRs must target `main`.
- Keep branches short-lived and scoped.

## Conventional Commits
- Commit messages and PR titles **must** follow Conventional Commits:
  - `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`, `ci:`
- Commit messages are linted in CI via `commitlint` to enforce the format.

## Required Gates (Do Not Bypass)
- **Lint + tests + coverage** must pass.
- **Metrics changes** require updated tests and benchmark logs.
- **Model changes** require DVC tracking, model cards, and benchmark logs.
- **Docs are a gate** for metrics, ML/CV, and architecture changes.

### Required PR checks
Make sure these checks are green before requesting review:
- `Flutter CI / Format, analyze, test`
- `CodeQL / CodeQL analysis`
- `Dependency Review / dependency-review`
- `Secret Scan / gitleaks`
- `Documentation and Intent Guard / docs-lint`
- `Documentation and Intent Guard / intent-guard`
- `Documentation and Intent Guard / metrics-guard`
- `CI Meta Guard / workflow-guard`
- `Conventional Commits / semantic-pr`

## DVC Workflow for Models
1. `dvc add ml-ops/models/<model-name>.tflite`
2. Commit the generated `.dvc` file.
3. Add a model card in `ml-ops/model_cards/`.
4. Add a benchmark log in `ml-ops/benchmarks/`.

## Testing
Run the standard checks before opening a PR:
```bash
flutter format --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

## Documentation Gates
Any PR touching:
- metrics (`lib/core/`, `lib/models/metrics.dart`)
- ML/CV (`lib/services/cv_engine.dart`,
  `lib/services/bio_tracking_service.dart`, `ml-ops/`)
- architecture (`lib/`, `ARCHITECTURE.md`)

must update the relevant docs in `docs/` and/or `ARCHITECTURE.md`.

## Reference
The full constitution is codified in
[`ENGINEERING_HANDBOOK.md`](ENGINEERING_HANDBOOK.md).
