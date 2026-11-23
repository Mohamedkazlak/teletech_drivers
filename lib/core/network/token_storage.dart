/// Persists the Sanctum bearer token across app launches.
abstract interface class TokenStorage {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clearToken();
}
