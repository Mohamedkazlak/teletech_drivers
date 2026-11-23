import 'package:flutter/foundation.dart';

/// App-wide configuration resolved from `--dart-define` and platform defaults.
abstract final class AppConfig {
  /// Override with `--dart-define=API_BASE_URL=https://host/api`.
  static const String _defineApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Same value as `REVERB_APP_KEY`. Empty disables the live socket.
  static const String reverbAppKey = String.fromEnvironment('REVERB_APP_KEY');

  static const String _reverbHostOverride = String.fromEnvironment(
    'REVERB_HOST',
  );

  static const String _reverbPort = String.fromEnvironment('REVERB_PORT');

  static const String _reverbScheme = String.fromEnvironment('REVERB_SCHEME');

  /// Laravel API base URL including the `/api` suffix (no trailing slash).
  static String get apiBaseUrl {
    final fromDefine = _defineApiBaseUrl.trim();
    if (fromDefine.isNotEmpty) return _stripTrailingSlash(fromDefine);
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL must be set via --dart-define for release builds.',
      );
    }
    return _stripTrailingSlash(_debugDefaultBaseUrl);
  }

  static String get _debugDefaultBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// WebSocket host. Defaults to the API host so an emulator uses 10.0.2.2
  /// and a phone uses the LAN address passed as API_BASE_URL.
  static String get reverbHost {
    final override = _reverbHostOverride.trim();
    if (override.isNotEmpty) return override;
    return Uri.parse(apiBaseUrl).host;
  }

  static int get reverbPort => int.tryParse(_reverbPort) ?? 8080;

  static bool get reverbUseTls => _reverbScheme == 'https';

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
