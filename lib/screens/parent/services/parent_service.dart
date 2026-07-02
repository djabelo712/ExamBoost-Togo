// lib/screens/parent/services/parent_service.dart
// Logique metier du module Parent ExamBoost Togo.
//
// Rôle : centraliser les modèles de données, les mocks et les futures
//        d'API que les écrans parent consomment. Aucune dépendance réseau
//        réelle pour la v1 (pitch DJANTA 24 juillet 2026) : tout est en
//        mémoire, ce qui permet de tester l'UX sans backend.
//
// Contenu :
//   1. Modèles : ParentAccount, Child, SubjectProgress, BadgeEarned,
//      ParentAlert, TeacherMessage, Conversation, PaymentHistory,
//      PaymentMethod, PremiumPlan.
//   2. Mocks : ParentMockData (3 parents, 5 enfants, alertes, messages,
//      historique de paiements).
//   3. ParentService : méthodes async simulées (login, fetchChildren,
//      fetchProgress, fetchAlerts, fetchConversations, sendMessage,
//      processPayment). Toutes renvoient des Futures avec un délai
//      simulé (300-800 ms) pour coller au comportement réseau réel.
//
// Branchement backend (post-DJANTA) : remplacer le corps des méthodes de
// ParentService par des appels Dio vers le FastAPI. Les signatures
// publiques peuvent rester identiques pour limiter les refactor.

import 'dart:async';

// ══════════════════════════════════════════════════════════════════
// MODÈLES
// ══════════════════════════════════════════════════════════════════

/// Compte parent (séparé de l'élève). Un parent peut avoir 1 à 3 enfants
/// liés via un code enfant à 6 chiffres généré côté backend.
class ParentAccount {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final bool isPremium;
  final DateTime? premiumExpireLe;
  final List<String> childIds;

  const ParentAccount({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.isPremium = false,
    this.premiumExpireLe,
    this.childIds = const [],
  });

  String get nomComplet => '$prenom $nom';

  /// Initiales pour l'avatar (ex: "Kossi Mensah" -> "KM").
  String get initiales {
    final i1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final i2 = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$i1$i2';
  }
}

/// Enfant vu par le parent. Vue agrégée (pas l'entité AppUser qui est
/// utilisée côté élève) : on ne remonte que les champs pertinents pour
/// un suivi parental.
class Child {
  final String id;
  final String prenom;
  final String nom;
  final String classe;          // ex: "3e B", "Terminale D"
  final String etablissement;
  final String codeEnfant;      // code à 6 chiffres (masqué dans l'UI)
  final int scoreGlobal;        // 0-100 (moyenne P(L) BKT)
  final int streakDays;
  final int daysSinceLastActive; // 0 = aujourd'hui
  final int tempsRevisionMinutes7j;
  final int totalQuestionsAnswered;
  final List<SubjectProgress> subjects;
  final List<BadgeEarned> badges;
  final int moyenneClasse;       // moyenne de la classe (comparaison)
  final List<DailyActivity> activity7j;

  const Child({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.etablissement,
    required this.codeEnfant,
    required this.scoreGlobal,
    required this.streakDays,
    required this.daysSinceLastActive,
    required this.tempsRevisionMinutes7j,
    required this.totalQuestionsAnswered,
    required this.subjects,
    required this.badges,
    required this.moyenneClasse,
    required this.activity7j,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final i1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final i2 = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$i1$i2';
  }

  /// Écart entre l'enfant et la moyenne de sa classe (en points).
  /// Positif = enfant au-dessus, négatif = enfant en dessous.
  int get ecartClasse => scoreGlobal - moyenneClasse;
}

/// Progression par matière (BKT agrégé sur les compétences de la matière).
class SubjectProgress {
  final String matiere;   // "Mathématiques", "SVT", "Physique-Chimie"...
  final int maitrise;     // 0-100 (moyenne P(L) des compétences)
  final int maitriseClasse;
  final int questionsRepondues;
  final int tempsMinutes;
  final IconDataRef iconData;

