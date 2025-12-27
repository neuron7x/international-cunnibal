import 'dart:async';
import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/dictation_session.dart';
import 'package:international_cunnibal/services/bio_tracking_service.dart';
import 'package:international_cunnibal/services/symbol_dictation_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

class PartnerModeStrings {
  static const introHeadline =
      'Партнер задає ритм — ти повторюєш рухами язика у реальному часі.';
  static const introBody =
      'Увімкніть фронтальну камеру, нехай партнерка натискає короткі '
      'та довгі такти, а ти намагаєшся попасти у ритм. Всі обчислення '
      'виконуються локально на пристрої — відео не зберігається і не передається.';
  static const patternLabel = 'Паттерн партнера';
  static const shortBeat = 'Короткий такт';
  static const longBeat = 'Довгий такт';
  static const resetLabel = 'Скинути паттерн';
  static const patternError =
      'Додайте щонайменше два такти, щоб задати ритм партнером.';
  static const startCta = 'СТАРТ: ПОВТОРИ ПАРТНЕРА';
  static const stopCta = 'ЗУПИНИТИ';
  static const partnerModeLabel = 'PARTNER';
  static const partnerModeSymbol = 'PARTNER';
}

class PartnerModeScreen extends StatefulWidget {
  const PartnerModeScreen({super.key});

  @override
  State<PartnerModeScreen> createState() => _PartnerModeScreenState();
}

class _PartnerModeScreenState extends State<PartnerModeScreen> {
  final SymbolDictationService _dictation = SymbolDictationService();
  final BioTrackingService _bioTracking = BioTrackingService();

  final List<double> _patternDurations = [];

  bool _isActive = false;
  DictationSession? _currentSession;
  StreamSubscription<DictationSession>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _resetPattern();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _bioTracking.initializeCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
      }
    }

    _sessionSubscription = _dictation.sessionStream.listen((session) {
      if (mounted) {
        setState(() => _currentSession = session);
      }
    });
  }

  Future<void> _togglePartnerMode() async {
    if (_isActive) {
      _bioTracking.stopTracking();
      _dictation.stopSession();
      setState(() => _isActive = false);
      return;
    }

    if (_patternDurations.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(PartnerModeStrings.patternError),
        ),
      );
      return;
    }

    await _bioTracking.startTracking();
    _dictation.startSession(
      PartnerModeStrings.partnerModeSymbol,
      customPattern: List.from(_patternDurations),
      sessionLabel: PartnerModeStrings.partnerModeLabel,
    );
    setState(() {
      _isActive = true;
      _currentSession = null;
    });
  }

  void _addBeat(double duration) {
    setState(() => _patternDurations.add(duration));
  }

  void _clearBeats() => setState(_resetPattern);

  void _resetPattern() {
    _patternDurations
      ..clear()
      ..addAll([
        RhythmPatterns.shortMovement,
        RhythmPatterns.longMovement,
      ]);
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _dictation.dispose();
    _bioTracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Mode'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      PartnerModeStrings.introHeadline,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PartnerModeStrings.introBody,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                PartnerModeStrings.patternLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patternDurations
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key + 1}: ${entry.value.toStringAsFixed(1)}s'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isActive ? null : () => _addBeat(RhythmPatterns.shortMovement),
                    icon: const Icon(Icons.blur_on),
                    label: const Text(PartnerModeStrings.shortBeat),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isActive ? null : () => _addBeat(RhythmPatterns.longMovement),
                    icon: const Icon(Icons.waves),
                    label: const Text(PartnerModeStrings.longBeat),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isActive ? null : _clearBeats,
                icon: const Icon(Icons.refresh),
                label: const Text(PartnerModeStrings.resetLabel),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentSession != null) ...[
              _PartnerStatCard(
                title: 'Синхронізація',
                value: '${_currentSession!.synchronizationScore.toStringAsFixed(1)}%',
                color: _getScoreColor(_currentSession!.synchronizationScore),
              ),
              const SizedBox(height: 12),
              _PartnerStatCard(
                title: 'Стабільність ритму',
                value: '${_currentSession!.rhythmConsistency.toStringAsFixed(1)}%',
                color: _getScoreColor(_currentSession!.rhythmConsistency),
              ),
              const SizedBox(height: 12),
              _PartnerStatCard(
                title: 'Виявлено рухів',
                value: '${_currentSession!.rhythmTimestamps.length}',
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _togglePartnerMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isActive ? PartnerModeStrings.stopCta : PartnerModeStrings.startCta,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _PartnerStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _PartnerStatCard({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
