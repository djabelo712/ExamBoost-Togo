# Module Administration B2B — ExamBoost Togo

Dashboard destiné aux **directeurs et chefs d'établissement** qui souscrivent
à la licence ExamBoost (100 000 FCFA / an). Il offre une vision agrégée de
l'activité des élèves de l'établissement et des outils de pilotage
pédagogique (alertes décrochage, rapports trimestriels, recommandations
automatiques).

> Code 100 % autonome : aucune modification du routeur, de `main.dart` ou de
> l'app élève n'est nécessaire pour compiler les fichiers. L'intégration des
> routes `/admin/login` et `/admin/dashboard` est documentée ci-dessous.

## Fichiers

| Fichier | Rôle |
|---|---|
| `admin_login_screen.dart` | Écran de connexion directeurs (séparé des élèves). |
| `admin_dashboard_screen.dart` | Dashboard principal (header établissement, 4 KPI, TabBar 3 onglets). Contient aussi les modèles `AdminStudent`, `AdminAlert`, `AdminMockData`. |
| `students_tab.dart` | Onglet « Élèves » : tableau dense, recherche, filtre, tri, pagination, dialog détails. |
| `alerts_tab.dart` | Onglet « Alertes » : élèves en décrochage, chute de score, compétence bloquée. |
| `reports_tab.dart` | Onglet « Rapports » : synthèse trimestrielle, bar chart maîtrise par matière, line chart évolution, recommandations. |
| `README.md` | Ce fichier. |

## 3 onglets principaux

1. **Élèves** — tableau paginé (20 lignes / page) avec colonnes : élève
   (avatar + initiales + nom complet), classe, score global, streak,
   dernière activité, statut (vert = actif, orange = modéré, rouge =
   inactif). Tap sur une ligne → dialog détails (compétences fortes /
   faibles, simulations). Recherche texte, filtre par classe, tri par
   score / nom / activité. Bouton « Export CSV » (UI seulement).
2. **Alertes** — liste filtrable des élèves en difficulté selon 3
   catégories : décrochage (rouge), chute de score (orange), compétence
   bloquée (jaune). Chaque carte propose « Contacter » (email/SMS simulé)
   et « Voir profil ». État vide : « Aucune alerte. Tout va bien dans
   votre établissement ! »
3. **Rapports** — sélecteur T1 / T2 / T3, carte résumé (moyenne classe,
   évolution, top 5, élèves en progression), graphique barres de la
   maîtrise par matière, graphique ligne de l'évolution sur 3 mois
   (fl_chart), bouton « Télécharger PDF », section recommandations
   automatiques (3 cartes).

## Intégration des routes dans `lib/utils/app_router.dart`

Le module admin utilise 2 routes distinctes de l'app élève :
`/admin/login` et `/admin/dashboard`. Aucune redirection `UserProvider`
n'est appliquée sur ces routes (l'auth directeur est indépendante de
l'auth élève — voir section « Différences »).

Ajouter dans `AppRoutes` :

```dart
class AppRoutes {
  // ... routes existantes ...
  static const String adminLogin    = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
}
```

Ajouter dans la liste `routes` du `GoRouter` :

```dart
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

// ... dans routes: [
GoRoute(
  path: AppRoutes.adminLogin,
  name: 'adminLogin',
  builder: (context, state) => const AdminLoginScreen(),
),
GoRoute(
  path: AppRoutes.adminDashboard,
  name: 'adminDashboard',
  builder: (context, state) => const AdminDashboardScreen(),
),
// ]
```

> Important : ne pas inclure `/admin/*` dans la logique de redirection
> `UserProvider` (qui force `/onboarding` si l'élève n'est pas authentifié).
> Une solution propre est d'exclure ces chemins dans la fonction `redirect` :

```dart
redirect: (context, state) {
  final loc = state.matchedLocation;
  // L'espace directeur est indépendant de l'auth élève
  if (loc.startsWith('/admin')) return null;
  // ... logique existante ...
}
```

## Brancher sur le vrai backend (FastAPI)

Tout le module est alimenté par des **mocks locaux** dans `AdminMockData`
(`admin_dashboard_screen.dart`). Pour brancher sur le backend :

### Endpoints nécessaires