  const SubjectProgress({
    required this.matiere,
    required this.maitrise,
    required this.maitriseClasse,
    required this.questionsRepondues,
    required this.tempsMinutes,
    required this.iconData,
  });
}

/// Indirection d'icône pour éviter un import flutter/material dans le
/// fichier de modèles pur. Les valeurs sont des chaînes résolues côté UI
/// (voir _iconForSubject dans parent_progress_tab.dart).
class IconDataRef {
  final String name;
  const IconDataRef(this.name);

  static const calcul = IconDataRef('calcul');
  static const science = IconDataRef('science');
  static const livre = IconDataRef('livre');
  static const globe = IconDataRef('globe');
  static const histoire = IconDataRef('histoire');
  static const physique = IconDataRef('physique');
}

/// Badge gagné par l'enfant (réutilisation de la sémantique BadgeService
/// côté élève, mais vue allégée pour le parent).
class BadgeEarned {
  final String id;
  final String titre;
  final String description;
  final DateTime gagneLe;
  final BadgeNiveau niveau;

  const BadgeEarned({
    required this.id,
    required this.titre,
    required this.description,
    required this.gagneLe,
    required this.niveau,
  });
}

enum BadgeNiveau { bronze, argent, or, platine }

/// Activité quotidienne d'un enfant (pour le line chart 7 jours).
class DailyActivity {
  final DateTime date;
  final int minutes;
  final int questions;

  const DailyActivity({required this.date, required this.minutes, required this.questions});
}

// ─── Alertes ─────────────────────────────────────────────────────

enum AlertType {
  decrochage,         // >7j sans révision
  chuteNotes,         // chute >5 pts sur 30 jours
  chapitreFaible,     // compétence < 35% persistante
  finPremium,         // abonnement premium arrive à échéance
  messageEnseignant,  // enseignant a envoyé un message
}

/// Alerte remontée au parent. Toujours rattachée à un enfant.
class ParentAlert {
  final String id;
  final AlertType type;
  final String childId;
  final String childName;
  final String titre;
  final String description;
  final DateTime date;
  final bool lue;

  const ParentAlert({
    required this.id,
    required this.type,
    required this.childId,
    required this.childName,
    required this.titre,
    required this.description,
    required this.date,
    this.lue = false,
  });
}

// ─── Messages ────────────────────────────────────────────────────

/// Message individuel dans une conversation parent-enseignant.
class TeacherMessage {
  final String id;
  final String contenu;
  final DateTime envoyeLe;
  final bool fromParent; // true = envoyé par le parent, false = reçu

  const TeacherMessage({
    required this.id,
    required this.contenu,
    required this.envoyeLe,
    required this.fromParent,
  });
}

/// Conversation entre un parent et l'enseignant principal d'un enfant.
class Conversation {
  final String id;
  final String childId;
  final String childName;
  final String enseignantNom;
  final String enseignantMatiere;
  final List<TeacherMessage> messages;
  final int nonLus;

  const Conversation({
    required this.id,
    required this.childId,
    required this.childName,
    required this.enseignantNom,
    required this.enseignantMatiere,
    required this.messages,
    this.nonLus = 0,
  });

  TeacherMessage? get dernier =>
      messages.isEmpty ? null : messages.last;
}

// ─── Paiement ────────────────────────────────────────────────────

enum PaymentMethod { flooz, tmoney, carteBancaire }

enum PaymentStatus { reussi, enAttente, echoue, annule }

class PaymentHistory {
  final String id;
  final int montantFcfa;
  final DateTime date;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference; // ID transaction opérateur

  const PaymentHistory({
    required this.id,
    required this.montantFcfa,
    required this.date,
    required this.method,
    required this.status,
    this.reference,
  });
}

/// Offre premium parent (2000 FCFA/mois par enfant, ou 5000/mois pour
/// jusqu'à 3 enfants — formule famille).
class PremiumPlan {
  final String id;
  final String titre;
  final String description;
  final int montantFcfa;
  final int dureeMois;
  final int maxEnfants;
  final bool isPopulaire;

  const PremiumPlan({
    required this.id,
    required this.titre,
    required this.description,
    required this.montantFcfa,
    required this.dureeMois,
    required this.maxEnfants,
    this.isPopulaire = false,
  });

