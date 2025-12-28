import 'dart:async';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/utils/constants.dart';

/// Symbol Dictation Service
/// Partner-led A-Z rhythmic synchronization in real-time
/// Reference: Symbol Dictation feature (2025-11-30)
class SymbolDictationService {
  static final SymbolDictationService _instance =
      SymbolDictationService._internal();
  factory SymbolDictationService() => _instance;
  SymbolDictationService._internal();

  final NeuralEngine _neuralEngine = NeuralEngine();

  DictationSession? _currentSession;
  final List<double> _rhythmTimestamps = [];
  String _targetSymbol = 'A';
  DateTime? _sessionStartTime;
  List<double>? _customPattern;

  StreamSubscription<TongueData>? _tongueDataSubscription;
  final StreamController<DictationSession> _sessionController =
      StreamController<DictationSession>.broadcast();

  Stream<DictationSession> get sessionStream => _sessionController.stream;
  DictationSession? get currentSession => _currentSession;
  String get targetSymbol => _targetSymbol;

  /// Start a new dictation session with target symbol
  void startSession(
    String symbol, {
    List<double>? customPattern,
    String? sessionLabel,
    DateTime? startTime,
  }) {
    final trimmedSymbol = symbol.trim();
    if (trimmedSymbol.length != 1 ||
        !RegExp(r'^[A-Z]$').hasMatch(trimmedSymbol)) {
      throw ArgumentError('Symbol must be a single letter A-Z');
    }
    final trimmedLabel = sessionLabel?.trim();
    if (trimmedLabel != null && trimmedLabel.isEmpty) {
      throw ArgumentError('Session label cannot be empty');
    }
    if (trimmedLabel != null && !RegExp(r'^[A-Z]+$').hasMatch(trimmedLabel)) {
      throw ArgumentError('Session label must be uppercase A-Z characters');
    }

    if (customPattern != null) {
      if (customPattern.length < 2) {
        throw ArgumentError('Custom pattern must include at least two beats');
      }
      if (customPattern.any((value) => value <= 0)) {
        throw ArgumentError('Custom pattern values must be positive durations');
      }
    }

    _targetSymbol =
        trimmedLabel?.isNotEmpty == true ? trimmedLabel! : trimmedSymbol;
    _sessionStartTime = startTime ?? DateTime.now();
    _rhythmTimestamps.clear();
    _customPattern = customPattern;

    // Listen to tongue data for rhythm detection
    _tongueDataSubscription = _neuralEngine.tongueDataStream.listen(
      (tongueData) => _processRhythm(tongueData),
    );
  }

  /// Process rhythm from tongue movements
  void _processRhythm(TongueData data) {
    if (_sessionStartTime == null) return;

    // Detect significant movement (velocity threshold)
    if (data.velocity > RhythmPatterns.significantMovementThreshold &&
        data.isValidated) {
      final timestamp =
          data.timestamp.difference(_sessionStartTime!).inMilliseconds / 1000.0;

      _rhythmTimestamps.add(timestamp);

      // Update session
      _updateSession();
    }
  }

  /// Update current session with latest data
  void _updateSession() {
    if (_sessionStartTime == null) return;

    final synchronizationScore = _calculateSynchronization();

    _currentSession = DictationSession(
      targetSymbol: _targetSymbol,
      startTime: _sessionStartTime!,
      rhythmTimestamps: List.from(_rhythmTimestamps),
      synchronizationScore: synchronizationScore,
    );

    if (!_sessionController.isClosed) {
      _sessionController.add(_currentSession!);
    }
  }

  /// Calculate synchronization score based on rhythm patterns
  /// Uses expected rhythm pattern for each letter
  double _calculateSynchronization() {
    if (_rhythmTimestamps.length < 2) return 0.0;

    // Expected rhythm patterns for letters (simplified)
    // In production, this would use more sophisticated pattern matching
    final expectedIntervals = _getExpectedRhythm(_targetSymbol);

    if (_rhythmTimestamps.length < expectedIntervals.length + 1) {
      return (_rhythmTimestamps.length / (expectedIntervals.length + 1)) * 100;
    }

    // Calculate actual intervals
    final actualIntervals = <double>[];
    for (int i = 1; i < _rhythmTimestamps.length; i++) {
      actualIntervals.add(_rhythmTimestamps[i] - _rhythmTimestamps[i - 1]);
    }

    // Compare with expected pattern
    double totalError = 0.0;
    final compareLength = actualIntervals.length.clamp(
      0,
      expectedIntervals.length,
    );

    for (int i = 0; i < compareLength; i++) {
      final error = (actualIntervals[i] - expectedIntervals[i]).abs();
      totalError += error;
    }

    if (compareLength == 0) return 0.0;

    final avgError = totalError / compareLength;
    final score = 100.0 / (1.0 + avgError);

    return score.clamp(0.0, 100.0);
  }

  /// Get expected rhythm pattern for symbol
  /// Each letter has a unique rhythm signature for dictation
  List<double> _getExpectedRhythm(String symbol) {
    return _customPattern ?? RhythmPatterns.getPattern(symbol);
  }

  /// Stop current dictation session
  void stopSession() {
    _tongueDataSubscription?.cancel();
    _tongueDataSubscription = null;
    _sessionStartTime = null;
    _customPattern = null;
  }

  void dispose() {
    stopSession();
    _sessionController.close();
  }
}
