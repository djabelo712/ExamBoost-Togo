// lib/screens/favorites/widgets/favorite_button.dart
// Bouton coeur reutilisable : a placer sur chaque carte question
// (revision_screen, simulation_screen) pour permettre a l'eleve de
// marquer/demarquer une question comme favorite.
//
// Comportement :
//   - Inactif : Icons.favorite_border, couleur inactiveColor (gris).
//   - Actif    : Icons.favorite, couleur activeColor (rouge par defaut).
//   - Au tap   : animation bounce (scale 1.0 -> 1.3 -> 1.0) + snackbar
//                "Ajoute aux favoris" / "Retire des favoris".
//
// Le bouton ecoute FavoritesService via Provider.of(context) : la vue
// se rafraichit automatiquement si le favori est modifie ailleurs.
//
// Usage :
//   FavoriteButton(
//     questionId: question.id,
//     userId: userProvider.currentUserId,
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String questionId;
  final String userId;

  /// Taille de l'icone (24 par defaut).
  final double size;

  /// Couleur quand la question EST favorite (rouge par defaut).
  final Color? activeColor;

  /// Couleur quand la question N'EST PAS favorite (gris par defaut).
  final Color? inactiveColor;

  /// Si true, aucun snackbar n'est affiche au tap (utile dans les
  /// contextes ou le parent affiche deja un feedback).
  final bool silent;

  const FavoriteButton({
    super.key,
    required this.questionId,
    required this.userId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.silent = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Le bounce : 300 ms au total.
    //  - 0   -> 0.4 : scale monte de 1.0 a 1.3 (pic, easeOut)
    //  - 0.4 -> 1.0 : scale redescend de 1.3 a 1.0 (retour spring elasticOut)
    // On utilise TweenSequence (une seule animation, pas besoin d'appeler
    // reverse() separement) -> rendu plus fiable.
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final service =
        Provider.of<FavoritesService>(context, listen: false);

    // Animation bounce : on lance le controller de 0 a 1 (forward),
    // la TweenSequence fait monter a 1.3 puis redescendre a 1.0.
    _bounceController.forward(from: 0.0);

    final wasFavorite = service.isFavorite(widget.userId, widget.questionId);
    final nowFavorite = await service.toggleFavorite(
      widget.userId,
      widget.questionId,
    );

    if (!mounted || widget.silent) return;

    // Feedback utilisateur : snackbar vert pour ajout, gris pour retrait.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nowFavorite
              ? 'Ajoute aux favoris'
              : 'Retire des favoris',
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: nowFavorite
            ? AppColors.success
            : AppColors.textSecondary,
        action: wasFavorite
            ? SnackBarAction(
                label: 'Annuler',
                textColor: Colors.white,
                onPressed: () {
                  service.toggleFavorite(
                    widget.userId,
                    widget.questionId,
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On ecoute le service pour rafraichir l'icone quand le favori
    // change (y compris depuis un autre widget).
    final service = Provider.of<FavoritesService>(context);
    final isFav = service.isFavorite(widget.userId, widget.questionId);

    final active = widget.activeColor ?? AppColors.error;
    final inactive = widget.inactiveColor ?? AppColors.textDisabled;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? active : inactive,
          size: widget.size,
        ),
        // Tooltip pour l'accessibilite (TalkBack).
        tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
        onPressed: _onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        splashRadius: widget.size,
      ),
    );
  }
}
