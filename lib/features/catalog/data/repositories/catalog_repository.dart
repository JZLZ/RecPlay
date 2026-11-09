import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dynamic_api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../admin/domain/repositories/api_config_repository.dart';
import '../../domain/entities/media_item.dart';

class CatalogRepository {
  final DynamicApiClient _apiClient;
  final ApiConfigRepository _configRepository;
  final SecureStorageService _storageService;

  // Caches em memória para navegação instantânea (0ms de latência)
  List<MediaCategory>? _cachedHome;
  List<MediaCategory>? _cachedChannels;
  List<MediaCategory>? _cachedMovies;
  List<MediaCategory>? _cachedSeries;
  List<MediaCategory>? _cachedAnimes;
  final Map<String, MediaItem> _allItemsMap = {};

  CatalogRepository({
    required DynamicApiClient apiClient,
    required ApiConfigRepository configRepository,
    required SecureStorageService storageService,
  })  : _apiClient = apiClient,
        _configRepository = configRepository,
        _storageService = storageService;

  // ==================== INÍCIO (HOME) ====================
  Future<List<MediaCategory>> getHomeContent({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHome != null && _cachedHome!.isNotEmpty) {
      return await _enrichWithPersonalizedRows(_cachedHome!);
    }

    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) return [];

    final categories = <MediaCategory>[];

