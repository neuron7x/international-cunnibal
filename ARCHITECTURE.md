# Architecture

## AI System Boundary

### Canonical AI Processing Flow (8 Steps)

This section defines the single source of truth for how AI/ML integrates with the Flutter app:

1. **Input Capture** → Camera frames (30 FPS) or demo synthesis via `CvEngine`
2. **ML Inference** → MediaPipe/TFLite landmark detection in `MediaPipeService` (on-device only)
3. **Data Normalization** → Raw landmarks → `TongueData` model (position, velocity, acceleration)
4. **Quality Validation** → `MotionValidationController` flags invalid measurements
5. **Buffering & Analysis** → `NeuralEngine` maintains 100-sample buffer for statistics
6. **Metrics Computation** → `MotionMetrics` calculates consistency, frequency, direction, intensity (pure math, no ML)
7. **Game Logic Integration** → `GameLogicService` consumes metrics, updates progression state
8. **UI Feedback** → Streams to Flutter widgets for real-time display and export logging

**Privacy Guarantee:** All processing happens on-device. No data leaves the phone.

### Where AI/ML Lives

#### On-Device Runtime (Production)
- **`lib/services/ml/mediapipe_service.dart`** - TFLite interpreter, model loading, inference
- **`lib/services/ui/cv_engine.dart`** - Camera/demo abstraction, frame preprocessing
- **`lib/services/ui/bio_tracking_service.dart`** - Orchestrates CV engine, streams to NeuralEngine
- **`assets/models/*.tflite`** - Binary model files (loaded at runtime via tflite_flutter package)

#### Processing Pipeline (No ML)
- **`lib/services/neural_engine.dart`** - Data buffering, validation orchestration, metrics streaming
- **`lib/services/motion_validation_controller.dart`** - Quality checks (deterministic logic, not ML)
- **`lib/core/motion_metrics.dart`** - Pure signal processing (FFT, PCA, statistics)
- **`lib/core/endurance_metrics.dart`** - Jaw aperture calculations (geometry, not ML)

#### Offline/Training-Only (Not in App)
- **`ml-ops/models/`** - DVC-tracked model binaries (training artifacts)
- **`ml-ops/model_cards/`** - Model documentation, provenance, performance metrics
- **`ml-ops/benchmarks/`** - Offline performance evaluation logs
- **`scripts/download_model.py`** - Development utility to fetch models (not used at runtime)

#### Development & CI
- **`tool/run_demo.dart`** - Standalone demo runner (no ML needed)
- **`tool/benchmark_core.dart`** - Performance benchmarking for MotionMetrics
- **`tool/verify_logic.dart`** - Logic validation without camera/models
- **`tool/ci/*.py`** - Architecture boundary checks, latency budgets, privacy guards

### Module Responsibilities (No Overlap)

| Layer | Modules | Responsibility | Dependencies |
|-------|---------|----------------|--------------|
| **ML Inference** | `lib/services/ml/*` | TFLite model loading, landmark detection | tflite_flutter, camera |
| **CV Abstraction** | `lib/services/ui/cv_engine.dart` | Camera/demo mode switching, frame streaming | camera package |
| **Data Pipeline** | `lib/services/neural_engine.dart` | Orchestration, buffering, streaming | Core services |
| **Signal Processing** | `lib/core/motion_metrics.dart` | Pure math (FFT, PCA, stats), no Flutter imports | vector_math only |
| **Business Logic** | `lib/services/game_logic_service.dart` | Progression, targets, level-up | Metrics only |
| **UI Presentation** | `lib/screens/*`, `lib/widgets/*` | Display, user interaction | Flutter framework |
| **Persistence** | `lib/services/ui/github_export_service.dart` | JSON export (user-triggered only) | path_provider |

**Boundary Rules:**
- Core (`lib/core/`) MUST NOT import Flutter or services (enforced by `tool/ci/check_architecture_boundaries.py`)
- Services MUST NOT perform UI rendering
- ML inference ONLY in `lib/services/ml/` - all other layers are ML-free
- Models MUST be tracked in `ml-ops/` with DVC, never committed to Git as binaries

### Demo Mode vs Real Tracking

The app supports two modes with clear boundaries:

**Demo Mode (Default):**
- `DemoCvEngine` generates synthetic data (sine waves + noise)
- No camera, no model loading, no permissions needed
- Perfect for development, CI, and offline testing
- Falls back automatically if model loading fails

**Real Tracking Mode:**
- `CameraCvEngine` captures frames, `MediaPipeService` runs inference
- Requires camera permission and valid TFLite model in `assets/models/`
- User explicitly enables via settings toggle
- Status tracked: `notLoaded` → `loading` → `loaded` / `loadFailed`

