import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_item.dart';

class QuickZapBar extends StatelessWidget {
  final MediaItem? currentItem;

  const QuickZapBar({super.key, this.currentItem});

  @override
  Widget build(BuildContext context) {
    if (currentItem == null || !currentItem!.isLive) {
      return const SizedBox.shrink();
    }

    final item = currentItem!;
    final initials = item.title.length > 3
        ? item.title.substring(0, 3).toUpperCase()
        : item.title.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121A).withOpacity(0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Channel Logo Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.cyan.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppTheme.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Channel Info & Program
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CANAL AO VIVO · ${item.title.toUpperCase()}',
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.overview ?? 'Transmissão Contínua em Alta Definição',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 3. Quick Progress Bar com Gradiente Astra (Indigo -> Cyan)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AO VIVO', style: TextStyle(color: AppTheme.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('SINAL ESTÁVEL', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF36404D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [AppTheme.indigo, AppTheme.cyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyan.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. AV Flags (Áudio & Legendas)
          Row(
            children: [
              _buildAvFlag(Icons.volume_up_outlined, '5.1 DOLBY'),
              const SizedBox(width: 14),
              _buildAvFlag(Icons.closed_caption_outlined, 'CC'),
              const SizedBox(width: 14),
              _buildAvFlag(Icons.high_quality_outlined, 'FULL HD'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvFlag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
