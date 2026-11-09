import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';

class TvHeroBackdrop extends StatelessWidget {
  final MediaItem? item;
  final bool isFavorite;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onOpenEpisodes;
  final double height;

  const TvHeroBackdrop({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onPlay,
    required this.onToggleFavorite,
    this.onOpenEpisodes,
    this.height = 360,
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
          // 1. Imagem de Fundo com Transição Suave (CrossFade)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: backdrop != null && backdrop.isNotEmpty
                ? Image.network(
                    backdrop,
                    key: ValueKey<String>(backdrop),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.surface),
                  )
                : Container(key: const ValueKey('placeholder'), color: AppTheme.surface),
          ),

          // 2. Gradiente Horizontal (escurece lado esquerdo para texto)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.background.withOpacity(0.96),
                  AppTheme.background.withOpacity(0.85),
                  AppTheme.background.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 0.75, 1.0],
              ),
            ),
          ),

          // 3. Gradiente Vertical (funde o banner suavemente com a grade inferior)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withOpacity(0.7),
                  AppTheme.background,
                ],
                stops: const [0.5, 0.85, 1.0],
              ),
            ),
          ),

          // 4. Informações do Item Focado + Botões de Ação Rápida
          Positioned(
            left: 36,
            top: 32,
            bottom: 24,
            width: 580,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tags e Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isChannel ? Colors.redAccent : AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isChannel ? 'CANAL AO VIVO' : (isSeries ? 'SÉRIE' : 'FILME'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (current.year != null && current.year!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        current.year!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Título Principal
                Text(
                  current.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),

                // Sinopse / Overview
                if (current.overview != null && current.overview!.isNotEmpty)
                  Text(
                    current.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 20),

                // Botões de Ação
                Row(
                  children: [
                    // Botão Assistir
                    TvFocusable(
                      onPressed: onPlay,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Assistir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Botão Favoritar (⭐)
                    TvFocusable(
                      onPressed: onToggleFavorite,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite ? Colors.amber : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isFavorite ? 'Favorito' : 'Favoritar',
                              style: TextStyle(
                                color: isFavorite ? Colors.amber : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Botão de Episódios se for Série
                    if (isSeries && onOpenEpisodes != null) ...[
                      const SizedBox(width: 14),
                      TvFocusable(
                        onPressed: onOpenEpisodes,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_list_bulleted, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Episódios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
}
