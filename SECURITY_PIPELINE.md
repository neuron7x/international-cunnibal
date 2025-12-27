## Security, Quality, and Control Pipeline

### Automated checks (run on every PR and pushes to `main`)
- **Flutter CI**: `flutter format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test --coverage` (coverage artifact uploaded).
- **CodeQL (GitHub Advanced Security)**: security-extended queries (GitHub-native). Dart is not yet supported, so the workflow runs in build-less mode for early detection where possible.
- **Dependency Review**: blocks high-severity dependency risks during PR review.
- **Secret Scan**: `gitleaks` ensures no secrets or tokens are committed.
- **Docs & Intent Guard**:
  - Markdown linting when docs change.
  - Requires docs updates when core/architecture code changes.
  - Requires metric-focused tests to be touched when metric logic changes (prevents silent metric drift).

### Dependency hygiene
- **Dependabot**: weekly updates for GitHub Actions and Dart (pub) dependencies in grouped batches.

### Branch protection (configure in repository settings)
1. Protect `main`:
   - Require pull requests, block direct pushes and force-pushes.
   - Require branches to be up to date before merging.
   - Require status checks: `Flutter CI`, `CodeQL`, `Dependency Review`, `Secret Scan`, `Documentation and Intent Guard`.
   - Require at least one approving review.
2. Enable GitHub Advanced Security features (CodeQL and secret scanning) in repository settings.

### Local verification (fail fast)
```bash
flutter format --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

### What is protected
- **Metrics & math**: changes in motion/metric logic must update tests; CI runs coverage to guard deterministic ranges.
- **Architecture & core logic**: PRs that modify core/services/models/utils must update docs (architecture or user-facing where relevant).
- **Secrets & artifacts**: `.gitignore` blocks common secrets, credentials, and large ML artifacts; secret scanning workflow enforces this at PR time.
