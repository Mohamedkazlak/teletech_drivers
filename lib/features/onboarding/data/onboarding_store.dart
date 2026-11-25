import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per signed-in user, that the first-run guide has been seen.
///
/// Any storage failure counts as "seen", so a broken store can never trap
/// someone on the guide (and tests without a preferences plugin skip it).
abstract final class OnboardingStore {
  static String _key(String userId) => 'onboarding_seen_v1_$userId';

  static Future<bool> hasSeen(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(userId)) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markSeen(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(userId), true);
    } catch (_) {
      // Ignored: see class comment.
    }
  }
}
