# Module Parent — ExamBoost Togo

Espace dédié aux **parents** pour suivre la progression de leurs enfants
sur ExamBoost Togo. Indépendant de l'app élève (auth séparée), il
regroupe :

- le **suivi de progression** (scores BKT, matières, badges, temps de
  révision, comparaison vs moyenne de classe),
- les **alertes** automatiques (décrochage >7 j, chute de notes >5 pts,
  chapitres faibles, fin d'essai premium, messages enseignant),
- la **communication avec les enseignants** (chat 1-à-1, mocké en v1),
- le **paiement premium** (2000 FCFA/mois par enfant — Flooz / TMoney /
  carte bancaire, UI uniquement en v1).

> Code 100 % autonome : aucune modification du routeur, de `main.dart`,
> de `pubspec.yaml` ou de l'app élève n'est nécessaire pour compiler
> les fichiers. L'intégration des routes `/parent/login` et
> `/parent/dashboard` est documentée ci-dessous (à réaliser par l'agent
> BA — câblage global).

## Fichiers

| Fichier | Rôle |
|---|---|
| `parent_login_screen.dart` | Écran de connexion parent (email + mot de passe + code enfant à 6 chiffres). |
| `parent_dashboard_screen.dart` | Dashboard principal (header parent + 4 KPI globaux + TabBar 5 onglets). |
| `parent_children_tab.dart` | Onglet « Enfants » : cartes résumées, bouton « Lier un enfant ». |
| `parent_progress_tab.dart` | Onglet « Progression » : sélecteur enfant, score global, comparaison classe, matières, badges, temps de révision 7 j (line chart fl_chart). |
| `parent_alerts_tab.dart` | Onglet « Alertes » : décrochage, chute de notes, chapitres faibles, fin premium, messages enseignant. Filtres par type. |
| `parent_messages_tab.dart` | Onglet « Messages » : liste conversations + vue chat (mocké, réponses enseignant simulées). |
| `parent_payment_screen.dart` | Écran de paiement premium (3 plans, Flooz/TMoney/CB, UI only, simulation 90 % de réussite). |
| `widgets/child_card.dart` | Carte résumée d'un enfant (avatar, score, streak, statut). |
| `widgets/progress_summary_card.dart` | Carte résumé de progression (circular % + comparaison classe). |
| `widgets/alert_card.dart` | Carte d'alerte (icône type + titre + description + actions). |
| `widgets/message_bubble.dart` | Bulle de message (envoyé / reçu). |
| `services/parent_service.dart` | Modèles de données + mocks + `ParentService` (méthodes async simulées). |
| `README.md` | Ce fichier. |

## 5 onglets + paiement

1. **Enfants** — cartes résumées (avatar initiales, score global,
   streak, dernière activité, badge écart vs classe). Bouton « Lier un
   enfant » (formulaire code à 6 chiffres — UI only). Tap sur une carte
   → onglet Progression avec l'enfant pré-sélectionné.
2. **Progression** — sélecteur enfant en haut. Score global (circular
   percent), écart vs moyenne classe (+14 pts / -6 pts), temps de
   révision 7 j, total questions répondues. Line chart fl_chart de
   l'activité 7 j (minutes/jour). Liste des matières (barres
   horizontales, maitrise enfant vs classe). Badges récents.
3. **Alertes** — liste filtrable (5 types). Chaque carte = enfant
   concerné + type + titre + description + date. Action « Marquer comme
   lue ». État vide rassurant : « Tout va bien, aucune alerte. »
4. **Messages** — liste des conversations (enseignant + matière + enfant
   + dernier message + badge non lus). Tap → vue chat avec bulles
   différenciées envoyé/reçu, champ de saisie, bouton envoyer. Réponses
   enseignant simulées (mock) en v1.
5. **Paiement** (écran séparé, accessible via bouton « Passer premium »
   du header) — 3 plans (Essentiel 2000/mois, Famille 5000/mois ≤3
   enfants, Trimestre 4800/3 mois). Choix méthode (Flooz / TMoney /
   CB). Champ téléphone (Flooz/TMoney) ou numéro carte (CB). Bouton
   « Payer ». Simulation 90 % de réussite + historique des paiements.

## Intégration des routes dans `lib/utils/app_router.dart`

