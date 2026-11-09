import '../../../../core/network/dynamic_api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/api_config.dart';
import '../../domain/repositories/api_config_repository.dart';
import '../models/api_config_model.dart';

class ApiConfigRepositoryImpl implements ApiConfigRepository {
  final SecureStorageService _storageService;
  final DynamicApiClient _apiClient;

  ApiConfigRepositoryImpl({
    required SecureStorageService storageService,
    required DynamicApiClient apiClient,
  })  : _storageService = storageService,
        _apiClient = apiClient;

  static final ApiConfig defaultConfig = ApiConfig(
    name: 'MegaFlix TV Provider',
    baseUrl: 'https://app.megafrixapi.com/TV/1.2/',
    categoriesEndpoint: '/',
    contentEndpoint: '/',
    liveEndpoint: 'https://app.megafrixapi.com/TV/1.2/?page=viewChannels',
    customHeaders: const {
      'User-Agent': 'MegaFlix/1.2',
      'Accept': '*/*',
      'Referer': 'https://megaflix.name',
    },
    lastUpdated: DateTime.now(),
  );

  @override
  Future<ApiConfig?> getActiveConfig() async {
    final json = await _storageService.getApiConfig();
    final ApiConfig config;
    if (json != null) {
      config = ApiConfigModel.fromJson(json);
    } else {
      config = defaultConfig;
      // Persiste automaticamente a configuração padrão para novas instalações
      try {
        final model = ApiConfigModel.fromEntity(config);
        await _storageService.saveApiConfig(model.toJson());
      } catch (_) {}
    }

    // Atualiza o cliente de rede com as configurações ativas
    _apiClient.updateConfiguration(
      baseUrl: config.baseUrl,
      customHeaders: config.customHeaders,
      authToken: config.authToken,
    );

    return config;
  }

  @override
  Future<void> saveConfig(ApiConfig config) async {
    final model = ApiConfigModel.fromEntity(config);
    await _storageService.saveApiConfig(model.toJson());

    // Atualiza imediatamente o cliente HTTP com as novas credenciais
    _apiClient.updateConfiguration(
      baseUrl: model.baseUrl,
      customHeaders: model.customHeaders,
      authToken: model.authToken,
    );
  }

  @override
  Future<void> clearConfig() async {
    await _storageService.clearApiConfig();
  }

  @override
  Future<Map<String, EndpointValidationResult>> validateAllEndpoints(ApiConfig config) async {
    final results = <String, EndpointValidationResult>{};

    // 1. Testa a Base URL
    if (config.baseUrl.isNotEmpty) {
      results['base_url'] = await _apiClient.validateEndpoint(
        config.baseUrl,
        headers: config.customHeaders,
        token: config.authToken,
      );
    }

    // 2. Testa endpoint de categorias
    if (config.categoriesEndpoint != null && config.categoriesEndpoint!.isNotEmpty) {
      final fullUrl = config.resolveUrl(config.categoriesEndpoint);
      results['categories'] = await _apiClient.validateEndpoint(
        fullUrl,
        headers: config.customHeaders,
        token: config.authToken,
      );
    }

    // 3. Testa endpoint de conteúdo
    if (config.contentEndpoint != null && config.contentEndpoint!.isNotEmpty) {
      final fullUrl = config.resolveUrl(config.contentEndpoint);
      results['content'] = await _apiClient.validateEndpoint(
        fullUrl,
        headers: config.customHeaders,
        token: config.authToken,
      );
    }

    // 4. Testa endpoint de canais ao vivo
    if (config.liveEndpoint != null && config.liveEndpoint!.isNotEmpty) {
      final fullUrl = config.resolveUrl(config.liveEndpoint);
      results['live'] = await _apiClient.validateEndpoint(
        fullUrl,
        headers: config.customHeaders,
        token: config.authToken,
      );
    }

    return results;
  }

  @override
  Future<bool> verifyAdminPin(String pin) async {
    final savedPin = await _storageService.getAdminPin();
    return pin == savedPin;
  }

  @override
  Future<void> updateAdminPin(String newPin) async {
    await _storageService.saveAdminPin(newPin);
  }
}
