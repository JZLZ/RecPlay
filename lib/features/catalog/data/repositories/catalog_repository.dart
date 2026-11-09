import '../../../../core/network/dynamic_api_client.dart';
import '../../../admin/domain/repositories/api_config_repository.dart';
import '../../domain/entities/media_item.dart';

class CatalogRepository {
  final DynamicApiClient _apiClient;
  final ApiConfigRepository _configRepository;

  CatalogRepository({
    required DynamicApiClient apiClient,
    required ApiConfigRepository configRepository,
  })  : _apiClient = apiClient,
        _configRepository = configRepository;

  Future<List<MediaCategory>> getCategoriesAndContent() async {
    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) {
      return [];
    }

    final categoriesUrl = config.resolveUrl(config.categoriesEndpoint ?? config.contentEndpoint);
    if (categoriesUrl.isEmpty) return [];

    try {
      final response = await _apiClient.get(categoriesUrl);
      if (response.data == null) return [];

      final rawData = response.data;
      if (rawData is List) {
        return rawData
            .map((item) => MediaCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (rawData is Map<String, dynamic>) {
        if (rawData['categories'] != null && rawData['categories'] is List) {
          return (rawData['categories'] as List)
              .map((item) => MediaCategory.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (rawData['data'] != null && rawData['data'] is List) {
          return (rawData['data'] as List)
              .map((item) => MediaCategory.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
