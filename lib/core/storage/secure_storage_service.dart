import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _apiConfigKey = 'recplay_active_api_config';
  static const String _adminPinKey = 'recplay_admin_pin';

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
}
