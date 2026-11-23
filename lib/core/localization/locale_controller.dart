import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/locale_store.dart';

/// Locale loaded before [runApp]. Tests keep the English default.
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('en'));

/// Holds the active [Locale] and writes it locally.
/// Pattern: Dependency Injection (Riverpod).
final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => ref.watch(initialLocaleProvider);

  Future<void> setLocale(Locale locale) async {
    final next = LocaleStore.parse(locale.languageCode);
    state = next;
    await LocaleStore.write(next);
  }

  Future<void> toggleEnglishArabic() {
    return setLocale(
      state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
    );
  }
}
