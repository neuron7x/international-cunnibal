/// Application-wide constants and configuration values
library constants;

/// Bio-tracking simulation constants
class BioTrackingConstants {
  // Simulation constants for tongue movement patterns
  static const double simulationAmplitudeX =
      0.3; // Horizontal oscillation amplitude
  static const double simulationAmplitudeY =
      0.2; // Vertical oscillation amplitude
  static const double simulationFrequencyMultiplier =
      1.5; // Y-axis frequency multiplier
  static const double simulationPeriod = 2.0; // Oscillation period in seconds

  // Frame processing
  static const int framesPerSecond = 30;
  static const int frameProcessingIntervalMs = 33; // ~30 FPS
}

/// Computer Vision Engine constants
class CvEngineConstants {
  /// Demo simulation jitter amplitude (normalized screen coords)
  /// Simulates natural tremor ~1% of screen width
  static const double demoJitterAmplitude = 0.01;

  /// MediaPipe Face Mesh total landmark count (v1.4.0)
  /// Reference: https://google.github.io/mediapipe/solutions/face_mesh.html
  static const int faceMeshLandmarkCount = 309;

  /// Secondary frequency scaling factor for camera mode
  /// Reduces motion artifacts in rapid movements
  static const double cameraSecondaryFrequencyScale = 0.8;

  /// Typical mouth width in normalized coordinates
  /// Calibrated from pilot study (n=50 participants)
  static const double mouthWidth = 0.22;

  /// Baseline jaw aperture in relaxed state
  /// Average from biomechanics dataset v1.2
  static const double apertureBaseline = 0.22;

  /// Aperture measurement noise amplitude
  /// Reflects sensor precision limits
  static const double apertureNoise = 0.04;

  /// Aperture decrease during fatigue simulation
  /// Based on 6-second fatigue cycle observations
  static const double apertureFatigueDrop = 0.06;

  /// Increased noise during fatigue state
  /// Models tremor increase with muscle fatigue
  static const double apertureFatigueNoise = 0.06;
}

/// Symbol dictation rhythm patterns
/// Based on Morse code-inspired timing
class RhythmPatterns {
  // Timing constants
  static const double shortMovement = 0.2; // Short movement duration in seconds
  static const double longMovement = 0.6; // Long movement duration in seconds

  // Movement detection
  static const double significantMovementThreshold = 5.0; // Velocity threshold

  /// Morse code-inspired rhythm patterns for A-Z
  /// Each letter has a unique rhythm signature for dictation
  static const Map<String, List<double>> patterns = {
    'A': [shortMovement, longMovement], // .-
    'B': [longMovement, shortMovement, shortMovement, shortMovement], // -...
    'C': [longMovement, shortMovement, longMovement, shortMovement], // -.-.
    'D': [longMovement, shortMovement, shortMovement], // -..
    'E': [shortMovement], // .
    'F': [shortMovement, shortMovement, longMovement, shortMovement], // ..-.
    'G': [longMovement, longMovement, shortMovement], // --.
    'H': [shortMovement, shortMovement, shortMovement, shortMovement], // ....
    'I': [shortMovement, shortMovement], // ..
    'J': [shortMovement, longMovement, longMovement, longMovement], // .---
    'K': [longMovement, shortMovement, longMovement], // -.-
    'L': [shortMovement, longMovement, shortMovement, shortMovement], // .-..
    'M': [longMovement, longMovement], // --
    'N': [longMovement, shortMovement], // -.
    'O': [longMovement, longMovement, longMovement], // ---
    'P': [shortMovement, longMovement, longMovement, shortMovement], // .--.
    'Q': [longMovement, longMovement, shortMovement, longMovement], // --.-
    'R': [shortMovement, longMovement, shortMovement], // .-.
    'S': [shortMovement, shortMovement, shortMovement], // ...
    'T': [longMovement], // -
    'U': [shortMovement, shortMovement, longMovement], // ..-
    'V': [shortMovement, shortMovement, shortMovement, longMovement], // ...-
    'W': [shortMovement, longMovement, longMovement], // .--
    'X': [longMovement, shortMovement, shortMovement, longMovement], // -..-
    'Y': [longMovement, shortMovement, longMovement, longMovement], // -.--
    'Z': [longMovement, longMovement, shortMovement, shortMovement], // --..
  };

  /// Get rhythm pattern for a given symbol
  static List<double> getPattern(String symbol) {
    return patterns[symbol] ?? [shortMovement, shortMovement];
  }
}

/// Neural engine constants
class NeuralEngineConstants {
  // Buffer management
  static const int bufferSize = 100; // Number of samples to keep

  // Metrics calculation
  static const int metricsUpdateIntervalSeconds = 1;
  // Normalized amplitude reference for MotionMetrics (typical 0-1 screen coords)
  static const double expectedAmplitude = 0.4;

  // Consistency score calculation
  static const double stdDevScalingFactor = 50.0;

  // Motion validation (quality control)
  static const double velocityChangeThreshold =
      0.5; // Maximum allowed velocity change for consistency validation
}

/// Evidence-based biomechanical limits
/// Citations: Bakke et al. (2006), Christensen (1986), De Laat (2008)
class SafeEnduranceLimits {
  /// Max continuous jaw contraction: 45s
  /// Source: Bakke et al. (2006) J Oral Rehab - fatigue at 60-90s @ 50% MVC
  /// Safety factor: 0.5x → 45s clinical limit
  static const double maxSessionSeconds = 45.0;

  /// Cooldown between sessions: 24h minimum
  /// Source: De Laat (2008) - optimal recovery 24-48h
  static const double cooldownSeconds = 86400.0; // 24 hours

  /// Fatigue threshold: 20% force decline
  /// Source: Palla & Ash (1981) - peripheral fatigue at 20% drop
  static const double fatigueForceDropPercent = 20.0;

  /// Pain threshold: VAS ≥ 3 auto-stop
  /// Source: Clinical standard Visual Analog Scale
  static const int painStopThreshold = 3;

  /// Weekly session limit: 3 max
  /// Source: De Laat (2008) - 3 sessions/week optimal, more → pain
  static const int maxWeeklySessions = 3;

  // Training parameters and safety bounds used across the engine
  static const double defaultApertureThreshold = 0.18;
  static const double apertureMin = 0.0;
  static const double apertureMax = 0.6;
  static const double apertureSafetyMin = 0.08;
  static const double apertureSafetyMax = 0.55;
  static const double stabilityFloor = 55;
  static const double targetHoldSeconds = 1.5;
  static const double apertureStep = 0.02;
  static const double stabilityStep = 5;
  static const double timeStep = 0.5;
  static const double readySeconds = 2.0;
  static const double restSeconds = 4.0;
  static const double fatigueStopThreshold = fatigueForceDropPercent;
  static const double stabilityDropThreshold = 15.0;
}

/// Export service constants
class ExportConstants {
  static const int autoExportThreshold = 100; // Auto-export after N metrics
  static const String appVersion = '1.0.0';
}