  /// Montant mensuel équivalent (pour comparaison UI).
  int get montantParMois => (montantFcfa / dureeMois).round();
}

// ══════════════════════════════════════════════════════════════════
// MOCK DATA
// ══════════════════════════════════════════════════════════════════

/// Données fictives du module parent. Noms togolais réalistes pour
/// coller au contexte BEPC/BAC Togo.
class ParentMockData {
  ParentMockData._();

  // ── Compte parent par défaut (mode démo) ──────────────────────
  static final ParentAccount defaultParent = ParentAccount(
    id: 'parent_demo_001',
    nom: 'Mensah',
    prenom: 'Kossi',
    email: 'kossi.mensah@example.tg',
    telephone: '+228 90 12 34 56',
    isPremium: false,
    premiumExpireLe: null,
    childIds: const ['child_001', 'child_002'],
  );

  // ── 2 enfants liés (cas typique : fratrie BEPC + Terminale) ──
  static final Child child1 = Child(
    id: 'child_001',
    prenom: 'Awa',
    nom: 'Mensah',
    classe: '3e B',
    etablissement: 'Collège d\'Enseignement Général de Tokoin',
    codeEnfant: '384726',
    scoreGlobal: 72,
    streakDays: 5,
    daysSinceLastActive: 0,
    tempsRevisionMinutes7j: 245,
    totalQuestionsAnswered: 318,
    moyenneClasse: 58,
    subjects: const [
      SubjectProgress(
        matiere: 'Mathématiques',
        maitrise: 68,
        maitriseClasse: 55,
        questionsRepondues: 94,
        tempsMinutes: 88,
        iconData: IconDataRef.calcul,
      ),
      SubjectProgress(
        matiere: 'Physique-Chimie',
        maitrise: 74,
        maitriseClasse: 60,
        questionsRepondues: 72,
        tempsMinutes: 65,
        iconData: IconDataRef.physique,
      ),
      SubjectProgress(
        matiere: 'SVT',
        maitrise: 81,
        maitriseClasse: 62,
        questionsRepondues: 58,
        tempsMinutes: 42,
        iconData: IconDataRef.science,
      ),
      SubjectProgress(
        matiere: 'Français',
        maitrise: 65,
        maitriseClasse: 61,
        questionsRepondues: 64,
        tempsMinutes: 38,
        iconData: IconDataRef.livre,
      ),
      SubjectProgress(
        matiere: 'Histoire-Géographie',
        maitrise: 70,
        maitriseClasse: 54,
        questionsRepondues: 30,
        tempsMinutes: 12,
        iconData: IconDataRef.histoire,
      ),
    ],
    badges: [
      BadgeEarned(
        id: 'b1',
        titre: 'Assidu·e',
        description: '7 jours de révision consécutifs',
        gagneLe: DateTime.parse('2026-06-20'),
        niveau: BadgeNiveau.argent,
      ),
      BadgeEarned(
        id: 'b2',
        titre: 'Maître des fractions',
        description: '90% de réussite sur les fractions',
        gagneLe: DateTime.parse('2026-06-15'),
        niveau: BadgeNiveau.bronze,
      ),
      BadgeEarned(
        id: 'b3',
        titre: 'Marathonien·ne',
        description: 'Plus de 300 questions répondues',
        gagneLe: DateTime.parse('2026-06-28'),
        niveau: BadgeNiveau.or,
      ),
    ],
    activity7j: _buildActivity([35, 0, 42, 28, 55, 50, 35]),
  );

