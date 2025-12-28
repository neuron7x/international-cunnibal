import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/services/symbol_dictation_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

void main() {
  group('SymbolDictationService Tests', () {
    late SymbolDictationService dictationService;

    setUp(() {
      dictationService = SymbolDictationService();
    });

    tearDown(() {
      dictationService.dispose();
    });

    test('SymbolDictationService starts session with valid symbol', () {
      expect(() => dictationService.startSession('A'), returnsNormally);
      expect(dictationService.targetSymbol, equals('A'));
    });

    test('SymbolDictationService accepts custom partner rhythm', () {
      expect(
        () => dictationService.startSession('A', customPattern: [0.2, 0.6]),
        returnsNormally,
      );
      dictationService.stopSession();
    });

    test('SymbolDictationService accepts custom label for partner mode', () {
      dictationService.startSession(
        'X',
        customPattern: [0.2, 0.6],
        sessionLabel: 'PARTNER',
      );
      expect(dictationService.targetSymbol, equals('PARTNER'));
      dictationService.stopSession();
    });

    test('SymbolDictationService validates custom pattern input', () {
      expect(
        () => dictationService.startSession('A', customPattern: []),
        throwsArgumentError,
      );
      expect(
        () => dictationService.startSession('A', customPattern: [0.2]),
        throwsArgumentError,
      );
      expect(
        () => dictationService.startSession('A', customPattern: [-0.1, 0.2]),
        throwsArgumentError,
      );
      expect(
        () => dictationService.startSession('A', customPattern: [0.0, 0.2]),
        throwsArgumentError,
      );
      expect(
        () => dictationService.startSession('', customPattern: [0.2, 0.2]),
        throwsArgumentError,
      );
    });

    test('SymbolDictationService rejects invalid symbols', () {
      expect(() => dictationService.startSession('1'), throwsArgumentError);
      expect(() => dictationService.startSession('AB'), throwsArgumentError);
      expect(() => dictationService.startSession('a'), throwsArgumentError);
      expect(
        () => dictationService.startSession('A', sessionLabel: 'partner'),
        throwsArgumentError,
      );
    });

    test('SymbolDictationService stops session correctly', () {
      dictationService.startSession('A');
      expect(() => dictationService.stopSession(), returnsNormally);
    });

    test('All A-Z symbols are supported', () {
      for (int i = 0; i < 26; i++) {
        final symbol = String.fromCharCode(65 + i); // A-Z
        expect(() => dictationService.startSession(symbol), returnsNormally);
        dictationService.stopSession();
      }
    });

    test('rhythm consistency stays within bounds and deterministic', () {
      final engine = NeuralEngine();
      engine.start(enableTimer: false);
      dictationService.startSession(
        'A',
        customPattern: const [0.2, 0.2],
        startTime: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final timestamps = <int>[0, 200, 400];
      for (final ms in timestamps) {
        engine.processTongueData(
          TongueData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
            position: const Offset(0.5, 0.5),
            velocity: RhythmPatterns.significantMovementThreshold + 1,
            acceleration: 0,
            landmarks: const [Offset(0.5, 0.5)],
            isValidated: true,
          ),
        );
      }

      final firstScore =
          dictationService.currentSession?.synchronizationScore ?? 0.0;
      expect(firstScore, inInclusiveRange(0, 100));

      dictationService.stopSession();
      dictationService.startSession(
        'A',
        customPattern: const [0.2, 0.2],
        startTime: DateTime.fromMillisecondsSinceEpoch(0),
      );
      for (final ms in timestamps) {
        engine.processTongueData(
          TongueData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
            position: const Offset(0.5, 0.5),
            velocity: RhythmPatterns.significantMovementThreshold + 1,
            acceleration: 0,
            landmarks: const [Offset(0.5, 0.5)],
            isValidated: true,
          ),
        );
      }

      final secondScore =
          dictationService.currentSession?.synchronizationScore ?? 0.0;
      expect(secondScore, closeTo(firstScore, 1e-9));
      engine.stop();
    });
  });
}
