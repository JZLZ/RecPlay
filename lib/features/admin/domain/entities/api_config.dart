import 'package:equatable/equatable.dart';

class ApiConfig extends Equatable {
  final String name;
  final String baseUrl;
  final String? authEndpoint;
  final String? categoriesEndpoint;
  final String? contentEndpoint;
  final String? liveEndpoint;
  final String? authToken;
  final Map<String, String>? customHeaders;
  final DateTime lastUpdated;

  const ApiConfig({
    required this.name,
    required this.baseUrl,
    this.authEndpoint,
    this.categoriesEndpoint,
    this.contentEndpoint,
    this.liveEndpoint,
    this.authToken,
    this.customHeaders,
    required this.lastUpdated,
  });

  bool get isValid => baseUrl.isNotEmpty && (baseUrl.startsWith('http://') || baseUrl.startsWith('https://'));

  String resolveUrl(String? endpoint) {
    if (endpoint == null || endpoint.isEmpty) return '';
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEnd = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$cleanBase$cleanEnd';
  }

  @override
  List<Object?> get props => [
        name,
        baseUrl,
        authEndpoint,
        categoriesEndpoint,
        contentEndpoint,
        liveEndpoint,
        authToken,
        customHeaders,
        lastUpdated,
      ];
}
