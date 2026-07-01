// lib/screens/community/forum_tab.dart
// Onglet "Forum d'entraide" du module Communauté.
//
// Structure :
//   - Liste de threads (questions posées par élèves)
//   - Chaque thread : titre, extrait, auteur, nb réponses, timestamp, tags (matière)
//   - Bouton "Poser une question" (FAB)
//   - Tap sur thread -> vue détaillée (non implémentée en v1, juste snackbar)
//   - Filtres par matière (chips horizontaux en haut)
//
// Données : mock local (10 threads). Pas d'appel réseau.
// Pour la production : remplacer _mockThreads() par un service backend
// (ex: ForumService.fetchThreads()) + pagination.

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// ─── Modèle local ───────────────────────────────────────────────────

class _Thread {
  final String id;
  final String titre;
  final String extrait;
  final String auteur;
  final String niveauAuteur;
  final String villeAuteur;
  final int nbReponses;
  final DateTime timestamp;
  final String matiere;

  const _Thread({
    required this.id,
    required this.titre,
    required this.extrait,
    required this.auteur,
    required this.niveauAuteur,
    required this.villeAuteur,
    required this.nbReponses,
    required this.timestamp,
    required this.matiere,
  });
}

// ─── Matières avec couleur ──────────────────────────────────────────

class _MatiereStyle {
  final String label;
  final Color color;
  const _MatiereStyle(this.label, this.color);
}

const List<_MatiereStyle> kMatieres = [
  _MatiereStyle('Mathématiques', Color(0xFF1565C0)),
  _MatiereStyle('Français', Color(0xFF6A1B9A)),
  _MatiereStyle('Sciences', Color(0xFF2E7D32)),
  _MatiereStyle('SVT', Color(0xFF00838F)),
  _MatiereStyle('H-G', Color(0xFFAD1457)),
  _MatiereStyle('Anglais', Color(0xFFEF6C00)),
];

Color _matiereColor(String matiere) {
  return kMatieres
      .firstWhere(
        (m) => m.label == matiere || matiere.startsWith(m.label),
        orElse: () => _MatiereStyle('Autre', AppColors.textSecondary),
      )
      .color;
}

// ─── Onglet Forum ───────────────────────────────────────────────────