  static final Child child2 = Child(
    id: 'child_002',
    prenom: 'Yao',
    nom: 'Mensah',
    classe: 'Terminale D',
    etablissement: 'Lycée de Tokoin',
    codeEnfant: '519084',
    scoreGlobal: 54,
    streakDays: 1,
    daysSinceLastActive: 9, // décrochage !
    tempsRevisionMinutes7j: 48,
    totalQuestionsAnswered: 142,
    moyenneClasse: 60,
    subjects: const [
      SubjectProgress(
        matiere: 'Mathématiques',
        maitrise: 48,
        maitriseClasse: 62,
        questionsRepondues: 40,
        tempsMinutes: 22,
        iconData: IconDataRef.calcul,
      ),
      SubjectProgress(
        matiere: 'Physique-Chimie',
        maitrise: 52,
        maitriseClasse: 58,
        questionsRepondues: 38,
        tempsMinutes: 18,
        iconData: IconDataRef.physique,
      ),
      SubjectProgress(
        matiere: 'SVT',
        maitrise: 62,
        maitriseClasse: 64,
        questionsRepondues: 34,
        tempsMinutes: 8,
        iconData: IconDataRef.science,
      ),
      SubjectProgress(
        matiere: 'Philosophie',
        maitrise: 58,
        maitriseClasse: 55,
        questionsRepondues: 18,
        tempsMinutes: 0,
        iconData: IconDataRef.livre,
      ),
      SubjectProgress(
        matiere: 'Histoire-Géographie',
        maitrise: 50,
        maitriseClasse: 59,
        questionsRepondues: 12,
        tempsMinutes: 0,
        iconData: IconDataRef.histoire,
      ),
    ],
    badges: [
      BadgeEarned(
        id: 'b4',
        titre: 'Premier pas',
        description: 'Première session de révision terminée',
        gagneLe: DateTime.parse('2026-06-10'),
        niveau: BadgeNiveau.bronze,
      ),
    ],
    activity7j: _buildActivity([15, 0, 0, 12, 0, 0, 21]),
  );

  // 3e enfant optionnel (formule famille) — désactivé par défaut
  static final Child child3 = Child(
    id: 'child_003',
    prenom: 'Adjo',
    nom: 'Mensah',
    classe: '2nde A',
    etablissement: 'Lycée de Bè',
    codeEnfant: '726153',
    scoreGlobal: 80,
    streakDays: 12,
    daysSinceLastActive: 0,
    tempsRevisionMinutes7j: 312,
    totalQuestionsAnswered: 421,
    moyenneClasse: 65,
    subjects: const [
      SubjectProgress(
        matiere: 'Mathématiques',
        maitrise: 82,
        maitriseClasse: 60,
        questionsRepondues: 120,
        tempsMinutes: 110,
        iconData: IconDataRef.calcul,
      ),
      SubjectProgress(
        matiere: 'Physique-Chimie',
        maitrise: 78,
        maitriseClasse: 58,
        questionsRepondues: 95,
        tempsMinutes: 88,
        iconData: IconDataRef.physique,
      ),
      SubjectProgress(
        matiere: 'SVT',
        maitrise: 85,
        maitriseClasse: 66,
        questionsRepondues: 88,
        tempsMinutes: 64,
        iconData: IconDataRef.science,
      ),
      SubjectProgress(
        matiere: 'Anglais',
        maitrise: 76,
        maitriseClasse: 70,
        questionsRepondues: 70,
        tempsMinutes: 32,
        iconData: IconDataRef.globe,
      ),
      SubjectProgress(
        matiere: 'Français',
        maitrise: 79,
        maitriseClasse: 68,
        questionsRepondues: 48,
        tempsMinutes: 18,
        iconData: IconDataRef.livre,
      ),
    ],
    badges: [
      BadgeEarned(
        id: 'b5',
        titre: 'Surpuissant·e',
        description: 'Streak de 10 jours',
        gagneLe: DateTime.parse('2026-06-29'),
        niveau: BadgeNiveau.or,
      ),
      BadgeEarned(
        id: 'b6',
        titre: 'Champion·ne SVT',
        description: 'Top 5 national en SVT',
        gagneLe: DateTime.parse('2026-06-25'),
        niveau: BadgeNiveau.platine,
      ),
    ],
    activity7j: _buildActivity([55, 42, 60, 38, 50, 45, 22]),
  );

  static List<Child> get children => [child1, child2];

