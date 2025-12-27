# Coding Agent Instructions

## Pull Request Conventions

All PR titles MUST follow Conventional Commits format as enforced by `.github/workflows/semantic-pr.yml`.

### Required Format
```
<type>: <description>
```

### Valid Types
- `feat` - New features or capabilities
- `fix` - Bug fixes
- `docs` - Documentation changes
- `refactor` - Code refactoring without behavior changes
- `perf` - Performance improvements
- `test` - Test additions or changes
- `chore` - Maintenance tasks
- `ci` - CI/CD configuration changes
- `build` - Build system changes
- `revert` - Revert previous changes

### Examples
- `feat: add Flutter-native dependency security scanner`
- `fix: resolve base ref error in dependency-review workflow`
- `ci: migrate dependency-review to Flutter pub outdated`
- `docs: update security scanning documentation`

### Validation
PR titles are automatically validated by the `semantic-pr` workflow. PRs with non-compliant titles will be blocked from merging.

## Code Quality Standards

- Follow existing code style and conventions
- Run `flutter analyze` before committing
- Ensure `flutter test` passes
- Update documentation for user-facing changes
- Keep changes minimal and focused

## Security

- Never commit secrets or credentials
- Use `pubspec.lock` to ensure reproducible builds
- Avoid git dependencies (use pub.dev packages)
- Run security scans via workflows before merging
