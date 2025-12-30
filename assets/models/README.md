# TFLite Models

This directory contains TensorFlow Lite models for on-device AI processing.

## Required Models

### tongue_detector.tflite
A MediaPipe-based facial landmark detection model adapted for tongue tracking.

**⚠️ Current Status:**
The included `tongue_detector.tflite` is a **placeholder text file** for demonstration purposes.
It will cause graceful fallback to demo mode when loaded. For production use, replace with an
actual trained TFLite binary model.

**Model Requirements:**
- Input: RGB image (320x320 or 640x480)
- Output: Facial landmarks (468 points) with confidence scores
- Format: TFLite with float32 inference

**Training Dataset:**
The model should be trained on a dataset of facial images with annotated tongue positions and landmarks.

### labels.txt
Label file containing landmark indices and names.

**Format:**
- Each line contains a landmark index (integer)
- Lines starting with `#` are comments
- Empty lines are ignored
- Indices correspond to tongue-relevant landmarks from the 468-point face mesh

**Example:**
```
# Tongue Landmark Indices
13   # Lower lip bottom
14   # Lower lip center
78   # Upper lip (left inner)
308  # Upper lip (right inner)
```

**Usage:**
The service loads these indices to identify which landmarks from the full face mesh
are relevant for tongue tracking. This allows focusing processing on tongue-specific
points rather than the entire face mesh.

**Interpreting labels.txt:**
1. Load the file line by line
2. Skip comment lines (starting with #) and empty lines
3. Parse remaining lines as integers
4. Use these indices to filter the 468-point face mesh output
5. Extract only the specified landmarks for tongue tracking

## Model Integration

The BioTrackingService in `lib/services/ui/bio_tracking_service.dart` is prepared to load and use these models. Currently, the service uses simulated data for demonstration purposes.

To integrate actual models:

1. Place `tongue_detector.tflite` in this directory
2. Place `labels.txt` in this directory
3. Update the model loading code in `BioTrackingService.loadModel()`
4. Implement the TFLite inference in `_processFrame()`

## Enabling Camera Mode

The app supports two tracking modes:

**Demo Mode (Default):**
- No model loading required
- Simulated data for testing
- No camera permissions needed
- Perfect for development and testing

**Real Tracking Mode:**
To enable real camera tracking:

1. Ensure model files are present in `assets/models/`
2. Call `BioTrackingService().loadModel()` on app start
3. Set mode to camera: `service.setMode(CvEngineMode.camera)`
4. Grant camera permissions when prompted
5. Check `service.isRealTrackingEnabled` to verify model loaded successfully
6. If model loading fails, service automatically falls back to demo mode

**Status Tracking:**
- `TrackingStatus.notLoaded` - Model not yet loaded
- `TrackingStatus.loading` - Model loading in progress
- `TrackingStatus.loaded` - Model ready, real tracking available
- `TrackingStatus.loadFailed` - Model load failed, using demo fallback
- `TrackingStatus.demo` - Demo mode active

**Example:**
```dart
final service = BioTrackingService();
await service.loadModel();

if (service.status == TrackingStatus.loaded) {
  await service.setMode(CvEngineMode.camera);
  await service.startTracking();
} else {
  // Fallback to demo mode
  await service.setMode(CvEngineMode.demo);
  await service.startTracking();
}
```

## Privacy Note

All model inference runs on-device. No data is sent to external servers, ensuring complete user privacy.

## References

- MediaPipe Face Mesh: https://google.github.io/mediapipe/solutions/face_mesh
- TensorFlow Lite: https://www.tensorflow.org/lite
- On-device AI for privacy (2025-11-30)
