# Contributing to International Cunnibal

Thank you for your interest in contributing to International Cunnibal! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Maintain professionalism in all interactions

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/international-cunnibal.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

## Development Setup

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / Xcode (for platform-specific development)
- Dart SDK (included with Flutter)

### Installation
```bash
flutter pub get
flutter run
```

### Running Tests
```bash
flutter test
```

## Code Style

### Dart/Flutter Guidelines
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Prefer `const` constructors when possible
- Use meaningful variable and function names

### File Organization
```
lib/
├── models/      # Data models only
├── services/    # Business logic, no UI
├── screens/     # Full-page UI components
├── widgets/     # Reusable UI components
└── utils/       # Helper functions
```

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Functions/Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE` or `camelCase` for const
- Private members: prefix with `_`

## Architecture Guidelines

### Services
- Use singleton pattern for services
- Keep services stateless where possible
- Use streams for reactive data
- Document public APIs with dartdoc comments

### Models
- Keep models immutable
- Provide `copyWith` methods for updates
- Implement `toJson` for serialization
- Use `@immutable` annotation

### UI Components
- Separate business logic from presentation
- Use `StreamBuilder` for reactive updates
- Extract reusable widgets
- Keep widget trees shallow

## Testing Guidelines

### Unit Tests
- Test all business logic
- Mock external dependencies
- Aim for >80% code coverage
- Use descriptive test names

Example:
```dart
test('NeuralEngine calculates consistency score correctly', () {
  // Arrange
  // Act
  // Assert
});
```

### Widget Tests
- Test UI interactions
- Verify state changes
- Test error states
- Use `pumpWidget` and `pump`

### Integration Tests
- Test complete user flows
- Use real services (or mocked external APIs)
- Verify end-to-end functionality

## Pull Request Process

1. **Update Documentation**: Ensure README, API docs, etc. are updated
2. **Add Tests**: All new features need tests
3. **Run Tests**: Ensure all tests pass
4. **Code Review**: Address all review comments
5. **Clean Commits**: Squash commits if requested

## Engineering Constitution (2025)

This repository is governed by the **Technical Constitution and Architectural Foundation** documented in
[`ENGINEERING_HANDBOOK.md`](ENGINEERING_HANDBOOK.md). All contributors are expected to follow its principles.

### Critical Protocol: \"No Ghosts\"
- **Rule:** No logic exists without a test. No model exists without a benchmark.
- **Enforcement:** Any PR touching ML logic must include a screenshot or log output from `LatencyBenchmark`
  executed on a physical device.

### Model Integration Standard
When adding a new `.tflite` or `.mlmodel`:
1. Add the source file under `ml-ops/models/`.
2. Run `dvc add ml-ops/models/new_model.tflite`.
3. Commit the generated `.dvc` file.
4. Update `model_card.md` with model provenance, accuracy metrics, and intent.
5. Update `Constants.kt` / `Constants.swift` with the new model path.

### 16ms Barrier Protocol
- **Android:** Use `suspend` functions for ML interactions and `withContext(Dispatchers.Default)` for tensor
  pre-processing.
- **iOS:** Run Vision/ML work on a background `DispatchQueue` or `Task`, update UI only on `MainActor`.
- **Violation:** Any profiler log indicating a dropped frame triggers mandatory refactoring.

### PR Title Format
```
[Type] Brief description

Types: Feature, Fix, Docs, Refactor, Test, Chore
```

Example: `[Feature] Add rhythm pattern validation for symbols`

### PR Description Template
```markdown
## Description
Brief description of changes

## Related Issue
Closes #123

## Changes Made
- Change 1
- Change 2

## Testing Done
- Test 1
- Test 2

## Screenshots (if applicable)
[Add screenshots]
```

## Feature Requests

1. Check existing issues first
2. Open a new issue with:
   - Clear description
   - Use cases
   - Expected behavior
   - Any relevant examples

## Bug Reports

Include:
- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs if applicable
- Device/OS information
- App version

## Areas for Contribution

### High Priority
- [ ] Integrate actual TFLite models for tongue detection
- [ ] Add comprehensive metrics visualization
- [ ] Implement progress tracking over time
- [ ] Add user profiles/multi-user support

### Medium Priority
- [ ] Improve Symbol Dictation pattern matching
- [ ] Add more sophisticated PCA analysis
- [ ] Create tutorial/onboarding flow
- [ ] Add accessibility features

### Documentation
- [ ] Video tutorials
- [ ] API usage examples
- [ ] Performance optimization guide
- [ ] Deployment guide

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
