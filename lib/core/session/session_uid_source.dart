/// Domain-friendly access to the signed-in user id.
abstract interface class SessionUidSource {
  String? get currentUserId;
}
