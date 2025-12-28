import 'package:flutter/material.dart';
import 'package:international_cunnibal/models/tongue_data.dart';

/// Overlay widget for displaying tracking data on camera preview
class TrackingOverlay extends StatelessWidget {
  final TongueData tongueData;

  const TrackingOverlay({super.key, required this.tongueData});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackingPainter(tongueData),
      child: Container(),
    );
  }
}

class _TrackingPainter extends CustomPainter {
  final TongueData tongueData;

  _TrackingPainter(this.tongueData);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw landmarks
    final landmarkPaint = Paint()
      ..color = tongueData.isValidated ? Colors.green : Colors.orange
      ..style = PaintingStyle.fill;

    for (final landmark in tongueData.landmarks) {
      final position = Offset(
        landmark.dx * size.width,
        landmark.dy * size.height,
      );
      canvas.drawCircle(position, 4, landmarkPaint);
    }

    // Draw main position with larger circle
    final mainPaint = Paint()
      ..color = tongueData.isValidated
          ? Colors.green.withAlpha(128)
          : Colors.orange.withAlpha(128)
      ..style = PaintingStyle.fill;

    final mainPosition = Offset(
      tongueData.position.dx * size.width,
      tongueData.position.dy * size.height,
    );
    canvas.drawCircle(mainPosition, 20, mainPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = tongueData.isValidated ? Colors.green : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(mainPosition, 20, borderPaint);

    // Draw velocity indicator
    if (tongueData.velocity > 0) {
      final velocityPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final velocityLength = tongueData.velocity * 2;
      final velocityEnd = Offset(
        mainPosition.dx + velocityLength,
        mainPosition.dy,
      );
      canvas.drawLine(mainPosition, velocityEnd, velocityPaint);
    }
  }

  @override
  bool shouldRepaint(_TrackingPainter oldDelegate) {
    return oldDelegate.tongueData != tongueData;
  }
}
