import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../../player/presentation/pages/player_page.dart';

class SeriesEpisodesModal extends StatefulWidget {
  final MediaItem series;
  final CatalogRepository repository;

  const SeriesEpisodesModal({
    super.key,
    required this.series,
    required this.repository,
  });

  static Future<void> show(BuildContext context, {
    required MediaItem series,
    required CatalogRepository repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeriesEpisodesModal(
        series: series,
        repository: repository,
      ),
    );
  }

  @override
  State<SeriesEpisodesModal> createState() => _SeriesEpisodesModalState();
}

class _SeriesEpisodesModalState extends State<SeriesEpisodesModal> {
  bool _isLoadingSeasons = true;
  bool _isLoadingEpisodes = false;
  List<SeasonInfo> _seasons = [];
  int _selectedSeason = 1;
  List<MediaItem> _episodes = [];

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoadingSeasons = true);
    final seasons = await widget.repository.getSeriesSeasons(widget.series.id);
    if (mounted) {
      setState(() {
        _seasons = seasons;
        _isLoadingSeasons = false;
        if (seasons.isNotEmpty) {
          _selectedSeason = seasons.first.seasonNum;
        }
      });
      if (seasons.isNotEmpty) {
        _loadEpisodes(_selectedSeason);
      }
    }
  }

  Future<void> _loadEpisodes(int season) async {
    setState(() {
      _selectedSeason = season;
      _isLoadingEpisodes = true;
    });

    final eps = await widget.repository.getSeriesEpisodes(widget.series.id, season);
    if (mounted) {
      setState(() {
        _episodes = eps;
        _isLoadingEpisodes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Título e Botão Fechar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.series.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecione a temporada e o episódio para assistir',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TvFocusable(
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),

          // Seletor de Temporadas (Chips Horizontais)
          if (_isLoadingSeasons)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_seasons.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _seasons.length,
                itemBuilder: (context, idx) {
                  final s = _seasons[idx];
                  final isSelected = s.seasonNum == _selectedSeason;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TvFocusable(
                      onPressed: () => _loadEpisodes(s.seasonNum),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.white12,
                          ),
                        ),
                        child: Text(
                          s.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),

          // Lista de Episódios
          Expanded(
            child: _isLoadingEpisodes
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _episodes.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum episódio encontrado para esta temporada.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _episodes.length,
                        itemBuilder: (context, idx) {
                          final ep = _episodes[idx];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TvFocusable(
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PlayerPage(item: ep)),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail do Episódio
                                    Container(
                                      width: 100,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: ep.posterUrl != null && ep.posterUrl!.isNotEmpty
                                          ? Image.network(
                                              ep.posterUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(
                                                child: Icon(Icons.play_circle_outline, color: Colors.white38),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.play_circle_outline, color: Colors.white38),
                                            ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Info do Episódio
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ep.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ep.overview ?? '',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Ícone de Play
                                    const Icon(Icons.play_arrow, color: AppTheme.primary, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
