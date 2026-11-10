import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';
import '../widgets/astra_brand.dart';
import '../widgets/astra_media_card.dart';
import '../widgets/category_chips_bar.dart';
import '../widgets/series_episodes_modal.dart';
import '../pages/search_page.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../../admin/presentation/pages/admin_panel_page.dart';

enum MobileNavTab {
  home,
  movies,
  series,
  liveTv,
  favorites,
}

class AstraMobileCatalog extends StatefulWidget {
  final CatalogRepository repository;
  final List<MediaCategory> homeCategories;
  final List<MediaCategory> channelsCategories;
  final List<MediaCategory> moviesCategories;
  final List<MediaCategory> seriesCategories;
  final List<MediaCategory> favoritesCategories;
  final Set<String> favoriteIds;
  final Function(MediaItem) onToggleFavorite;
  final VoidCallback onRefresh;

  const AstraMobileCatalog({
    super.key,
    required this.repository,
    required this.homeCategories,
    required this.channelsCategories,
    required this.moviesCategories,
    required this.seriesCategories,
    required this.favoritesCategories,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onRefresh,
  });

  @override
  State<AstraMobileCatalog> createState() => _AstraMobileCatalogState();
}

class _AstraMobileCatalogState extends State<AstraMobileCatalog> {
  MobileNavTab _currentTab = MobileNavTab.home;
  String _selectedMovieFilter = '★ Todos';
  String _selectedSeriesFilter = '★ Todos';
  MediaItem? _activeLiveChannel;
  int _activeLiveIndex = 0;

  @override
  void initState() {
    super.initState();
    _initLiveChannel();
  }

  void _initLiveChannel() {
    if (widget.channelsCategories.isNotEmpty &&
        widget.channelsCategories.first.items.isNotEmpty) {
      _activeLiveChannel = widget.channelsCategories.first.items.first;
      _activeLiveIndex = 0;
    }
  }

