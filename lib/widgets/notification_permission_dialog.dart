// lib/widgets/notification_permission_dialog.dart
// Dialog bienveillant demande la permission d'envoyer des notifications.
//
// Affiche au premier lancement (si permissionRequested == false) :
//   - Titre + description rassurante
//   - 2 boutons : "Bien sur !" / "Plus tard"
//
// Sur "Bien sur !" :
//   1. Appelle NotificationService().init()
//   2. Met a jour settings (permissionRequested = true, nextPrompt = null)
//   3. Appelle le callback [onGranted] (le caller peut y planifier les
//      rappels avec le contexte utilisateur)
//
// Sur "Plus tard" :
//   1. Met a jour settings (permissionRequested = true, nextPrompt = +7j)
//   2. Retourne false
//
// Usage typique (a brancher dans home_screen ou main.dart) :
//
//   final settings = await NotificationSettingsStore.load();
//   if (settings.canRePromptPermission) {
//     await showNotificationPermissionDialog(
//       context,
//       settings: settings,
//       onGranted: () async {
//         final scheduler = NotificationScheduler(...);
//         await scheduler.scheduleAllReminders(...);
//       },
//     );
//   }

import 'package:flutter/material.dart';

import '../models/notification_settings.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Affiche le dialog de demande de permission notifications.
///
/// Renvoie :
///   - true si l'utilisateur a accepte ("Bien sur !")
///   - false si l'utilisateur a refuse ("Plus tard")
///   - null si le dialog a ete dismiss sans choix (tap outside)
Future<bool?> showNotificationPermissionDialog(
  BuildContext context, {
  required NotificationSettings settings,
  Future<void> Function()? onGranted,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PermissionDialog(
      settings: settings,
      onGranted: onGranted,
    ),
  );
}

class _PermissionDialog extends StatefulWidget {
  const _PermissionDialog({
    required this.settings,
    this.onGranted,
  });

  final NotificationSettings settings;
  final Future<void> Function()? onGranted;

  @override
  State<_PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<_PermissionDialog> {
  bool _working = false;

  Future<void> _accept() async {
    setState(() => _working = true);

    try {
      // 1. Initialise le service de notifications
      await NotificationService().init();

      // 2. Met a jour les settings
      widget.settings.markPermissionRequested(granted: true);

      // 3. Callback optionnel (le caller y planifie les rappels)
      if (widget.onGranted != null) {
        await widget.onGranted!();
      }
    } catch (_) {
      // Best-effort : meme si l'init echoue, on marque comme demande
      // pour ne pas re-poser la question a chaque lancement.
      widget.settings.markPermissionRequested(granted: false);
    } finally {
      if (mounted) {
        setState(() => _working = false);
        Navigator.of(context).pop(true);
      }
    }
  }

  void _refuse() {
    widget.settings.markPermissionRequested(granted: false);
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Icone ronde ────────────────────────────────────
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Titre ──────────────────────────────────────────
            Text(
              'Rappels pour t\'aider a rester regulier ?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // ─── Description ────────────────────────────────────
            Text(
              'ExamBoost peut t\'envoyer des notifications locales pour :',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            _Bullet(text: 'Te rappeler de reviser chaque jour a ton heure preferee'),
            _Bullet(text: 'Te prevenir si ton streak est en danger'),
            _Bullet(text: 'Te signaler quand de nouvelles questions sont disponibles'),
            const SizedBox(height: 8),
            Text(
              'Aucune donnee envoyee a un serveur. Tout reste sur ton telephone.',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // ─── Bouton "Plus tard" ──────────────────────────────
        TextButton(
          onPressed: _working ? null : _refuse,
          child: const Text('Plus tard'),
        ),
        // ─── Bouton "Bien sur !" ─────────────────────────────
        ElevatedButton(
          onPressed: _working ? null : _accept,
          child: _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Bien sur !'),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
