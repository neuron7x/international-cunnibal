import 'package:flutter/material.dart';

class PainScaleDialog extends StatelessWidget {
  final Function(int) onRated;

  const PainScaleDialog({super.key, required this.onRated});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pain Check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Any jaw discomfort right now?'),
          const SizedBox(height: 16),
          Row(
            children: List.generate(11, (i) => _buildVASButton(context, i)),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('No pain'),
              Text('Worst pain'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildVASButton(BuildContext context, int vas) {
    Color color =
        vas <= 2 ? Colors.green : (vas <= 5 ? Colors.yellow : Colors.red);
    return Expanded(
      child: Semantics(
        label: 'Pain level $vas out of 10',
        button: true,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop(vas);
            onRated(vas);
          },
          child: Container(
            height: 50,
            margin: const EdgeInsets.all(2),
            color: color,
            child: Center(child: Text('$vas')),
          ),
        ),
      ),
    );
  }
}
