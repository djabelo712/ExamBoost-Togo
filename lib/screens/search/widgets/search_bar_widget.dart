// lib/screens/search/widgets/search_bar_widget.dart
// Barre de recherche full-text avec suggestions d'autocompletion.
//
// Comportement :
//   - TextField avec icone loupe a gauche, bouton "Filtres" (entonnoir) a droite
//   - Bouton "Effacer" (X) qui apparait quand du texte est present
//   - Suggestions en dropdown (OverlayEntry) basees sur les chapitres
//     correspondant a la saisie (via SearchService.getKeywordSuggestions)
//   - Tap sur une suggestion -> remplit le TextField et declenche la recherche
//   - Submit (Enter) -> declenche la recherche
//
// Le widget est stateful pour gerer le OverlayEntry des suggestions.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilterButtonPressed,
    required this.suggestionsFetcher,
    this.initialText,
    this.hintText = 'Rechercher une question, un chapitre...',
    this.autofocus = false,
  });

  /// Callback a chaque caractere tape.
  final ValueChanged<String> onChanged;

  /// Callback quand l'utilisateur soumet (Enter ou tap sur suggestion).
  final ValueChanged<String> onSubmitted;

  /// Callback quand on tap sur le bouton "Filtres".
  final VoidCallback onFilterButtonPressed;

  /// Fonction qui retourne les suggestions pour une saisie donnee
  /// (typiquement SearchService.getKeywordSuggestions).
  final List<String> Function(String query) suggestionsFetcher;

  /// Texte initial (pour pre-remplir depuis une SavedSearch).
  final String? initialText;

  /// Texte d'aide.
  final String hintText;

  /// Focus automatique a l'affichage.
  final bool autofocus;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = const [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged(text);
    if (text.trim().isEmpty) {
      _suggestions = const [];
      _removeOverlay();
      return;
    }
    _suggestions = widget.suggestionsFetcher(text);
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Laisser le temps a un tap sur suggestion de se declencher avant
      // de fermer l'overlay.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    } else if (_suggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    _overlayEntry = OverlayEntry(
      builder: (ctx) => _SuggestionsOverlay(
        suggestions: _suggestions,
        width: size.width,
        onTap: (s) {
          _controller.text = s;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: s.length),
          );
          widget.onSubmitted(s);
          _removeOverlay();
          _focusNode.unfocus();
        },
      ),
    );
    overlay.insert(_overlayEntry!);
    _showSuggestions = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  void _onFieldSubmitted(String value) {
    _removeOverlay();
    widget.onSubmitted(value);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _removeOverlay();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: _onFieldSubmitted,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textDisabled,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: _clear,
                        tooltip: 'Effacer',
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FilterButton(onPressed: widget.onFilterButtonPressed),
        ],
      ),
    );
  }
}

// ─── Bouton "Filtres" (entonnoir) ─────────────────────────────────────

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: const Icon(
            Icons.tune,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─── Overlay des suggestions ──────────────────────────────────────────

class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.suggestions,
    required this.width,
    required this.onTap,
  });

  final List<String> suggestions;
  final double width;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // Positionner juste sous la barre de recherche (qui fait ~58px de haut
    // avec son padding). On utilise Positioned pour ancrer l'overlay en haut
    // de l'ecran, a gauche, avec une marge de 16px.
    final mediaQuery = MediaQuery.of(context);
    return Positioned(
      top: mediaQuery.padding.top + 70, // sous l'AppBar + la barre de recherche
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: suggestions.length * 48.0 + 8,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider,
            ),
            itemBuilder: (ctx, i) {
              final s = suggestions[i];
              return InkWell(
                onTap: () => onTap(s),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.book_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.north_west,
                          size: 14, color: AppColors.textDisabled),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
