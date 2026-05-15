import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for JWT tokens and user data.
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _homeHighlightsSeenKey = 'home_highlights_seen';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── Access Token ───
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  // ─── Refresh Token ───
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  // ─── User Role ───
  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<void> saveUserRole(String role) =>
      _storage.write(key: _userRoleKey, value: role);

  // ─── User ID ───
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> saveUserId(String id) =>
      _storage.write(key: _userIdKey, value: id);

  // ─── Save All Tokens ───
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // ─── Clear All ───
  Future<void> clearAll() => _storage.deleteAll();

  // ─── Check Auth ───
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Home Highlights ───
  Future<bool> hasSeenHomeHighlights() async {
    final seen = await _storage.read(key: _homeHighlightsSeenKey);
    return seen == 'true';
  }

  Future<void> setHomeHighlightsSeen() =>
      _storage.write(key: _homeHighlightsSeenKey, value: 'true');
}
