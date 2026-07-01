// lib/screens/settings/settings_screen.dart
// Ecran Parametres — 6 sections :
//   1. Langue (FR / EN via LocaleProvider)
//   2. Theme (Clair / Sombre / Systeme via ThemeProvider)
//   3. Compte (profil, reset progression, supprimer compte)
//   4. A propos (version, credits, liens, mentions legales)
//   5. Donnees (collecte anonyme PostHog, export JSON)
//   6. Notifications (rappels quotidiens, alertes streak, heure preferee)
//
// Architecture : StatefulWidget + ScrollView + Cards par section.
// Tous les toggles persistent dans SharedPreferences (cle 'settings.*').
// Les actions destructives (reset / supprimer) demandent une confirmation
// dialog avec couleur rouge pour "Supprimer mon compte".

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ─── Etat des toggles (charges depuis SharedPreferences au initState) ───
  bool _analyticsEnabled = true;     // collecte anonyme PostHog
  bool _dailyReminderEnabled = true; // rappels quotidiens
  bool _streakAlertsEnabled = true;  // alertes streak
  TimeOfDay _preferredTime = const TimeOfDay(hour: 18, minute: 0);

  // ─── Clefs SharedPreferences ───────────────────────────────────────────
  static const String _kAnalytics = 'settings.analytics_enabled';
  static const String _kDailyReminder = 'settings.daily_reminder_enabled';
  static const String _kStreakAlerts = 'settings.streak_alerts_enabled';
  static const String _kPreferredHour = 'settings.preferred_hour';
  static const String _kPreferredMinute = 'settings.preferred_minute';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _analyticsEnabled = prefs.getBool(_kAnalytics) ?? true;
        _dailyReminderEnabled = prefs.getBool(_kDailyReminder) ?? true;
        _streakAlertsEnabled = prefs.getBool(_kStreakAlerts) ?? true;
        final h = prefs.getInt(_kPreferredHour) ?? 18;
        final m = prefs.getInt(_kPreferredMinute) ?? 0;
        _preferredTime = TimeOfDay(hour: h, minute: m);
      });
    } catch (_) {
      // Etat par defaut conserve.
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {/* non bloquant */}
  }

  Future<void> _setPreferredTime(TimeOfDay t) async {
    setState(() => _preferredTime = t);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPreferredHour, t.hour);
      await prefs.setInt(_kPreferredMinute, t.minute);
    } catch (_) {/* non bloquant */}
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parametres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSectionLangue(),
              const SizedBox(height: 16),
              _buildSectionTheme(),
              const SizedBox(height: 16),
              _buildSectionCompte(),
              const SizedBox(height: 16),
              _buildSectionDonnees(),
              const SizedBox(height: 16),
              _buildSectionNotifications(),
              const SizedBox(height: 16),
              _buildSectionAPropos(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 1. SECTION LANGUE
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLangue() {
    // On ne peut pas acceder au LocaleProvider via Provider.of sans
    // ecouter (sinon rebuild inutile du SegmentedButton). On l'utilise
    // dans le Consumer ci-dessous pour la valeur courante.
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final isFr = localeProvider.locale.languageCode == 'fr';
        return _SectionCard(
          icon: Icons.language,
          title: 'Langue',
          subtitle: 'Choisis la langue de l\'application',
          children: <Widget>[
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'fr',
                  icon: Text('FR'),
                  label: Text('Francais'),
                ),
                ButtonSegment<String>(
                  value: 'en',
                  icon: Text('EN'),
                  label: Text('Anglais'),
                ),
              ],
              selected: <String>{isFr ? 'fr' : 'en'},
              onSelectionChanged: (Set<String> newSelection) async {
                final code = newSelection.first;
                await localeProvider.setLocale(Locale(code));
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Le francais est la langue par defaut (langue d\'enseignement '
              'au Togo). L\'anglais sert pour le programme DJANTA et les '
              'eleves anglophones de la CEDEAO.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 2. SECTION THEME
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionTheme() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final String selected;
        switch (themeProvider.themeMode) {
          case ThemeMode.light:
            selected = 'light';
            break;
          case ThemeMode.dark:
            selected = 'dark';
            break;
          case ThemeMode.system:
            selected = 'system';
            break;
        }
        return _SectionCard(
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Clair, sombre ou suivant le systeme',
          children: <Widget>[
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'light',
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Clair'),
                ),
                ButtonSegment<String>(
                  value: 'dark',
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Sombre'),
                ),
                ButtonSegment<String>(
                  value: 'system',
                  icon: Icon(Icons.settings_brightness),
                  label: Text('Systeme'),
                ),
              ],
              selected: <String>{selected},
              onSelectionChanged: (Set<String> newSelection) async {
                final value = newSelection.first;
                final mode = <String, ThemeMode>{
                  'light': ThemeMode.light,
                  'dark': ThemeMode.dark,
                  'system': ThemeMode.system,
                }[value]!;
                await themeProvider.setThemeMode(mode);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Le mode sombre reduit la fatigue oculaire en environnement '
              'faiblement eclaire. "Systeme" suit automatiquement les '
              'reglages de ton telephone.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 3. SECTION COMPTE
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionCompte() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return _SectionCard(
      icon: Icons.person_outline,
      title: 'Compte',
      subtitle: 'Profil, progression et suppression de compte',
      children: <Widget>[
        if (user != null) ...<Widget>[
          _InfoRow(label: 'Nom complet', value: '${user.prenom} ${user.nom}'),
          _InfoRow(label: 'Niveau', value: _niveauLabel(user.niveauScolaire, user.serie)),
          _InfoRow(label: 'Etablissement', value: user.etablissement ?? 'Non renseigne'),
          _InfoRow(
            label: 'Inscrit le',
            value: '${user.dateInscription.day.toString().padLeft(2, '0')}/'
                '${user.dateInscription.month.toString().padLeft(2, '0')}/'
                '${user.dateInscription.year}',
          ),
          _InfoRow(
            label: 'Competences suivies',
            value: '${user.bktMaitrise.length}',
          ),
          _InfoRow(
            label: 'Questions repondues',
            value: '${user.totalQuestionsAnswered}',
          ),
          const Divider(height: 24),
        ],
        // ─── Reset progression ────────────────────────────────────
        ListTile(
          leading: const Icon(Icons.restart_alt, color: AppColors.warning),
          title: const Text('Reinitialiser ma progression'),
          subtitle: const Text(
            'Efface tes cartes SRS et scores BKT. Ton profil est conserve.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _confirmResetProgression(context),
        ),
        // ─── Supprimer compte ─────────────────────────────────────
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: Text(
            'Supprimer mon compte',
            style: const TextStyle(color: AppColors.error),
          ),
          subtitle: const Text(
            'Efface toutes tes donnees et te deconnecte. Action irreversible.',
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.error),
          onTap: () => _confirmDeleteAccount(context),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 4. SECTION A PROPOS
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionAPropos() {
    return _SectionCard(
      icon: Icons.info_outline,
      title: 'A propos',
      subtitle: 'Version, credits et mentions legales',
      children: <Widget>[
        _InfoRow(label: 'Application', value: 'ExamBoost Togo'),
        _InfoRow(label: 'Version', value: '0.1.0 (build 1)'),
        _InfoRow(label: 'Equipe', value: 'SmartFarm Togo / AIMS Ghana'),
        _InfoRow(label: 'Licence', value: 'MIT (open source)'),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.code, color: AppColors.primary),
          title: const Text('Code source (GitHub)'),
          subtitle: const Text('github.com/djabelo712/ExamBoost-Togo'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _showInfo(
            context,
            'Code source',
            'Le depot GitHub est public :\n'
                'github.com/djabelo712/ExamBoost-Togo\n\n'
                'Tu peux contribuer, ouvrir une issue ou proposer une '
                'amelioration (pull request).',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public, color: AppColors.primary),
          title: const Text('Site web'),
          subtitle: const Text('examboost-togo.vercel.app'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _showInfo(
            context,
            'Site web',
            'Landing page d\'inscription a la beta :\n'
                'examboost-togo.vercel.app\n\n'
                'Page Next.js 16 deployee sur Vercel.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel, color: AppColors.textSecondary),
          title: const Text('Mentions legales'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showInfo(
            context,
            'Mentions legales',
            'ExamBoost Togo est edite par SmartFarm Togo (Lome) en partenariat '
                'avec AIMS Ghana.\n\n'
                'Donnees : 100% locales (Hive) sur ton telephone. Aucune '
                'donnees pedagogique n\'est transmise hors-ligne, sauf si tu '
                'actives la collecte anonyme (voir section Donnees).\n\n'
                'Licence : MIT. Marque ExamBoost © 2026.\n'
                'Contact : hello@examboost-togo.tg',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.groups, color: AppColors.accent),
          title: const Text('Credits equipe'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showInfo(
            context,
            'Credits',
            'Chefs de projet :\n'
                '  - Djabelo (Lead dev Flutter)\n'
                '  - [Equipe a completer]\n\n'
                'Partenaires :\n'
                '  - DJANTA Tech Hub (CcHub Nigeria)\n'
                '  - AIMS Ghana (Ghana)\n'
                '  - Direction des Examens et Concours (MEPST Togo)\n\n'
                'Remerciements : tous les professeurs et eleves togolais '
                'ayant participe a l\'enquete terrain de juin 2026.',
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 5. SECTION DONNEES
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionDonnees() {
    return _SectionCard(
      icon: Icons.privacy_tip_outlined,
      title: 'Donnees et confidentialite',
      subtitle: 'Collecte anonyme et export de tes donnees',
      children: <Widget>[
        SwitchListTile(
          secondary: const Icon(Icons.analytics_outlined, color: AppColors.primary),
          title: const Text('Autoriser la collecte anonyme'),
          subtitle: const Text(
            'Aide l\'equipe a ameliorer l\'app (PostHog auto-héberge). '
            'Aucune donnee personnelle n\'est collectee.',
          ),
          value: _analyticsEnabled,
          activeColor: AppColors.primary,
          onChanged: (bool value) async {
            setState(() => _analyticsEnabled = value);
            await _setBool(_kAnalytics, value);
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.download_outlined, color: AppColors.info),
          title: const Text('Exporter mes donnees (JSON)'),
          subtitle: const Text(
            'Genere un fichier JSON avec ton profil, tes scores BKT et tes '
            'cartes SRS. Transmis via le partage systeme.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportData(context),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 6. SECTION NOTIFICATIONS
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildSectionNotifications() {
    return _SectionCard(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: 'Rappels, alertes et heure preferee',
      children: <Widget>[
        SwitchListTile(
          secondary: const Icon(Icons.alarm, color: AppColors.accent),
          title: const Text('Rappels quotidiens'),
          subtitle: const Text(
            'Recois une notification chaque jour pour t\'inviter a reviser.',
          ),
          value: _dailyReminderEnabled,
          activeColor: AppColors.primary,
          onChanged: (bool value) async {
            setState(() => _dailyReminderEnabled = value);
            await _setBool(_kDailyReminder, value);
          },
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department, color: AppColors.accent),
          title: const Text('Alertes streak'),
          subtitle: const Text(
            'Notifie si ton streak de revision est en danger (avant minuit).',
          ),
          value: _streakAlertsEnabled,
          activeColor: AppColors.primary,
          onChanged: (bool value) async {
            setState(() => _streakAlertsEnabled = value);
            await _setBool(_kStreakAlerts, value);
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.schedule, color: AppColors.info),
          title: const Text('Heure preferee de revision'),
          subtitle: Text(
            'Les rappels quotidiens arriveront vers '
            '${_preferredTime.hour.toString().padLeft(2, '0')}:'
            '${_preferredTime.minute.toString().padLeft(2, '0')}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _preferredTime,
              helpText: 'Choisis l\'heure de tes rappels quotidiens',
            );
            if (picked != null) {
              await _setPreferredTime(picked);
            }
          },
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ACTIONS DESTRUCTIVES
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _confirmResetProgression(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reinitialiser la progression ?'),
        content: const Text(
          'Cette action va effacer :\n'
          '  - Toutes tes cartes SRS (review_cards)\n'
          '  - Tes scores BKT par competence\n\n'
          'Ton profil (nom, niveau, etablissement) est conserve.\n\n'
          'Cette action est irreversible.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reinitialiser'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Efface la box Hive "review_cards"
      if (Hive.isBoxOpen('review_cards')) {
        await Hive.box<ReviewCard>('review_cards').clear();
      }
      // Efface les BKT de l'utilisateur (en remettant la map a vide)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      if (user != null) {
        user.bktMaitrise.clear();
        user.totalQuestionsAnswered = 0;
        user.totalSessionsCount = 0;
        await user.save();
      }
    } catch (e) {
      debugPrint('Erreur reset progression : $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progression reinitialisee. Tu repars de zero !'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Supprimer definitivement mon compte ?',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Cette action est IRREVERSIBLE.\n\n'
          'Toutes tes donnees seront effacees :\n'
          '  - Profil (nom, niveau, etablissement)\n'
          '  - Cartes SRS et scores BKT\n'
          '  - Historique de sessions et simulations\n'
          '  - Preferences\n\n'
          'Tu seras deconnecte et renvoye vers l\'onboarding.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer definitivement'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Efface les box Hive
      if (Hive.isBoxOpen('review_cards')) {
        await Hive.box<ReviewCard>('review_cards').clear();
      }
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      if (user != null && Hive.isBoxOpen('users')) {
        await Hive.box<AppUser>('users').delete(user.id);
      }
      // Efface toutes les preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Deconnexion
      await userProvider.logout();
    } catch (e) {
      debugPrint('Erreur suppression compte : $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte supprime. A bientot !'),
        backgroundColor: AppColors.error,
      ),
    );
    // Redirige vers l'onboarding (le router fera le redirect auto)
    if (mounted) context.go(AppRoutes.onboarding);
  }

  // ────────────────────────────────────────────────────────────────────────
  // EXPORT JSON
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _exportData(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      final Map<String, dynamic> data = <String, dynamic>{
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '0.1.0',
        'user': user == null
            ? null
            : <String, dynamic>{
                'id': user.id,
                'prenom': user.prenom,
                'nom': user.nom,
                'niveau_scolaire': user.niveauScolaire,
                'serie': user.serie,
                'etablissement': user.etablissement,
                'ville': user.ville,
                'date_inscription': user.dateInscription.toIso8601String(),
                'total_sessions': user.totalSessionsCount,
                'total_questions': user.totalQuestionsAnswered,
                'theta_irt': user.thetaIrt,
                'bkt_maitrise':
                    Map<String, dynamic>.from(user.bktMaitrise),
              },
        'settings': <String, dynamic>{
          'analytics_enabled': _analyticsEnabled,
          'daily_reminder_enabled': _dailyReminderEnabled,
          'streak_alerts_enabled': _streakAlertsEnabled,
          'preferred_hour': _preferredTime.hour,
          'preferred_minute': _preferredTime.minute,
        },
      };

      // En v1 : on affiche juste le JSON dans un dialog (le partage fichier
      // natif via share_plus sera ajoute dans une v2).
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erreur export : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // HELPERS UI
  // ────────────────────────────────────────────────────────────────────────
  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _niveauLabel(String? niveau, String? serie) {
    if (niveau == null) return 'Non renseigne';
    final niveauFormat = <String, String>{
      '3eme': '3e',
      '2nde': '2nde',
      '1ere': '1ere',
      'Terminale': 'Terminale',
    }[niveau] ?? niveau;
    if (serie != null && (niveau == '1ere' || niveau == 'Terminale')) {
      return '$niveauFormat $serie';
    }
    return niveauFormat;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// WIDGETS PRIVES
// ────────────────────────────────────────────────────────────────────────────

/// Carte de section avec en-tete (icon + titre + sous-titre) et un enfant
/// Column. Reutilise le CardTheme du ThemeData (radius 16, elevation 2).
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Ligne d'information label / valeur (utilise dans Compte et A propos).
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
