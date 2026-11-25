import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the animated splash stays up on cold start, at minimum.
///
/// Long enough for the logo build-in to finish, so a fast auth check never
/// cuts the animation off mid-way. Tests override this with [Duration.zero].
final splashMinimumDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1900),
);

/// True once the splash has been on screen for its minimum duration.
final splashGateProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);

class SplashGate extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    final minimum = ref.watch(splashMinimumDurationProvider);
    if (minimum <= Duration.zero) return true;
    _timer?.cancel();
    _timer = Timer(minimum, () => state = true);
    ref.onDispose(() => _timer?.cancel());
    return false;
  }
}