  // ── Alertes (générées à partir des enfants) ──────────────────
  static final List<ParentAlert> alerts = [
    ParentAlert(
      id: 'a1',
      type: AlertType.decrochage,
      childId: 'child_002',
      childName: 'Yao Mensah',
      titre: 'Décrochage détecté',
      description: 'Yao n\'a pas révisé depuis 9 jours. Un contact '
          'bienveillant peut relancer sa motivation avant le BAC.',
      date: DateTime(2026, 7, 1, 8, 30),
    ),
    ParentAlert(
      id: 'a2',
      type: AlertType.chuteNotes,
      childId: 'child_002',
      childName: 'Yao Mensah',
      titre: 'Chute de 12 points en Mathématiques',
      description: 'Le score de Yao en Mathématiques est passé de '
          '60% à 48% sur les 30 derniers jours. La trigonométrie '
          'et les suites sont à revoir en priorité.',
      date: DateTime(2026, 6, 30, 17, 0),
    ),
    ParentAlert(
      id: 'a3',
      type: AlertType.chapitreFaible,
      childId: 'child_001',
      childName: 'Awa Mensah',
      titre: 'Chapitre faible : Théorème de Thalès',
      description: 'Awa maîtrise le chapitre Thalès à 28% '
          '(moyenne classe 52%). 3 sessions de révision ciblée '
          'recommandées cette semaine.',
      date: DateTime(2026, 6, 29, 10, 15),
    ),
    ParentAlert(
      id: 'a4',
      type: AlertType.messageEnseignant,
      childId: 'child_001',
      childName: 'Awa Mensah',
      titre: 'Nouveau message de M. Agbodjan',
      description: 'L\'enseignant de Mathématiques vous a envoyé '
          'un message concernant la progression d\'Awa.',
      date: DateTime(2026, 6, 28, 14, 45),
    ),
    ParentAlert(
      id: 'a5',
      type: AlertType.finPremium,
      childId: 'child_002',
      childName: 'Yao Mensah',
      titre: 'Essai premium bientôt terminé',
      description: 'L\'essai premium de Yao se termine dans 3 jours. '
          'Passez à l\'abonnement (2000 FCFA/mois) pour conserver '
          'l\'accès aux examens blancs et au tuteur IA.',
      date: DateTime(2026, 6, 27, 9, 0),
    ),
  ];

  // ── Conversations avec enseignants ───────────────────────────
  static final List<Conversation> conversations = [
    Conversation(
      id: 'c1',
      childId: 'child_001',
      childName: 'Awa Mensah',
      enseignantNom: 'M. Koffi Agbodjan',
      enseignantMatiere: 'Mathématiques',
      nonLus: 1,
      messages: [
        TeacherMessage(
          id: 'm1',
          contenu: 'Bonjour Monsieur, comment se comporte Awa en classe '
              'ces dernières semaines ?',
          envoyeLe: DateTime(2026, 6, 25, 16, 20),
          fromParent: true,
        ),
        TeacherMessage(
          id: 'm2',
          contenu: 'Bonjour Mr Mensah. Awa est très attentive et participe '
              'activement. Elle a cependant quelques difficultés sur le '
              'théorème de Thalès que nous reverrons la semaine prochaine.',
          envoyeLe: DateTime(2026, 6, 26, 8, 15),
          fromParent: false,
        ),
        TeacherMessage(
          id: 'm3',
          contenu: 'Parfait, je vais lui faire réviser Thalès sur ExamBoost '
              'ce week-end. Merci pour votre retour.',
          envoyeLe: DateTime(2026, 6, 26, 12, 40),
          fromParent: true,
        ),
        TeacherMessage(
          id: 'm4',
          contenu: 'Excellent Mr Mensah. Je reste à votre disposition si '
              'vous souhaitez un entretien. Awa a vraiment un bon potentiel '
              'pour le BEPC.',
          envoyeLe: DateTime(2026, 6, 28, 14, 45),
          fromParent: false,
        ),
      ],
    ),
    Conversation(
      id: 'c2',
      childId: 'child_002',
      childName: 'Yao Mensah',
      enseignantNom: 'Mme Afi Tchalla',
      enseignantMatiere: 'Physique-Chimie',
      nonLus: 0,
      messages: [
        TeacherMessage(
          id: 'm5',
          contenu: 'Bonjour Madame, Yao semble découragé ces temps-ci. '
              'Avez-vous remarqué quelque chose en classe ?',
          envoyeLe: DateTime(2026, 6, 20, 18, 0),
          fromParent: true,
        ),
        TeacherMessage(
          id: 'm6',
          contenu: 'Bonjour. Effectivement, Yao a été plus discret en classe '
              'depuis 2 semaines. Je lui ai proposé un soutien individualisé '
              'mais il n\'a pas donné suite. Je vous appelle dès que possible.',
          envoyeLe: DateTime(2026, 6, 21, 10, 30),
          fromParent: false,
        ),
      ],
    ),
  ];

