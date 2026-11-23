import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';

/// Observer: attaches a polled stream only while a session is active.
///
/// Returns [whenSignedOut] when the user is null, auth is still loading, or
/// [sessionSigningOutProvider] is true so listeners stop before sign-out.
Stream<T> authBoundStream<T>(
  Ref ref, {
  required Stream<T> Function(AppUser user) create,
  required T whenSignedOut,
}) {
  if (ref.watch(sessionSigningOutProvider)) {
    return Stream<T>.value(whenSignedOut);
  }

  final auth = ref.watch(currentUserProvider);
  return auth.when(
    data: (user) {
      if (user == null) {
        return Stream<T>.value(whenSignedOut);
      }
      return create(user);
    },
    loading: () => Stream<T>.value(whenSignedOut),
    error: (error, stackTrace) => Stream<T>.error(error, stackTrace),
  );
}
