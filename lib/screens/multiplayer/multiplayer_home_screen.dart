// lib/screens/multiplayer/multiplayer_home_screen.dart
// Écran d'accueil du mode Multijoueur Étude.
//
// Propose 2 actions principales :
//   1. Créer une room (devient hôte, génère un code à partager)
//   2. Rejoindre une room (via code ou room publique)
//
// Affiche aussi :
//   - un en-tête expliquant le principe
//   - une carte "Comment ça marche"
//   - les 2 modes (compétitif / coopératif) décrits
//
// Ce screen est le point d'entrée du module. Il instancie le
// MultiplayerSocketService via Provider et le réutilise dans les
// écrans suivants (create / join / lobby / game / results).
//
// Navigation : les écrans prennent en paramètre le service déjà créé
// (pas de nouvelle instance) pour conserver l'état entre transitions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'services/multiplayer_socket_service.dart';

class MultiplayerHomeScreen extends StatelessWidget {
  const MultiplayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Multijoueur Étude',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Révise à plusieurs en temps réel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bannière d'accueil
              _HeroBanner(),
              const SizedBox(height: 20),
              // Deux actions principales
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle,
                      title: 'Créer',
                      subtitle: 'une room',
                      color: AppColors.primary,
                      onTap: () => _goCreate(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.login,
                      title: 'Rejoindre',
                      subtitle: 'avec un code',
                      color: AppColors.accent,
                      onTap: () => _goJoin(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Section "Comment ça marche"
              _HowItWorksCard(),
              const SizedBox(height: 16),
              // Comparaison des modes
              _ModesComparisonCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _goCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MultiplayerSocketService(),
          child: const CreateRoomScreen(),
        ),
      ),
    );
  }

  void _goJoin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MultiplayerSocketService(),
          child: const JoinRoomScreen(),
        ),
      ),
    );
  }
}

// ─── Bannière d'accueil ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Révise avec tes amis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jusqu\'à 6 élèves en même temps. Questions synchronisées, chat live, podium final.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte d'action (Créer / Rejoindre) ─────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 18),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Comment ça marche ──────────────────────────────────────────────
class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(
        num: '1',
        icon: Icons.vpn_key,
        title: 'Crée ou rejoins une room',
        text: 'Génère un code à 6 chiffres ou entre celui d\'un ami.',
      ),
      _Step(
        num: '2',
        icon: Icons.forum,
        title: 'Discute dans le lobby',
        text: 'Jusqu\'à 6 joueurs, chat avant la partie, marque-toi prêt.',
      ),
      _Step(
        num: '3',
        icon: Icons.timer,
        title: 'Réponds en temps réel',
        text: 'Tous voient la même question. 30s par question. Chat suspendu.',
      ),
      _Step(
        num: '4',
        icon: Icons.emoji_events,
        title: 'Monte sur le podium',
        text: 'Classement final, stats par joueur, rejoue une partie.',
      ),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Comment ça marche',
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.num,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(s.icon,
                                    size: 14,
                                    color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  s.title,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.text,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Comparaison des modes ──────────────────────────────────────────
class _ModesComparisonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Deux modes de jeu',
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeTile(
                    icon: Icons.flag,
                    color: AppColors.primary,
                    title: 'Compétitif',
                    text: 'Chacun pour soi. Classement individuel. Le plus rapide marque plus.',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeTile(
                    icon: Icons.handshake,
                    color: AppColors.accent,
                    title: 'Coopératif',
                    text: 'Équipe. Score cumulé. Questions plus difficiles pour le groupe.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _ModeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String num;
  final IconData icon;
  final String title;
  final String text;

  const _Step({
    required this.num,
    required this.icon,
    required this.title,
    required this.text,
  });
}
