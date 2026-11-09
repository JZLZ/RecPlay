import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../catalog/domain/entities/media_item.dart';

class PlayerPage extends StatefulWidget {
  final MediaItem item;

  const PlayerPage({super.key, required this.item});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _isPlaying = true;
  bool _showControls = true;
  double _currentPosition = 0.0;
  final double _totalDuration = 7200.0; // Exemplo: 2 horas simuladas

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _showControls = true;
    });
  }

  void _seekBy(double seconds) {
    setState(() {
      _currentPosition = (_currentPosition + seconds).clamp(0.0, _totalDuration);
      _showControls = true;
    });
  }

  String _formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seekBy(-10),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _seekBy(10),
          const SingleActivator(LogicalKeyboardKey.select): () => _togglePlayPause(),
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () => _togglePlayPause(),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              children: [
                // Camada do Player de Vídeo (ExoPlayer / MediaKit)
                Center(
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.movie_creation_outlined, size: 72, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'Reproduzindo: ${widget.item.title}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Stream: ${widget.item.streamUrl}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controles Overlay OSD
                if (_showControls) ...[
                  // Header
                  Positioned(
                    top: 24,
                    left: 24,
                    right: 24,
                    child: Row(
                      children: [
                        TvFocusable(
                          onPressed: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Barra de Progresso e Botões
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _currentPosition,
                                  max: _totalDuration,
                                  activeColor: AppTheme.primary,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) => setState(() => _currentPosition = val),
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TvFocusable(
                                onPressed: () => _seekBy(-10),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.replay_10, color: Colors.white, size: 32),
                                ),
                              ),
                              const SizedBox(width: 20),
                              TvFocusable(
                                autofocus: true,
                                onPressed: _togglePlayPause,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              TvFocusable(
                                onPressed: () => _seekBy(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.forward_10, color: Colors.white, size: 32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
