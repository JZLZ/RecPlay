import '../../domain/entities/api_config.dart';

class ApiConfigModel extends ApiConfig {
  const ApiConfigModel({
    required super.name,
    required super.baseUrl,
    super.authEndpoint,
    super.categoriesEndpoint,
    super.contentEndpoint,
    super.liveEndpoint,
    super.authToken,
    super.customHeaders,
    required super.lastUpdated,
  });

  factory ApiConfigModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? headers;
    if (json['custom_headers'] != null && json['custom_headers'] is Map) {
      headers = (json['custom_headers'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else if (json['customHeaders'] != null && json['customHeaders'] is Map) {
      headers = (json['customHeaders'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return ApiConfigModel(
      name: json['name'] as String? ?? 'Default Media Source',
      baseUrl: json['base_url'] as String? ?? json['baseUrl'] as String? ?? '',
      authEndpoint: json['auth_endpoint'] as String? ?? json['authEndpoint'] as String?,
      categoriesEndpoint: json['categories_endpoint'] as String? ?? json['categoriesEndpoint'] as String?,
      contentEndpoint: json['content_endpoint'] as String? ?? json['contentEndpoint'] as String?,
      liveEndpoint: json['live_endpoint'] as String? ?? json['liveEndpoint'] as String?,
      authToken: json['auth_token'] as String? ?? json['authToken'] as String?,
      customHeaders: headers,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'base_url': baseUrl,
      'auth_endpoint': authEndpoint,
      'categories_endpoint': categoriesEndpoint,
      'content_endpoint': contentEndpoint,
      'live_endpoint': liveEndpoint,
      'auth_token': authToken,
      'custom_headers': customHeaders,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ApiConfigModel.fromEntity(ApiConfig entity) {
    return ApiConfigModel(
      name: entity.name,
      baseUrl: entity.baseUrl,
      authEndpoint: entity.authEndpoint,
      categoriesEndpoint: entity.categoriesEndpoint,
      contentEndpoint: entity.contentEndpoint,
      liveEndpoint: entity.liveEndpoint,
      authToken: entity.authToken,
      customHeaders: entity.customHeaders,
      lastUpdated: entity.lastUpdated,
    );
  }
}
