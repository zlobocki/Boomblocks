import 'package:shared_preferences/shared_preferences.dart';

/// Persists acceptance of the in-app Terms of Use.
class LegalAcceptance {
  static const prefsKey = 'mine_puzzle_terms_accepted_v1';

  /// Bump when Terms change in a way that requires re-acceptance.
  static const termsVersion = 1;

  static const privacyUrl =
      'https://zlobocki.github.io/mine_puzzle/privacy.html';
  static const termsUrl = 'https://zlobocki.github.io/mine_puzzle/terms.html';

  static bool accepted = false;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      accepted = prefs.getInt(prefsKey) == termsVersion;
    } catch (_) {
      accepted = false;
    }
  }

  static Future<void> accept() async {
    accepted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefsKey, termsVersion);
    } catch (_) {}
  }
}
