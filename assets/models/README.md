# TFLite Models

This directory contains TensorFlow Lite models for on-device AI processing.

## Required Models

### tongue_detector.tflite
A MediaPipe-based facial landmark detection model adapted for tongue tracking.

**Model Requirements:**
- Input: RGB image (320x320 or 640x480)
- Output: Facial landmarks (468 points) with confidence scores
- Format: TFLite with float32 inference

**Training Dataset:**
The model should be trained on a dataset of facial images with annotated tongue positions and landmarks.

### labels.txt
Label file containing landmark indices and names.

## Model Integration

The BioTrackingService in `lib/services/bio_tracking_service.dart` is prepared to load and use these models. Currently, the service uses simulated data for demonstration purposes.

To integrate actual models:

1. Place `tongue_detector.tflite` in this directory
2. Place `labels.txt` in this directory
3. Update the model loading code in `BioTrackingService.loadModel()`
4. Implement the TFLite inference in `_processFrame()`

## Privacy Note

All model inference runs on-device. No data is sent to external servers, ensuring complete user privacy.

## References

- MediaPipe Face Mesh: https://google.github.io/mediapipe/solutions/face_mesh
- TensorFlow Lite: https://www.tensorflow.org/lite
- On-device AI for privacy (2025-11-30)
