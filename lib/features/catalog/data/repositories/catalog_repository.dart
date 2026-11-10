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
  final Set<String> _knownSeriesIds = {};
  final Set<String> _knownMovieIds = {};
  final Map<String, Map<String, String>> _episodeRawUrls = {};

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

      // Tenta regex completa com extração de players (br e eng)
      final epDivRegex = RegExp(r'''onclick=['"]loadPlayers\(\{\s*br:\s*['"]([^'"]*)['"],\s*eng:\s*['"]([^'"]*)['"],.*?episode:\s*\{([^}]+)\}''', dotAll: true);
      final epMatches = epDivRegex.allMatches(html);

      for (final m in epMatches) {
        final brStr = m.group(1) ?? '';
        final engStr = m.group(2) ?? '';
        final content = m.group(3) ?? '';
        final idMatch = RegExp(r'''id:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final titleMatch = RegExp(r'''title:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final epNumMatch = RegExp(r'''episode_num:\s*['"]([^'"]+)['"]''').firstMatch(content);
        final posterMatch = RegExp(r'''poster:\s*['"]([^'"]+)['"]''').firstMatch(content);

        final id = idMatch?.group(1) ?? 'ep_${seriesId}_${season}_${episodes.length + 1}';
        final title = titleMatch?.group(1) ?? 'Episódio ${episodes.length + 1}';
        final epNum = int.tryParse(epNumMatch?.group(1) ?? '') ?? (episodes.length + 1);
        final poster = posterMatch?.group(1);

        _episodeRawUrls[id] = {
          'br': brStr,
          'eng': engStr,
        };

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

      // Fallback para caso o formato do HTML seja diferente
      if (episodes.isEmpty) {
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
      }
    } catch (_) {}

    return episodes;
  }

  // ==================== VERIFICAÇÃO INTELIGENTE DE SÉRIE ====================
  Future<bool> checkIfSeries(MediaItem item) async {
    if (item.isSeries || item.isAnime || item.isEpisode) return true;
    if (_knownSeriesIds.contains(item.id)) return true;
    if (_knownMovieIds.contains(item.id)) return false;
    if (item.isLive) return false;

    try {
      final config = await _configRepository.getActiveConfig();
      if (config == null) return false;
      final url = config.resolveUrl('?page=viewItem&id=${item.id}');
      final resp = await _apiClient.post(
        url,
        data: 'userHistoric=[]',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'MegaFlix/1.2', ...?config.customHeaders},
        ),
      );
      final html = resp.data?.toString() ?? '';
      if (html.contains('class="season"') || html.contains('getEpisodes(')) {
        _knownSeriesIds.add(item.id);
        _allItemsMap[item.id] = item.copyWith(mediaType: 'series');
        return true;
      } else {
        _knownMovieIds.add(item.id);
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  // ==================== LISTA DE SERVIDORES (DUBLADOS & LEGENDADOS) ====================
  Future<MediaServersResult> getMediaServers(MediaItem item) async {
    final dubbedUrls = <String>[];
    final subbedUrls = <String>[];

    try {
      final config = await _configRepository.getActiveConfig();
      final customHeaders = config?.customHeaders ?? {};

      if (item.isEpisode || item.seriesId != null) {
        // 1. EPISÓDIO DE SÉRIE
        final targetId = item.seriesId ?? item.id;
        final season = item.seasonNum ?? 1;
        final episode = item.episodeNum ?? 1;

        // A. Dados de Warez2
        final warezUrl = 'https://megafrixapi.com/iptv/warez2.php?item_id=$targetId&season_num=$season&episode_num=$episode';
        try {
          final resp = await _apiClient.get(
            warezUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'MegaFlix/1.2', ...customHeaders},
            ),
          );
          final raw = resp.data?.toString() ?? '';
          if (raw.isNotEmpty) {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              if (decoded['br'] is List) {
                for (final u in decoded['br'] as List) {
                  dubbedUrls.add(u.toString());
                }
              }
              if (decoded['eng'] is List) {
                for (final u in decoded['eng'] as List) {
                  subbedUrls.add(u.toString());
                }
              }
            }
          }
        } catch (_) {}

        // B. Dados em cache de getEpisodes
        if (_episodeRawUrls.containsKey(item.id)) {
          final rawMap = _episodeRawUrls[item.id]!;
          final brStr = rawMap['br'] ?? '';
          final engStr = rawMap['eng'] ?? '';
          if (brStr.isNotEmpty) {
            for (final u in brStr.split(',')) {
              if (u.trim().isNotEmpty) dubbedUrls.add(u.trim());
            }
          }
          if (engStr.isNotEmpty) {
            for (final u in engStr.split(',')) {
              if (u.trim().isNotEmpty) subbedUrls.add(u.trim());
            }
          }
        }
      } else {
        // 2. FILME
        final movieId = item.id;

        // A. Dados de Warez2
        final warezUrl = 'https://megafrixapi.com/iptv/warez2.php?item_id=$movieId';
        try {
          final resp = await _apiClient.get(
            warezUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'MegaFlix/1.2', ...customHeaders},
            ),
          );
          final raw = resp.data?.toString() ?? '';
          if (raw.isNotEmpty) {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              if (decoded['br'] is List) {
                for (final u in decoded['br'] as List) {
                  dubbedUrls.add(u.toString());
                }
              }
              if (decoded['eng'] is List) {
                for (final u in decoded['eng'] as List) {
                  subbedUrls.add(u.toString());
                }
              }
            }
          }
        } catch (_) {}

        // B. Dados do viewItem
        try {
          final viewUrl = config?.resolveUrl('?page=viewItem&id=$movieId') ?? '';
          if (viewUrl.isNotEmpty) {
            final resp = await _apiClient.post(
              viewUrl,
              data: 'userHistoric=[]',
              options: Options(
                responseType: ResponseType.plain,
                headers: {'User-Agent': 'MegaFlix/1.2', ...customHeaders},
              ),
            );
            final html = resp.data?.toString() ?? '';
            final loadMatch = RegExp(r'''loadPlayers\(\{\s*br:\s*['"]([^'"]*)['"],\s*eng:\s*['"]([^'"]*)['"]''').firstMatch(html);
            if (loadMatch != null) {
              final brStr = loadMatch.group(1) ?? '';
              final engStr = loadMatch.group(2) ?? '';
              if (brStr.isNotEmpty) {
                for (final u in brStr.split(',')) {
                  if (u.trim().isNotEmpty) dubbedUrls.add(u.trim());
                }
              }
              if (engStr.isNotEmpty) {
                for (final u in engStr.split(',')) {
                  if (u.trim().isNotEmpty) subbedUrls.add(u.trim());
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback: se nada foi retornado mas há streamUrl no item
    if (dubbedUrls.isEmpty && subbedUrls.isEmpty && item.streamUrl.isNotEmpty) {
      dubbedUrls.add(item.streamUrl);
    }

    final dubbed = _buildServerList(dubbedUrls, isDubbed: true);
    final subbed = _buildServerList(subbedUrls, isDubbed: false);

    return MediaServersResult(
      dubbedServers: dubbed,
      subbedServers: subbed,
    );
  }

  List<MediaServer> _buildServerList(List<String> rawUrls, {required bool isDubbed}) {
    final servers = <MediaServer>[];
    final seenUrls = <String>{};

    for (final rawUrl in rawUrls) {
      final cleanUrl = rawUrl.trim();
      if (cleanUrl.isEmpty || !cleanUrl.startsWith('http') || seenUrls.contains(cleanUrl)) {
        continue;
      }
      seenUrls.add(cleanUrl);

      final lower = cleanUrl.toLowerCase();
      String name;
      int priority;
      String quality = '1080p Full HD';

      if (lower.contains('voltz.php')) {
        name = 'Servidor Voltz (Recomendado)';
        priority = 10;
        quality = '1080p 60fps';
      } else if (lower.contains('upbolt') || lower.contains('bolt')) {
        name = 'Servidor UpBolt';
        priority = 20;
        quality = '1080p Full HD';
      } else if (lower.contains('lulu') || lower.contains('luluvdo')) {
        name = 'Servidor Lulu';
        priority = 30;
        quality = '1080p Full HD';
      } else if (lower.contains('hidehide') || lower.contains('vidhide') || lower.contains('hide')) {
        name = 'Servidor VidHide';
        priority = 40;
        quality = '1080p Full HD';
      } else if (lower.contains('byse')) {
        name = 'Servidor Byse';
        priority = 50;
        quality = 'Full HD';
      } else if (lower.contains('mixdrop') || lower.contains('mdy48')) {
        name = 'Servidor MixDrop';
        priority = 60;
        quality = 'Full HD';
      } else if (lower.contains('dood')) {
        name = 'Servidor DoodStream';
        priority = 70;
        quality = 'HD 720p';
      } else if (lower.contains('gocine')) {
        name = 'Servidor GoCine';
        priority = 80;
        quality = '1080p Full HD';
      } else if (lower.contains('vidara')) {
        name = 'Servidor Vidara';
        priority = 90;
        quality = '1080p Full HD';
      } else if (lower.contains('playmate')) {
        name = 'Servidor Playmate';
        priority = 100;
        quality = 'Full HD';
      } else if (lower.contains('upns') || lower.contains('megafl')) {
        name = 'Servidor Upns';
        priority = 110;
        quality = 'Full HD';
      } else if (lower.contains('take')) {
        name = 'Servidor Take';
        priority = 120;
        quality = 'Full HD';
      } else if (lower.contains('redeflix') || lower.contains('rdf')) {
        name = 'Servidor Redeflix';
        priority = 130;
        quality = 'Full HD';
      } else if (lower.contains('.mp4') || lower.contains('cnvs/')) {
        name = 'Servidor MP4 Direto';
        priority = 140;
        quality = '1080p Full HD';
      } else {
        name = 'Servidor Alternativo ${servers.length + 1}';
        priority = 200 + servers.length;
        quality = 'Full HD';
      }

      servers.add(
        MediaServer(
          id: 'srv_${servers.length}_${cleanUrl.hashCode}',
          name: name,
          url: cleanUrl,
          isDubbed: isDubbed,
          quality: quality,
          priority: priority,
        ),
      );
    }

    servers.sort((a, b) => a.priority.compareTo(b.priority));
    return servers;
  }

  // ==================== STREAM RESOLVER DINÂMICO ====================
  Future<String?> resolveServerStream(MediaServer server) async {
    final url = server.url;
    if (url.contains('voltz.php')) {
      final voltz = await _resolveVoltzStream(url);
      if (voltz != null && voltz.isNotEmpty) return voltz;
    }

    if (url.contains('.mp4') || url.contains('.m3u8')) {
      return url;
    }

    try {
      final getUrlEndpoint = 'https://megafrixapi.com/iptv/get_url.php?url=${Uri.encodeComponent(url)}';
      final resp = await _apiClient.get(
        getUrlEndpoint,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'MegaFlix/1.2'},
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

  Future<String?> resolveStreamUrl(MediaItem item) async {
    // 1. Canais ao vivo
    if (item.isLive || item.streamUrl.contains('get_token_channel.php')) {
      final tokenUrl = item.streamUrl.isNotEmpty
          ? item.streamUrl
          : 'https://app.megafrixapi.com/get_token_channel.php?channel=${item.id}';
      return await _resolveTokenToM3u8(tokenUrl);
    }

    // 2. Busca lista de servidores e resolve o melhor
    try {
      final servers = await getMediaServers(item);
      final bestList = servers.dubbedServers.isNotEmpty ? servers.dubbedServers : servers.subbedServers;
      if (bestList.isNotEmpty) {
        final resolved = await resolveServerStream(bestList.first);
        if (resolved != null && resolved.isNotEmpty) {
          return resolved;
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
      final lowerTitle = title.toLowerCase();

      final isSeriesCategory = defaultType == 'series' ||
          defaultType == 'anime' ||
          lowerTitle.contains('série') ||
          lowerTitle.contains('series') ||
          lowerTitle.contains('novela') ||
          lowerTitle.contains('anime') ||
          lowerTitle.contains('dorama') ||
          lowerTitle.contains('temporada') ||
          sectionBlock.contains('data-type="2"');

      final effectiveType = isSeriesCategory ? 'series' : defaultType;

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

          if (isSeriesCategory) {
            _knownSeriesIds.add(id);
          } else if (defaultType == 'movie') {
            _knownMovieIds.add(id);
          }

          final item = MediaItem(
            id: id,
            title: map['titulo'] ?? map['title'] ?? map['name'] ?? 'Título',
            overview: map['sinopse'] ?? map['overview'],
            posterUrl: map['img'] ?? map['poster'],
            backdropUrl: map['bg'] ?? map['background'] ?? map['img'],
            year: map['ano']?.toString() ?? map['year']?.toString(),
            mediaType: effectiveType,
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