    try {
      final homeUrl = config.resolveUrl('?page=viewHome');
      final response = await _apiClient.post(
        homeUrl,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'MegaFlix/1.2',
            ...?config.customHeaders,
          },
        ),
      );

      final raw = response.data?.toString() ?? '';
      if (raw.contains('class="section"') || raw.contains('data-data=')) {
        final parsed = _parseMegaFlixSections(raw, defaultType: 'movie');
        categories.addAll(parsed);
      }
    } catch (_) {
      // Fallback para conteúdo genérico VOD
      try {
        final vod = await _fetchVODContent(config.resolveUrl(config.categoriesEndpoint ?? config.contentEndpoint), config.customHeaders);
        categories.addAll(vod);
      } catch (_) {}
    }

    // Se estiver vazio, tenta carregar os canais como início padrão
    if (categories.isEmpty) {
      final channels = await getChannels();
      return channels;
    }

    _cachedHome = categories;
    return await _enrichWithPersonalizedRows(categories);
  }

  // ==================== CANAIS AO VIVO ====================
  Future<List<MediaCategory>> getChannels({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedChannels != null && _cachedChannels!.isNotEmpty) {
      return _cachedChannels!;
    }

    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) return [];

    try {
      final liveUrl = (config.liveEndpoint != null && config.liveEndpoint!.isNotEmpty)
          ? config.resolveUrl(config.liveEndpoint)
          : config.resolveUrl('?page=viewChannels');

      final response = await _apiClient.get(
        liveUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': '*/*',
            'User-Agent': 'MegaFlix/1.2',
            ...?config.customHeaders,
          },
        ),
      );

      final raw = response.data?.toString() ?? '';
      if (raw.contains('class="channel"') || raw.contains('data-data=')) {
        final channels = _parseMegaFlixChannels(raw);
        _cachedChannels = channels;
        return channels;
      }
    } catch (_) {}

    return [];
  }

  // ==================== FILMES ====================
  Future<List<MediaCategory>> getMovies({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMovies != null && _cachedMovies!.isNotEmpty) {
      return _cachedMovies!;
    }

    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) return [];

    final categories = <MediaCategory>[];

    try {
      // 1. Carrega primeiras seções principais de filmes
      final moviesUrl = config.resolveUrl('?page=viewMovies');
      final resp = await _apiClient.post(
        moviesUrl,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'MegaFlix/1.2',
            ...?config.customHeaders,
          },
        ),
      );
      final raw = resp.data?.toString() ?? '';
      if (raw.isNotEmpty) {
        categories.addAll(_parseMegaFlixSections(raw, defaultType: 'movie'));
      }

      // 2. Pré-carrega páginas adicionais de gêneros em paralelo para enriquecer o catálogo
      final extraFutures = [2, 3].map((page) async {
        try {
          final pageUrl = config.resolveUrl('?page=getGenres&pagination=$page&type=1');
          final r = await _apiClient.get(
            pageUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
            ),
          );
          final text = r.data?.toString() ?? '';
          if (text.length > 50) {
            return _parseMegaFlixSections(text, defaultType: 'movie');
          }
        } catch (_) {}
        return <MediaCategory>[];
      });

      final extraResults = await Future.wait(extraFutures);
      for (final extra in extraResults) {
        categories.addAll(extra);
      }
    } catch (_) {}

    if (categories.isNotEmpty) {
      _cachedMovies = categories;
    }
    return categories;
  }

  // ==================== SÉRIES ====================
  Future<List<MediaCategory>> getSeries({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSeries != null && _cachedSeries!.isNotEmpty) {
      return _cachedSeries!;
    }

    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) return [];

    final categories = <MediaCategory>[];

    try {
      final seriesUrl = config.resolveUrl('?page=viewSeries');
      final resp = await _apiClient.post(
        seriesUrl,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'MegaFlix/1.2',
            ...?config.customHeaders,
          },
        ),
      );
      final raw = resp.data?.toString() ?? '';
      if (raw.isNotEmpty) {
        categories.addAll(_parseMegaFlixSections(raw, defaultType: 'series'));
      }

      final extraFutures = [2, 3].map((page) async {
        try {
          final pageUrl = config.resolveUrl('?page=getGenres&pagination=$page&type=2');
          final r = await _apiClient.get(
            pageUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
            ),
          );
          final text = r.data?.toString() ?? '';
          if (text.length > 50) {
            return _parseMegaFlixSections(text, defaultType: 'series');
          }
        } catch (_) {}
        return <MediaCategory>[];
      });

      final extraResults = await Future.wait(extraFutures);
      for (final extra in extraResults) {
        categories.addAll(extra);
      }
    } catch (_) {}

    if (categories.isNotEmpty) {
      _cachedSeries = categories;
    }
    return categories;
  }

  // ==================== ANIMES ====================
  Future<List<MediaCategory>> getAnimes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAnimes != null && _cachedAnimes!.isNotEmpty) {
      return _cachedAnimes!;
    }

    final config = await _configRepository.getActiveConfig();
    if (config == null || !config.isValid) return [];

    final categories = <MediaCategory>[];

    try {
      final animesUrl = config.resolveUrl('?page=viewAnimes');
      final resp = await _apiClient.post(
        animesUrl,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'MegaFlix/1.2',
            ...?config.customHeaders,
          },
        ),
      );
      final raw = resp.data?.toString() ?? '';
      if (raw.isNotEmpty) {
        categories.addAll(_parseMegaFlixSections(raw, defaultType: 'anime'));
      }
    } catch (_) {}

    if (categories.isNotEmpty) {
      _cachedAnimes = categories;
    }
    return categories;
  }

  // ==================== BUSCA ONLINE & LOCAL ====================
  Future<List<MediaItem>> searchOnline(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final results = <MediaItem>[];
    final addedIds = <String>{};

    // 1. Busca Local nos Canais ao Vivo
    for (final item in _allItemsMap.values) {
      if (item.isLive && item.title.toLowerCase().contains(cleanQuery.toLowerCase())) {
        if (addedIds.add(item.id)) {
          results.add(item);
        }
      }
    }

    // 2. Busca na API Remota MegaFlix (Filmes, Séries, Animes)
    try {
      final config = await _configRepository.getActiveConfig();
      if (config != null && config.isValid) {
        final searchUrl = config.resolveUrl('?page=getItemsByTitle&title=${Uri.encodeComponent(cleanQuery)}');
        final resp = await _apiClient.get(
          searchUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
          ),
        );

        final raw = resp.data?.toString() ?? '';
        if (raw.startsWith('[') && raw.endsWith(']')) {
          final list = jsonDecode(raw) as List;
          for (final entry in list) {
            if (entry is Map<String, dynamic>) {
              final id = entry['id']?.toString() ?? '';
              if (id.isEmpty) continue;

              final item = MediaItem(
                id: id,
                title: entry['titulo'] ?? entry['title'] ?? 'Sem título',
                posterUrl: entry['bg'] ?? entry['img'],
                backdropUrl: entry['bg'] ?? entry['img'],
                year: entry['ano']?.toString(),
                mediaType: 'movie',
                streamUrl: '',
              );

              _allItemsMap[id] = item;
              if (addedIds.add(id)) {
                results.add(item);
              }
            }
          }
        }
      }
    } catch (_) {}

    return results;
  }

  // ==================== TEMPORADAS E EPISÓDIOS (SÉRIES) ====================
  Future<List<SeasonInfo>> getSeriesSeasons(String seriesId) async {
    final seasons = <SeasonInfo>[];
    try {
      final config = await _configRepository.getActiveConfig();
      if (config == null) return seasons;

      final url = config.resolveUrl('?page=viewItem&id=$seriesId');
      final resp = await _apiClient.post(
        url,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
        ),
      );

      final html = resp.data?.toString() ?? '';
      final regex = RegExp(r'''onclick=['"]getEpisodes\(['"](\d+)['"],\s*['"](\d+)['"]\)['"][^>]*>([^<]+)<''');
      final matches = regex.allMatches(html);

      for (final m in matches) {
        final sNum = int.tryParse(m.group(1) ?? '1') ?? 1;
        final title = (m.group(3) ?? '$sNumª Temporada').trim();
        seasons.add(SeasonInfo(seasonNum: sNum, title: title));
      }
    } catch (_) {}

    if (seasons.isEmpty) {
      seasons.add(const SeasonInfo(seasonNum: 1, title: '1ª Temporada'));
    }
    return seasons;
  }

  Future<List<MediaItem>> getSeriesEpisodes(String seriesId, int season) async {
    final episodes = <MediaItem>[];
    try {
      final config = await _configRepository.getActiveConfig();
      if (config == null) return episodes;

      final url = config.resolveUrl('?page=getEpisodes&season=$season&item=$seriesId');
      final resp = await _apiClient.post(
        url,
        data: 'episodesCheck=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
        ),
      );

      final html = resp.data?.toString() ?? '';
      final matches = RegExp(r'episode:\s*\{([^}]+)\}').allMatches(html);

      for (final m in matches) {
        final content = m.group(1) ?? '';
        final idMatch = RegExp(r'''id:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final titleMatch = RegExp(r'''title:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final epNumMatch = RegExp(r'''episode_num:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final posterMatch = RegExp(r'''poster:\s*['"]([^'"]+)['"]''').firstMatch(content);

        final id = idMatch?.group(1) ?? 'ep_${seriesId}_${season}_${episodes.length + 1}';
        final title = titleMatch?.group(1) ?? 'Episódio ${episodes.length + 1}';
        final epNum = int.tryParse(epNumMatch?.group(1) ?? '') ?? (episodes.length + 1);
        final poster = posterMatch?.group(1);

        final epItem = MediaItem(
          id: id,
          title: '$season x $epNum - $title',
          overview: 'Temporada $season • Episódio $epNum',
          posterUrl: poster,
          backdropUrl: poster,
          seriesId: seriesId,
          seasonNum: season,
          episodeNum: epNum,
          mediaType: 'episode',
          streamUrl: '',
        );

        _allItemsMap[epItem.id] = epItem;
        episodes.add(epItem);
      }
    } catch (_) {}

    return episodes;
  }

  // ==================== STREAM RESOLVER DINÂMICO ====================
  Future<String?> resolveStreamUrl(MediaItem item) async {
    // 1. Canais ao vivo
    if (item.isLive || item.streamUrl.contains('get_token_channel.php')) {
      final tokenUrl = item.streamUrl.isNotEmpty
          ? item.streamUrl
          : 'https://app.megafrixapi.com/get_token_channel.php?channel=${item.id}';
      return await _resolveTokenToM3u8(tokenUrl);
    }

    // 2. Filmes ou Episódios via Warez2 / Voltz
    final targetId = item.seriesId ?? item.id;
    final seasonParam = item.seasonNum != null ? '&season_num=${item.seasonNum}' : '';
    final epParam = item.episodeNum != null ? '&episode_num=${item.episodeNum}' : '';
    final warezUrl = 'https://megafrixapi.com/iptv/warez2.php?item_id=$targetId$seasonParam$epParam';

    try {
      final resp = await _apiClient.get(
        warezUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'MegaFlix/1.2'},
        ),
      );

      final raw = resp.data?.toString() ?? '';
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && decoded['br'] is List) {
          final brList = decoded['br'] as List;
          for (final entry in brList) {
            final urlStr = entry.toString();
            if (urlStr.contains('voltz.php')) {
              final voltzResolved = await _resolveVoltzStream(urlStr);
              if (voltzResolved != null && voltzResolved.isNotEmpty) {
                return voltzResolved;
              }
            } else if (urlStr.contains('.mp4') || urlStr.contains('.m3u8')) {
              return urlStr;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fallback inteligente
    if (item.streamUrl.isNotEmpty) {
      if (item.streamUrl.contains('token') || !item.streamUrl.endsWith('.m3u8')) {
        final tokenResolved = await _resolveTokenToM3u8(item.streamUrl);
        if (tokenResolved.isNotEmpty) return tokenResolved;
      }
      return item.streamUrl;
    }

    return null;
  }

  Future<String?> _resolveVoltzStream(String url) async {
    try {
      final resp = await _apiClient.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Referer': 'https://megaflix.name',
          },
        ),
      );
      final body = resp.data?.toString() ?? '';
      final regex = RegExp(r'''(?:var|const|let)\s+stream\s*=\s*['"](https?://[^'"]+)['"]''');
      final m = regex.firstMatch(body);
      if (m != null && m.group(1) != null) {
        return m.group(1)!;
      }
    } catch (_) {}
    return null;
  }

  Future<String> _resolveTokenToM3u8(String url) async {
    try {
      final resp = await _apiClient.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Referer': 'https://megaflix.name',
          },
        ),
      );
      final body = resp.data?.toString() ?? '';
      final regex = RegExp(r'''(?:var|const|let)\s+stream\s*=\s*['"](https?://[^'"]+)['"]''');
      final m = regex.firstMatch(body);
      if (m != null && m.group(1) != null) {
        return m.group(1)!;
      }
    } catch (_) {}
    return url;
  }

  // ==================== FAVORITOS E RECENTES ====================
  Future<bool> toggleFavorite(String id) async {
    return await _storageService.toggleFavorite(id);
  }

  Future<bool> isFavorite(String id) async {
    return await _storageService.isFavorite(id);
  }

  Future<void> recordRecent(String id) async {
    await _storageService.addRecentId(id);
  }

  Future<List<MediaCategory>> getFavorites() async {
    final favIds = await _storageService.getFavoriteIds();
    final items = <MediaItem>[];
    for (final id in favIds) {
      if (_allItemsMap.containsKey(id)) {
        items.add(_allItemsMap[id]!);
      }
    }

    if (items.isEmpty) return [];

    return [
      MediaCategory(
        id: 'user_favorites',
        title: '⭐ Seus Favoritos (${items.length})',
        items: items,
      ),
    ];
  }

  Future<List<MediaItem>> getRecentItems() async {
    final recIds = await _storageService.getRecentIds();
    final items = <MediaItem>[];
    for (final id in recIds) {
      if (_allItemsMap.containsKey(id)) {
        items.add(_allItemsMap[id]!);
      }
    }
    return items;
  }

  Future<List<MediaCategory>> _enrichWithPersonalizedRows(List<MediaCategory> baseCategories) async {
    final result = <MediaCategory>[];

    // Adiciona Favoritos no topo se houver itens salvos
    final favorites = await getFavorites();
    if (favorites.isNotEmpty) {
      result.addAll(favorites);
    }

    // Adiciona Recentes no topo se houver itens assistidos
    final recents = await getRecentItems();
    if (recents.isNotEmpty) {
      result.add(
        MediaCategory(
          id: 'user_recent',
          title: '🕒 Continuar Assistindo (${recents.length})',
          items: recents,
        ),
      );
    }

    result.addAll(baseCategories);
    return result;
  }

  // ==================== PARSERS INTERNOS ====================
  List<MediaCategory> _parseMegaFlixSections(String html, {required String defaultType}) {
    final results = <MediaCategory>[];
    final rawSections = html.split('<div class="section">');

    for (final sectionBlock in rawSections) {
      if (sectionBlock.trim().isEmpty) continue;

      final titleMatch = RegExp(r'<span class="title">([^<]+)</span>').firstMatch(sectionBlock);
      if (titleMatch == null) continue;

      final title = titleMatch.group(1)!.trim();
      final itemsB64 = RegExp(r'data-data="([^"]+)"').allMatches(sectionBlock);
      final items = <MediaItem>[];

      for (final match in itemsB64) {
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

          final item = MediaItem(
            id: id,
            title: map['titulo'] ?? map['title'] ?? map['name'] ?? 'Título',
            overview: map['sinopse'] ?? map['overview'],
            posterUrl: map['img'] ?? map['poster'],
            backdropUrl: map['bg'] ?? map['background'] ?? map['img'],
            year: map['ano']?.toString() ?? map['year']?.toString(),
            mediaType: defaultType,
            streamUrl: '',
          );

          _allItemsMap[id] = item;
          items.add(item);
        } catch (_) {}
      }

      if (items.isNotEmpty) {
        results.add(
          MediaCategory(
            id: 'sec_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
            title: title,
            items: items,
          ),
        );
      }
    }

    return results;
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
          mediaType: 'channel',
          streamUrl: 'https://app.megafrixapi.com/get_token_channel.php?channel=$id',
          streamType: 'hls',
          streamHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
            'Referer': 'https://megaflix.name',
          },
        );

        _allItemsMap[id] = item;
        allChannels.add(item);

        for (final catId in catIds) {
          if (catId == '0') continue;
          final catName = _getChannelCategoryTitle(catId);
          categoryMap.putIfAbsent(catName, () => []).add(item);
        }
      } catch (_) {}
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

  String _getChannelCategoryTitle(String catId) {
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

  // Compatibilidade com código legado
  Future<List<MediaCategory>> getCategoriesAndContent() async {
    return await getHomeContent();
  }
}
