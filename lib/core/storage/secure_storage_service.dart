import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _apiConfigKey = 'recplay_active_api_config';
  static const String _adminPinKey = 'recplay_admin_pin';
  static const String _favoritesKey = 'recplay_favorites_list';
  static const String _recentKey = 'recplay_recent_list';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  Future<void> saveApiConfig(Map<String, dynamic> configJson) async {
    final raw = jsonEncode(configJson);
    await _storage.write(key: _apiConfigKey, value: raw);
  }

  Future<Map<String, dynamic>?> getApiConfig() async {
    final raw = await _storage.read(key: _apiConfigKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearApiConfig() async {
    await _storage.delete(key: _apiConfigKey);
  }

  Future<void> saveAdminPin(String pin) async {
    await _storage.write(key: _adminPinKey, value: pin);
  }

  Future<String> getAdminPin() async {
    final pin = await _storage.read(key: _adminPinKey);
    return pin ?? '0000'; // PIN padrão inicial para primeiro acesso
  }

  // ==================== FAVORITOS ====================
  Future<List<String>> getFavoriteIds() async {
    final raw = await _storage.read(key: _favoritesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isFavorite(String id) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(id);
  }

  Future<bool> toggleFavorite(String id) async {
    final favorites = await getFavoriteIds();
    final bool nowFavorite;
    if (favorites.contains(id)) {
      favorites.remove(id);
      nowFavorite = false;
    } else {
      favorites.add(id);
      nowFavorite = true;
    }
    await _storage.write(key: _favoritesKey, value: jsonEncode(favorites));
    return nowFavorite;
  }

  // ==================== RECENTES ====================
  Future<List<String>> getRecentIds() async {
    final raw = await _storage.read(key: _recentKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecentId(String id) async {
    final recent = await getRecentIds();
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > 25) {
      recent.removeLast();
    }
    await _storage.write(key: _recentKey, value: jsonEncode(recent));
  }
}
