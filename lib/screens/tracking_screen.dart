import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:international_cunnibal/services/bio_tracking_service.dart';
import 'package:international_cunnibal/services/neural_engine.dart';
import 'package:international_cunnibal/models/tongue_data.dart';
import 'package:international_cunnibal/widgets/tracking_overlay.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final BioTrackingService _bioTracking = BioTrackingService();
  final NeuralEngine _neuralEngine = NeuralEngine();
  
  bool _isTracking = false;
  TongueData? _latestData;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _bioTracking.initializeCamera();
      setState(() {});
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = _bioTracking.cameraController;
    final isInitialized = cameraController?.value.isInitialized ?? false;

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
                  : const Center(
                      child: CircularProgressIndicator(),
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

                  const Spacer(),

                  // Control Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isInitialized ? _toggleTracking : null,
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
