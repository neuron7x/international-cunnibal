import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/screens/tracking_screen.dart';

void main() {
  group('Tracking control gating', () {
    test('demo mode always enables control', () {
      expect(
        isTrackingControlEnabled(isDemoMode: true, cameraReady: false),
        isTrue,
      );
    });

    test('camera mode requires readiness', () {
      expect(
        isTrackingControlEnabled(isDemoMode: false, cameraReady: false),
        isFalse,
      );
      expect(
        isTrackingControlEnabled(isDemoMode: false, cameraReady: true),
        isTrue,
      );
    });
  });
}
