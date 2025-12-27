import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:international_cunnibal/services/bio_tracking_service.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/models/game_state.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/widgets/tracking_overlay.dart';
import 'package:international_cunnibal/services/cv_engine.dart';

bool isTrackingControlEnabled({
  required bool isDemoMode,
  required bool cameraReady,
}) {
  return isDemoMode || cameraReady;
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final BioTrackingService _bioTracking = BioTrackingService();
  final NeuralEngine _neuralEngine = NeuralEngine();
  final GameLogicService _gameLogic = GameLogicService();
  
  bool _isTracking = false;
  TongueData? _latestData;
  GameState? _gameState;
  StreamSubscription<GameState>? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _bioTracking.prepare();
      _gameSubscription = _gameLogic.stateStream.listen((state) {
        if (mounted) {
          setState(() => _gameState = state);
        }
      });
      setState(() {
        _gameState = _gameLogic.state;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }

    // Listen to tongue data stream
    _neuralEngine.tongueDataStream.listen((data) {
      if (mounted) {
        setState(() => _latestData = data);
      }
    });
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _bioTracking.stopTracking();
      setState(() => _isTracking = false);
    } else {
      await _bioTracking.startTracking();
      setState(() => _isTracking = true);
    }
  }

  @override
  void dispose() {
    _bioTracking.dispose();
    _gameSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = _bioTracking.cameraController;
    final isInitialized = cameraController?.value.isInitialized ?? false;
    final controlEnabled = isTrackingControlEnabled(
      isDemoMode: _bioTracking.isDemoMode,
      cameraReady: isInitialized,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bio-Tracking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(cameraController!),
                        if (_latestData != null)
                          TrackingOverlay(tongueData: _latestData!),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.blueGrey],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.videogame_asset, color: Colors.white70, size: 64),
                              SizedBox(height: 12),
                              Text(
                                'Demo CV Engine Running',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'No camera or ML models required',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Status Panel
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking ? Icons.circle : Icons.circle_outlined,
                        color: _isTracking ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTracking ? 'TRACKING ACTIVE' : 'TRACKING STOPPED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isTracking ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text(_bioTracking.isDemoMode ? 'DEMO ENGINE' : 'CAMERA FEED'),
                        backgroundColor: _bioTracking.isDemoMode
                            ? Colors.green.withOpacity(0.2)
                            : Colors.blueGrey.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isTracking
                            ? null
                            : () async {
                                await _bioTracking.setMode(
                                  _bioTracking.isDemoMode
                                      ? CvEngineMode.camera
                                      : CvEngineMode.demo,
                                );
                                if (mounted) setState(() {});
                              },
                        icon: Icon(
                          _bioTracking.isDemoMode ? Icons.camera_alt : Icons.bolt,
                        ),
                        tooltip: _bioTracking.isDemoMode
                            ? 'Switch to camera feed'
                            : 'Switch to demo feed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Data
                  if (_latestData != null) ...[
                    _DataRow(
                      label: 'Position',
                      value: '(${_latestData!.position.dx.toStringAsFixed(2)}, '
                          '${_latestData!.position.dy.toStringAsFixed(2)})',
                    ),
                    _DataRow(
                      label: 'Velocity',
                      value: '${_latestData!.velocity.toStringAsFixed(2)} px/s',
                    ),
                    _DataRow(
                      label: 'Validated',
                      value: _latestData!.isValidated ? 'YES' : 'NO',
                      valueColor: _latestData!.isValidated 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ],
                  if (_gameState != null) ...[
                    const SizedBox(height: 12),
                    _DataRow(
                      label: 'Level',
                      value: _gameState!.level.toString(),
                    ),
                    _DataRow(
                      label: 'Score',
                      value: _gameState!.score.toString(),
                    ),
                    _DataRow(
                      label: 'Targets',
                      value:
                          '${_gameState!.targetConsistency.toStringAsFixed(0)}% · ${_gameState!.targetFrequency.toStringAsFixed(1)}Hz',
                    ),
                  ],

                  const Spacer(),

                  // Control Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controlEnabled ? _toggleTracking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isTracking ? 'STOP TRACKING' : 'START TRACKING',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
