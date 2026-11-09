import 'package:dio/dio.dart';

class EndpointValidationResult {
  final String endpoint;
  final bool isReachable;
  final int? statusCode;
  final int latencyMs;
  final String? errorMessage;

  const EndpointValidationResult({
    required this.endpoint,
    required this.isReachable,
    this.statusCode,
    required this.latencyMs,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'endpoint': endpoint,
        'isReachable': isReachable,
        'statusCode': statusCode,
        'latencyMs': latencyMs,
        'errorMessage': errorMessage,
      };
}

class DynamicApiClient {
  final Dio _dio;

  DynamicApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                  'User-Agent': 'RecPlay/1.0',
                },
              ),
            );

  void updateConfiguration({
    String? baseUrl,
    Map<String, dynamic>? customHeaders,
    String? authToken,
  }) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
    if (customHeaders != null) {
      _dio.options.headers.addAll(customHeaders);
    }
    if (authToken != null && authToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $authToken';
    }
  }

  Dio get rawDio => _dio;

  /// Valida a conectividade em tempo real com um endpoint específico
  Future<EndpointValidationResult> validateEndpoint(
    String url, {
    Map<String, String>? headers,
    String? token,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final reqHeaders = <String, dynamic>{
        'Accept': 'application/json',
        ...?headers,
      };
      if (token != null && token.isNotEmpty) {
        reqHeaders['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: reqHeaders,
          validateStatus: (status) => true, // Aceita qualquer código para avaliar resposta do servidor
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      stopwatch.stop();
      final isSuccess = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 400;

      return EndpointValidationResult(
        endpoint: url,
        isReachable: isSuccess,
        statusCode: response.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return EndpointValidationResult(
        endpoint: url,
        isReachable: false,
        statusCode: e.response?.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.message ?? e.type.name,
      );
    } catch (e) {
      stopwatch.stop();
      return EndpointValidationResult(
        endpoint: url,
        isReachable: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
