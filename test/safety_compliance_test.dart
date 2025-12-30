import 'package:flutter_test/flutter_test.dart';
import 'package:international_cunnibal/models/endurance_session_state.dart';
import 'package:international_cunnibal/services/endurance_session_service.dart';
import 'package:international_cunnibal/services/health/session_tracker.dart';
import 'package:international_cunnibal/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('VAS 3+ stops session', () {
    final service = EnduranceSessionService();
    service.start(0);
    service.reportPainVAS(SafeEnduranceLimits.painStopThreshold);

    expect(service.state.phase, EnduranceSessionPhase.summary);
    expect(service.state.prompt, contains('Pain detected'));
  });

  test('4th session blocked', () async {
    final prefs = await SharedPreferences.getInstance();
    final tracker = SessionTracker(prefs);

    await tracker.recordSession();
    await tracker.recordSession();
    await tracker.recordSession();

    final eligible = await tracker.checkEligibility();
    expect(eligible.canStart, isFalse);
    expect(eligible.reason, contains('Weekly limit'));
  });

  test('second session too soon', () async {
    final prefs = await SharedPreferences.getInstance();
    final tracker = SessionTracker(prefs);
    await tracker.recordSession();

    final eligible = await tracker.checkEligibility();
    expect(eligible.canStart, isFalse);
  });
}
