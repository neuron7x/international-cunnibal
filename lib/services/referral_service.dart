class ReferralService {
  final Map<String, int> _referralCounts = {};
  final Map<String, int> _points = {};

  String generateReferralCode(String userId) =>
      userId.length <= 8 ? userId : userId.substring(0, 8);

  Future<void> trackReferral(
    String code, {
    String? refereeUserId,
  }) async {
    final count = _referralCounts[code] ?? 0;
    _referralCounts[code] = count + 1;

    _points[code] = (_points[code] ?? 0) + 50; // referrer bonus
    if (refereeUserId != null) {
      _points[refereeUserId] = (_points[refereeUserId] ?? 0) + 25;
    }
  }

  int referralCount(String code) => _referralCounts[code] ?? 0;

  int pointsFor(String code) => _points[code] ?? 0;
}