class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  String? _matiereFiltre; // null = toutes les matières
  late List<_Thread> _threads;

  @override
  void initState() {
    super.initState();
    _threads = _mockThreads();
  }

  List<_Thread> get _threadsFiltres {
    if (_matiereFiltre == null) return _threads;
    return _threads.where((t) => t.matiere == _matiereFiltre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _poserQuestion,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit, size: 20),
        label: const Text(
          'Poser une question',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        elevation: 3,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Mock : simule un rechargement.
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) setState(() {});
        },
        child: Column(
          children: [
            _buildFiltres(),
            Expanded(
              child: _threadsFiltres.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: _threadsFiltres.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = _threadsFiltres[i];
                        return _ThreadCard(
                          thread: t,
                          onTap: () => _ouvrirThread(t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filtres par matière ───────────────────────────────────────

  Widget _buildFiltres() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: kMatieres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            // Chip "Toutes"
            final selected = _matiereFiltre == null;
            return ChoiceChip(
              label: const Text('Toutes'),
              selected: selected,
              onSelected: (_) => setState(() => _matiereFiltre = null),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            );
          }
          final m = kMatieres[i - 1];
          final selected = _matiereFiltre == m.label;
          return ChoiceChip(
            label: Text(m.label),
            selected: selected,
            onSelected: (_) =>
                setState(() => _matiereFiltre = selected ? null : m.label),
            selectedColor: m.color,
            labelStyle: TextStyle(
              color: selected ? Colors.white : m.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? m.color : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.forum_outlined, size: 64, color: AppColors.textDisabled),
        const SizedBox(height: 12),
        Text(
          _matiereFiltre == null
              ? 'Aucune question pour le moment.\nSois le premier à demander de l\'aide !'
              : 'Aucune question en ${_matiereFiltre}.\nPose la première !',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────

  void _ouvrirThread(_Thread t) {
    // V1 : on n'ouvre pas encore la vue détaillée — feedback temporaire.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de "${t.titre}"...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _poserQuestion() {
    // V1 : feedback temporaire — sera remplacé par un formulaire (modal).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulaire de question — à venir dans la v2.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Carte d'un thread ──────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final _Thread thread;
  final VoidCallback onTap;

  const _ThreadCard({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final matiereColor = _matiereColor(thread.matiere);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Tag matière + nb réponses ───────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: matiereColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      thread.matiere,
                      style: TextStyle(
                        color: matiereColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chat_bubble_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${thread.nbReponses}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ─── Titre ─────────────────────────────────────────
              Text(
                thread.titre,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ─── Extrait ──────────────────────────────────────
              Text(
                thread.extrait,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ─── Auteur + timestamp ───────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: matiereColor,
                    child: Text(
                      thread.auteur.isNotEmpty
                          ? thread.auteur[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${thread.auteur} · ${thread.niveauAuteur} ${thread.villeAuteur}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(thread.timestamp),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatage relatif : "il y a Xh" / "il y a Xj" / date.
  String _formatTimeAgo(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }
}

// ─── Mock data : 10 threads ─────────────────────────────────────────

List<_Thread> _mockThreads() {
  final now = DateTime.now();
  return [
    _Thread(
      id: 't1',
      titre: 'Comment factoriser x²-9 ?',
      extrait: 'Je vois dans mon cours qu\'on peut factoriser avec une identité '
          'remarquable mais je ne comprends pas pourquoi ça donne (x-3)(x+3)...',
      auteur: 'Aya',
      niveauAuteur: '3e',
      villeAuteur: 'Lomé',
      nbReponses: 5,
      timestamp: now.subtract(const Duration(hours: 2)),
      matiere: 'Mathématiques',
    ),
    _Thread(
      id: 't2',
      titre: 'Différence entre métaphore et comparaison ?',
      extrait: 'Le prof a dit qu\'une métaphore n\'a pas de mot de comparaison '
          'mais je n\'arrive pas à les distinguer dans mes textes...',
      auteur: 'Kossi',
      niveauAuteur: '3e',
      villeAuteur: 'Atakpamé',
      nbReponses: 3,
      timestamp: now.subtract(const Duration(hours: 5)),
      matiere: 'Français',
    ),
    _Thread(
      id: 't3',
      titre: 'Loi d\'Ohm : je ne comprends pas U=RI',
      extrait: 'Comment on peut passer d\'une multiplication à une division '
          'pour calculer R ou I ? Et les unités ?',
      auteur: 'Komlan',
      niveauAuteur: 'Terminale C',
      villeAuteur: 'Kara',
      nbReponses: 8,
      timestamp: now.subtract(const Duration(hours: 8)),
      matiere: 'Sciences',
    ),
    _Thread(
      id: 't4',
      titre: 'Comment mémoriser les organes de la cellule ?',
      extrait: 'Je confonds toujours réticulum endoplasmique et appareil de '
          'Golgi. Des astuces pour s\'en souvenir ?',
      auteur: 'Adjo',
      niveauAuteur: '1ère D',
      villeAuteur: 'Lomé',
      nbReponses: 4,
      timestamp: now.subtract(const Duration(hours: 14)),
      matiere: 'SVT',
    ),
    _Thread(
      id: 't5',
      titre: 'Indépendance du Togo : 27 avril 1960, qui étaient les acteurs ?',
      extrait: 'Je dois préparer un exposé sur les pères de l\'indépendance '
          'togolaise. Quelles sont les sources fiables ?',
      auteur: 'Yao',
      niveauAuteur: 'Terminale A',
      villeAuteur: 'Kpalimé',
      nbReponses: 6,
      timestamp: now.subtract(const Duration(hours: 22)),
      matiere: 'H-G',
    ),
    _Thread(
      id: 't6',
      titre: 'Past simple vs present perfect : quand utiliser lequel ?',
      extrait: 'En classe, mon prof dit que le present perfect c\'est pour '
          'une action qui continue mais je ne comprends pas vraiment...',
      auteur: 'Akossiwa',
      niveauAuteur: '2nde',
      villeAuteur: 'Sokodé',
      nbReponses: 7,
      timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      matiere: 'Anglais',
    ),
    _Thread(
      id: 't7',
      titre: 'Suites arithmétiques : comment trouver la raison r ?',
      extrait: 'J\'ai U1=3 et U5=15. Comment je calcule r ? Et la formule '
          'générale Un=U0+nr c\'est toujours valable ?',
      auteur: 'Komi',
      niveauAuteur: '1ère C',
      villeAuteur: 'Lomé',
      nbReponses: 4,
      timestamp: now.subtract(const Duration(days: 1, hours: 9)),
      matiere: 'Mathématiques',
    ),
    _Thread(
      id: 't8',
      titre: 'Phrases complexes : coordonnées ou subordonnées ?',
      extrait: 'Je n\'arrive pas à identifier si une proposition est '
          'coordonnée par "et" ou subordonnée par "que"...',
      auteur: 'Dédé',
      niveauAuteur: '3e',
      villeAuteur: 'Tsévié',
      nbReponses: 2,
      timestamp: now.subtract(const Duration(days: 2)),
      matiere: 'Français',
    ),
    _Thread(
      id: 't9',
      titre: 'Méiose et mitose : tableau comparatif ?',
      extrait: 'Quelqu\'un peut m\'aider à faire un tableau récapitulatif des '
          'différences entre méiose et mitose (nombre de cellules filles, '
          'chromosomes...) ?',
      auteur: 'Afia',
      niveauAuteur: 'Terminale D',
      villeAuteur: 'Dapaong',
      nbReponses: 5,
      timestamp: now.subtract(const Duration(days: 3)),
      matiere: 'SVT',
    ),
    _Thread(
      id: 't10',
      titre: 'Calculer la vitesse du son dans l\'air à 25°C',
      extrait: 'Je sais que v=331+0,6×T mais le prof veut une démonstration. '
          'Quelqu\'un peut m\'expliquer d\'où vient cette formule ?',
      auteur: 'Bouraïma',
      niveauAuteur: 'Terminale C',
      villeAuteur: 'Kara',
      nbReponses: 3,
      timestamp: now.subtract(const Duration(days: 4)),
      matiere: 'Sciences',
    ),
  ];
}
