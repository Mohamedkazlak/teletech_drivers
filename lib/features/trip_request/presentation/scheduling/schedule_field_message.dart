import 'package:teletech_drivers/core/errors/failures.dart';

/// Server 422 text for a past `requested_at` or `scheduled_at`, if present.
String? scheduleFieldMessage(Failure? failure) {
  if (failure is! ValidationFailure) return null;
  for (final key in const ['requested_at', 'scheduled_at']) {
    final messages = failure.fieldErrors[key];
    if (messages == null) continue;
    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
  }
  return null;
}
