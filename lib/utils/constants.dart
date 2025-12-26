/// Application-wide constants and configuration values
library constants;

/// Bio-tracking simulation constants
class BioTrackingConstants {
  // Simulation constants for tongue movement patterns
  static const double simulationAmplitudeX = 0.3; // Horizontal oscillation amplitude
  static const double simulationAmplitudeY = 0.2; // Vertical oscillation amplitude
  static const double simulationFrequencyMultiplier = 1.5; // Y-axis frequency multiplier
  static const double simulationPeriod = 2.0; // Oscillation period in seconds
  
  // Frame processing
  static const int framesPerSecond = 30;
  static const int frameProcessingIntervalMs = 33; // ~30 FPS
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
  
  // Consistency score calculation
  static const double stdDevScalingFactor = 50.0;
  
  // Action Acceptor validation
  static const double velocityChangeThreshold = 0.5; // For consistency validation
}

/// Export service constants
class ExportConstants {
  static const int autoExportThreshold = 100; // Auto-export after N metrics
  static const String appVersion = '1.0.0';
}
