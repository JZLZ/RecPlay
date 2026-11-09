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

  const MediaItem({
    required this.id,
    required this.title,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.streamUrl,
    this.streamType,
    this.streamHeaders,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title'] ?? json['name'] ?? 'Título Desconhecido',
      overview: json['overview'] ?? json['description'],
      posterUrl: json['poster_url'] ?? json['poster'] ?? json['thumbnail'],
      backdropUrl: json['backdrop_url'] ?? json['backdrop'] ?? json['banner'],
      streamUrl: json['stream_url'] ?? json['url'] ?? json['source'] ?? '',
      streamType: json['stream_type'] ?? json['type'] ?? 'hls',
      streamHeaders: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
    );
  }

  @override
  List<Object?> get props => [id, title, streamUrl];
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