  void _handleItemPress(MediaItem item) {
    if (item.isSeries) {
      SeriesEpisodesModal.show(context, series: item, repository: widget.repository);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerPage(item: item)),
      );
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          repository: widget.repository,
          isTv: false,
        ),
      ),
    );
  }

  void _openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPanelPage()),
    );
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Header Mobile (Astra Brand + Search + Admin)
            if (_currentTab != MobileNavTab.liveTv)
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.background.withOpacity(0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AstraBrand(size: 20),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white, size: 22),
                          onPressed: _openSearch,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 22),
                          onPressed: _openAdmin,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 2. Conteúdo Central Mobile
            Expanded(
              child: _buildTabContent(),
            ),

            // 3. Barra de Navegação Inferior Mobile (Astra Glass Bottom Nav)
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case MobileNavTab.home:
        return _buildHomeTab();
      case MobileNavTab.movies:
        return _buildMoviesTab();
      case MobileNavTab.series:
        return _buildSeriesTab();
      case MobileNavTab.liveTv:
        return _buildMobileLiveTv();
      case MobileNavTab.favorites:
        return _buildFavoritesTab();
    }
  }

  // ==================== 1. ABA INÍCIO MOBILE ====================
  Widget _buildHomeTab() {
    final heroItem = widget.homeCategories.isNotEmpty &&
            widget.homeCategories.first.items.isNotEmpty
        ? widget.homeCategories.first.items.first
        : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Mobile Hero Banner (do Figma)
        if (heroItem != null) _buildMobileHero(heroItem),

        const SizedBox(height: 16),

        // Carrosséis de Conteúdo
        ...widget.homeCategories.map((cat) {
          final isRanked = cat.title.toLowerCase().contains('alta') ||
              cat.title.toLowerCase().contains('top');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  cat.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.02,
                  ),
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cat.items.length,
                  itemBuilder: (context, idx) {
                    final item = cat.items[idx];
                    final isFav = widget.favoriteIds.contains(item.id);

                    return AstraMediaCard(
                      item: item,
                      isFavorite: isFav,
                      rank: isRanked ? (idx + 1) : null,
                      width: 125,
                      height: 180,
                      onPlay: () => _handleItemPress(item),
                      onToggleFavorite: () => widget.onToggleFavorite(item),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMobileHero(MediaItem item) {
    final backdrop = item.backdropUrl ?? item.posterUrl;

    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.obsidian,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop != null && backdrop.isNotEmpty)
            Image.network(
              backdrop,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceCard),
            ),

          // Sombra Gradiente Astra
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.obsidian.withOpacity(0.5),
                  AppTheme.obsidian.withOpacity(0.96),
                ],
                stops: const [0.2, 0.6, 1.0],
              ),
            ),
          ),

          // Informações do Título
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildPillBadge('4K HDR'),
                    const SizedBox(width: 6),
                    _buildPillBadge('IMDb 8.5'),
                    const SizedBox(width: 6),
                    _buildPillBadge('16+'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ASTRA ORIGINAL',
                  style: TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.year ?? '2026'} · ${item.isSeries ? 'Série' : 'Filme'}',
                  style: const TextStyle(color: Color(0xFFB4BDCA), fontSize: 11),
                ),
                const SizedBox(height: 14),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleItemPress(item),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.cyan,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.cyan.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, color: Color(0xFF061014), size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Play Now',
                                style: TextStyle(
                                  color: Color(0xFF061014),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => widget.onToggleFavorite(item),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E29).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Icon(
                          widget.favoriteIds.contains(item.id) ? Icons.star : Icons.star_border,
                          color: widget.favoriteIds.contains(item.id) ? Colors.amber : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. ABA LIVE TV MOBILE (MobileLive Figma) ====================
  Widget _buildMobileLiveTv() {
    final allChannels = widget.channelsCategories.isNotEmpty
        ? widget.channelsCategories.first.items
        : <MediaItem>[];

    if (_activeLiveChannel == null && allChannels.isNotEmpty) {
      _activeLiveChannel = allChannels.first;
    }

    final currentChannel = _activeLiveChannel;
    final initials = currentChannel != null && currentChannel.title.length > 3
        ? currentChannel.title.substring(0, 3).toUpperCase()
        : 'LIVE';

    return Column(
      children: [
        // Metade Superior: Vídeo / Preview ao Vivo com Zap Hint
        Container(
          height: 220,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (currentChannel != null && currentChannel.backdropUrl != null)
                Image.network(
                  currentChannel.backdropUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.live_tv, color: AppTheme.cyan, size: 54),
                  ),
                )
              else
                const Center(child: Icon(Icons.live_tv, color: AppTheme.cyan, size: 54)),

              // Top Live Indicator
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const AstraLiveDot(size: 6),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE · $initials',
                        style: const TextStyle(
                          color: AppTheme.cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botão Play no Centro
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (currentChannel != null) {
                      _handleItemPress(currentChannel);
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.cyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withOpacity(0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow, color: Color(0xFF061014), size: 32),
                  ),
                ),
              ),

              // Dica "SWIPE TO ZAP"
              const Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: Color(0xFF9AA5B5), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'SELECIONE O CANAL ABAIXO',
                      style: TextStyle(
                        color: Color(0xFF9AA5B5),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Color(0xFF9AA5B5), size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Metade Inferior: Sheet de Canais EPG (mobile-epg)
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF13161F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Color(0x22FFFFFF), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5361),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE TV',
                        style: TextStyle(
                          color: AppTheme.cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Now on air',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de Canais EPG
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: allChannels.length,
                    itemBuilder: (context, idx) {
                      final ch = allChannels[idx];
                      final isActive = idx == _activeLiveIndex;
                      final chInitials = ch.title.length > 3
                          ? ch.title.substring(0, 3).toUpperCase()
                          : ch.title.toUpperCase();

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeLiveIndex = idx;
                            _activeLiveChannel = ch;
                          });
                        },
                        onDoubleTap: () => _handleItemPress(ch),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.cyan.withOpacity(0.08)
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive ? AppTheme.cyan : Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Número do Canal
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${idx + 1}'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: Color(0xFF657083),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Logo Badge
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.cyan.withOpacity(0.4)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  chInitials,
                                  style: const TextStyle(
                                    color: AppTheme.cyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info do Canal
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isActive ? '● LIVE NOW' : 'CANAL AO VIVO',
                                      style: TextStyle(
                                        color: isActive ? AppTheme.cyan : AppTheme.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ch.title,
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

                              // Botão Assistir
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: AppTheme.cyan, size: 26),
                                onPressed: () => _handleItemPress(ch),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 3. ABA FILMES MOBILE ====================
  Widget _buildMoviesTab() {
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

    List<MediaCategory> visible = widget.moviesCategories;
    if (_selectedMovieFilter != '★ Todos') {
      final cleanFilter = _selectedMovieFilter.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      visible = widget.moviesCategories.where((cat) {
        return cat.title.toLowerCase().contains(cleanFilter.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        const SizedBox(height: 6),
        CategoryChipsBar(
          categories: chips,
          selectedCategory: _selectedMovieFilter,
          onSelected: (chip) => setState(() => _selectedMovieFilter = chip),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: visible.length,
            itemBuilder: (context, catIdx) {
              final cat = visible[catIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cat.items.length,
                      itemBuilder: (context, idx) {
                        final item = cat.items[idx];
                        final isFav = widget.favoriteIds.contains(item.id);

                        return AstraMediaCard(
                          item: item,
                          isFavorite: isFav,
                          width: 125,
                          height: 180,
                          onPlay: () => _handleItemPress(item),
                          onToggleFavorite: () => widget.onToggleFavorite(item),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 4. ABA SÉRIES MOBILE ====================
  Widget _buildSeriesTab() {
    final chips = [
      '★ Todos',
      '💥 Action & Adventure',
      '🎨 Animação',
      '😂 Comédia',
      '🎭 Drama',
      '🔍 Mistério',
      '🚀 Ficção',
    ];

    List<MediaCategory> visible = widget.seriesCategories;
    if (_selectedSeriesFilter != '★ Todos') {
      final cleanFilter = _selectedSeriesFilter.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
      visible = widget.seriesCategories.where((cat) {
        return cat.title.toLowerCase().contains(cleanFilter.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        const SizedBox(height: 6),
        CategoryChipsBar(
          categories: chips,
          selectedCategory: _selectedSeriesFilter,
          onSelected: (chip) => setState(() => _selectedSeriesFilter = chip),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: visible.length,
            itemBuilder: (context, catIdx) {
              final cat = visible[catIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cat.items.length,
                      itemBuilder: (context, idx) {
                        final item = cat.items[idx];
                        final isFav = widget.favoriteIds.contains(item.id);

                        return AstraMediaCard(
                          item: item,
                          isFavorite: isFav,
                          width: 125,
                          height: 180,
                          onPlay: () => _handleItemPress(item),
                          onToggleFavorite: () => widget.onToggleFavorite(item),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 5. ABA FAVORITOS MOBILE ====================
  Widget _buildFavoritesTab() {
    final favItems = widget.favoritesCategories.isNotEmpty
        ? widget.favoritesCategories.first.items
        : <MediaItem>[];

    if (favItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: 54, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Nenhum favorito ainda',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Marque a estrela nos canais e filmes favoritos para encontrá-los aqui rapidamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seus Favoritos (${favItems.length})',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: favItems.length,
              itemBuilder: (context, idx) {
                final item = favItems[idx];
                return AstraMediaCard(
                  item: item,
                  isFavorite: true,
                  width: double.infinity,
                  height: double.infinity,
                  onPlay: () => _handleItemPress(item),
                  onToggleFavorite: () => widget.onToggleFavorite(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAV BAR (Figma mobile-nav) ====================
  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1118).withOpacity(0.96),
        border: const Border(
          top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(MobileNavTab.home, 'Home', Icons.home),
          _buildNavItem(MobileNavTab.movies, 'Movies', Icons.movie_outlined),
          _buildNavItem(MobileNavTab.series, 'Series', Icons.grid_view),
          _buildNavItem(MobileNavTab.liveTv, 'Live TV', Icons.tv),
          _buildNavItem(MobileNavTab.favorites, 'Favorites', Icons.star_border),
        ],
      ),
    );
  }

  Widget _buildNavItem(MobileNavTab tab, String label, IconData icon) {
    final isActive = _currentTab == tab;

    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.cyan : const Color(0xFF657083),
              size: 22,
              shadows: isActive
                  ? [
                      Shadow(
                        color: AppTheme.cyan.withOpacity(0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.cyan : const Color(0xFF657083),
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10).withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
