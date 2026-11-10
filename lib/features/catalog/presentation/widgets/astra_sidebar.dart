import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import 'astra_brand.dart';

enum CatalogNavTab {
  home,
  channels,
  movies,
  series,
  favorites,
  search,
}

class AstraSidebar extends StatefulWidget {
  final CatalogNavTab currentTab;
  final ValueChanged<CatalogNavTab> onTabSelected;
  final VoidCallback onAdminPressed;

  const AstraSidebar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onAdminPressed,
  });

  @override
  State<AstraSidebar> createState() => _AstraSidebarState();
}

class _AstraSidebarState extends State<AstraSidebar> {
  bool _isExpanded = false;

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() => _isExpanded = expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 210.0 : 68.0;

    return MouseRegion(
      onEnter: (_) => _setExpanded(true),
      onExit: (_) => _setExpanded(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.96),
          border: const Border(
            right: BorderSide(color: Color(0x1FFFFFFF), width: 1),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 28),
            // Astra Brand
            GestureDetector(
              onTap: () => widget.onTabSelected(CatalogNavTab.home),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: AstraBrand(compact: !_isExpanded, size: 24),
              ),
            ),
            const SizedBox(height: 32),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildNavItem(
                    tab: CatalogNavTab.search,
                    title: 'Search',
                    icon: Icons.search,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.home,
                    title: 'Home',
                    icon: Icons.home,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.channels,
                    title: 'TV Channels',
                    icon: Icons.tv,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.movies,
                    title: 'Movies',
                    icon: Icons.movie_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.series,
                    title: 'Series',
                    icon: Icons.grid_view,
                  ),
                  const SizedBox(height: 8),
                  _buildNavItem(
                    tab: CatalogNavTab.favorites,
                    title: 'Favorites',
                    icon: Icons.star_border,
                  ),
                ],
              ),
            ),

            // Profile Chip & Settings at Bottom (From Figma Design)
            Padding(
              padding: const EdgeInsets.all(10),
              child: TvFocusable(
                onFocusChange: (f) => _setExpanded(f),
                onPressed: widget.onAdminPressed,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppTheme.indigo,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'AS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Astra TV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ajustes',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.settings_outlined, color: AppTheme.textMuted, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required CatalogNavTab tab,
    required String title,
    required IconData icon,
  }) {
    final isSelected = widget.currentTab == tab;

    return TvFocusable(
      onFocusChange: (focused) {
        _setExpanded(focused);
      },
      onPressed: () {
        widget.onTabSelected(tab);
      },
      borderRadius: BorderRadius.circular(8),
      scaleFactor: 1.03,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.cyan.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF061014) : AppTheme.textSecondary,
              size: 22,
            ),
            if (_isExpanded) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF061014) : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
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
