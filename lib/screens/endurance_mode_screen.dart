import 'dart:async';

import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/endurance_snapshot.dart';
import 'package:international_cunnibal/models/endurance_session_state.dart';
import 'package:international_cunnibal/services/endurance_engine.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/services/endurance_session_service.dart';
import 'package:international_cunnibal/services/health/session_tracker.dart';
import 'package:international_cunnibal/utils/constants.dart';
import 'package:international_cunnibal/widgets/pain_scale_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnduranceModeScreen extends StatefulWidget {
  const EnduranceModeScreen({super.key});

  @override
  State<EnduranceModeScreen> createState() => _EnduranceModeScreenState();
}

class _EnduranceModeScreenState extends State<EnduranceModeScreen> {
  final EnduranceEngine _engine = EnduranceEngine();
  final EnduranceGameLogicService _logic = EnduranceGameLogicService();
  final EnduranceSessionService _session = EnduranceSessionService();
  SessionTracker? _sessionTracker;

  EnduranceSnapshot _snapshot = EnduranceSnapshot.empty(
    threshold: SafeEnduranceLimits.defaultApertureThreshold,
  );
  EnduranceSessionState _sessionState = EnduranceSessionState.initial(
    targetHoldSeconds: SafeEnduranceLimits.targetHoldSeconds,
  );
  bool _optedIn = false;
  Timer? _demoTimer;
  bool _sessionRecorded = false;

  @override
  void initState() {
    super.initState();
    _session.onPainCheckRequested = _handlePainCheckRequest;
    _initSessionTracker();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSessionTracker() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sessionTracker = SessionTracker(prefs);
    });
  }

  void _toggleOptIn(bool value) {
    setState(() => _optedIn = value);
    if (!value) {
      _demoTimer?.cancel();
      _demoTimer = null;
      _snapshot = EnduranceSnapshot.empty(
        threshold: SafeEnduranceLimits.defaultApertureThreshold,
      );
      _logic.reset();
      _session.reset();
      _sessionState = EnduranceSessionState.initial(
        targetHoldSeconds: SafeEnduranceLimits.targetHoldSeconds,
      );
      _sessionRecorded = false;
    }
  }

  Future<void> _toggleSession() async {
    if (!_optedIn) return;
    if (_demoTimer != null) {
      _demoTimer?.cancel();
      _demoTimer = null;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _session.stop(nowSeconds);
      await _recordSession();
      setState(() {});
      return;
    }
    final tracker = _sessionTracker;
    if (tracker != null) {
      final eligibility = await tracker.checkEligibility();
      if (!eligibility.canStart) {
        setState(() {
          _sessionState = _session.state.copyWith(
            canStart: false,
            prompt: eligibility.reason ??
                'Rest required before starting another session.',
          );
        });
        return;
      }
    }
    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _session.start(nowSeconds);
    if (!_session.state.canStart) {
      setState(() => _sessionState = _session.state);
      return;
    }
    _sessionRecorded = false;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final tSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final snap = _engine.demoTick(tSeconds);
      _logic.ingest(snap);
      final session = _session.ingest(snapshot: snap, tSeconds: tSeconds);
      if (session.phase == EnduranceSessionPhase.summary) {
        _demoTimer?.cancel();
        _demoTimer = null;
        _recordSession();
      }
      setState(() {
        _snapshot = snap;
        _sessionState = session;
      });
    });
  }

  Future<void> _recordSession() async {
    if (_sessionRecorded) return;
    _sessionRecorded = true;
    await _sessionTracker?.recordSession();
  }

  Future<void> _handlePainCheckRequest() async {
    if (!mounted) return;
    final vas = await showDialog<int>(
      context: context,
      builder: (context) => PainScaleDialog(
        onRated: (_) {},
      ),
    );
    if (vas != null) {
      _session.reportPainVAS(vas);
      setState(() => _sessionState = _session.state);
      if (_sessionState.phase == EnduranceSessionPhase.summary) {
        await _recordSession();
      }
    }
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
              'Jaw endurance training',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Women-focused, consent-based training for endurance, stability, '
              'and control. All processing stays on-device and sessions are optional.',
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
              onPressed: _optedIn ? _toggleSession : null,
              icon: Icon(_demoTimer == null ? Icons.play_arrow : Icons.stop),
              label: Text(
                _demoTimer == null
                    ? 'Start session (on-device)'
                    : 'Stop session',
              ),
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
                    Text(
                      _sessionState.prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Session Timer',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const Spacer(),
                        Text(
                          '${_sessionState.sessionSeconds.toStringAsFixed(1)}s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_snapshot.apertureStability / 100).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _snapshot.apertureStability >=
                                  SafeEnduranceLimits.stabilityFloor
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Stability',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const Spacer(),
                        Text(
                          '${_snapshot.apertureStability.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag(
                          'Aperture',
                          '${(_snapshot.aperture * 100).toStringAsFixed(1)}%',
                        ),
                        _tag(
                          'Stability',
                          '${_snapshot.apertureStability.toStringAsFixed(1)}%',
                        ),
                        _tag(
                          'Fatigue',
                          '${_snapshot.fatigueIndicator.toStringAsFixed(1)}%',
                        ),
                        _tag(
                          'Hold Time',
                          '${_snapshot.enduranceTime.toStringAsFixed(2)}s ≥ ${_snapshot.threshold.toStringAsFixed(2)}',
                        ),
                        _tag(
                          'Hold Progress',
                          '${_sessionState.safeHoldSeconds.toStringAsFixed(1)}'
                              '/${_sessionState.targetHoldSeconds.toStringAsFixed(1)}s',
                        ),
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
