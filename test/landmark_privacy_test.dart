import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/utils/landmark_privacy.dart';

void main() {
  group('LandmarkPrivacyFilter', () {
    test('leaves small landmark sets unchanged', () {
      final landmarks = [const Offset(0.1, 0.2), const Offset(0.3, 0.4)];
      final filtered = LandmarkPrivacyFilter.stripFaceLandmarks(landmarks);
      expect(filtered, same(landmarks));
    });

    test('zeroes face landmarks and preserves body landmarks', () {
      final landmarks = List<Offset>.generate(
        15,
        (i) => Offset(i.toDouble(), i.toDouble()),
      );

      final filtered = LandmarkPrivacyFilter.stripFaceLandmarks(landmarks);

      for (var i = 0; i < LandmarkPrivacyFilter.defaultFaceLandmarkCount; i++) {
        expect(filtered[i], Offset.zero);
      }
      for (var i = LandmarkPrivacyFilter.defaultFaceLandmarkCount;
          i < landmarks.length;
          i++) {
        expect(filtered[i], landmarks[i]);
      }
    });
  });
}
