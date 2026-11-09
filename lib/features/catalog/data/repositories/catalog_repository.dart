import 'dart:convert';
import 'package:dio/dio.dart';
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

    final categories = <MediaCategory>[];

    // 1. Carrega Canais ao Vivo (se liveEndpoint configurado ou fallback inteligente)
    try {
      final liveUrl = (config.liveEndpoint != null && config.liveEndpoint!.isNotEmpty)
          ? config.resolveUrl(config.liveEndpoint)
          : (config.baseUrl.contains('megafrixapi') || config.baseUrl.contains('megaflix'))
              ? config.resolveUrl('?page=viewChannels')
              : null;

      if (liveUrl != null && liveUrl.isNotEmpty) {
        final liveCategories = await _fetchLiveChannels(liveUrl, config.customHeaders);
        categories.addAll(liveCategories);
      }
    } catch (_) {
      // Continua caso ocorra falha na busca de canais
    }

    // 2. Carrega Conteúdo VOD (Categorias / Filmes / Séries)
    try {
      final contentUrl = config.resolveUrl(config.categoriesEndpoint ?? config.contentEndpoint);
      if (contentUrl.isNotEmpty) {
        final contentCategories = await _fetchVODContent(contentUrl, config.customHeaders);
        categories.addAll(contentCategories);
      }
    } catch (_) {
      // Continua caso ocorra falha no VOD
    }

    return categories;
  }

  Future<List<MediaCategory>> _fetchLiveChannels(String url, Map<String, String>? customHeaders) async {
    final response = await _apiClient.get(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Accept': '*/*',
          'User-Agent': 'MegaFlix/1.2',
          ...?customHeaders,
        },
      ),
    );

    if (response.data == null) return [];

    final raw = response.data;
    if (raw is String) {
      // Se for resposta HTML com canais em Base64
      if (raw.contains('class="channel"') || raw.contains('data-data=')) {
        return _parseMegaFlixChannels(raw);
      }

      // Se for JSON em formato String
      try {
        final parsedJson = jsonDecode(raw);
        return _parseJsonCategories(parsedJson);
      } catch (_) {}
    } else {
      return _parseJsonCategories(raw);
    }

    return [];
  }

  List<MediaCategory> _parseMegaFlixChannels(String html) {
    final regex = RegExp(r'data-data="([^"]+)"');
    final matches = regex.allMatches(html);

    final allChannels = <MediaItem>[];
    final categoryMap = <String, List<MediaItem>>{};

    for (final match in matches) {
      final b64 = match.group(1);
      if (b64 == null) continue;

      try {
        var cleanB64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
        while (cleanB64.length % 4 != 0) {
          cleanB64 += '=';
        }
        final decodedBytes = base64.decode(cleanB64);
        final decodedStr = utf8.decode(decodedBytes);
        final map = jsonDecode(decodedStr) as Map<String, dynamic>;

        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final name = map['name']?.toString() ?? id;
        final bg = map['background']?.toString() ?? 'https://img.faz-o-eli.online/$id.png';
        final catIds = (map['categories'] as List?)?.map((c) => c.toString()).toList() ?? [];

        final item = MediaItem(
          id: id,
          title: name,
          overview: 'Canal Ao Vivo - $name',
          posterUrl: bg,
          backdropUrl: bg,
          streamUrl: 'https://app.megafrixapi.com/get_token_channel.php?channel=$id',
          streamType: 'hls',
          streamHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
            'Referer': 'https://megaflix.name',
          },
        );

        allChannels.add(item);

        for (final catId in catIds) {
          if (catId == '0') continue; // Categoria 0 é "Todos"
          final catName = _getCategoryTitle(catId);
          categoryMap.putIfAbsent(catName, () => []).add(item);
        }
      } catch (_) {
        // Ignora canal malformado
      }
    }

    final result = <MediaCategory>[];

    if (allChannels.isNotEmpty) {
      result.add(
        MediaCategory(
          id: 'live_all',
          title: '★ Todos os Canais Ao Vivo (${allChannels.length})',
          items: allChannels,
        ),
      );
    }

    categoryMap.forEach((name, items) {
      result.add(
        MediaCategory(
          id: 'live_${name.toLowerCase().replaceAll(' ', '_')}',
          title: '📺 $name (${items.length})',
          items: items,
        ),
      );
    });

    return result;
  }

  String _getCategoryTitle(String catId) {
    switch (catId) {
      case '1':
        return 'Esportes';
      case '2':
        return 'Infantil & Desenhos';
      case '3':
        return 'Documentários';
      case '4':
        return 'Filmes & Séries';
      case '5':
        return 'Notícias';
      case '6':
        return 'Abertos & Variedades';
      case '7':
        return 'Canais 24 Horas';
      case '8':
        return 'Reality Shows';
      case '9':
        return 'Internacionais';
      default:
        return 'Canais Especiais';
    }
  }

  Future<List<MediaCategory>> _fetchVODContent(String url, Map<String, String>? customHeaders) async {
    final response = await _apiClient.get(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: customHeaders,
      ),
    );

    if (response.data == null) return [];

    final raw = response.data;
    if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        return _parseJsonCategories(parsed);
      } catch (_) {}
    } else {
      return _parseJsonCategories(raw);
    }

    return [];
  }

  List<MediaCategory> _parseJsonCategories(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => MediaCategory.fromJson(item))
          .toList();
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['categories'] != null && rawData['categories'] is List) {
        return (rawData['categories'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => MediaCategory.fromJson(item))
            .toList();
      }
      if (rawData['data'] != null && rawData['data'] is List) {
        return (rawData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => MediaCategory.fromJson(item))
            .toList();
      }
    }
    return [];
  }
}
