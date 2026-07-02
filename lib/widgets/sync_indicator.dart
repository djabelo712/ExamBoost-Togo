// lib/widgets/sync_indicator.dart
// Petit indicateur de statut de sync a mettre dans les AppBars.
//
// Affichage :
//   idle              : icone cloud grise (offline mode implicite)
//   syncing           : icone cloud + petit CircularProgressIndicator
//   success           : icone cloud_done verte (1s puis retour idle visuel)
//   partialError      : icone cloud_queue orange + badge "!"
//   error             : icone cloud_off rouge
//   offline           : icone cloud_off grise
//
// Consomme un SyncService via Provider (ChangeNotifier). Tap pour ouvrir
// l'ecran de parametres de sync.
//
// Usage :
//   AppBar(
//     title: Text('Home'),
//     actions: [
//       const SyncIndicator(),
//       ...,
//     ],
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class SyncIndicator extends StatelessWidget {
  /// Taille de l'icone (default 22 pour s'integrer dans une AppBar).
  final double size;

  /// Si true, affiche un petit badge avec le nombre d'actions en attente.
  final bool showPendingBadge;

  /// Callback quand on tap. Si null, ne fait rien (bouton inerte).
  /// Recommande : ouvrir l'ecran de parametres de sync.
  final VoidCallback? onTap;

  const SyncIndicator({
    super.key,
    this.size = 22,
    this.showPendingBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final status = syncService.status;
        final pending = syncService.pendingCount;

        return Tooltip(
          message: _tooltip(status, pending, syncService.lastError),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildContent(status, pending),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(SyncStatus status, int pending) {
    switch (status) {
      case SyncStatus.idle:
        return _wrap(
          Icon(Icons.cloud_outlined,
              size: size, color: AppColors.textSecondary),
          pending: pending,
          badgeColor: AppColors.textSecondary,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.cloud, size: size, color: AppColors.info),
              SizedBox(
                width: size * 0.7,
                height: size * 0.7,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                ),
              ),
            ],
          ),
        );
      case SyncStatus.success:
        return Icon(Icons.cloud_done,
            size: size, color: AppColors.success);
      case SyncStatus.partialError:
        return _wrap(
          Icon(Icons.cloud_queue, size: size, color: AppColors.warning),
          pending: pending,
          badgeColor: AppColors.warning,
          forceBadge: true,
        );
      case SyncStatus.error:
        return Icon(Icons.cloud_off, size: size, color: AppColors.error);
      case SyncStatus.offline:
        return Icon(Icons.cloud_off,
            size: size, color: AppColors.textSecondary);
    }
    // unreachable mais pour le compilateur
    return Icon(Icons.cloud_outlined, size: size);
  }

  Widget _wrap(
    Widget icon, {
    int pending = 0,
    Color badgeColor = AppColors.accent,
    bool forceBadge = false,
  }) {
    if (!showPendingBadge) return icon;
    final showBadge = forceBadge || pending > 0;
    if (!showBadge) return icon;

    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: icon),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: BoxConstraints(
                minWidth: size * 0.45,
                minHeight: size * 0.45,
              ),
              child: Text(
                pending > 99 ? '99+' : '$pending',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltip(SyncStatus status, int pending, String? error) {
    switch (status) {
      case SyncStatus.idle:
        return pending > 0
            ? '$pending action(s) en attente de sync'
            : 'Synchronise';
      case SyncStatus.syncing:
        return 'Synchronisation en cours... ($pending restantes)';
      case SyncStatus.success:
        return 'Synchronisation reussie';
      case SyncStatus.partialError:
        return '$pending action(s) non synchronisees — appuyez pour reessayer';
      case SyncStatus.error:
        return 'Erreur de sync: ${error ?? "inconnue"}';
      case SyncStatus.offline:
        return 'Hors-ligne — $pending action(s) en attente';
    }
    return 'Sync';
  }
}