Le module parent utilise 2 routes distinctes de l'app élève :
`/parent/login` et `/parent/dashboard`. Une 3e route optionnelle
`/parent/payment` est accessible depuis le dashboard.

Ajouter dans `AppRoutes` :

```dart
class AppRoutes {
  // ... routes existantes ...
  static const String parentLogin    = '/parent/login';
  static const String parentDashboard = '/parent/dashboard';
  static const String parentPayment  = '/parent/payment';
}
```

Ajouter dans la liste `routes` du `GoRouter` :

```dart
import '../screens/parent/parent_login_screen.dart';
import '../screens/parent/parent_dashboard_screen.dart';
import '../screens/parent/parent_payment_screen.dart';

// ... dans routes: [
GoRoute(
  path: AppRoutes.parentLogin,
  name: 'parentLogin',
  builder: (context, state) => const ParentLoginScreen(),
),
GoRoute(
  path: AppRoutes.parentDashboard,
  name: 'parentDashboard',
  builder: (context, state) => const ParentDashboardScreen(),
),
GoRoute(
  path: AppRoutes.parentPayment,
  name: 'parentPayment',
  builder: (context, state) => const ParentPaymentScreen(),
),
// ]
```

> Important : ne pas inclure `/parent/*` dans la logique de redirection
> `UserProvider` (qui force `/onboarding` si l'élève n'est pas
> authentifié). L'auth parent est indépendante de l'auth élève — voir
> section « Différences ». Solution propre : exclure ces chemins dans
> la fonction `redirect` :
>
> ```dart
> redirect: (context, state) {
>   final loc = state.matchedLocation;
>   // L'espace parent est indépendant de l'auth élève
>   if (loc.startsWith('/parent')) return null;
>   // ... logique existante ...
> }
> ```

## Brancher sur le vrai backend (FastAPI)

Tout le module est alimenté par des **mocks locaux** dans
`ParentMockData` (`services/parent_service.dart`). Pour brancher sur le
backend, remplacer le corps des méthodes de `ParentService` par des
appels `Dio`. Les modèles (`ParentAccount`, `Child`, `ParentAlert`,
`Conversation`, `PaymentHistory`, `PremiumPlan`) peuvent être réutilisés
tels quels — il suffit d'ajouter des `fromJson` / `toJson`.

### Endpoints nécessaires

| Méthode | Endpoint | Rôle |
|---|---|---|
| `POST` | `/auth/parent/login` | Connexion parent (email + mot de passe + code enfant). Renvoie JWT parent. |
| `POST` | `/parent/children/link` | Lier un nouvel enfant au compte parent (via code enfant 6 chiffres). |
| `GET`  | `/parent/children` | Liste des enfants liés. |
| `GET`  | `/parent/children/{id}` | Détail enfant (progression, badges, activité 7 j). |
| `GET`  | `/parent/alerts` | Liste des alertes. |
| `PATCH`| `/parent/alerts/{id}/read` | Marquer une alerte comme lue. |
| `GET`  | `/parent/conversations` | Liste des conversations parent-enseignant. |
| `POST` | `/parent/conversations/{id}/messages` | Envoyer un message. |
| `POST` | `/payment/initiate` | Initier un paiement (renvoie ref opérateur + URL USSD). |
| `POST` | `/payment/confirm` | Confirmer un paiement (appelé par webhook opérateur). |
| `GET`  | `/parent/payments` | Historique des paiements. |
| `GET`  | `/parent/plans` | Offres premium disponibles. |

### Service recommandé