**Switching Logic:** `BioTrackingService` coordinates mode selection, handles graceful fallback.

### Non-Goals

This architecture explicitly DOES NOT:
- ❌ Send data to cloud or external servers (100% on-device)
- ❌ Perform model training at runtime (training is offline only)
- ❌ Use ML for signal processing (core math is deterministic, not learned)
- ❌ Store raw camera frames (only extracted landmarks with privacy filters)
- ❌ Require internet connectivity (works fully offline)
- ❌ Share models between users (each device loads from local assets)
- ❌ Perform online learning or model updates (static models)

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
│   ├── symbol_dictation_service.dart
│   ├── ui/                   # UI/platform-facing services
│   │   ├── bio_tracking_service.dart
│   │   ├── cv_engine.dart
│   │   └── github_export_service.dart
│   └── endurance_session_service.dart
├── core/                     # Pure math / signal processing
│   ├── motion_metrics.dart
│   └── endurance_metrics.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── tracking_screen.dart
│   ├── dictation_screen.dart
│   └── metrics_screen.dart
└── widgets/                  # Reusable UI components
    └── tracking_overlay.dart
```

For the end-to-end data and AI pipeline (ingestion → processing → export) see the [Data & AI Architecture Blueprint](docs/data_architecture.md).

## Core Components

### NeuralEngine
The central coordinator for biomechanics processing and metrics calculation:

**Responsibilities:**
- Process incoming tongue biomechanics data from camera pipeline
- Validate motion data consistency to ensure quality measurements
- Calculate real-time metrics (consistency, frequency, direction, intensity, pattern)
- Stream processed data to UI and game logic components

**Key Features:**
- Singleton pattern for global access
- Stream-based architecture for reactive updates
- Buffer management for statistical analysis (100 samples)
- Motion validation for quality control (see [Motion Validation](docs/motion_validation.md))

**Processing Pipeline:**
```
Camera → TongueData → Validation → Buffer → Metrics → UI/Game
                         ↓
                   Quality Check (MotionValidationController)
```

### MotionValidationController
**NEW:** Concrete system component for data quality validation

**Responsibility:**
Validates biomechanics data consistency in real-time by detecting measurement anomalies.

**How it works:**
- Compares consecutive velocity measurements
- Flags data as invalid if velocity change exceeds threshold (100 px/s)
- Tracks validation statistics (validation rate, valid/invalid counts)
- Deterministic: same input always produces same output

**Guarantees:**
- Bounded response time (<1ms per validation)
- No external dependencies (on-device only)
- Observable via metrics stream

See [Motion Validation Documentation](docs/motion_validation.md) for details.

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
- Build aggregated JSON payloads
- Calculate summary statistics
- Delegate file I/O to `ExportFileWriter` in `lib/utils/export_file_writer.dart`

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
3. **TongueData** → NeuralEngine
4. **Motion Validation** → MotionValidationController (quality check)
5. **Validated TongueData** → UI (via Stream)
6. **Metrics Calculation** → BiometricMetrics
7. **Metrics** → GitHubExportService (logging)
8. **Export** → JSON file (on-device) via `ExportFileWriter`
9. **Jaw Endurance Loop (optional)** → EnduranceEngine → EnduranceGameLogicService
10. **Couple Dashboard (opt-in)** → informational comparison only

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

## Dual-Partner Skill Model

- **Symmetric skills**: Motion (tongue control) and Endurance (jaw aperture) run side by side with independent progression ladders.
- **EnduranceEngine**: Consumes MediaPipe Face Mesh landmarks (13, 14, 78, 308) when available and falls back to bounded demo synthesis when sensors are absent. Outputs aperture, stability, endurance time, and normalized endurance score.
- **Independent progression**: `GameLogicService` and `EnduranceGameLogicService` maintain separate targets/levels; no cross-coupling of rewards.
- **Couple dashboard**: `CoupleDashboard` model presents consistency ↔ endurance, vector accuracy ↔ aperture stability, and level ↔ level without ranking.
- **Consent-first**: Endurance mode and comparisons are opt-in in the UI; no automatic partner comparisons are triggered.

## Endurance Engine & Safety Guarantees

- **Endurance engine role**: `EnduranceEngine` consumes aperture samples and computes deterministic, bounded metrics: aperture, stability (tremor index), endurance time, fatigue indicator, and a 0–100 endurance score.
- **Session safety**: The endurance session flow is ready → hold → rest → summary with hard limits on aperture bounds, maximum session duration, cooldown intervals, and auto-stop on fatigue thresholds.
- **Auto-pause controls**: Sudden stability drops trigger rest prompts; hold time only accumulates under stable, in-bounds conditions.

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
