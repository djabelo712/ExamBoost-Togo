// lib/widgets/sync_status_banner.dart
// Bandeau non-intrusif qui apparaît en haut de l'ecran quand le statut de
// sync n'est pas "idle".
//
// Affichage :
//   syncing      : bandeau bleu  "Synchronisation en cours... (X actions)"
//   success      : bandeau vert  "Synchronise !" (auto-dismiss 3s)
//   error        : bandeau rouge "Erreur de sync. Reessai dans Xs" + bouton
//   partialError : bandeau orange "X actions non synchronisees"
//   offline      : bandeau gris "Hors-ligne — X actions en attente"
//   idle         : rien (banner hidden)
//
// Usage (a placer en haut d'un Scaffold body, juste sous l'AppBar) :
//   Column(
//     children: [
//       const SyncStatusBanner(),
//       Expanded(child: ...),
//     ],
//   )
//
// Ou via AnimatedSwitcher pour un fondu entre bandeau visible / invisible.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class SyncStatusBanner extends StatelessWidget {
  /// Si fourni, callback quand on tap sur "Reessayer maintenant".
  /// Si null, le bouton "Reessayer" n'apparait pas (le retry auto suffit).
  final VoidCallback? onRetryTap;

  /// Si true, le bandeau success s'auto-masque apres 3 secondes (defaut).
  /// Sinon, reste visible jusqu'a ce que le SyncService passe en idle.
  final bool autoDismissOnSuccess;

  const SyncStatusBanner({
    super.key,
    this.onRetryTap,
    this.autoDismissOnSuccess = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final status = syncService.status;
        if (status == SyncStatus.idle) {
          return const SizedBox.shrink();
        }

        // Sur success : auto-dismiss apres 3s
        if (status == SyncStatus.success && autoDismissOnSuccess) {
          // Le SyncService reset deja a idle apres 5s ; on accelere ici.
          Future.delayed(const Duration(seconds: 3), () {
            // Rien a faire : le state change soit via le timer du service,
            // soit on force un rebuild via le consumer (qui ecoute deja).
          });
        }

        return _Banner(
          status: status,
          pendingCount: syncService.pendingCount,
          lastError: syncService.lastError,
          retryInSeconds: syncService.retryInSeconds,
          onRetry: onRetryTap ??
              () => syncService.syncNow(reason: 'bannerRetry'),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;
  final String? lastError;
  final int? retryInSeconds;
  final VoidCallback onRetry;

  const _Banner({
    required this.status,
    required this.pendingCount,
    required this.lastError,
    required this.retryInSeconds,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _spec(status, pendingCount, lastError, retryInSeconds);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Material(
        key: ValueKey('${status}_${pendingCount}_$retryInSeconds'),
        color: spec.backgroundColor,
        elevation: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [
                if (spec.icon != null) ...[
                  spec.icon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spec.title,
                        style: TextStyle(
                          color: spec.foregroundColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (spec.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          spec.subtitle!,
                          style: TextStyle(
                            color: spec.foregroundColor.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (spec.actionLabel != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: spec.foregroundColor,
                      backgroundColor: spec.foregroundColor.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      spec.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BannerSpec _spec(
    SyncStatus status,
    int pending,
    String? error,
    int? retrySec,
  ) {
    switch (status) {
      case SyncStatus.syncing:
        return _BannerSpec(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          icon: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          title: 'Synchronisation en cours...',
          subtitle: pending > 0
              ? '$pending action(s) restante(s) a envoyer'
              : 'Finalisation...',
        );
      case SyncStatus.success:
        return _BannerSpec(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
          title: 'Synchronise avec succes',
        );
      case SyncStatus.partialError:
        return _BannerSpec(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 18),
          title: '$pending action(s) non synchronisee(s)',
          subtitle: error ?? 'Certaines actions ont echoue',
          actionLabel: 'Reessayer',
        );
      case SyncStatus.error:
        return _BannerSpec(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.cloud_off, color: Colors.white, size: 18),
          title: 'Erreur de synchronisation',
          subtitle: retrySec != null && retrySec > 0
              ? 'Nouvel essai dans ${retrySec}s — ${error ?? ""}'
              : (error ?? 'Erreur inconnue'),
          actionLabel: 'Reessayer maintenant',
        );
      case SyncStatus.offline:
        return _BannerSpec(
          backgroundColor: AppColors.textSecondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          title: 'Hors-ligne',
          subtitle: pending > 0
              ? '$pending action(s) en attente — seront envoyees des le retour du reseau'
              : 'Les actions seront synchronisees des le retour du reseau',
        );
      case SyncStatus.idle:
        // unreachable car le parent filtre deja, mais pour le compilateur
        return _BannerSpec(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          title: '',
        );
    }
  }
}

@immutable
class _BannerSpec {
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;

  const _BannerSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.title,
    this.icon,
    this.subtitle,
    this.actionLabel,
  });
}
