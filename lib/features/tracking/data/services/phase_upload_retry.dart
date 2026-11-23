import 'dart:async';
import 'dart:math' as math;

/// Retries a failing phase upload with exponential backoff.
class PhaseUploadRetry {
  PhaseUploadRetry({
    this.maxAttempts = 8,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 2),
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;

  Future<void> run(
    Future<void> Function() action, {
    bool Function(Object error)? shouldRetry,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await action();
        return;
      } on Object catch (error) {
        lastError = error;
        final retry = shouldRetry?.call(error) ?? true;
        if (!retry || attempt == maxAttempts - 1) break;
        final seconds = math.min(
          maxDelay.inSeconds,
          initialDelay.inSeconds * math.pow(2, attempt).toInt(),
        );
        await Future<void>.delayed(Duration(seconds: seconds));
      }
    }
    Error.throwWithStackTrace(
      lastError ?? StateError('Phase upload failed'),
      StackTrace.current,
    );
  }
}
