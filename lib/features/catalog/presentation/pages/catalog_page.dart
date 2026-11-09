import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../core/device/device_detector.dart';
import '../../../admin/presentation/pages/admin_panel_page.dart';
import '../../../admin/domain/repositories/api_config_repository.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';

class CatalogPage extends StatefulWidget {
  final DeviceDetector deviceDetector;
  final CatalogRepository catalogRepository;
  final ApiConfigRepository configRepository;

  const CatalogPage({
    super.key,
    required this.deviceDetector,
    required this.catalogRepository,
    required this.configRepository,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool _isLoading = true;
  bool _isTv = false;
  List<MediaCategory> _categories = [];
  MediaItem? _selectedItemForPreview;
  int _secretTapCount = 0;

  @override
  void initState() {
    super.initState();
    _initDeviceAndData();
  }

  Future<void> _initDeviceAndData() async {
    final type = await widget.deviceDetector.getDeviceType();
    setState(() {
      _isTv = type == DeviceType.television;
    });
    await _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    final items = await widget.catalogRepository.getCategoriesAndContent();
    setState(() {
      _categories = items;
      _isLoading = false;
      if (items.isNotEmpty && items.first.items.isNotEmpty) {
        _selectedItemForPreview = items.first.items.first;
      }
    });
  }

  void _handleSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _openAdminPanel();
    }
  }

  void _openAdminPanel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPanelPage()),
    );
    _loadCatalog(); // Recarrega catálogo caso a API tenha sido alterada
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Carregando ecossistema de mídia...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isTv ? _buildTvLeanbackLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 72, color: AppTheme.textSecondary),
              const SizedBox(height: 20),
              const Text(
                'Nenhuma API Conectada',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Este aplicativo é 100% agnóstico e não possui URLs fixas. Acesse o Painel Administrativo para inserir os endpoints ou importar o arquivo JSON de configuração.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 28),
              TvFocusable(
                autofocus: true,
                onPressed: _openAdminPanel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Abrir Painel Administrativo', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ==================== LAYOUT 1: ANDROID TV (LEANBACK) ====================
  Widget _buildTvLeanbackLayout() {
    return Stack(
      children: [
        // Backdrop Hero Preview
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surfaceCard.withOpacity(0.8),
                  AppTheme.background,
                ],
              ),
            ),
            padding: const EdgeInsets.only(left: 48, top: 40, right: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _handleSecretTap,
                      child: const Row(
                        children: [
                          Icon(Icons.tv, color: AppTheme.primary, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'RECPLAY TV',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                    TvFocusable(
                      onPressed: _openAdminPanel,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_selectedItemForPreview != null) ...[
                  Text(
                    _selectedItemForPreview!.title,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 600,
                    child: Text(
                      _selectedItemForPreview!.overview ?? 'Pressione SELECT para reproduzir.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Carrosséis Horizontais de Categorias
        Positioned.fill(
          top: 260,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 48, bottom: 48),
            itemCount: _categories.length,
            itemBuilder: (context, catIdx) {
              final cat = _categories[catIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cat.items.length,
                      itemBuilder: (context, itemIdx) {
                        final item = cat.items[itemIdx];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: TvFocusable(
                            autofocus: catIdx == 0 && itemIdx == 0,
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () {
                              setState(() => _selectedItemForPreview = item);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PlayerPage(item: item)),
                              );
                            },
                            child: Container(
                              width: 240,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                                          ? Image.network(
                                              item.posterUrl!,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.tv, color: AppTheme.primary, size: 36),
                                            )
                                          : const Icon(Icons.play_circle_outline,
                                              color: AppTheme.primary, size: 36),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== LAYOUT 2: SMARTPHONE (TOUCH) ====================
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: GestureDetector(
            onTap: _handleSecretTap,
            child: const Text('RecPlay'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openAdminPanel,
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, catIdx) {
              final cat = _categories[catIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      cat.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cat.items.length,
                      itemBuilder: (context, itemIdx) {
                        final item = cat.items[itemIdx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PlayerPage(item: item)),
                            );
                          },
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                                        ? Image.network(
                                            item.posterUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.tv, size: 36, color: Colors.white38),
                                          )
                                        : const Icon(Icons.movie, size: 36, color: Colors.white38),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            childCount: _categories.length,
          ),
        ),
      ],
    );
  }
}
