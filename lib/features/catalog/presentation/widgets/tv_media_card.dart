import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';

class TvMediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isFavorite;
  final VoidCallback onPlay;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onFocused;
  final double width;
  final double height;
  final bool autofocus;

  const TvMediaCard({
    super.key,
    required this.item,
    this.isFavorite = false,
    required this.onPlay,
    this.onToggleFavorite,
    this.onFocused,
    this.width = 150,
    this.height = 220,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoster = item.posterUrl != null && item.posterUrl!.isNotEmpty;
    final isChannel = item.isLive;

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: TvFocusable(
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(10),
        scaleFactor: 1.08,
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
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Imagem de Capa (Pôster TMDB ou Logo do Canal)
              if (hasPoster)
                Image.network(
                  item.posterUrl!,
                  fit: isChannel ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              // 2. Gradiente Inferior para legibilidade do texto
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: isChannel ? 50 : 70,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Título e Badges
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.year != null && item.year!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.year!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 4. Badge de Favorito (⭐)
              if (isFavorite)
                Positioned(
                  top: 6,
                  right: 6,
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
                      size: 14,
                    ),
                  ),
                ),

              // 5. Badge "AO VIVO" para canais
              if (isChannel)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'AO VIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Center(
        child: Icon(
          item.isLive
              ? Icons.live_tv
              : (item.isSeries ? Icons.video_library : Icons.movie),
          color: Colors.white24,
          size: 42,
        ),
      ),
    );
  }
}
