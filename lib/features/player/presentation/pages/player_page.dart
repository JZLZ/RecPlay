import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';

class PlayerPage extends StatefulWidget {
  final MediaItem item;

  const PlayerPage({super.key, required this.item});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  bool _isResolvingStream = true;
  String? _errorMessage;
  String? _resolvedStreamUrl;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  late final CatalogRepository _catalogRepository;

  @override
  void initState() {
    super.initState();
    _catalogRepository = sl<CatalogRepository>();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
    _recordRecent();
  }

  Future<void> _recordRecent() async {
    try {
      await _catalogRepository.recordRecent(widget.item.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _playerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isResolvingStream = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolução dinâmica de stream via CatalogRepository (Warez2 / Voltz / HLS Token)
      final resolvedUrl = await _catalogRepository.resolveStreamUrl(widget.item);
      final streamToPlay = (resolvedUrl != null && resolvedUrl.isNotEmpty)
          ? resolvedUrl
          : widget.item.streamUrl;

      if (streamToPlay.isEmpty) {
        throw Exception('Não foi possível obter uma fonte de vídeo válida.');
      }

      _resolvedStreamUrl = streamToPlay;

      // 2. Inicialização do player com headers padrão do CDN
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36',
        'Referer': 'https://megaflix.name',
        ...?widget.item.streamHeaders,
      };

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamToPlay),
        httpHeaders: headers,
      );

      await controller.initialize();
      controller.addListener(_playerListener);
      await controller.play();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isResolvingStream = false;
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResolvingStream = false;
          _errorMessage = 'Falha ao reproduzir mídia: ${e.toString()}';
        });
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _seekBy(int seconds) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    _controller!.seekTo(target);
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.item.isLive ||
        (_controller != null && _controller!.value.duration == Duration.zero);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seekBy(-10),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _seekBy(10),
          const SingleActivator(LogicalKeyboardKey.select): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.enter): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.space): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): _togglePlayPause,
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // 1. Superfície de Vídeo
                Center(
                  child: _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : Container(color: Colors.black),
                ),

                // 2. Indicador de Carregamento / Buffering
                if (_isResolvingStream ||
                    (_controller != null &&
                        _controller!.value.isInitialized &&
                        _controller!.value.isBuffering))
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            _isResolvingStream
                                ? 'Sincronizando sinal: ${widget.item.title}...'
                                : 'Carregando buffer de transmissão...',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Tela de Erro com Ação de Tentar Novamente
                if (_errorMessage != null)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          const Text(
                            'Erro na Transmissão',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TvFocusable(
                                autofocus: true,
                                onPressed: _initializePlayer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.refresh, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Tentar Novamente', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              TvFocusable(
                                onPressed: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Voltar ao Catálogo', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Controles OSD de Reprodução
                if (_showControls && _errorMessage == null) ...[
                  // Top Header
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
                        Expanded(
                          child: Text(
                            widget.item.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'AO VIVO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Controls
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isLive &&
                              _controller != null &&
                              _controller!.value.isInitialized) ...[
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_controller!.value.position),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _controller!.value.position.inSeconds
                                        .toDouble()
                                        .clamp(0.0, _controller!.value.duration.inSeconds.toDouble()),
                                    max: _controller!.value.duration.inSeconds.toDouble(),
                                    activeColor: AppTheme.primary,
                                    inactiveColor: Colors.white24,
                                    onChanged: (val) {
                                      _controller!.seekTo(Duration(seconds: val.toInt()));
                                    },
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller!.value.duration),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isLive) ...[
                                TvFocusable(
                                  onPressed: () => _seekBy(-10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.replay_10, color: Colors.white, size: 32),
                                  ),
                                ),
                                const SizedBox(width: 20),
                              ],
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
                                    (_controller != null && _controller!.value.isPlaying)
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                              if (!isLive) ...[
                                const SizedBox(width: 20),
                                TvFocusable(
                                  onPressed: () => _seekBy(10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.forward_10, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
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
