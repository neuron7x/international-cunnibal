import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/couple_dashboard.dart';
import 'package:international_cunnibal/models/metrics.dart';
import 'package:international_cunnibal/models/movement_direction.dart';
import 'package:international_cunnibal/services/endurance_game_logic_service.dart';
import 'package:international_cunnibal/services/game_logic_service.dart';
import 'package:international_cunnibal/services/ui/github_export_service.dart';
import 'package:international_cunnibal/services/neural_engine.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final NeuralEngine _neuralEngine = NeuralEngine();
  final GitHubExportService _exportService = GitHubExportService();
  final GameLogicService _gameLogic = GameLogicService();
  final EnduranceGameLogicService _enduranceGameLogic =
      EnduranceGameLogicService();

  BiometricMetrics? _currentMetrics;
  bool _isExporting = false;
  bool _showComparisons = false;
  bool _enduranceOptIn = false;

  @override
  void initState() {
    super.initState();
    _initializeMetrics();
  }

  void _initializeMetrics() {
    // Listen to metrics stream
    _neuralEngine.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() => _currentMetrics = metrics);
        _exportService.logMetrics(metrics);
      }
    });
  }

  Future<void> _exportLogs() async {
    setState(() => _isExporting = true);

    try {
      final filePath = await _exportService.exportPerformanceLog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _isExporting ? null : _exportLogs,
            tooltip: 'Export to GitHub',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Real-Time Biometric Metrics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by Anokhin\'s Action Acceptor',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable jaw endurance tracking'),
              subtitle: const Text(
                'On-device aperture control (consent-based)',
              ),
              value: _enduranceOptIn,
              onChanged: (value) {
                setState(() => _enduranceOptIn = value);
                _neuralEngine.configureEndurance(enabled: value);
              },
            ),
            const SizedBox(height: 16),

            // Metrics Cards
            if (_currentMetrics != null) ...[
              _MetricCard(
                title: 'Consistency Score',
                subtitle: 'Based on Standard Deviation',
                value: _currentMetrics!.consistencyScore,
                unit: '%',
                icon: Icons.timeline,
                color: _getConsistencyColor(_currentMetrics!.consistencyScore),
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Movement Frequency',
                subtitle: 'Movements per second',
                value: _currentMetrics!.frequency,
                unit: 'Hz',
                icon: Icons.graphic_eq,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.explore, size: 48, color: Colors.teal[400]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Direction Control',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Dominant: ${_currentMetrics!.movementDirection.label}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_currentMetrics!.directionStability.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_enduranceOptIn) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Endurance Control',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Jaw aperture stability (on-device)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentMetrics!.endurance.enduranceScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipStat(
                              label: 'Aperture',
                              value:
                                  '${(_currentMetrics!.endurance.aperture * 100).toStringAsFixed(1)}%',
                            ),
                            _ChipStat(
                              label: 'Stability',
                              value:
                                  '${_currentMetrics!.endurance.apertureStability.toStringAsFixed(1)}%',
                            ),
                            _ChipStat(
                              label: 'Fatigue',
                              value:
                                  '${_currentMetrics!.endurance.fatigueIndicator.toStringAsFixed(1)}%',
                            ),
                            _ChipStat(
                              label: 'Hold Time',
                              value:
                                  '${_currentMetrics!.endurance.enduranceTime.toStringAsFixed(2)}s',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'Enable jaw endurance tracking to view aperture stability metrics.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],

              // PCA Variance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.insights, color: Colors.purple),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vector PCA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Principal Component Analysis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PCABar(
                        label: 'PC1',
                        value: _currentMetrics!.pcaVariance[0],
                        color: Colors.purple[700]!,
                      ),
                      const SizedBox(height: 8),
                      _PCABar(
                        label: 'PC2',
                        value: _currentMetrics!.pcaVariance[1],
                        color: Colors.purple[500]!,
                      ),
                      const SizedBox(height: 8),
                      _PCABar(
                        label: 'PC3',
                        value: _currentMetrics!.pcaVariance[2],
                        color: Colors.purple[300]!,
                      ),
                    ],
                  ),
                ),
              ),
              if (_enduranceOptIn) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Comparison Dashboard (opt-in)'),
                  subtitle: const Text('Side-by-side without ranking'),
                  value: _showComparisons,
                  onChanged: (value) {
                    setState(() => _showComparisons = value);
                    _neuralEngine.configureEndurance(
                      enabled: value || _enduranceOptIn,
                    );
                  },
                ),
                if (_showComparisons)
                  _CoupleDashboardCard(
                    dashboard: CoupleDashboard.fromInputs(
                      motion: _currentMetrics!,
                      motionState: _gameLogic.state,
                      endurance: _currentMetrics!.endurance,
                      enduranceState: _enduranceGameLogic.state,
                      comparisonsEnabled: _showComparisons,
                    ),
                  ),
              ],
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No metrics available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start bio-tracking to see metrics',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Export Section
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'GitHub Integration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Automated performance log exports for GitHub. '
                      'All data processed on-device for privacy.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _exportLogs,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isExporting
                              ? 'Exporting...'
                              : 'Export Performance Log',
                        ),
                      ),
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

  Color _getConsistencyColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;

  const _ChipStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}

class _CoupleDashboardCard extends StatelessWidget {
  final CoupleDashboard dashboard;

  const _CoupleDashboardCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparison Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informational only — no automatic ranking.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _ComparisonRow(row: dashboard.consistencyVsEndurance, unit: '%'),
            const SizedBox(height: 8),
            _ComparisonRow(row: dashboard.directionVsStability, unit: '%'),
            const SizedBox(height: 8),
            _ComparisonRow(row: dashboard.levelVsLevel, unit: ''),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final CoupleComparisonRow row;
  final String unit;

  const _ComparisonRow({required this.row, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.leftLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${row.leftValue.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.compare_arrows, color: Colors.grey),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.rightLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${row.rightValue.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontSize: 32,
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

class _PCABar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PCABar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 24,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
