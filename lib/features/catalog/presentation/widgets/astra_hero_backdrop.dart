import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';

class AstraHeroBackdrop extends StatelessWidget {
  final MediaItem? item;
  final bool isFavorite;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onOpenEpisodes;
  final double height;

  const AstraHeroBackdrop({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onPlay,
    required this.onToggleFavorite,
    this.onOpenEpisodes,
    this.height = 380,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return SizedBox(height: height);
    }

    final current = item!;
    final backdrop = current.backdropUrl ?? current.posterUrl;
    final isChannel = current.isLive;
    final isSeries = current.isSeries;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de Fundo em Alta Resolução com Transição Suave
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: backdrop != null && backdrop.isNotEmpty
                ? Image.network(
                    backdrop,
                    key: ValueKey<String>(backdrop),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.obsidian),
                  )
                : Container(key: const ValueKey('placeholder'), color: AppTheme.obsidian),
          ),

          // 2. Gradiente Horizontal (Astra Left Shade)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.background.withOpacity(0.97),
                  AppTheme.background.withOpacity(0.85),
                  AppTheme.background.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 0.75, 1.0],
              ),
            ),
          ),

          // 3. Gradiente Vertical (Astra Bottom Shade)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withOpacity(0.6),
                  AppTheme.background,
                ],
                stops: const [0.35, 0.8, 1.0],
              ),
            ),
          ),

          // 4. Conteúdo Hero Tipografia Astra
          Positioned(
            left: 36,
            top: 24,
            bottom: 24,
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badges (4K HDR, IMDb, etc. do Figma)
                Row(
                  children: [
                    _buildPillBadge('4K HDR'),
                    const SizedBox(width: 6),
                    _buildPillBadge(isChannel ? 'LIVE FEED' : 'IMDb 8.5'),
                    const SizedBox(width: 6),
                    _buildPillBadge('16+'),
                  ],
                ),
                const SizedBox(height: 10),

                // Eyebrow Tag (ex: ASTRA ORIGINAL)
                Text(
                  isChannel
                      ? 'ASTRA LIVE TV'
                      : (isSeries ? 'ASTRA SERIES' : 'ASTRA ORIGINAL'),
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(height: 8),

                // Título em Caixa Alta e Peso Forte
                Text(
                  current.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Meta Info (Ano · Categoria · Duração)
                Text(
                  isChannel
                      ? 'Transmissão Oficial ao Vivo · Sem Interrupções'
                      : '${current.year ?? '2026'} · ${isSeries ? 'Série' : 'Filme'} · Áudio 5.1 Dolby',
                  style: const TextStyle(
                    color: Color(0xFFB4BDCA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Sinopse
                if (current.overview != null && current.overview!.isNotEmpty)
                  Text(
                    current.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 18),

                // Botões de Ação
                Row(
                  children: [
                    // Botão Play Now Primário (Ciano Neon Astra)
                    TvFocusable(
                      onPressed: onPlay,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyan.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Color(0xFF061014), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Play Now',
                              style: TextStyle(
                                color: Color(0xFF061014),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botão Secundário Favoritar (Glass)
                    TvFocusable(
                      onPressed: onToggleFavorite,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E29).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite ? Colors.amber : Colors.white,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isFavorite ? 'Saved' : 'Add to List',
                              style: TextStyle(
                                color: isFavorite ? Colors.amber : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Botão de Episódios se Série
                    if (isSeries && onOpenEpisodes != null) ...[
                      const SizedBox(width: 12),
                      TvFocusable(
                        onPressed: onOpenEpisodes,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1E29).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.grid_view, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Episodes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10).withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