Créer `lib/services/parent_api_service.dart` avec un client `Dio`
décoré d'un intercepteur JWT parent (header `Authorization: Bearer
<token>`, stocké dans `SharedPreferences` sous la clé `parent_token`).
Remplacer ensuite les appels à `ParentMockData.children`,
`ParentMockData.alerts` etc. par des `Future` renvoyant des modèles
identiques.

### Webhooks opérateurs Flooz / TMoney

Le paiement mobile money au Togo suit ce flux :
1. L'UI appelle `POST /payment/initiate` avec `{ planId, method, telephone }`.
2. Le backend renvoie un `transactionId` + déclenche un push USSD sur le
   téléphone du parent.
3. Le parent valide sur son téléphone (code PIN opérateur).
4. L'opérateur appelle le webhook backend `POST /payment/confirm` avec
   le statut final (`success` / `failed`).
5. Le backend met à jour la `PaymentHistory` et active le premium.

Pour la démo DJANTA (24 juillet 2026), l'UI simule toute la chaîne en
local (90 % de réussite, 10 % d'échec) — pas de backend requis.

## Différences avec l'app élève et le module admin

| Aspect | App élève | Module admin B2B | Module parent |
|---|---|---|---|
| **Utilisateur** | `AppUser` (Hive, typeId 3) | `AdminStudent` (mock) | `Child` (mock) |
| **Auth** | `UserProvider` + Hive | Login dédié, JWT directeur | Login dédié (email + mdp + code enfant), JWT parent |
| **Routes** | `/`, `/revision`, `/dashboard`... | `/admin/login`, `/admin/dashboard` | `/parent/login`, `/parent/dashboard`, `/parent/payment` |
| **Données** | Locales (Hive) + sync backend élève | Agrégations backend directeurs | Agrégations backend parents (lié à l'élève via `childCode`) |
| **Ton UX** | Motivant, coloré, gamifié | sobre, pilotage, densité tabulaire | sobre, rassurant, focus alertes + progression |
| **Couleurs** | Vert + orange chaleureux | Neutre, dominance blanche | Vert dominant (rassurant) + accents sémantiques (rouge alertes, or premium) |
| **Objectif** | Motiver l'élève | Piloter l'établissement | Aider le parent à soutenir l'enfant |
| **Emplacement** | `lib/screens/<module>/` | `lib/screens/admin/` | `lib/screens/parent/` |

## Stack utilisée

- Flutter 3.44+, Material 3
- `go_router` — navigation (routes à câbler, voir plus haut)
- `provider` — state management (StatefulWidget local en v1, le service
  est stateless et peut être wrap dans un `ChangeNotifier` plus tard)
- `fl_chart` 0.68 — line chart activité 7 j, bar chart matières
- `percent_indicator` 4.2 — circular percent (score global)
- `AdaptiveColors` (lib/theme/adaptive_colors.dart) — dark mode
- Aucune dépendance réseau : tout est mock local pour la démo DJANTA

## Lancer la démo

1. Câbler les routes comme indiqué ci-dessus (agent BA).
2. Lancer l'app et naviguer vers `/parent/login`.
3. Mode démo : n'importe quel email valide + mot de passe ≥ 4 caractères
   + code enfant à 6 chiffres → redirige vers `/parent/dashboard`.
4. Le dashboard affiche 2 enfants mockés (Awa Mensah, 3e B — Yao
   Mensah, Terminale D). 5 alertes sont pré-générées (1 décrochage, 2
   chutes, 1 chapitre faible, 1 message enseignant, 1 fin premium).
5. Le bouton « Passer premium » du header ouvre `/parent/payment` :
   choisir un plan, une méthode, valider → 90 % de succès simulé.

## Conventions

- **Commentaires en français** (cohérent avec le reste du projet).
- **Pas d'emojis** dans le code (cohérent avec `app_theme.dart`).
- **Material 3** : `ColorScheme.fromSeed`, `CardThemeData`,
  `ElevatedButtonThemeData` hérités du thème global.
- **AdaptiveColors** : toutes les couleurs qui dépendent du ThemeMode
  passent par `AdaptiveColors.xxx(context)` ou l'extension
  `context.surface`, `context.textPrimary`, etc.
- **Noms togolais réalistes** pour les mocks (Kossi, Awa, Yao, Adjo,
  Agbodjan, Tchalla) — cohérent avec le module admin.
- **Pas d'images réseau** : avatars = initiales dans des
  `CircleAvatar` colorés.

## Notes

- Les notifications push (décrochage, chute de notes) ne sont pas
  implémentées en v1 — l'onglet Alertes suffit pour la démo. À brancher
  plus tard via `flutter_local_notifications` + FCM.
- La vue chat des messages ne persiste pas (mock local). À brancher sur
  WebSocket (le module classroom a déjà un `classroom_socket_service`
  réutilisable).
- L'historique de paiements est en lecture seule (pas de facture PDF en
  v1 — TODO backend `GET /parent/payments/{id}.pdf`).
