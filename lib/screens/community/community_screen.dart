// lib/screens/community/community_screen.dart
// Module Communauté ExamBoost — 3 onglets :
//   1. Classements (national / régional / établissement)
//   2. Défis hebdomadaires (défi de la semaine + en cours + historique)
//   3. Forum d'entraide entre élèves (liste de threads + FAB)
//
// Architecture : DefaultTabController (longueur 3) + TabBar + TabBarView.
// AppBar avec titre "Communauté ExamBoost" et sous-titre "Élèves de tout le Togo".
// Tous les onglets sont des StatelessWidgets avec données mock locales.
// Pour la v1 : aucune dépendance réseau — les données proviennent des
// méthodes statiques _mockXxx() de chaque onglet.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'leaderboard_tab.dart';
import 'challenges_tab.dart';
import 'forum_tab.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  // Indices des onglets — exposés pour permettre une navigation
  // programmatique (ex: ouvrir directement sur le forum).
  static const int tabIndexLeaderboard = 0;
  static const int tabIndexChallenges = 1;
  static const int tabIndexForum = 2;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: tabIndexLeaderboard,
      child: Scaffold(
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
                'Communauté ExamBoost',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Élèves de tout le Togo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            // 3 onglets conformes au cahier des charges.
            tabs: const [
              Tab(
                icon: Icon(Icons.emoji_events_outlined),
                text: 'Classements',
              ),
              Tab(
                icon: Icon(Icons.local_fire_department_outlined),
                text: 'Défis',
              ),
              Tab(
                icon: Icon(Icons.forum_outlined),
                text: 'Forum',
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: const TabBarView(
          // Swipe entre onglets désactivé : on évite les conflits de geste
          // avec les listes horizontales (chips régions / matières) à
          // l'intérieur des onglets. La navigation se fait via les tabs.
          physics: NeverScrollableScrollPhysics(),
          children: [
            LeaderboardTab(),
            ChallengesTab(),
            ForumTab(),
          ],
        ),
      ),
    );
  }
}
