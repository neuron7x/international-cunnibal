# Quick Start Guide

## AI System at a Glance

**International Cunnibal** uses on-device AI for tongue biomechanics tracking. Here's what you need to know:

### Two Operating Modes

1. **Demo Mode (Default)** - No setup needed
   - Simulated data generation
   - No camera or ML models required
   - Perfect for development and testing
   - Run immediately: `flutter run`

2. **Real Tracking Mode** - Production use
   - Requires camera permissions
   - Loads TFLite model from `assets/models/`
   - 100% on-device inference (no cloud)
   - Enable via app settings

### AI Pipeline (8 Steps)

```
Camera → TFLite Landmarks → Normalization → Validation → 
Buffer → Metrics (FFT/PCA) → Game Logic → UI Feedback
```

**Key Point:** Only Step 2 (TFLite) uses ML. Steps 3-8 are deterministic math and business logic.

### Where AI Code Lives

- **ML Inference**: `lib/services/ml/mediapipe_service.dart`
- **Camera/Demo**: `lib/services/ui/cv_engine.dart`
- **Signal Processing**: `lib/core/motion_metrics.dart` (pure math, no ML)
- **Orchestration**: `lib/services/neural_engine.dart`

See [ARCHITECTURE.md](ARCHITECTURE.md#ai-system-boundary) for detailed system boundary documentation.

---

## Installation

### 1. Install Flutter
Download and install Flutter SDK from [flutter.dev](https://flutter.dev)

### 2. Clone Repository
```bash
git clone https://github.com/neuron7x/international-cunnibal.git
cd international-cunnibal
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Run on Device/Simulator
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

## Key Commands

### Development
```bash
# Run with hot reload
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios
```

## Project Structure Quick Reference

```
lib/
├── main.dart                          # App entry point
│
├── models/                            # Data models
│   ├── tongue_data.dart              # Biomechanics data
│   ├── metrics.dart                  # Calculated metrics
│   └── dictation_session.dart        # Dictation session data
│
├── services/                          # Business logic
│   ├── neural_engine.dart            # Action Acceptor implementation
│   ├── bio_tracking_service.dart     # Camera & tracking
│   ├── symbol_dictation_service.dart # Symbol rhythm matching
│   └── github_export_service.dart    # Log export
│
├── screens/                           # Full page UIs
│   ├── home_screen.dart              # Main menu
│   ├── tracking_screen.dart          # Bio-tracking UI
│   ├── dictation_screen.dart         # Symbol dictation UI
│   └── metrics_screen.dart           # Metrics dashboard
│
└── widgets/                           # Reusable components
    └── tracking_overlay.dart          # Camera overlay
```

## Common Tasks

### Add a New Screen
1. Create file in `lib/screens/`
2. Implement StatefulWidget or StatelessWidget
3. Add navigation from home_screen.dart
4. Test UI

### Add a New Service
1. Create file in `lib/services/`
2. Implement singleton pattern
3. Add business logic
4. Add tests in `test/`

### Add a New Model
1. Create file in `lib/models/`
2. Define class with final fields
3. Add `toJson()` method
4. Add `copyWith()` if mutable operations needed
5. Add tests

### Modify Metrics Calculation
Edit `lib/services/neural_engine.dart`:
- `_calculateConsistencyScore()` - Consistency metric
- `_calculateFrequency()` - Frequency metric
- `_calculatePCA()` - PCA variance

## Debugging

### Enable Debug Mode
```bash
flutter run --debug
```

### View Logs
```bash
# All logs
flutter logs

# Filter logs
flutter logs | grep "NeuralEngine"
```

### Inspector
```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/neural_engine_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Common Issues

### Camera Permission Denied
- Android: Check `android/app/src/main/AndroidManifest.xml`
- iOS: Check `ios/Runner/Info.plist`

### Build Fails
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

### Hot Reload Not Working
- Press 'r' in terminal to reload
- Press 'R' for hot restart
- Check for syntax errors

## Performance Tips

1. **Use const constructors** - Improves performance
2. **Avoid rebuilding** - Use StreamBuilder efficiently
3. **Profile with DevTools** - Find bottlenecks
4. **Test on real devices** - Simulators can be slower

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)

## Getting Help

1. Check [Issues](https://github.com/neuron7x/international-cunnibal/issues)
2. Read [ARCHITECTURE.md](ARCHITECTURE.md)
3. Read [API.md](API.md)
4. Open a new issue with question label
