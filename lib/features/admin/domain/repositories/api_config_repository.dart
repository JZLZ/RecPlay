import '../../../../core/network/dynamic_api_client.dart';
import '../entities/api_config.dart';

abstract class ApiConfigRepository {
  Future<ApiConfig?> getActiveConfig();
  Future<void> saveConfig(ApiConfig config);
  Future<void> clearConfig();
  Future<Map<String, EndpointValidationResult>> validateAllEndpoints(ApiConfig config);
  Future<bool> verifyAdminPin(String pin);
  Future<void> updateAdminPin(String newPin);
}
