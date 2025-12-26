import 'package:flutter/material.dart';
import 'package:international_cunnibal/services/symbol_dictation_service.dart';
import 'package:international_cunnibal/services/bio_tracking_service.dart';
import 'package:international_cunnibal/models/dictation_session.dart';

class DictationScreen extends StatefulWidget {
  const DictationScreen({super.key});

  @override
  State<DictationScreen> createState() => _DictationScreenState();
}

class _DictationScreenState extends State<DictationScreen> {
  final SymbolDictationService _dictation = SymbolDictationService();
  final BioTrackingService _bioTracking = BioTrackingService();
  
  bool _isActive = false;
  String _selectedSymbol = 'A';
  DictationSession? _currentSession;
  StreamSubscription<DictationSession>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
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

    // Listen to dictation sessions
    _sessionSubscription = _dictation.sessionStream.listen((session) {
      if (mounted) {
        setState(() => _currentSession = session);
      }
    });
  }

  Future<void> _toggleDictation() async {
    if (_isActive) {
      _bioTracking.stopTracking();
      _dictation.stopSession();
      setState(() => _isActive = false);
    } else {
      await _bioTracking.startTracking();
      _dictation.startSession(_selectedSymbol);
      setState(() {
        _isActive = true;
        _currentSession = null;
      });
    }
  }

  void _selectSymbol(String symbol) {
    setState(() => _selectedSymbol = symbol);
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _dictation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbol Dictation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partner-Led Symbol Dictation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a letter (A-Z) and perform rhythmic tongue movements '
                      'matching the symbol\'s pattern. Each letter has a unique rhythm signature.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symbol Selector
            const Text(
              'Select Target Symbol',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _SymbolGrid(
              selectedSymbol: _selectedSymbol,
              onSymbolSelected: _isActive ? null : _selectSymbol,
            ),
            const SizedBox(height: 24),

            // Current Target Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Target Symbol',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedSymbol,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Session Stats
            if (_currentSession != null) ...[
              _StatCard(
                title: 'Synchronization Score',
                value: '${_currentSession!.synchronizationScore.toStringAsFixed(1)}%',
                color: _getScoreColor(_currentSession!.synchronizationScore),
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Rhythm Consistency',
                value: '${_currentSession!.rhythmConsistency.toStringAsFixed(1)}%',
                color: _getScoreColor(_currentSession!.rhythmConsistency),
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Movements Detected',
                value: '${_currentSession!.rhythmTimestamps.length}',
              ),
            ],

            const Spacer(),

            // Start/Stop Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _toggleDictation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isActive ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isActive ? 'STOP DICTATION' : 'START DICTATION',
                  style: const TextStyle(fontSize: 18),
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

class _SymbolGrid extends StatelessWidget {
  final String selectedSymbol;
  final void Function(String)? onSymbolSelected;

  const _SymbolGrid({
    required this.selectedSymbol,
    required this.onSymbolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final symbols = List.generate(26, (i) => String.fromCharCode(65 + i));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symbols.map((symbol) {
        final isSelected = symbol == selectedSymbol;
        return InkWell(
          onTap: onSymbolSelected != null
              ? () => onSymbolSelected!(symbol)
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _StatCard({
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
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
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
