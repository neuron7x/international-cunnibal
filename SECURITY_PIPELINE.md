# Security, Quality, and Control Pipeline

## Automated checks (run on every PR and pushes to `main`)

- **Flutter CI**: `flutter format --set-exit-if-changed lib test`, `flutter analyze`,
  `flutter test --coverage` (coverage artifact uploaded).
- **CodeQL (GitHub Advanced Security)**: security-extended queries
  (build-less JS scan until Dart is supported).
- **Dependency Review**: blocks high-severity dependency risks during PR review.
- **Secret Scan**: `gitleaks` ensures no secrets or tokens are committed.
- **Docs & Intent Guard**:
  - Markdown linting when docs change.
  - Requires docs updates when core or architecture code changes.
  - Requires metric-focused tests to be touched when metric logic changes.
- **CI Meta Guard**: blocks invalid action versions in workflows.
- **Conventional Commits**: PR titles must follow Conventional Commits.

## Dependency hygiene

- **Dependabot**: weekly updates for GitHub Actions and Dart (pub) dependencies,
  delivered in grouped batches.

## Branch protection (configure in repository settings)

1. Protect `main`:
   - Require pull requests; block direct pushes and force-pushes.
   - Require branches to be up to date before merging.
   - Require the following status checks:
     - `Flutter CI / Format, analyze, test`
     - `CodeQL / CodeQL analysis`
     - `Dependency Review / dependency-review`
     - `Secret Scan / gitleaks`
     - `Documentation and Intent Guard / docs-lint`
     - `Documentation and Intent Guard / intent-guard`
     - `Documentation and Intent Guard / metrics-guard`
     - `CI Meta Guard / workflow-guard`
     - `Conventional Commits / semantic-pr`
   - Require at least one approving review.
2. Enable GitHub Advanced Security features (CodeQL and secret scanning)
   in repository settings.

## Local Development Workflow

Run these commands in order to mirror CI locally (single path, no alternatives):

```bash
flutter format .
flutter analyze
flutter test --coverage
python tool/ci/check_coverage.py
python tool/ci/check_privacy_guards.py
python tool/ci/check_architecture_boundaries.py
python tool/ci/check_metric_changes.py
python tool/ci/check_doc_updates.py
python tool/ci/check_doc_lint.py
python tool/ci/check_latency_budget.py
```

## What is protected

* **Metrics & math**: changes in motion or metric logic must update tests;
  CI enforces deterministic ranges via coverage and metric guards.
* **Architecture & core logic**: PRs that modify core, services, models, or utils
  must update architecture or user-facing documentation where relevant.
* **Secrets & artifacts**: `.gitignore` blocks common secrets, credentials, and large ML artifacts;
  secret scanning enforces this at PR time.
