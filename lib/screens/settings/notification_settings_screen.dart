// lib/screens/settings/notification_settings_screen.dart
// Ecran de configuration des notifications locales ExamBoost.
//
// Sections :
//   1. Rappel quotidien     — Switch + TimePicker (par defaut 18:00)
//   2. Alertes streak        — Switch + description
//   3. Notifications sociales — Switch + description
//   4. Nouvelles questions   — Switch + description
//   5. Test                  — Bouton "Envoyer une notification test"
//   6. Danger                — Bouton "Desactiver toutes les notifications"
//   7. Historique            — Apercu des 10 dernieres notifs envoyees
//
// Donnees : NotificationSettings (Hive box "notification_settings"),
//           NotificationHistory (Hive box "notification_history"),
//           AppUser + SrsStats (via Provider) pour re-planifier apres changements.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notification_history.dart';
import '../../models/notification_settings.dart';
import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../services/notification_scheduler.dart';
import '../../services/notification_service.dart';
import '../../services/notification_templates.dart';
import '../../services/srs_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  List<NotificationHistory> _history = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // ─── Chargement settings + historique ─────────────────────────
  Future<void> _load() async {
    try {
      // Settings
      final settingsBox = Hive.isBoxOpen('notification_settings')
          ? Hive.box<NotificationSettings>('notification_settings')
          : await Hive.openBox<NotificationSettings>('notification_settings');
      NotificationSettings? s = settingsBox.get('current');
      if (s == null) {
        s = NotificationSettings();
        await settingsBox.put('current', s);
        // Apres put(), l'objet est associe a la box et save() fonctionne.
      }

      // Historique
      final historyBox = Hive.isBoxOpen('notification_history')
          ? Hive.box<NotificationHistory>('notification_history')
          : await Hive.openBox<NotificationHistory>('notification_history');
      final hist = historyBox.values.toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      if (mounted) {
        setState(() {
          _settings = s;
          _history = hist.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Erreur chargement notif settings: $e');
    }
  }

  // ─── Re-planification apres changement de settings ────────────
  Future<void> _reschedule() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = _settings;
      if (settings == null) return;

      // Capturer le SrsService AVANT tout await (evite l'usage de context
      // au-dela d'un gap async — "BuildContext across async gaps").
      final srs = context.read<SrsService>();

      final service = NotificationService();
      await service.init();
      final scheduler = NotificationScheduler(
        service: service,
        settings: settings,
      );

      // Recupere l'utilisateur + les cartes pour calculer streak precis
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? 'user_demo';
      final userBox = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');
      AppUser user = userBox.get(userId) ??
          AppUser(
            id: userId,
            nom: 'Eleve',
            prenom: 'Eleve',
            niveauScolaire: '3eme',
            dateInscription: DateTime.now(),
          );

      final stats = srs.getStats(userId);

      // Cartes pour streak precis
      List<ReviewCard>? cards;
      try {
        final cardBox = Hive.isBoxOpen('review_cards')
            ? Hive.box<ReviewCard>('review_cards')
            : await Hive.openBox<ReviewCard>('review_cards');
        cards = cardBox.values.where((c) => c.userId == userId).toList();
      } catch (_) {
        cards = null;
      }

      await scheduler.onSettingsChanged(
        user: user,
        srsStats: stats,
        cards: cards,
      );
    } catch (e) {
      debugPrint('Erreur re-planification: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── Switch change handler ────────────────────────────────────
  Future<void> _onSwitchChanged(
    bool Function(NotificationSettings) getter,
    void Function(NotificationSettings, bool) setter,
    bool value,
  ) async {
    final s = _settings;
    if (s == null) return;
    setter(s, value);
    await s.save();
    setState(() {});
    await _reschedule();
  }

  // ─── Time picker ──────────────────────────────────────────────
  Future<void> _pickTime() async {
    final s = _settings;
    if (s == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: s.preferredReminderTime,
      helpText: 'Heure du rappel quotidien',
      confirmText: 'OK',
      cancelText: 'Annuler',
    );
    if (picked == null) return;

    s.setPreferredTime(picked);
    await s.save();
    setState(() {});
    await _reschedule();
  }

  // ─── Test notification ────────────────────────────────────────
  Future<void> _sendTest() async {
    await NotificationService().sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification test envoyee.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    await _load(); // rafraichit l'historique
  }

  // ─── Disable all ──────────────────────────────────────────────
  Future<void> _confirmDisableAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactiver toutes les notifications ?'),
        content: const Text(
          'Tu ne recevras plus aucun rappel, alerte streak ou notification '
          'sociale. Tu pourras les reactiver a tout moment ici.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactiver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final s = _settings;
    if (s == null) return;

    s.dailyReminderEnabled = false;
    s.streakAlertsEnabled = false;
    s.socialNudgesEnabled = false;
    s.newQuestionsAlertsEnabled = false;
    await s.save();

    await NotificationService().cancelAll();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont ete desactivees.'),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 20),

                    // 1. Rappel quotidien
                    _buildSectionTitle('Rappel quotidien'),
                    _buildDailyReminderCard(),
                    const SizedBox(height: 16),

                    // 2. Alertes streak
                    _buildSectionTitle('Alertes streak'),
                    _buildSwitchCard(
                      icon: Icons.local_fire_department,
                      iconColor: AppColors.accent,
                      title: 'Streak en danger',
                      subtitle:
                          'Previents-moi si mon streak est en danger (apres 20h).',
                      value: _settings!.streakAlertsEnabled,
                      onChanged: (v) => _onSwitchChanged(
                        (s) => s.streakAlertsEnabled,
                        (s, v) => s.streakAlertsEnabled = v,
                        v,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Notifications sociales
                    _buildSectionTitle('Notifications sociales'),
                    _buildSwitchCard(
                      icon: Icons.people,
                      iconColor: AppColors.info,
                      title: 'Comparaison avec d\'autres eleves',
                      subtitle:
                          'Encouragement amical hebdomadaire (mock, sera branche au backend).',
                      value: _settings!.socialNudgesEnabled,
                      onChanged: (v) => _onSwitchChanged(
                        (s) => s.socialNudgesEnabled,
                        (s, v) => s.socialNudgesEnabled = v,
                        v,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Nouvelles questions
                    _buildSectionTitle('Nouvelles questions'),
                    _buildSwitchCard(
                      icon: Icons.new_releases,
                      iconColor: AppColors.success,
                      title: 'Alertes nouveautes',
                      subtitle:
                          'Previents-moi quand de nouvelles questions sont ajoutees.',
                      value: _settings!.newQuestionsAlertsEnabled,
                      onChanged: (v) => _onSwitchChanged(
                        (s) => s.newQuestionsAlertsEnabled,
                        (s, v) => s.newQuestionsAlertsEnabled = v,
                        v,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Test
                    _buildSectionTitle('Test'),
                    _buildTestCard(),
                    const SizedBox(height: 24),

                    // 6. Historique
                    _buildSectionTitle('Historique recent'),
                    _buildHistoryCard(),
                    const SizedBox(height: 24),

                    // 7. Danger
                    _buildDangerCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Composants UI ────────────────────────────────────────────
  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure tes rappels pour rester regulier dans tes revisions. '
              'Tout est local, aucune donnee envoyee.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDailyReminderCard() {
    final s = _settings!;
    final timeStr =
        '${s.preferredHour.toString().padLeft(2, '0')}:${s.preferredMinute.toString().padLeft(2, '0')}';

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Rappel quotidien', style: AppTextStyles.h3),
              ),
              Switch(
                value: s.dailyReminderEnabled,
                onChanged: (v) => _onSwitchChanged(
                  (s) => s.dailyReminderEnabled,
                  (s, v) => s.dailyReminderEnabled = v,
                  v,
                ),
              ),
            ],
          ),
          if (s.dailyReminderEnabled) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Heure preferee', style: AppTextStyles.body),
                    ),
                    Text(
                      timeStr,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildTestCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verifier que les notifications fonctionnent',
              style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Envoie une notification test immediatement pour confirmer '
            'que les permissions sont accordees.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendTest,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer une notification test'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    if (_history.isEmpty) {
      return Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune notification envoyee pour le moment.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _history.map((h) {
          final catLabel = NotificationTemplates.categoryLabel(h.category);
          final timeStr =
              '${h.sentAt.hour.toString().padLeft(2, '0')}:${h.sentAt.minute.toString().padLeft(2, '0')} '
              '${h.sentAt.day}/${h.sentAt.month}';

          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(
              _iconForCategory(h.category),
              color: _colorForCategory(h.category),
              size: 20,
            ),
            title: Text(
              h.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
            subtitle: Text(
              '$catLabel - $timeStr${h.wasTapped ? " - ouverte" : ""}',
              style: AppTextStyles.bodySmall,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Zone dangereuse',
                  style: AppTextStyles.h3.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Desactive toutes les notifications locales. Tu pourras les '
            'reactiver a tout moment.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: _confirmDisableAll,
              icon: const Icon(Icons.notifications_off),
              label: const Text('Desactiver toutes les notifications'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  IconData _iconForCategory(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminders:
        return Icons.alarm;
      case NotificationCategory.streak:
        return Icons.local_fire_department;
      case NotificationCategory.social:
        return Icons.people;
      case NotificationCategory.updates:
        return Icons.new_releases;
    }
  }

  Color _colorForCategory(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.reminders:
        return AppColors.primary;
      case NotificationCategory.streak:
        return AppColors.accent;
      case NotificationCategory.social:
        return AppColors.info;
      case NotificationCategory.updates:
        return AppColors.success;
    }
  }
}
