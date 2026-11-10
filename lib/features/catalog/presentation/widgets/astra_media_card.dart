import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';
import 'astra_brand.dart';

class AstraMediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isFavorite;
  final int? rank;
  final double? progress;
  final VoidCallback onPlay;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onFocused;
  final double width;
  final double height;
  final bool autofocus;

  const AstraMediaCard({
    super.key,
    required this.item,
    this.isFavorite = false,
    this.rank,
    this.progress,
    required this.onPlay,
    this.onToggleFavorite,
    this.onFocused,
    this.width = 160,
    this.height = 220,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    final isChannel = item.isLive;

    return Padding(
      padding: EdgeInsets.only(
        right: 14,
        left: rank != null ? 18 : 0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rank Outline Number (From Figma Design)
          if (rank != null)
            Positioned(
              left: -18,
              top: 10,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(3, 3),
                      blurRadius: 10,
                    ),
                  ],
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..color = const Color(0xFFCBD5E1),
                ),
              ),
            ),

          // Focusable Card Container
          TvFocusable(
            autofocus: autofocus,
            borderRadius: BorderRadius.circular(10),
            scaleFactor: 1.06,
            glowColor: AppTheme.cyan,
            onFocusChange: (focused) {
              if (focused) {
                onFocused?.call();
              }
            },
            onPressed: onPlay,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                boxShadow: AppTheme.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Imagem de Capa (TMDB Poster ou Logo do Canal)
                  if (hasPoster)
                    Image.network(
                      item.posterUrl!,
                      fit: isChannel ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // 2. Gradiente Inferior
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: isChannel ? 56 : 74,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.obsidian.withOpacity(0.96),
                            AppTheme.obsidian.withOpacity(0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Título e Metadados
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isChannel
                              ? 'LIVE TV'
                              : (item.year != null ? '${item.year} · ${item.isSeries ? 'Série' : 'Filme'}' : (item.isSeries ? 'Série' : 'Filme')),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Mini Barra de Progresso no Rodapé da Imagem
                  if (progress != null && progress! > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 3,
                        color: Colors.white.withOpacity(0.15),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress!.clamp(0.0, 1.0),
                          child: Container(
                            color: AppTheme.cyan,
                          ),
                        ),
                      ),
                    ),

                  // 5. Badge "AO VIVO" com AstraLiveDot
                  if (isChannel)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cyan.withOpacity(0.4), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AstraLiveDot(size: 5),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppTheme.cyan,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 6. Badge de Favorito (⭐)
                  if (isFavorite)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.03),
      child: Center(
        child: Icon(
          item.isLive
              ? Icons.live_tv
              : (item.isSeries ? Icons.grid_view : Icons.movie),
          color: Colors.white24,
          size: 38,
        ),
      ),
    );
  }
}
