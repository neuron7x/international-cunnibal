## Security, Quality, and Control Pipeline

### Automated checks (run on every PR and pushes to `main`)
- **CI Meta Guard**: blocks invalid action versions in workflows.
- **Code Scanning Results (CodeQL)**: summarizes CodeQL results for PRs.
- **CodeQL (GitHub Advanced Security)**: security-extended queries (build-less JS scan until Dart is supported).
- **Secret Scan**: `gitleaks` ensures no secrets or tokens are committed.
- **Documentation and Intent Guard**:
  - Requires docs updates when core/architecture code changes.
  - Requires metric-focused tests to be touched when metric logic changes.

### Dependency hygiene
- **Dependabot**: weekly updates for GitHub Actions and Dart (pub) dependencies in grouped batches.

### Branch protection (configure in repository settings)
1. Protect `main`:
   - Require pull requests, block direct pushes and force-pushes.
   - Require branches to be up to date before merging.
   - Require status checks:
     - `CI Meta Guard / workflow-guard`
     - `Code Scanning Results / CodeQL`
     - `CodeQL / CodeQL analysis`
     - `Documentation and Intent Guard / intent-guard`
     - `Documentation and Intent Guard / metrics-guard`
     - `Secret Scan / gitleaks`
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
