# Architecture

## Overview

International Cunnibal implements a clean architecture pattern with clear separation of concerns:

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── tongue_data.dart
│   ├── metrics.dart
│   └── dictation_session.dart
├── services/                 # Business logic layer
│   ├── neural_engine.dart
│   ├── bio_tracking_service.dart
│   ├── symbol_dictation_service.dart
│   └── github_export_service.dart
├── core/                     # Pure math / signal processing
│   └── motion_metrics.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── tracking_screen.dart
│   ├── dictation_screen.dart
│   └── metrics_screen.dart
└── widgets/                  # Reusable UI components
    └── tracking_overlay.dart
```

## Core Components

### NeuralEngine
The heart of the application, implementing Anokhin's Action Acceptor theory and feeding MotionMetrics:

**Responsibilities:**
- Process incoming tongue biomechanics data
- Validate motor patterns against expected outcomes
- Calculate real-time metrics (consistency, frequency, direction, intensity, pattern)
- Stream processed data to UI components

**Key Features:**
- Singleton pattern for global access
- Stream-based architecture for reactive updates
- Buffer management for statistical analysis
- Action Acceptor pattern implementation

### BioTrackingService
Handles real-time tongue tracking via camera:

**Responsibilities:**
- Camera initialization and management
- Frame processing at 30 FPS
- TFLite model integration (placeholder for actual model)
- Landmark detection and extraction
- Demo CV engine provides deterministic simulated motion when no camera/model is used

**Integration Points:**
- Sends TongueData to NeuralEngine
- Provides camera preview to UI
- Manages camera lifecycle

### SymbolDictationService
Implements the A-Z symbol dictation feature:

**Responsibilities:**
- Manage dictation sessions for symbols A-Z
- Pattern matching using rhythm signatures (Morse-inspired)
- Calculate synchronization scores
- Track rhythm consistency

**Pattern System:**
- Each letter has a unique rhythm signature
- Short movements (0.2s) and long movements (0.6s)
- Real-time comparison with expected patterns

### GitHubExportService
Handles performance log generation and export:

**Responsibilities:**
- Log all metrics and sessions
- Generate JSON export files
- Calculate summary statistics
- Provide export directory management

**Export Format:**
```json
{
  "exportTimestamp": "ISO8601",
  "appVersion": "1.0.0",
  "totalMetrics": 100,
  "totalSessions": 10,
  "metrics": [...],
  "sessions": [...],
  "summary": {...}
}
```

## Data Flow

1. **Camera Frame** → BioTrackingService
2. **Tongue Detection** → TongueData model
3. **TongueData** → NeuralEngine (Action Acceptor)
4. **Validated TongueData** → UI (via Stream)
5. **Metrics Calculation** → BiometricMetrics
6. **Metrics** → GitHubExportService (logging)
7. **Export** → JSON file (on-device)

## Design Patterns

### Singleton Pattern
All services use singleton pattern for global state management:
- NeuralEngine
- BioTrackingService
- SymbolDictationService
- GitHubExportService

### Stream Pattern
Reactive architecture using Dart Streams:
- Real-time data updates
- Efficient UI rendering
- Decoupled components

### Model-View Architecture
Clear separation between data, logic, and presentation:
- Models: Pure data classes with serialization
- Services: Business logic and state management
- Screens/Widgets: UI presentation layer

## Privacy by Design

All processing happens on-device:
- TFLite models run locally
- No network requests for core functionality
- Data stored locally only
- User has full control over exports

## Testing Strategy

- Unit tests for models (data integrity)
- Service tests (business logic)
- Widget tests (UI components)
- Integration tests (end-to-end flows)

## Future Enhancements

1. **ML Model Integration**: Replace simulated tracking with actual TFLite model
2. **Advanced Metrics**: Add more sophisticated PCA analysis
3. **Cloud Sync**: Optional cloud backup (with user consent)
4. **Multi-user Support**: Track multiple users/profiles
5. **Progress Tracking**: Historical performance charts
