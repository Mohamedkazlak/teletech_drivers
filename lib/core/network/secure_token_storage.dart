import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teletech_drivers/core/network/token_storage.dart';

const _authTokenKey = 'auth_bearer_token';

/// [TokenStorage] backed by [FlutterSecureStorage].
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _authTokenKey);

  @override
  Future<void> writeToken(String token) {
    return _storage.write(key: _authTokenKey, value: token);
  }

  @override
  Future<void> clearToken() => _storage.delete(key: _authTokenKey);
}