  // ── Historique de paiements ──────────────────────────────────
  static final List<PaymentHistory> payments = [
    PaymentHistory(
      id: 'p1',
      montantFcfa: 2000,
      date: DateTime(2026, 6, 1, 9, 32),
      method: PaymentMethod.flooz,
      status: PaymentStatus.reussi,
      reference: 'FLZ-260601-9321',
    ),
    PaymentHistory(
      id: 'p2',
      montantFcfa: 2000,
      date: DateTime(2026, 5, 1, 8, 14),
      method: PaymentMethod.flooz,
      status: PaymentStatus.reussi,
      reference: 'FLZ-260501-8842',
    ),
    PaymentHistory(
      id: 'p3',
      montantFcfa: 2000,
      date: DateTime(2026, 4, 1, 19, 5),
      method: PaymentMethod.tmoney,
      status: PaymentStatus.reussi,
      reference: 'TM-260401-2245',
    ),
  ];

  // ── Offres premium ───────────────────────────────────────────
  static final List<PremiumPlan> plans = [
    PremiumPlan(
      id: 'plan_mensuel',
      titre: 'Essentiel',
      description: '1 enfant · accès complet · sans engagement',
      montantFcfa: 2000,
      dureeMois: 1,
      maxEnfants: 1,
    ),
    PremiumPlan(
      id: 'plan_famille',
      titre: 'Famille',
      description: 'Jusqu\'à 3 enfants · 15% d\'économie',
      montantFcfa: 5000,
      dureeMois: 1,
      maxEnfants: 3,
      isPopulaire: true,
    ),
    PremiumPlan(
      id: 'plan_trimestre',
      titre: 'Trimestre',
      description: '1 enfant · 3 mois · 20% d\'économie',
      montantFcfa: 4800,
      dureeMois: 3,
      maxEnfants: 1,
    ),
  ];

  // ── Helpers de construction ──────────────────────────────────
  /// Construit une liste de 7 DailyActivity à partir des minutes par jour.
  /// Les dates sont calculées à partir d'aujourd'hui en remontant 6 jours.
  static List<DailyActivity> _buildActivity(List<int> minutes) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      // 1 question toutes les ~2.5 min en moyenne
      final questions = (minutes[i] / 2.5).round();
      return DailyActivity(date: date, minutes: minutes[i], questions: questions);
    });
  }
}



// ══════════════════════════════════════════════════════════════════
// SERVICE
// ══════════════════════════════════════════════════════════════════

/// Service parent : expose des méthodes async qui simulent les appels
/// backend. Toutes renvoient des `Future` avec un délai de 300-800 ms
/// pour reproduire le comportement réseau réel (squelette de chargement,
/// gestion d'erreur, etc.).
///
/// Branchez ces méthodes sur le FastAPI en remplaçant le corps par un
/// `dio.get/post`. Les signatures peuvent rester identiques.
class ParentService {
  ParentService._();

