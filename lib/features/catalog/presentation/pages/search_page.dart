import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../domain/entities/media_item.dart';
import '../../data/repositories/catalog_repository.dart';
import '../widgets/astra_media_card.dart';
import '../widgets/astra_brand.dart';
import '../widgets/series_episodes_modal.dart';
import '../../../player/presentation/pages/player_page.dart';

class SearchPage extends StatefulWidget {
  final CatalogRepository repository;
  final bool isTv;

  const SearchPage({
    super.key,
    required this.repository,
    this.isTv = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  List<MediaItem> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  final Set<String> _favoriteIds = {};

  final List<List<String>> _keyboardLayout = [
    ['A', 'B', 'C', 'D', 'E', 'F'],
    ['G', 'H', 'I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P', 'Q', 'R'],
    ['S', 'T', 'U', 'V', 'W', 'X'],
    ['Y', 'Z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favCategories = await widget.repository.getFavorites();
    if (favCategories.isNotEmpty && mounted) {
      setState(() {
        _favoriteIds.addAll(favCategories.first.items.map((i) => i.id));
      });
    }
  }

  void _onKeyPress(String char) {
    _textController.text += char;
    _onQueryChanged(_textController.text);
  }

  void _onBackspace() {
    final current = _textController.text;
    if (current.isNotEmpty) {
      _textController.text = current.substring(0, current.length - 1);
      _onQueryChanged(_textController.text);
    }
  }

  void _onClear() {
    _textController.clear();
    _onQueryChanged('');
  }

  void _onSpace() {
    _textController.text += ' ';
    _onQueryChanged(_textController.text);
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final items = await widget.repository.searchOnline(query);
      if (mounted) {
        setState(() {
          _results = items;
          _isSearching = false;
        });
      }
    });
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

  Future<void> _toggleFavorite(MediaItem item) async {
    final isFav = await widget.repository.toggleFavorite(item.id);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(item.id);
        } else {
          _favoriteIds.remove(item.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lado Esquerdo: Barra de Busca + Teclado Virtual Astra D-Pad
          SizedBox(
            width: widget.isTv ? 340 : 300,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderSubtle, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Astra na Busca
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: AstraBrand(size: 20),
                  ),

                  // Campo de Texto de Busca com Estilo Astra Glass
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.slateGlass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _inputFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search Astra ecosystem...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.cyan, size: 20),
                        suffixIcon: _textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                                onPressed: _onClear,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: _onQueryChanged,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teclado D-Pad Astra
                  Expanded(
                    child: ListView(
                      children: [
                        ..._keyboardLayout.map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: row.map((char) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: TvFocusable(
                                      scaleFactor: 1.12,
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () => _onKeyPress(char),
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          char,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),

                        // Teclas Especiais: Espaço, Apagar e Limpar
                        Row(
                          children: [
                            // Espaço
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: TvFocusable(
                                  scaleFactor: 1.06,
                                  borderRadius: BorderRadius.circular(8),
                                  onPressed: _onSpace,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'SPACE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Apagar
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: TvFocusable(
                                  scaleFactor: 1.08,
                                  borderRadius: BorderRadius.circular(8),
                                  onPressed: _onBackspace,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ),

                            // Limpar
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: TvFocusable(
                                  scaleFactor: 1.08,
                                  borderRadius: BorderRadius.circular(8),
                                  onPressed: _onClear,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'CLEAR',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
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
            ),
          ),

          // Lado Direito: Grade de Resultados em Tempo Real Astra
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _textController.text.trim().isEmpty
                            ? 'Search Results'
                            : 'Results for "${_textController.text.trim()}" (${_results.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.02,
                        ),
                      ),
                      if (_isSearching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: _textController.text.trim().isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 64, color: Colors.white12),
                                SizedBox(height: 16),
                                Text(
                                  'Search live channels, movies and series across Astra',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty && !_isSearching
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.white12),
                                    SizedBox(height: 16),
                                    Text(
                                      'No titles found.',
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 180,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, idx) {
                                  final item = _results[idx];
                                  final isFav = _favoriteIds.contains(item.id);

                                  return AstraMediaCard(
                                    item: item,
                                    isFavorite: isFav,
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
            ),
          ),
        ],
      ),
    );
  }
}
