import 'package:flutter/material.dart';

/// Tongue biomechanics data model
class TongueData {
  final DateTime timestamp;
  final Offset position; // Normalized position (0-1, 0-1)
  final double velocity; // Pixels per second
  final double acceleration; // Pixels per second squared
  final List<Offset> landmarks; // MediaPipe-style landmarks
  final bool isValidated; // Action Acceptor validation status

  const TongueData({
    required this.timestamp,
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.landmarks,
    required this.isValidated,
  });

  TongueData copyWith({
    DateTime? timestamp,
    Offset? position,
    double? velocity,
    double? acceleration,
    List<Offset>? landmarks,
    bool? isValidated,
  }) {
    return TongueData(
      timestamp: timestamp ?? this.timestamp,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      acceleration: acceleration ?? this.acceleration,
      landmarks: landmarks ?? this.landmarks,
      isValidated: isValidated ?? this.isValidated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'position': {'x': position.dx, 'y': position.dy},
      'velocity': velocity,
      'acceleration': acceleration,
      'landmarks': landmarks.map((l) => {'x': l.dx, 'y': l.dy}).toList(),
      'isValidated': isValidated,
    };
  }
}
