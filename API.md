# API Documentation

## NeuralEngine

### Overview
Implements Anokhin's Action Acceptor theory for sensory-motor validation.

### Methods

#### `start()`
Starts the neural engine processing.

```dart
void start()
```

**Side Effects:**
- Starts metrics calculation timer (1s interval)
- Clears data buffer
- Sets processing state to active

#### `stop()`
Stops the neural engine processing.

```dart
void stop()
```

**Side Effects:**
- Cancels metrics timer
- Sets processing state to inactive
- Preserves data buffer

#### `processTongueData(TongueData data)`
Processes incoming tongue biomechanics data.

```dart
void processTongueData(TongueData data)
```

**Parameters:**
- `data`: TongueData object containing biomechanics information

**Behavior:**
1. Adds data to buffer (maintains buffer size)
2. Applies Action Acceptor validation
3. Emits validated data via stream

#### `tongueDataStream`
Stream of validated tongue data.

```dart
Stream<TongueData> get tongueDataStream
```

**Returns:** Broadcast stream of TongueData

#### `metricsStream`
Stream of calculated biometric metrics.

```dart
Stream<BiometricMetrics> get metricsStream
```

**Returns:** Broadcast stream of BiometricMetrics

## BioTrackingService

### Methods

#### `initializeCamera()`
Initializes camera for bio-tracking.

```dart
Future<void> initializeCamera()
```

**Returns:** Future that completes when camera is ready

**Throws:** Exception if no cameras available

#### `startTracking()`
Starts real-time bio-tracking.

```dart
Future<void> startTracking()
```

**Side Effects:**
- Initializes camera if needed
- Starts NeuralEngine
- Begins frame processing at 30 FPS

#### `stopTracking()`
Stops bio-tracking.

```dart
void stopTracking()
```

**Side Effects:**
- Stops frame processing
- Stops NeuralEngine
- Camera remains initialized

#### `isTracking`
Current tracking state.

```dart
bool get isTracking
```

**Returns:** True if tracking is active

## SymbolDictationService

### Methods

#### `startSession(String symbol)`
Starts a new dictation session.

```dart
void startSession(String symbol)
```

**Parameters:**
- `symbol`: Single letter A-Z

**Throws:** ArgumentError if symbol is invalid

#### `stopSession()`
Stops the current dictation session.

```dart
void stopSession()
```

#### `sessionStream`
Stream of dictation session updates.

```dart
Stream<DictationSession> get sessionStream
```

**Returns:** Broadcast stream of DictationSession

#### `targetSymbol`
Current target symbol.

```dart
String get targetSymbol
```

**Returns:** Current symbol (A-Z)

## GitHubExportService

### Methods

#### `logMetrics(BiometricMetrics metrics)`
Logs a metrics data point.

```dart
void logMetrics(BiometricMetrics metrics)
```

**Parameters:**
- `metrics`: BiometricMetrics object to log

**Side Effects:**
- Adds to metrics log
- Auto-exports after 100 entries

#### `logSession(DictationSession session)`
Logs a dictation session.

```dart
void logSession(DictationSession session)
```

**Parameters:**
- `session`: DictationSession object to log

#### `exportPerformanceLog()`
Exports performance log to JSON file.

```dart
Future<String> exportPerformanceLog()
```

**Returns:** Future with file path of exported log

**File Format:**
- JSON with metrics, sessions, and summary
- Named: `performance_log_YYYYMMDD_HHMMSS.json`
- Location: Application documents directory

#### `clearLogs()`
Clears all logged data.

```dart
void clearLogs()
```

## Data Models

### TongueData

```dart
class TongueData {
  final DateTime timestamp;
  final Offset position;        // Normalized (0-1)
  final double velocity;        // Pixels per second
  final double acceleration;    // Pixels per second squared
  final List<Offset> landmarks; // MediaPipe landmarks
  final bool isValidated;       // Action Acceptor validation
}
```

### BiometricMetrics

```dart
class BiometricMetrics {
  final double consistencyScore;  // 0-100 (inverse std dev)
  final double frequency;         // Hz
  final List<double> pcaVariance; // [PC1, PC2, PC3] percentages
  final DateTime timestamp;
}
```

### DictationSession

```dart
class DictationSession {
  final String targetSymbol;              // A-Z
  final DateTime startTime;
  final List<double> rhythmTimestamps;    // Seconds from start
  final double synchronizationScore;      // 0-100
  
  // Computed property
  double get rhythmConsistency;           // 0-100
}
```

## Streams

All services use broadcast streams for reactive updates:

- **Hot streams**: Start emitting when first listener subscribes
- **Broadcast**: Multiple listeners supported
- **Error handling**: Errors propagated to listeners
- **Disposal**: Close streams in dispose() methods

## Error Handling

Services handle errors gracefully:
- Camera errors: Show user-friendly messages
- Export errors: Return error info without crashing
- Invalid input: Throw descriptive ArgumentError
