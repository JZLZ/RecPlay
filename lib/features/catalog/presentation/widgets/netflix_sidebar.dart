import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';

enum CatalogNavTab {
  home,
  channels,
  movies,
  series,
  favorites,
  search,
}

class NetflixSidebar extends StatefulWidget {
  final CatalogNavTab currentTab;
  final ValueChanged<CatalogNavTab> onTabSelected;
  final VoidCallback onAdminPressed;
  final VoidCallback? onExitRight;

  const NetflixSidebar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onAdminPressed,
    this.onExitRight,
  });

  @override
  State<NetflixSidebar> createState() => _NetflixSidebarState();
}

class _NetflixSidebarState extends State<NetflixSidebar> {
  bool _isExpanded = false;

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() => _isExpanded = expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 210.0 : 70.0;

    return MouseRegion(
      onEnter: (_) => _setExpanded(true),
      onExit: (_) => _setExpanded(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.95),
          border: const Border(
            right: BorderSide(color: Colors.white10, width: 1),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo / Header
            GestureDetector(
              onTap: () => widget.onTabSelected(CatalogNavTab.home),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'RECPLAY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildNavItem(
                    tab: CatalogNavTab.home,
                    title: 'Início',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.channels,
                    title: 'Canais',
                    icon: Icons.live_tv_outlined,
                    activeIcon: Icons.live_tv,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.movies,
                    title: 'Filmes',
                    icon: Icons.movie_outlined,
                    activeIcon: Icons.movie,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.series,
                    title: 'Séries',
                    icon: Icons.video_library_outlined,
                    activeIcon: Icons.video_library,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.favorites,
                    title: 'Favoritos',
                    icon: Icons.star_outline,
                    activeIcon: Icons.star,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.search,
                    title: 'Buscar',
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search,
                  ),
                ],
              ),
            ),

            // Settings / Admin Panel at Bottom
            Padding(
              padding: const EdgeInsets.all(10),
              child: TvFocusable(
                onFocusChange: (f) => _setExpanded(f),
                onPressed: widget.onAdminPressed,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 22),
                      if (_isExpanded) ...[
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Ajustes',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required CatalogNavTab tab,
    required String title,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = widget.currentTab == tab;

    return TvFocusable(
      onFocusChange: (focused) {
        _setExpanded(focused);
      },
      onPressed: () {
        widget.onTabSelected(tab);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
            if (_isExpanded) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
