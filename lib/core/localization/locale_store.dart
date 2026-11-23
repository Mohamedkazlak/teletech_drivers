import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the chosen locale. `shared_preferences` is already a dependency
/// and is the app's local key-value store.
abstract final class LocaleStore {
  static const storageKey = 'app_locale';

  static Future<Locale> read() async {
    final prefs = await SharedPreferences.getInstance();
    return parse(prefs.getString(storageKey));
  }

  static Future<void> write(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, locale.languageCode);
  }

  static Locale parse(String? code) {
    if (code == 'ar') return const Locale('ar');
    return const Locale('en');
  }
}
