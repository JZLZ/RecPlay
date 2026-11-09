import '../entities/api_config.dart';
import '../repositories/api_config_repository.dart';

class GetActiveConfig {
  final ApiConfigRepository repository;
  GetActiveConfig(this.repository);

  Future<ApiConfig?> call() => repository.getActiveConfig();
}

class SaveApiConfig {
  final ApiConfigRepository repository;
  SaveApiConfig(this.repository);

  Future<void> call(ApiConfig config) => repository.saveConfig(config);
}

class ValidateApiConfig {
  final ApiConfigRepository repository;
  ValidateApiConfig(this.repository);

  Future<Map<String, dynamic>> call(ApiConfig config) async {
    final results = await repository.validateAllEndpoints(config);
    return results.map((key, value) => MapEntry(key, value.toMap()));
  }
}

class VerifyAdminPin {
  final ApiConfigRepository repository;
  VerifyAdminPin(this.repository);

  Future<bool> call(String pin) => repository.verifyAdminPin(pin);
}
