import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../core/device/device_detector.dart';
import '../../../admin/presentation/pages/admin_panel_page.dart';
import '../../../admin/domain/repositories/api_config_repository.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';
import '../widgets/netflix_sidebar.dart';
import '../widgets/tv_hero_backdrop.dart';
import '../widgets/tv_media_card.dart';
import '../widgets/category_chips_bar.dart';
import '../widgets/series_episodes_modal.dart';
import 'search_page.dart';

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
  CatalogNavTab _currentTab = CatalogNavTab.home;
  
  // Dados de cada seção
  List<MediaCategory> _homeCategories = [];
  List<MediaCategory> _channelsCategories = [];
  List<MediaCategory> _moviesCategories = [];
  List<MediaCategory> _seriesCategories = [];
  List<MediaCategory> _favoritesCategories = [];

  // Filtros de chips
  String _selectedChannelFilter = '★ Todos';
  String _selectedMovieFilter = '★ Todos';
  String _selectedSeriesFilter = '★ Todos';

  // Item atualmente em foco para Hero Backdrop
  MediaItem? _selectedItemForPreview;
  final Set<String> _favoriteIds = {};
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
    await _loadTabContent(_currentTab);
  }

  Future<void> _loadTabContent(CatalogNavTab tab) async {
    setState(() => _isLoading = true);

    // Carrega IDs favoritos
    final favList = await widget.catalogRepository.getFavorites();
    if (mounted) {
      _favoriteIds.clear();
      for (final cat in favList) {
        _favoriteIds.addAll(cat.items.map((i) => i.id));
      }
    }

    switch (tab) {
      case CatalogNavTab.home:
        _homeCategories = await widget.catalogRepository.getHomeContent();
        if (_homeCategories.isNotEmpty && _homeCategories.first.items.isNotEmpty) {
          _selectedItemForPreview = _homeCategories.first.items.first;
        }
        break;

      case CatalogNavTab.channels:
        _channelsCategories = await widget.catalogRepository.getChannels();
        if (_channelsCategories.isNotEmpty && _channelsCategories.first.items.isNotEmpty) {
          _selectedItemForPreview = _channelsCategories.first.items.first;
        }
        break;

      case CatalogNavTab.movies:
        _moviesCategories = await widget.catalogRepository.getMovies();
        if (_moviesCategories.isNotEmpty && _moviesCategories.first.items.isNotEmpty) {
          _selectedItemForPreview = _moviesCategories.first.items.first;
        }
        break;

      case CatalogNavTab.series:
        _seriesCategories = await widget.catalogRepository.getSeries();
        if (_seriesCategories.isNotEmpty && _seriesCategories.first.items.isNotEmpty) {
          _selectedItemForPreview = _seriesCategories.first.items.first;
        }
        break;

      case CatalogNavTab.favorites:
        _favoritesCategories = favList;
        if (_favoritesCategories.isNotEmpty && _favoritesCategories.first.items.isNotEmpty) {
          _selectedItemForPreview = _favoritesCategories.first.items.first;
        }
        break;

      case CatalogNavTab.search:
        // A tela de busca gerencia seus próprios estados
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onTabSelected(CatalogNavTab tab) {
    if (_currentTab != tab) {
      setState(() => _currentTab = tab);
      _loadTabContent(tab);
    }
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    final isFav = await widget.catalogRepository.toggleFavorite(item.id);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(item.id);
        } else {
          _favoriteIds.remove(item.id);
        }
      });
      // Atualiza lista de favoritos se estiver na aba
      if (_currentTab == CatalogNavTab.favorites || _currentTab == CatalogNavTab.home) {
        final favList = await widget.catalogRepository.getFavorites();
        setState(() {
          _favoritesCategories = favList;
        });
      }
    }
  }

  void _handleItemPress(MediaItem item) {
    if (item.isSeries) {
      SeriesEpisodesModal.show(
        context,
        series: item,
        repository: widget.catalogRepository,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerPage(item: item)),
      );
    }
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
    _loadTabContent(_currentTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // 1. Menu Lateral Retrátil Estilo Netflix
          NetflixSidebar(
            currentTab: _currentTab,
            onTabSelected: _onTabSelected,
            onAdminPressed: _openAdminPanel,
          ),

          // 2. Conteúdo Central de Acordo com a Aba Selecionada
          Expanded(
            child: _currentTab == CatalogNavTab.search
                ? SearchPage(
                    repository: widget.catalogRepository,
                    isTv: _isTv,
                  )
                : _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Sincronizando catálogo Netflix...',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _buildCurrentTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTab) {
      case CatalogNavTab.home:
        return _buildCategoriesView(_homeCategories);

      case CatalogNavTab.channels:
        return _buildFilteredChannelsView();

      case CatalogNavTab.movies:
        return _buildFilteredMoviesView();

      case CatalogNavTab.series:
        return _buildFilteredSeriesView();

      case CatalogNavTab.favorites:
        return _buildFavoritesView();

      case CatalogNavTab.search:
        return const SizedBox.shrink();
    }
  }

  // ==================== VISÃO GERAL DE CATEGORIAS (INÍCIO) ====================
  Widget _buildCategoriesView(List<MediaCategory> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Hero Backdrop Dinâmico
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: TvHeroBackdrop(
            item: _selectedItemForPreview,
            isFavorite: _selectedItemForPreview != null &&
                _favoriteIds.contains(_selectedItemForPreview!.id),
            onPlay: () {
              if (_selectedItemForPreview != null) {
                _handleItemPress(_selectedItemForPreview!);
              }
            },
            onToggleFavorite: () {
              if (_selectedItemForPreview != null) {
                _toggleFavorite(_selectedItemForPreview!);
              }
            },
            onOpenEpisodes: (_selectedItemForPreview != null && _selectedItemForPreview!.isSeries)
                ? () => _handleItemPress(_selectedItemForPreview!)
                : null,
          ),
        ),

        // Carrosséis Horizontais de Conteúdo
        Positioned.fill(
          top: 310,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 36, bottom: 48),
            itemCount: categories.length,
            itemBuilder: (context, catIdx) {
              final cat = categories[catIdx];
              return _buildCarouselRow(cat, catIdx);
            },
          ),
        ),
      ],
    );
  }

  // ==================== CANAIS COM FILTROS DE CHIPS ====================
  Widget _buildFilteredChannelsView() {
    final chips = [
      '★ Todos',
      '⚽ Esportes',
      '🎬 Filmes & Séries',
      '👶 Infantil & Desenhos',
      '📰 Notícias',
      '📺 Abertos & Variedades',
      '⏰ Canais 24 Horas',
      '⭐ Reality Shows',
      '🌐 Internacionais',
    ];

    List<MediaCategory> visibleCategories = _channelsCategories;
    if (_selectedChannelFilter != '★ Todos') {
      final cleanFilter = _selectedChannelFilter.replaceAll(RegExp(r'[^a-zA-Z0-9& ]'), '').trim();
      visibleCategories = _channelsCategories.where((cat) {
        return cat.title.toLowerCase().contains(cleanFilter.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Chips de Filtro Rápido
        CategoryChipsBar(
          categories: chips,
          selectedCategory: _selectedChannelFilter,
          onSelected: (chip) {
            setState(() => _selectedChannelFilter = chip);
          },
        ),
        const SizedBox(height: 12),

        // Conteúdo
        Expanded(
          child: visibleCategories.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum canal encontrado nesta categoria.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 36, bottom: 48, top: 12),
                  itemCount: visibleCategories.length,
                  itemBuilder: (context, catIdx) {
                    final cat = visibleCategories[catIdx];
                    return _buildCarouselRow(cat, catIdx);
                  },
                ),
        ),
      ],
    );
  }

  // ==================== FILMES COM FILTROS DE CHIPS ====================
  Widget _buildFilteredMoviesView() {
    final chips = [
      '★ Todos',
      '💥 Ação',
      '🎨 Animação',
      '🗺️ Aventura',
      '😂 Comédia',
      '🔪 Crime',
      '🎭 Drama',
      '👻 Terror',
      '🚀 Ficção',
    ];

    List<MediaCategory> visible = _moviesCategories;
    if (_selectedMovieFilter != '★ Todos') {
      final cleanFilter = _selectedMovieFilter.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      visible = _moviesCategories.where((cat) {
        return cat.title.toLowerCase().contains(cleanFilter.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        CategoryChipsBar(
          categories: chips,
          selectedCategory: _selectedMovieFilter,
          onSelected: (chip) {
            setState(() => _selectedMovieFilter = chip);
          },
        ),
        const SizedBox(height: 12),

        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum filme nesta categoria.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 36, bottom: 48, top: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, catIdx) {
                    final cat = visible[catIdx];
                    return _buildCarouselRow(cat, catIdx);
                  },
                ),
        ),
      ],
    );
  }

  // ==================== SÉRIES COM FILTROS DE CHIPS ====================
  Widget _buildFilteredSeriesView() {
    final chips = [
      '★ Todos',
      '💥 Action & Adventure',
      '🎨 Animação',
      '😂 Comédia',
      '🎭 Drama',
      '🔍 Mistério',
      '🚀 Ficção',
    ];

    List<MediaCategory> visible = _seriesCategories;
    if (_selectedSeriesFilter != '★ Todos') {
      final cleanFilter = _selectedSeriesFilter.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      visible = _seriesCategories.where((cat) {
        return cat.title.toLowerCase().contains(cleanFilter.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        CategoryChipsBar(
          categories: chips,
          selectedCategory: _selectedSeriesFilter,
          onSelected: (chip) {
            setState(() => _selectedSeriesFilter = chip);
          },
        ),
        const SizedBox(height: 12),

        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma série nesta categoria.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 36, bottom: 48, top: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, catIdx) {
                    final cat = visible[catIdx];
                    return _buildCarouselRow(cat, catIdx);
                  },
                ),
        ),
      ],
    );
  }

  // ==================== ABA DE FAVORITOS ====================
  Widget _buildFavoritesView() {
    if (_favoritesCategories.isEmpty || _favoritesCategories.first.items.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(32),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: 72, color: Colors.amber),
              SizedBox(height: 20),
              Text(
                'Sua Lista está Vazia',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 12),
              Text(
                'Navegue pelos canais, filmes e séries e marque o botão de estrela (⭐) para adicioná-los aos seus favoritos e acessá-los rapidamente aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final items = _favoritesCategories.first.items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text(
                'Seus Favoritos (${items.length})',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                return TvMediaCard(
                  item: item,
                  isFavorite: true,
                  width: double.infinity,
                  height: double.infinity,
                  onPlay: () => _handleItemPress(item),
                  onToggleFavorite: () => _toggleFavorite(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CARROSSEL DE ITENS ====================
  Widget _buildCarouselRow(MediaCategory cat, int catIdx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            cat.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cat.items.length,
            itemBuilder: (context, itemIdx) {
              final item = cat.items[itemIdx];
              final isFav = _favoriteIds.contains(item.id);

              return TvMediaCard(
                item: item,
                isFavorite: isFav,
                width: 130,
                height: 180,
                autofocus: catIdx == 0 && itemIdx == 0,
                onFocused: () {
                  setState(() => _selectedItemForPreview = item);
                },
                onPlay: () {
                  setState(() => _selectedItemForPreview = item);
                  _handleItemPress(item);
                },
                onToggleFavorite: () => _toggleFavorite(item),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==================== ESTADO VAZIO ====================
  Widget _buildEmptyState() {
    return Center(
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
              'Acesse as configurações para inserir endpoints ou importar configurações salvas.',
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
                    Text('Abrir Ajustes / Painel Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
