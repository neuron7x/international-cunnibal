import 'dart:async';

import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/services/endurance_engine.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/utils/constants.dart';

class EnduranceModeScreen extends StatefulWidget {
  const EnduranceModeScreen({super.key});

  @override
  State<EnduranceModeScreen> createState() => _EnduranceModeScreenState();
}

class _EnduranceModeScreenState extends State<EnduranceModeScreen> {
  final EnduranceEngine _engine = EnduranceEngine();
  final EnduranceGameLogicService _logic = EnduranceGameLogicService();

  EnduranceSnapshot _snapshot =
      EnduranceSnapshot.empty(threshold: EnduranceConstants.defaultApertureThreshold);
  bool _optedIn = false;
  Timer? _demoTimer;
  int _ticks = 0;

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  void _toggleOptIn(bool value) {
    setState(() => _optedIn = value);
    if (!value) {
      _demoTimer?.cancel();
      _snapshot = EnduranceSnapshot.empty(
        threshold: EnduranceConstants.defaultApertureThreshold,
      );
      _logic.reset();
    }
  }

  void _toggleDemo() {
    if (!_optedIn) return;
    if (_demoTimer != null) {
      _demoTimer?.cancel();
      setState(() => _demoTimer = null);
      return;
    }
    _ticks = 0;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final snap = _engine.demoTick(_ticks * 0.2);
      _logic.ingest(snap);
      setState(() {
        _snapshot = snap;
        _ticks += 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = _logic.state.level;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endurance Mode'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Couple skill training (jaw endurance)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Neutral, consent-based training for aperture control. '
              'All processing stays on-device; comparisons are opt-in only.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable endurance mode'),
              subtitle: const Text('Explicit opt-in; safe to dismiss anytime'),
              value: _optedIn,
              onChanged: _toggleOptIn,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _optedIn ? _toggleDemo : null,
              icon: Icon(_demoTimer == null ? Icons.play_arrow : Icons.stop),
              label: Text(_demoTimer == null ? 'Start demo (on-device)' : 'Stop demo'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Endurance Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_snapshot.enduranceScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag('Aperture', '${(_snapshot.aperture * 100).toStringAsFixed(1)}%'),
                        _tag('Stability',
                            '${_snapshot.apertureStability.toStringAsFixed(1)}%'),
                        _tag('Hold Time',
                            '${_snapshot.enduranceTime.toStringAsFixed(2)}s ≥ ${_snapshot.threshold.toStringAsFixed(2)}'),
                        _tag('Level', 'L$level'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, String value) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
