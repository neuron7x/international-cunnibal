import 'package:flutter/material.dart';

class LandmarkPrivacyFilter {
  static const int defaultFaceLandmarkCount = 11;

  static List<Offset> stripFaceLandmarks(
    List<Offset> landmarks, {
    int faceLandmarkCount = defaultFaceLandmarkCount,
  }) {
    if (landmarks.isEmpty || landmarks.length <= faceLandmarkCount) {
      return landmarks;
    }

    return List<Offset>.generate(landmarks.length, (index) {
      if (index < faceLandmarkCount) {
        return Offset.zero;
      }
      return landmarks[index];
    });
  }
}
