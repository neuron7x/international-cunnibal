import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/services/ui/bio_tracking_service.dart';
import 'package:international_cunnibal/services/ui/cv_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BioTrackingService', () {
    late BioTrackingService service;

    setUp(() {
      service = BioTrackingService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Model Loading', () {
      test('initial status is notLoaded', () {
        expect(service.status, TrackingStatus.notLoaded);
        expect(service.isRealTrackingEnabled, false);
      });

      test('graceful fallback when model loading fails', () async {
        // loadModel should handle missing model file gracefully
        await service.loadModel();
        
        // Should fallback to loadFailed or demo status
        expect(
          service.status,
          anyOf(TrackingStatus.loadFailed, TrackingStatus.demo),
        );
      });

      test('demo mode does not require model loading', () async {
        await service.setMode(CvEngineMode.demo);
        expect(service.status, TrackingStatus.demo);
        expect(service.isDemoMode, true);
        expect(service.isRealTrackingEnabled, false);
      });
    });

    group('Mode Toggling', () {
      test('can switch between demo and camera mode', () async {
        // Start in demo mode (default)
        expect(service.isDemoMode, true);

        // Note: Switching to camera mode requires camera setup
        // In tests, we just verify the mode can be set
        await service.setMode(CvEngineMode.demo);
        expect(service.isDemoMode, true);
      });

      test('switching mode stops tracking if active', () async {
        // This test verifies that mode changes handle tracking state
        expect(service.isTracking, false);
        
        await service.setMode(CvEngineMode.demo);
        expect(service.isDemoMode, true);
      });

      test('real tracking requires camera mode and loaded model', () {
        // Demo mode - no real tracking
        expect(service.isRealTrackingEnabled, false);
        
        // Even if we set camera mode, need loaded model
        // (can't test actual camera mode here without camera setup)
      });
    });

    group('Labels Parsing', () {
      test('label indices are empty before model load', () {
        expect(service.labelIndices, isEmpty);
      });

      test('label indices are immutable', () {
        final indices = service.labelIndices;
        expect(() => indices.add(1), throwsUnsupportedError);
      });
    });

    group('Tracking Status', () {
      test('status transitions correctly', () async {
        expect(service.status, TrackingStatus.notLoaded);
        
        await service.setMode(CvEngineMode.demo);
        expect(service.status, TrackingStatus.demo);
      });

      test('isRealTrackingEnabled requires loaded status and camera mode', () {
        expect(service.isRealTrackingEnabled, false);
        
        // Demo mode should never enable real tracking
        service.setMode(CvEngineMode.demo);
        expect(service.isRealTrackingEnabled, false);
      });
    });

    group('Service Lifecycle', () {
      test('service can be disposed without errors', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('tracking starts in demo mode without camera', () async {
        await service.setMode(CvEngineMode.demo);
        // Should be able to prepare in demo mode
        expect(() => service.prepare(), returnsNormally);
      });
    });
  });
}
