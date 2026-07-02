// lib/screens/settings/sync_settings_screen.dart
// Ecran de configuration avancee de la synchronisation cloud.
//
// Sections :
//   1. Statut actuel : derniere sync, nb actions en attente, etat courant
//   2. Actions manuelles : Sync maintenant / Reessayer abandonnees / Annuler
//   3. Parametres auto-sync : WiFi only, donnees mobiles, frequence
//   4. Historique : 20 dernieres syncs (timestamp + statut + nb actions)
//
// Cet ecran lit le SyncService via Provider et met a jour les settings via
// syncService.updateSettings().
//
// Pour l'integrer au router (a faire par l'agent wiring) :
//   GoRoute(
//     path: '/settings/sync',
//     builder: (_, __) => const SyncSettingsScreen(),
//   ),

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sync_status.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final settings = syncService.settings;
        final history = syncService.getHistory(limit: 20);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Synchronisation'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(syncService: syncService),
              const SizedBox(height: 12),
              _ActionsCard(syncService: syncService),
              const SizedBox(height: 12),
              _AutoSyncCard(
                settings: settings,
                onChanged: (newSettings) =>
                    syncService.updateSettings(newSettings),
              ),
              const SizedBox(height: 12),
              _HistoryCard(history: history),
              const SizedBox(height: 24),
              Text(
                'ExamBoost Togo v0.1 — Sync CRDT-LWW',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Carte 1 : Statut actuel ──────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final SyncService syncService;
  const _StatusCard({required this.syncService});

  @override
  Widget build(BuildContext context) {
    final status = syncService.status;
    final pending = syncService.pendingCount;
    final lastSync = syncService.lastSyncAt;
    final error = syncService.lastError;
    final retry = syncService.retryInSeconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusIcon(status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(
              'Derniere sync',
              formatLastSync(lastSync),
            ),
            _infoRow(
              'Actions en attente',
              '$pending',
            ),
            if (syncService.abandonedCount > 0)
              _infoRow(
                'Actions abandonnees',
                '${syncService.abandonedCount}',
                color: AppColors.error,
              ),
            if (retry != null && retry > 0)
              _infoRow(
                'Reessai dans',
                '${retry}s',
                color: AppColors.warning,
              ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icon(Icons.cloud_done, color: AppColors.success, size: 24);
      case SyncStatus.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.info,
          ),
        );
      case SyncStatus.success:
        return Icon(Icons.check_circle, color: AppColors.success, size: 24);
      case SyncStatus.partialError:
        return Icon(Icons.warning_amber, color: AppColors.warning, size: 24);
      case SyncStatus.error:
        return Icon(Icons.error, color: AppColors.error, size: 24);
      case SyncStatus.offline:
        return Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 24);
    }
  }

  String _statusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Pret';
      case SyncStatus.syncing:
        return 'Synchronisation en cours';
      case SyncStatus.success:
        return 'Synchronise';
      case SyncStatus.partialError:
        return 'Synchronisation partielle';
      case SyncStatus.error:
        return 'Erreur de sync';
      case SyncStatus.offline:
        return 'Hors-ligne';
    }
  }
}

// ─── Carte 2 : Actions manuelles ──────────────────────────────────
class _ActionsCard extends StatelessWidget {
  final SyncService syncService;
  const _ActionsCard({required this.syncService});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions manuelles',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: syncService.status == SyncStatus.syncing
                    ? null
                    : () => syncService.syncNow(reason: 'manualSettings'),
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser maintenant'),
              ),
            ),
            const SizedBox(height: 8),
            if (syncService.abandonedCount > 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => syncService.retryAbandoned(),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Reessayer ${syncService.abandonedCount} action(s) abandonnee(s)',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                onPressed: () => _confirmCancelAll(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Annuler toutes les actions en attente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler toutes les actions ?'),
        content: Text(
          '${syncService.pendingCount} action(s) en attente seront definitivement supprimees. '
          'Ces donnees ne pourront pas etre recuperees. Les actions deja synchronisees ne sont pas affectees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final count = await syncService.cancelAllPending();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count action(s) supprimee(s)')),
        );
      }
    }
  }
}

// ─── Carte 3 : Parametres auto-sync ───────────────────────────────
class _AutoSyncCard extends StatelessWidget {
  final SyncSettings settings;
  final ValueChanged<SyncSettings> onChanged;

  const _AutoSyncCard({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synchronisation automatique',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Declenche la sync des que le reseau approprie est disponible.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-sync sur WiFi'),
              subtitle: const Text('Recommande — gratuit et rapide'),
              value: settings.autoSyncOnWifi,
              onChanged: (v) =>
                  onChanged(settings.copyWith(autoSyncOnWifi: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Auto-sync sur donnees mobiles'),
              subtitle: const Text(
                'Active si vous avez un forfait data suffisant',
              ),
              value: settings.autoSyncOnMobile,
              onChanged: (v) =>
                  onChanged(settings.copyWith(autoSyncOnMobile: v)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24),
            const Text('Frequence de verification'),
            const SizedBox(height: 4),
            Text(
              'L\'app verifiera toutes les ${settings.autoSyncIntervalMinutes == 0 ? "—" : "${settings.autoSyncIntervalMinutes} min"} si des actions sont en attente.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _IntervalSelector(
              value: settings.autoSyncIntervalMinutes,
              onChanged: (minutes) =>
                  onChanged(settings.copyWith(autoSyncIntervalMinutes: minutes)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _IntervalSelector({required this.value, required this.onChanged});

  static const _options = [
    (1, '1 min'),
    (5, '5 min'),
    (15, '15 min'),
    (0, 'Manuel'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((opt) {
        final (minutes, label) = opt;
        final selected = value == minutes;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onChanged(minutes),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Carte 4 : Historique ─────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final List<SyncHistoryEntry> history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${history.length} / 20',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Aucune sync effectuee pour le moment',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...history.map(_historyTile),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(SyncHistoryEntry entry) {
    final color = _statusColor(entry.status);
    final icon = _statusIcon(entry.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.successCount} ok / ${entry.failCount} echec',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (entry.errorMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (entry.remainingCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.remainingCount} restantes',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SyncHistoryStatus s) {
    switch (s) {
      case SyncHistoryStatus.success:
        return AppColors.success;
      case SyncHistoryStatus.partialError:
        return AppColors.warning;
      case SyncHistoryStatus.error:
        return AppColors.error;
      case SyncHistoryStatus.offline:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(SyncHistoryStatus s) {
    switch (s) {
      case SyncHistoryStatus.success:
        return Icons.check_circle;
      case SyncHistoryStatus.partialError:
        return Icons.warning_amber;
      case SyncHistoryStatus.error:
        return Icons.error;
      case SyncHistoryStatus.offline:
        return Icons.wifi_off;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final delta = now.difference(dt);
    if (delta.inMinutes < 1) return 'A l\'instant';
    if (delta.inMinutes < 60) return 'Il y a ${delta.inMinutes} min';
    if (delta.inHours < 24) return 'Il y a ${delta.inHours} h';
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Helper expose pour le wiring ─────────────────────────────────
//
// L'agent wiring pourra ajouter cette route au AppRouter :
//
//   GoRoute(
//     path: '/settings/sync',
//     builder: (context, state) => const SyncSettingsScreen(),
//   ),
//
// Et un bouton "Sync cloud" dans settings_screen.dart section 5 (Donnees)
// qui navigue vers '/settings/sync'.
