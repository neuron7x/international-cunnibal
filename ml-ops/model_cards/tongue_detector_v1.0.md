# Model Card: Tongue Detector v1.0

## Model Details

**Model Name:** Tongue Detector v1.0  
**Model Type:** TensorFlow Lite (TFLite)  
**Architecture:** MediaPipe Face Mesh inspired  
**Version:** 1.0.0  
**Date:** 2025-12-30  
**Owner:** International Cunnibal Team

## Model Description

This model detects tongue landmarks in real-time from camera input for biomechanics tracking.
Based on MediaPipe Face Mesh architecture, it identifies key tongue position landmarks from facial imagery.

### Intended Use

**Primary Use Cases:**
- Real-time tongue position tracking
- Biomechanics analysis for oral motor training
- On-device biofeedback for sensory-motor synchronization

**Target Users:**
- Individuals using the International Cunnibal app for training
- Researchers studying oral biomechanics
- Healthcare professionals in rehabilitation contexts

**Out-of-Scope Uses:**
- Medical diagnosis
- Clinical decision-making without professional oversight
- Use cases requiring medical-grade accuracy

## Model Architecture

**Input:**
- Image tensor: [1, 256, 256, 3]
- Normalized RGB values: [-1, 1]
- Expected: Front-facing camera frames

**Output:**
- Landmark coordinates: [1, 468, 3]
- 468 facial landmarks (x, y, z)
- Tongue-relevant indices: 13, 14, 78, 308, 324, 375, 405, 406, 407

**Model Size:** ~TBD MB  
**Inference Time:** Target <33ms per frame (30 FPS)

## Training Data

**Dataset:** [Specify training dataset]  
**Size:** [Number of samples]  
**Demographics:** [Distribution of training data]  
**Preprocessing:** Image normalization, augmentation details

## Performance Metrics

### Accuracy Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Landmark Detection Accuracy | TBD% | Average across test set |
| Inference Time (Mobile) | <33ms | Target for 30 FPS |
| Model Size | TBD MB | On-device constraints |

### Benchmark Results

**Device Performance:**
- **Pixel 6:** ~XX ms per frame
- **iPhone 13:** ~XX ms per frame
- **Budget Android:** ~XX ms per frame

## Limitations

**Known Limitations:**
- Requires good lighting conditions
- Works best with frontal face view
- May struggle with extreme facial expressions
- Accuracy depends on camera quality

**Bias Considerations:**
- Training data demographics
- Potential performance variations across populations
- Recommendations for diverse usage scenarios

## Ethical Considerations

**Privacy:**
- All processing happens on-device
- No data transmitted to servers
- User consent required for camera access
- Landmarks filtered to remove identifying facial features

**Fairness:**
- Model tested across diverse populations
- Performance monitoring for bias detection
- Continuous improvement based on user feedback

## Usage Guidelines

### Loading the Model

```dart
import 'package:international_cunnibal/services/ui/bio_tracking_service.dart';

final trackingService = BioTrackingService();
await trackingService.loadModel();

if (trackingService.isRealTrackingEnabled) {
  // Model loaded successfully
  await trackingService.startTracking();
} else {
  // Fallback to demo mode
}
```

### Interpreting labels.txt

The `labels.txt` file contains landmark indices corresponding to tongue-relevant points:

```text
13   # Lower lip bottom
14   # Lower lip center
78   # Upper lip (left inner)
308  # Upper lip (right inner)
324  # Mouth corner (right)
375  # Mouth corner (left)
405  # Tongue tip (approximate)
406  # Tongue center
407  # Tongue base
```

### Camera Mode Setup

1. Ensure camera permissions are granted
2. Load model via `BioTrackingService.loadModel()`
3. Check `isRealTrackingEnabled` status
4. Start tracking with `startTracking()`
5. Model automatically falls back to demo mode on failure

## Version History

### v1.0.0 (2025-12-30)
- Initial model release
- Placeholder implementation
- Demo mode fallback support

## Contact

For questions or issues:
- GitHub: https://github.com/neuron7x/international-cunnibal/issues
- Documentation: [ML-Ops README](../README.md)

---

## How to Add Model Cards

When adding new models to the project:

1. **Copy this template** to `ml-ops/model_cards/[model_name]_v[version].md`
2. **Fill in all sections** with model-specific details
3. **Update performance metrics** based on benchmarking
4. **Document training data** and methodology
5. **Add usage examples** relevant to your model
6. **Track the model card** in version control
7. **Link from main documentation** as appropriate

**Required Sections:**
- Model Details
- Intended Use & Limitations
- Performance Metrics
- Ethical Considerations
- Usage Guidelines

**Best Practices:**
- Keep metrics up-to-date
- Document all model versions
- Include benchmark results
- Address bias and fairness
- Maintain clear usage guidelines
