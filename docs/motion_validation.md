# Motion Validation System

## Overview

The Motion Validation System is a quality control feature that monitors tongue movement tracking in real-time and flags inconsistent measurements. This ensures that users receive reliable feedback based on accurate data.

## What It Does

### Core Function

The system continuously checks each movement measurement to ensure it's physically plausible. If two consecutive measurements show an unrealistic velocity jump (e.g., from 10 pixels/second to 200 pixels/second instantly), the system flags the second measurement as invalid.

### User Benefit

- **Reliable Feedback**: Users get accurate performance metrics based on validated data
- **Anomaly Detection**: System automatically detects and filters sensor glitches or tracking errors
- **Trust**: Users can trust that their scores and progress reflect real performance, not sensor noise

## How It Works

### Processing Pipeline

```
Camera Frame → Position Detection → Velocity Calculation → Validation Check → Metrics
                                                             ↓
                                                    [PASS] Valid data
                                                    [FAIL] Invalid data (flagged)
```

### Validation Logic

1. **Input**: Receives a new motion measurement with position, velocity, and timestamp
2. **Compare**: Calculates the velocity change from the previous measurement
3. **Check**: Compares velocity change against a threshold (100 pixels/second)
4. **Output**: Marks the measurement as valid or invalid

### Example

```
Measurement 1: velocity = 50 px/s  ✓ (first measurement, always valid)
Measurement 2: velocity = 60 px/s  ✓ (change = 10, below threshold)
Measurement 3: velocity = 250 px/s ✗ (change = 190, exceeds threshold)
Measurement 4: velocity = 255 px/s ✓ (change = 5, below threshold)
```

## Technical Specifications

### System Properties

| Property | Value | Notes |
|----------|-------|-------|
| **Processing Speed** | <1ms per measurement | Fast enough for 30 FPS video |
| **Threshold** | 100 px/s | Velocity change limit |
| **Determinism** | 100% | Same input always produces same output |
| **Dependencies** | None | No network, no external services |
| **Data Storage** | In-memory only | No persistent storage |

### Invariants (Guarantees)

1. **First measurement is always valid**: System has no previous data to compare against
2. **Deterministic results**: Same velocity sequence always produces same validation results
3. **Bounded response time**: Each validation completes in <1ms
4. **No side effects**: Validation doesn't modify the original measurement data

### What It Does NOT Do

1. **Does not correct data**: Only flags invalid data, doesn't fix or interpolate values
2. **Does not predict**: Uses only current and previous measurement, no prediction
3. **Does not store history**: Only keeps reference to last measurement
4. **Does not make decisions**: Simply validates; other components decide how to use the flag

## Observable Behavior

### Metrics Tracking

The system tracks and reports:

- **Total Validations**: Count of all measurements processed
- **Valid Count**: Number of measurements marked valid
- **Invalid Count**: Number of measurements marked invalid
- **Validation Rate**: Percentage of valid measurements (0-100%)

### Monitoring

Metrics are emitted every ~1 second (30 validations at 30 FPS) via a data stream. This allows the system to be monitored in real-time during development and testing.

### Example Output

```
ValidationMetrics(total: 150, valid: 142, invalid: 8, rate: 94.7%)
```

This shows 150 measurements processed, with 94.7% validation rate.

## Testing

### Test Coverage

The system includes comprehensive unit tests covering:

1. **Basic Validation**
   - First measurement is valid
   - Small velocity changes are valid
   - Large velocity changes are invalid
   - Boundary conditions (at threshold)

2. **Statistics Tracking**
   - Accurate counting of validations
   - Correct valid/invalid separation
   - Accurate validation rate calculation

3. **State Management**
   - Reset clears all state
   - Fresh start after reset

4. **Determinism**
   - Same inputs produce same outputs
   - Repeatable validation results

5. **Edge Cases**
   - Zero velocity
   - Negative velocity
   - Velocity sign changes

### Running Tests

```bash
flutter test test/motion_validation_controller_test.dart
```

Expected output: All tests pass, 25+ test cases

## Integration

### In the Application

The Motion Validation Controller is used by the NeuralEngine service:

```
User tongue movement
    ↓
Camera captures frame (30 FPS)
    ↓
CV engine detects position/velocity
    ↓
NeuralEngine receives TongueData
    ↓
MotionValidationController.validate()  ← Validation happens here
    ↓
Validated data buffered for metrics
    ↓
Metrics calculated and displayed
```

### Code Integration Point

Located in: `lib/services/neural_engine.dart`

```dart
void processTongueData(TongueData data) {
  // Validate motion data consistency
  final validated = _validator.validate(data);
  
  // Continue processing with validated data
  _dataBuffer.add(validated);
  // ...
}
```

## Failure Modes

### Detectable Failures

1. **High Invalid Rate**: If >20% of measurements are invalid, may indicate:
   - Poor lighting conditions
   - Camera obstruction
   - Tracking model issues
   - Excessive user movement

2. **Zero Validations**: If no measurements are being processed:
   - System not started
   - Camera not providing data
   - Processing pipeline stalled

### Detection

Monitor the `validationRate` metric:
- **>90%**: Normal operation
- **70-90%**: Degraded tracking quality
- **<70%**: Poor tracking, consider alerting user

## Performance

### Benchmarks

| Metric | Value |
|--------|-------|
| Validation time | <0.1ms per measurement |
| Memory usage | <1KB (single previous measurement) |
| CPU usage | <1% on modern devices |

### Scalability

- Handles 30 FPS (30 validations/second) easily
- Can handle up to 120 FPS if needed
- No accumulation of state over time
- Constant memory footprint

## Acceptance Criteria

### Feature Complete When:

- [x] Validation logic correctly compares velocity changes
- [x] Statistics accurately track valid/invalid counts
- [x] Validation rate is calculated correctly
- [x] System is deterministic (same input → same output)
- [x] Response time is <1ms per validation
- [x] All unit tests pass
- [x] Integration with NeuralEngine works
- [x] Documentation explains feature without AI terminology
- [x] Metrics are observable via stream
- [x] CI tests pass

## Future Enhancements

Potential improvements (not in current scope):

1. **Adaptive Thresholds**: Adjust threshold based on user's typical movement patterns
2. **Multi-Factor Validation**: Consider acceleration, position drift, and other factors
3. **Validation History**: Track validation trends over time
4. **User Alerts**: Notify users when validation rate drops significantly
5. **Configurable Thresholds**: Allow threshold adjustment for different use cases

## Glossary

- **Measurement**: A single data point with timestamp, position, velocity, acceleration
- **Validation**: Process of checking if a measurement is physically plausible
- **Threshold**: Maximum allowed velocity change between consecutive measurements
- **Validation Rate**: Percentage of measurements that pass validation
- **Deterministic**: Always produces the same output for the same input

## References

- Implementation: `lib/services/motion_validation_controller.dart`
- Tests: `test/motion_validation_controller_test.dart`
- Integration: `lib/services/neural_engine.dart`
- Architecture: `ARCHITECTURE.md`
