import 'package:flutter/material.dart';
import 'package:international_cunnibal/screens/tracking_screen.dart';
import 'package:international_cunnibal/screens/dictation_screen.dart';
import 'package:international_cunnibal/screens/metrics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('International Cunnibal'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Title and Description
              const Icon(
                Icons.psychology,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Neural Biofeedback Engine',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Train, Dominate, Savor',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Feature Cards
              _FeatureCard(
                title: 'Bio-Tracking',
                description: 'Real-time tongue biomechanics',
                icon: Icons.track_changes,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackingScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _FeatureCard(
                title: 'Symbol Dictation',
                description: 'A-Z rhythmic synchronization',
                icon: Icons.record_voice_over,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DictationScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _FeatureCard(
                title: 'Metrics Dashboard',
                description: 'Performance analytics',
                icon: Icons.analytics,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MetricsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 20),
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
