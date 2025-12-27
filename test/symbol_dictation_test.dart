import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/symbol_dictation_service.dart';

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
        () => dictationService.startSession('PARTNER', customPattern: [0.2, 0.6]),
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
        () => dictationService.startSession('', customPattern: [0.2, 0.2]),
        throwsArgumentError,
      );
    });

    test('SymbolDictationService rejects invalid symbols', () {
      expect(() => dictationService.startSession('1'), throwsArgumentError);
      expect(() => dictationService.startSession('AB'), throwsArgumentError);
      expect(() => dictationService.startSession('a'), throwsArgumentError);
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
  });
}
