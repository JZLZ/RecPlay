import 'package:equatable/equatable.dart';

class MediaItem extends Equatable {
  final String id;
  final String title;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final String streamUrl;
  final String? streamType; // 'hls', 'mp4', 'dash'
  final Map<String, String>? streamHeaders;
  final String? year;
  final String mediaType; // 'channel', 'movie', 'series', 'anime', 'episode'
  final String? category;
  final String? seriesId;
  final int? seasonNum;
  final int? episodeNum;

  const MediaItem({
    required this.id,
    required this.title,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.streamUrl,
    this.streamType,
    this.streamHeaders,
    this.year,
    this.mediaType = 'movie',
    this.category,
    this.seriesId,
    this.seasonNum,
    this.episodeNum,
  });

  bool get isLive => mediaType == 'channel' || streamType == 'hls' || streamUrl.contains('get_token_channel');
  bool get isMovie => mediaType == 'movie';
  bool get isSeries => mediaType == 'series';
  bool get isAnime => mediaType == 'anime';
  bool get isEpisode => mediaType == 'episode';

  MediaItem copyWith({
    String? id,
    String? title,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    String? streamUrl,
    String? streamType,
    Map<String, String>? streamHeaders,
    String? year,
    String? mediaType,
    String? category,
    String? seriesId,
    int? seasonNum,
    int? episodeNum,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      streamType: streamType ?? this.streamType,
      streamHeaders: streamHeaders ?? this.streamHeaders,
      year: year ?? this.year,
      mediaType: mediaType ?? this.mediaType,
      category: category ?? this.category,
      seriesId: seriesId ?? this.seriesId,
      seasonNum: seasonNum ?? this.seasonNum,
      episodeNum: episodeNum ?? this.episodeNum,
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json, {String defaultType = 'movie'}) {
    return MediaItem(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] ?? json['titulo'] ?? json['name'] ?? 'Título Desconhecido',
      overview: json['overview'] ?? json['sinopse'] ?? json['description'],
      posterUrl: json['poster_url'] ?? json['poster'] ?? json['img'] ?? json['thumbnail'],
      backdropUrl: json['backdrop_url'] ?? json['backdrop'] ?? json['bg'] ?? json['banner'],
      streamUrl: json['stream_url'] ?? json['url'] ?? json['source'] ?? '',
      streamType: json['stream_type'] ?? json['type'] ?? 'hls',
      streamHeaders: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
      year: json['year']?.toString() ?? json['ano']?.toString(),
      mediaType: json['media_type'] ?? json['mediaType'] ?? defaultType,
      category: json['category'] ?? json['categoria'],
      seriesId: json['series_id']?.toString(),
      seasonNum: json['season_num'] != null ? int.tryParse(json['season_num'].toString()) : null,
      episodeNum: json['episode_num'] != null ? int.tryParse(json['episode_num'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'stream_url': streamUrl,
      'stream_type': streamType,
      'headers': streamHeaders,
      'year': year,
      'media_type': mediaType,
      'category': category,
      'series_id': seriesId,
      'season_num': seasonNum,
      'episode_num': episodeNum,
    };
  }

  @override
  List<Object?> get props => [id, title, streamUrl, mediaType, year];
}

class MediaCategory extends Equatable {
  final String id;
  final String title;
  final List<MediaItem> items;

  const MediaCategory({
    required this.id,
    required this.title,
    required this.items,
  });

  factory MediaCategory.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? json['media'] as List? ?? [];
    return MediaCategory(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Categoria',
      items: list.map((i) => MediaItem.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, items];
}

class SeasonInfo extends Equatable {
  final int seasonNum;
  final String title;

  const SeasonInfo({
    required this.seasonNum,
    required this.title,
  });

  @override
  List<Object?> get props => [seasonNum, title];
}
