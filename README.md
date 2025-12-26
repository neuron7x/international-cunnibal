# International Cunnibal

**Train, Dominate, Savor.**

Neural Biofeedback Engine for Precision Oral Biomechanics and Sensory-Motor Synchronization.

## Overview

International Cunnibal is a Flutter application that implements a sophisticated neural biofeedback system for real-time tongue biomechanics tracking and analysis. Built on Anokhin's Action Acceptor theory, the app provides advanced sensory-motor synchronization training through on-device AI processing.

## Features

### 1. Bio-Tracking
Real-time tongue biomechanics tracking via MediaPipe/TFLite integration:
- High-frequency camera-based tracking (30 FPS)
- Landmark detection for precise position tracking
- Velocity and acceleration calculations
- Action Acceptor validation for movement consistency

### 2. Biometric Metrics
Comprehensive performance analytics:
- **Consistency Score**: Standard deviation-based measurement (0-100%)
- **Frequency Analysis**: Movement frequency in Hz
- **Vector PCA**: Principal Component Analysis for dimensional reduction
- Real-time metric updates

### 3. Symbol Dictation (A-Z)
Partner-led rhythmic synchronization feature:
- 26 unique rhythm patterns (A-Z) based on Morse code
- Real-time synchronization scoring
- Rhythm consistency analysis
- Interactive symbol selection interface

### 4. Infrastructure
Privacy-focused on-device processing:
- On-device AI using TFLite for complete privacy
- Automated GitHub performance log exports (JSON format)
- Comprehensive session logging
- No cloud processing required

## Architecture

### NeuralEngine Service
Implements Anokhin's Action Acceptor theory (Reference: 2025-11-30):
- Processes afferent (sensory) input from tongue tracking
- Compares actual movements with expected patterns
- Validates motor command execution
- Provides real-time feedback for sensory-motor learning

### Services
- **BioTrackingService**: Camera integration and biomechanics detection
- **NeuralEngine**: Action Acceptor implementation and data processing
- **SymbolDictationService**: Rhythm pattern matching and synchronization
- **GitHubExportService**: Performance log generation and export

### Data Models
- **TongueData**: Biomechanics data with landmarks and validation status
- **BiometricMetrics**: Calculated performance metrics
- **DictationSession**: Symbol dictation session data with rhythm analysis

## Technical Stack

- **Framework**: Flutter 3.0+
- **AI/ML**: TensorFlow Lite (TFLite) for on-device inference
- **Computer Vision**: MediaPipe-style landmark detection
- **Camera**: camera package for real-time video capture
- **Data Export**: JSON format for GitHub integration

## Installation

1. Clone the repository:
```bash
git clone https://github.com/neuron7x/international-cunnibal.git
cd international-cunnibal
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Usage

### Bio-Tracking Mode
1. Navigate to "Bio-Tracking" from the home screen
2. Grant camera permissions
3. Tap "START TRACKING" to begin real-time tracking
4. View live biomechanics data and validation status
5. Tap "STOP TRACKING" when done

### Symbol Dictation Mode
1. Navigate to "Symbol Dictation" from the home screen
2. Select a target symbol (A-Z)
3. Tap "START DICTATION"
4. Perform rhythmic tongue movements matching the symbol's pattern
5. Monitor synchronization score and rhythm consistency
6. Tap "STOP DICTATION" when done

### Metrics Dashboard
1. Navigate to "Metrics Dashboard" from the home screen
2. View real-time biometric metrics:
   - Consistency Score (based on std dev)
   - Movement Frequency (Hz)
   - Vector PCA (principal components)
3. Tap the download icon to export performance logs
4. Logs are saved as JSON files with timestamp

## Performance Logs

Exported logs include:
- Timestamp and app version
- All recorded biometric metrics
- Dictation session data
- Summary statistics (averages, totals)
- Rhythm analysis for each session

Example export location:
```
/Documents/performance_log_20251226_120000.json
```

## References

- Anokhin's Action Acceptor theory (2025-11-30)
- Real-time tongue biomechanics via MediaPipe/TFLite (2025-11-30)
- Metrics: Consistency Score (Std Dev), Frequency (Hz), Vector PCA (2025-11-30)
- On-device AI for privacy & automated GitHub performance log exports (2025-11-30)

## Privacy

All processing is done on-device. No data is sent to external servers. The app uses:
- Local TFLite models for AI inference
- Local storage for performance logs
- No network connectivity required for core functionality

## License

Copyright © 2025 International Cunnibal Project

## Contributing

This project follows clean code principles and Flutter best practices. Contributions should maintain:
- Clear separation of concerns
- Comprehensive documentation
- Type safety
- Privacy-first design