| Méthode | Endpoint | Rôle |
|---|---|---|
| `POST` | `/auth/admin/login` | Connexion directeur (email + mot de passe, JWT spécifique rôle `director`). |
| `POST` | `/admin/demo-request` | Soumission du formulaire « Demander une démo ». |
| `GET`  | `/admin/dashboard` | KPI agrégés : élèves actifs, temps moyen, maîtrise, évolution. |
| `GET`  | `/admin/students?class=&q=&sort=&page=` | Liste paginée des élèves + scores agrégés. |
| `GET`  | `/admin/students/{id}` | Détail élève (compétences, simulations). |
| `GET`  | `/admin/alerts?type=` | Liste des alertes (décrochage / chute / compétence bloquée). |
| `GET`  | `/admin/reports/{trimestre}` | Synthèse trimestrielle (moyenne, top 5, évolution). |
| `GET`  | `/admin/reports/{trimestre}/mastery` | Maîtrise par matière (bar chart). |
| `GET`  | `/admin/reports/{trimestre}/trend` | Évolution mensuelle (line chart). |
| `GET`  | `/admin/recommendations` | Recommandations automatiques. |
| `GET`  | `/admin/students.csv` | Export CSV de la liste filtrée. |
| `GET`  | `/admin/reports/{trimestre}.pdf` | Rapport PDF trimestriel. |
| `POST` | `/admin/contact-student/{id}` | Déclencher l'email/SMS de relance. |
| `POST` | `/billing/renew` | Renouvellement de la licence (paiement). |

### Service recommandé

Créer `lib/services/admin_api_service.dart` avec un client `Dio` séparé
décoré d'un intercepteur JWT directeur (header `Authorization: Bearer <token>`,
stocké dans `SharedPreferences` sous la clé `admin_token`). Remplacer
ensuite les appels à `AdminMockData.students`, `AdminMockData.alerts` etc.
par des `Future` renvoyant des modèles identiques (les classes
`AdminStudent` et `AdminAlert` peuvent être réutilisées telles quelles —
il suffit d'ajouter des `fromJson`).

## Différences avec l'app élève

| Aspect | App élève | Module admin B2B |
|---|---|---|
| **Utilisateur** | `AppUser` (Hive, typeId 3) | `AdminStudent` (mock, futur : DTO backend) |
| **Auth** | `UserProvider` + Hive `users` | Login dédié, JWT séparé rôle `director` |
| **Routes** | `/`, `/onboarding`, `/revision`, `/simulation`, `/dashboard` | `/admin/login`, `/admin/dashboard` |
| **Données** | Locales (Hive) + synchro backend élève | Agrégations backend directeurs (pas de cache local) |
| **Couleurs** | Accent vert + orange chaleureux | Ton plus blanc, moins de couleurs vives, dominance neutre |
| **Tableau** | Cards individuelles (CircularPercentIndicator, LinearPercentIndicator) | `DataTable` dense + `fl_chart` (bar/line) |
| **Objectif UX** | Motiver l'élève, le fidéliser | Aider le directeur à piloter, alerter |
| **Emplacement** | `lib/screens/<module>/` | `lib/screens/admin/` (sous-module isolé) |

Aucun widget commun n'est importé depuis les écrans élèves : le module
admin est **autosuffisant** et n'a qu'une seule dépendance interne au
projet → `lib/theme/app_theme.dart`.

## Stack utilisée

- Flutter 3.x, Material 3
- `fl_chart` 0.68 — graphiques barres / lignes
- `go_router` — navigation (routes à câbler, voir plus haut)
- Aucune dépendance réseau : tout est mock local pour la démo DJANTA

## Lancer la démo

1. Câbler les routes comme indiqué ci-dessus.
2. Lancer l'app et naviguer vers `/admin/login`.
3. Mode démo : n'importe quel email valide + mot de passe non vide est
   accepté → redirige vers `/admin/dashboard`.
4. Le bouton « Demander une démo » ouvre un formulaire (snackbar de
   confirmation à la soumission).

## Notes

- Les avatars utilisent les initiales (pas d'images réseau) — cohérent
  avec l'app élève.
- Le bouton « Renouveler » et le bouton « Télécharger PDF » sont des UI
  simulées (snackbars) en attendant l'intégration paiement + génération
  PDF serveur.
- Les 30 élèves fictifs ont des noms togolais réalistes (Kossi, Aya,
  Komlan, Adjo, Yao, Akossiwa, etc.) répartis sur 4 classes (3e A, 3e B,
  Terminale C, Terminale D).
- 8 alertes sont générées : 3 décrochages, 3 chutes de score, 2
  compétences bloquées.
