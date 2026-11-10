import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../../player/presentation/pages/player_page.dart';

enum AudioTrackType { dubbed, subbed }

class ServerSelectorModal extends StatefulWidget {
  final MediaItem item;
  final CatalogRepository repository;

  const ServerSelectorModal({
    super.key,
    required this.item,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required MediaItem item,
    required CatalogRepository repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServerSelectorModal(
        item: item,
        repository: repository,
      ),
    );
  }

  @override
  State<ServerSelectorModal> createState() => _ServerSelectorModalState();
}

class _ServerSelectorModalState extends State<ServerSelectorModal> {
  bool _isLoadingServers = true;
  String? _connectingServerId;
  MediaServersResult _serversResult = const MediaServersResult();
  AudioTrackType _selectedAudio = AudioTrackType.dubbed;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoadingServers = true);
    final result = await widget.repository.getMediaServers(widget.item);

    if (mounted) {
      setState(() {
        _serversResult = result;
        _isLoadingServers = false;

        // Seleciona automaticamente o áudio que possui servidores disponíveis
        if (result.dubbedServers.isNotEmpty) {
          _selectedAudio = AudioTrackType.dubbed;
        } else if (result.subbedServers.isNotEmpty) {
          _selectedAudio = AudioTrackType.subbed;
        }
      });
    }
  }

  Future<void> _handleServerSelect(MediaServer server) async {
    setState(() => _connectingServerId = server.id);

    try {
      final resolvedUrl = await widget.repository.resolveServerStream(server);

      if (!mounted) return;

      setState(() => _connectingServerId = null);

      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        // Fecha o modal antes de abrir o player para retorno limpo
        Navigator.pop(context);

        final playItem = widget.item.copyWith(
          streamUrl: resolvedUrl,
          streamType: resolvedUrl.contains('.m3u8') ? 'hls' : 'mp4',
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerPage(item: playItem)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível conectar ao ${server.name}. Escolha outro servidor.'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _connectingServerId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao conectar ao servidor. Tente outro da lista.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeServers = _selectedAudio == AudioTrackType.dubbed
        ? _serversResult.dubbedServers
        : _serversResult.subbedServers;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.cyan.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puxador central (design mobile)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header do Modal com Informações do Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
                            ),
                            child: Text(
                              widget.item.isEpisode ? 'EPISÓDIO' : 'FILME',
                              style: const TextStyle(
                                color: AppTheme.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (widget.item.year != null && widget.item.year!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              widget.item.year!,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Escolha o áudio e o servidor para assistir',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TvFocusable(
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Seletor de Áudio (Dublado vs Legendado)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                // Aba Dublado
                Expanded(
                  child: _buildAudioTabButton(
                    type: AudioTrackType.dubbed,
                    icon: Icons.record_voice_over,
                    label: 'Dublado',
                    count: _serversResult.dubbedServers.length,
                    isSelected: _selectedAudio == AudioTrackType.dubbed,
                  ),
                ),
                const SizedBox(width: 12),

                // Aba Legendado
                Expanded(
                  child: _buildAudioTabButton(
                    type: AudioTrackType.subbed,
                    icon: Icons.subtitles,
                    label: 'Legendado',
                    count: _serversResult.subbedServers.length,
                    isSelected: _selectedAudio == AudioTrackType.subbed,
                  ),
                ),
              ],
            ),
          ),

          // Lista de Servidores Disponíveis
          Expanded(
            child: _isLoadingServers
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.cyan),
                        SizedBox(height: 16),
                        Text(
                          'Carregando servidores disponíveis...',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : activeServers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedAudio == AudioTrackType.dubbed
                                  ? Icons.volume_off_outlined
                                  : Icons.subtitles_off_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum servidor ${_selectedAudio == AudioTrackType.dubbed ? "dublado" : "legendado"} encontrado.',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            if (_selectedAudio == AudioTrackType.dubbed &&
                                _serversResult.subbedServers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextButton.icon(
                                  onPressed: () => setState(() => _selectedAudio = AudioTrackType.subbed),
                                  icon: const Icon(Icons.subtitles, color: AppTheme.cyan, size: 16),
                                  label: const Text(
                                    'Ver opções legendadas',
                                    style: TextStyle(color: AppTheme.cyan),
                                  ),
                                ),
                              ),
                            if (_selectedAudio == AudioTrackType.subbed &&
                                _serversResult.dubbedServers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextButton.icon(
                                  onPressed: () => setState(() => _selectedAudio = AudioTrackType.dubbed),
                                  icon: const Icon(Icons.record_voice_over, color: AppTheme.cyan, size: 16),
                                  label: const Text(
                                    'Ver opções dubladas',
                                    style: TextStyle(color: AppTheme.cyan),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: activeServers.length,
                        itemBuilder: (context, idx) {
                          final server = activeServers[idx];
                          final isConnecting = _connectingServerId == server.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TvFocusable(
                              borderRadius: BorderRadius.circular(12),
                              onPressed: isConnecting ? null : () => _handleServerSelect(server),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: server.priority == 10
                                        ? AppTheme.cyan.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Ícone do Servidor
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: server.priority == 10
                                            ? AppTheme.cyan.withOpacity(0.15)
                                            : Colors.white10,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: isConnecting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppTheme.cyan,
                                                ),
                                              )
                                            : Icon(
                                                Icons.play_arrow_rounded,
                                                color: server.priority == 10
                                                    ? AppTheme.cyan
                                                    : Colors.white,
                                                size: 26,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Informações do Servidor
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  server.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: server.priority == 10
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (server.priority == 10) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.cyan.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'RÁPIDO',
                                                    style: TextStyle(
                                                      color: AppTheme.cyan,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                server.quality,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 3,
                                                height: 3,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.textSecondary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                server.isDubbed ? 'Áudio em Português' : 'Áudio Original c/ Legenda',
                                                style: TextStyle(
                                                  color: server.isDubbed
                                                      ? const Color(0xFF34D399)
                                                      : const Color(0xFF60A5FA),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Botão Assistir
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isConnecting
                                            ? Colors.white10
                                            : AppTheme.cyan.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isConnecting
                                              ? Colors.transparent
                                              : AppTheme.cyan.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        isConnecting ? 'Conectando...' : 'Assistir',
                                        style: TextStyle(
                                          color: isConnecting ? Colors.white54 : AppTheme.cyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
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

  Widget _buildAudioTabButton({
    required AudioTrackType type,
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
  }) {
    return TvFocusable(
      borderRadius: BorderRadius.circular(12),
      onPressed: () => setState(() => _selectedAudio = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.cyan.withOpacity(0.15)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.cyan : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.cyan : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.cyan : Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