  /// Login parent.
  /// [email] : email du compte parent.
  /// [password] : mot de passe (non chiffré en mode démo — à hasher côté
  ///              backend avec bcrypt ou argon2).
  /// [childCode] : code enfant à 6 chiffres fourni par l'établissement
  ///               ou par l'élève lui-même dans son app.
  ///
  /// Mode démo : accepte n'importe quel email valide + mot de passe non
  /// vide + code à 6 chiffres. Renvoie le compte parent par défaut.
  static Future<ParentAccount> login({
    required String email,
    required String password,
    required String childCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // Validations basiques (côté UI aussi, mais on double-check ici).
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      throw ParentAuthException('Format d\'email invalide.');
    }
    if (password.length < 4) {
      throw ParentAuthException('Mot de passe trop court.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(childCode)) {
      throw ParentAuthException('Le code enfant doit comporter 6 chiffres.');
    }

    return ParentMockData.defaultParent;
  }

  /// Récupère la liste des enfants liés au compte parent.
  static Future<List<Child>> fetchChildren(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ParentMockData.children;
  }

  /// Récupère le détail d'un enfant précis (progression, badges, activité).
  static Future<Child> fetchChildDetail(String childId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final all = [
      ParentMockData.child1,
      ParentMockData.child2,
      ParentMockData.child3,
    ];
    return all.firstWhere(
      (c) => c.id == childId,
      orElse: () => ParentMockData.child1,
    );
  }

  /// Récupère les alertes non lues + lues récentes du parent.
  static Future<List<ParentAlert>> fetchAlerts(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return ParentMockData.alerts;
  }

  /// Marque une alerte comme lue.
  static Future<void> markAlertRead(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // En mode démo : no-op (l'UI met à jour son état local).
  }

  /// Récupère les conversations parent-enseignant.
  static Future<List<Conversation>> fetchConversations(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ParentMockData.conversations;
  }

  /// Envoie un message dans une conversation. Renvoie le message créé.
  static Future<TeacherMessage> sendMessage({
    required String conversationId,
    required String contenu,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return TeacherMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      contenu: contenu,
      envoyeLe: DateTime.now(),
      fromParent: true,
    );
  }

  /// Récupère l'historique des paiements.
  static Future<List<PaymentHistory>> fetchPayments(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ParentMockData.payments;
  }

  /// Traite un paiement premium. Simule un appel Flooz/TMoney.
  ///
  /// En production :
  ///   1. POST /payment/initiate { planId, method } -> renvoie un
  ///      identifiant de transaction opérateur + URL USSD.
  ///   2. L'utilisateur valide sur son téléphone (USSD push).
  ///   3. Webhook backend confirme -> statut reussi.
  ///
  /// Ici on simule : 90% de réussite, 10% d'échec aléatoire pour
  /// démontrer la gestion d'erreur dans l'UI.
  static Future<PaymentHistory> processPayment({
    required String planId,
    required PaymentMethod method,
    required String telephone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final plan = ParentMockData.plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => ParentMockData.plans.first,
    );

    // 10% d'échec simulé
    final rnd = DateTime.now().microsecondsSinceEpoch % 10;
    final status = rnd == 0
        ? PaymentStatus.echoue
        : PaymentStatus.reussi;

    if (status == PaymentStatus.echoue) {
      throw PaymentException(
        'Le paiement a échoué côté opérateur. Vérifiez votre solde '
        'et réessayez. Aucun montant n\'a été débité.',
      );
    }

    final ref = method == PaymentMethod.flooz
        ? 'FLZ-${DateTime.now().millisecondsSinceEpoch}'
        : method == PaymentMethod.tmoney
            ? 'TM-${DateTime.now().millisecondsSinceEpoch}'
            : 'CB-${DateTime.now().millisecondsSinceEpoch}';

    return PaymentHistory(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      montantFcfa: plan.montantFcfa,
      date: DateTime.now(),
      method: method,
      status: status,
      reference: ref,
    );
  }

  /// Active le premium après un paiement réussi (mise à jour du compte).
  static Future<ParentAccount> activatePremium({
    required String parentId,
    required PremiumPlan plan,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final base = ParentMockData.defaultParent;
    return ParentAccount(
      id: base.id,
      nom: base.nom,
      prenom: base.prenom,
      email: base.email,
      telephone: base.telephone,
      isPremium: true,
      premiumExpireLe: DateTime.now().add(Duration(days: 30 * plan.dureeMois)),
      childIds: base.childIds,
    );
  }
}

// ─── Exceptions ──────────────────────────────────────────────────

class ParentAuthException implements Exception {
  final String message;
  ParentAuthException(this.message);
  @override
  String toString() => message;
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  @override
  String toString() => message;
}
