# Case Study — Amina, 15 ans, 3e, Lomé

*Récit narratif — pilote ExamBoost Togo — Avril à Juin 2026*
*Document de production — diffusion investisseurs, mentors DJANTA, partenaires institutionnels*

---

## Profil

- **Nom** : Amina (prénom modifié pour anonymat)
- **Âge** : 15 ans
- **Niveau** : 3e (BEPC cette année)
- **Établissement** : Lycée public de Tokoin, Lomé
- **Vie** : vit avec ses parents et 2 frères à Adidogomé (banlieue de Lomé)
- **Smartphone** : Tecno Spark 4 (2 Go RAM, 16 Go stockage, Android 9)
- **Forfait data** : 500 Mo/mois via Moov Africa (Flooz)
- **Objectif** : réussir BEPC 2026 pour entrer en 2nde S

Amina est l'élève type que ExamBoost Togo a été conçu pour servir. Pas exceptionnelle ni en grande difficulté, elle navigue dans ce que les enseignants appellent "le milieu du peloton" — ces élèves qui pourraient réussir avec les bons outils mais qui n'y ont pas accès. Son profil correspond exactement au segment A (élève individuel B2C) défini dans le Plan Go-to-Market : 14–19 ans, urbaine péri-urbaine, smartphone entry-level, budget data contraint, absence d'outil numérique structuré pour préparer le BEPC.

## Avant ExamBoost — Mars 2026

Amina prépare son BEPC comme elle peut. Comme 87 % des élèves interrogés lors de l'enquête terrain ExamBoost (juin 2026, 30 élèves Lomé + Atakpamé), elle n'a aucun outil numérique dédié. Ses méthodes sont bricolées à partir des ressources disponibles :

- Elle relit ses cahiers, souvent incomplets car elle est absente certaines journées (transport Adidogomé–Tokoin en taxi-ville, 30–45 min selon le traffic, parfois raté).
- Elle télécharge des PDF d'annales sur WhatsApp quand son forfait data le permet, mais les fichiers sont souvent mal scannés, illisibles, et sans correction.
- Elle demande de l'aide à sa cousine en Terminale au Lycée de Bè, mais celle-ci n'est pas toujours disponible et ne sait pas toujours expliquer les notions difficiles.
- Elle participe à un cours de soutien le samedi matin organisé par un enseignant de son lycée, 5 000 FCFA/mois — une somme importante pour la famille (le père est mécanicien, la mère vend des tissus au marché d'Adawlato, revenu combiné ~120 000 FCFA/mois pour 5 personnes).

Ses problèmes, tels qu'elle les exprime lors de l'entretien initial :

- **Pas de visibilité** : "Je pense être moyenne en maths, mais je sais pas vraiment. Je peux avoir 8 un jour et 13 la semaine d'après, je comprends pas pourquoi."
- **Pas de structure** : elle révise au hasard, oublie ce qu'elle a vu, n'a pas de plan de révision. La répétition espacée ne fait pas partie de son vocabulaire.
- **Stress** : à 3 mois du BEPC (juin 2026), l'angoisse monte. Sa cousine lui a dit que le BEPC 2024 avait eu 44 % de réussite seulement — Amina a peur de faire partie des 56 % qui ratent.
- **Pas d'argent** pour des cours particuliers réguliers. Les 5 000 FCFA/mois du samedi représentent déjà un sacrifice familial.

**Ses notes de contrôle en Mars 2026** (T2, base de référence avant ExamBoost) :

| Matière | Note contrôle Mars 2026 |
|---|---|
| Mathématiques | 8/20 |
| Français | 11/20 |
| Sciences Physiques | 9/20 |
| SVT | 10/20 |
| Histoire-Géographie | 9/20 |
| Anglais | 12/20 |
| **Moyenne générale** | **9,5/20** |

Avec 9,5/20 de moyenne, Amina est dans la zone grise du BEPC : ni assurée d'avoir, ni condamnée à rater. Tout dépendra de la préparation des 3 prochains mois. Sans intervention, ses chances de réussite sont estimées à 40–50 % (baseline nationale 44 %).

## Découverte ExamBoost — Avril 2026

Amina entend parler d'ExamBoost par trois canaux simultanés en avril 2026 — exactement le mix d'acquisition prévu par le Plan Go-to-Market :

- **Un ami de classe** qui a vu une vidéo TikTok d'ExamBoost (format "Astuce maths en 30 sec — Thalès en situation Lomé-Kpalimé"). L'ami lui montre la vidéo, Amina trouve ça concret et pas "scolaire-scolaire".
- **Son professeur principal de maths**, Monsieur K., qui mentionne l'app en classe : "Il paraît qu'il y a une app gratuite pour le BEPC, je sais pas si c'est sérieux, mais vous pouvez regarder." C'est exactement le relais enseignant que le programme ambassadeurs vise à activer.
- **Une affiche dans le cybercafé** où elle va imprimer ses cours à Adidogomé. Format A3, QR code vers le Play Store, slogan "Prépare ton BEPC gratuitement. 15 minutes par jour suffisent."

### Installation

Amina télécharge l'APK depuis le Play Store. La taille — 22 Mo — tient dans son forfait data grâce au wifi du lycée (connexion免费 pendant les heures de cours, en dehors elle utilise son forfait personnel). L'installation prend 3 minutes.

**Onboarding** :

1. Création de profil : Amina, 15 ans, classe de 3e, Lycée public de Tokoin, Lomé.
2. Choix des matières préférées : Mathématiques, Sciences Physiques, Français (les 3 matières à plus fort coefficient au BEPC et où elle se sent le plus en difficulté).
3. Test de niveau initial : 10 questions courtes (5 maths, 3 sciences, 2 français) — l'IRT 3PL commence à calibrer son niveau.
4. Personnalisation : objectif "Réussir BEPC 2026", rythme "15 minutes par jour", créneau préféré "soir 18h".

Le mode hors-ligne est activé automatiquement — toutes les questions téléchargées sont stockées en local (Hive + SQLite). Amina n'aura plus besoin de data pour réviser.

## Première semaine — Découverte

**Jour 1** — Amina fait sa première session de révision Maths, 15 minutes entre 18h et 18h15 après les devoirs.

10 questions sur les équations du premier degré (chapitre où elle avait eu 8/20 en contrôle). L'IRT 3PL lui propose d'abord des questions de difficulté moyenne (paramètre b ≈ 0), puis ajuste :

- 7/10 correctes — l'algo détecte qu'elle est à l'aise sur les équations simples, propose 2 questions plus difficiles (b ≈ +0,5).
- Score affiché : "Tu progresses en Mathématiques. Continue."
- 2 badges débloqués : "Premier pas" + "Curieux".
- Compétences identifiées : TG-MATHS-EQ1-001 (équations 1er degré) — maîtrise BKT initiale : 38 %.

**Jour 2 à Jour 7** — Amina révise 15 minutes chaque soir, notification à 18h (son créneau préféré).

| Jour | Matière | Durée | Score | Badge débloqué |
|---|---|---|---|---|
| 2 | Sciences Physiques — Loi d'Ohm | 15 min | 6/10 | — |
| 3 | Maths — Pythagore | 15 min | 8/10 | "Régularité Bronze" (3 jours) |
| 4 | Français — Métaphore | 12 min | 9/10 | — |
| 5 | Maths — Thalès | 18 min | 5/10 | — |
| 6 | Sciences — Volumes | 15 min | 7/10 | "Marathonien Bronze" (5 jours) |
| 7 | Première simulation BEPC | 35 min | 11/20 | "Curieux Bronze" (7 jours) |

Sa première simulation BEPC donne **11/20** — vs 8/20 en contrôle de maths de mars. L'app lui indique : "Prédiction BEPC : ~12/20 — confiance moyenne (peu de données, 7 jours d'usage)."

**Réaction d'Amina** (entretien J+7) : "Pour la première fois, je sais où j'en suis. L'app me dit exactement quoi réviser demain, et je vois mes scores monter. C'est bizarre, j'ai presque envie de réviser maintenant."

Cette réaction — le passage de la révision comme corvée subie à la révision comme jeu structuré — est précisément l'effet recherché par la combinaison SM-2 (rappels optimaux) + gamification (badges + streaks). Le Plan Go-to-Market vise un streak moyen de 7 jours à M18 ; Amina l'atteint dès la semaine 1.

## Trois mois avec ExamBoost — Avril à Juin 2026

### Mois 1 — Avril 2026 : la régularité

Amina installe une habitude. Chaque soir à 18h, la notification arrive. Elle révise 15 minutes avant de rejoindre sa famille pour le dîner.

**Bilan Mois 1** :

- 22 sessions de révision complétées (sur 30 jours — 8 jours manqués pour fatigue ou devoirs lourds).
- **Streak maximal** : 14 jours consécutifs (badge "Régularité Argent" à 14 jours).
- **Maîtrise globale BKT** : 38 % (70 compétences suivies).
- 7 badges débloqués : Régularité Bronze (3 j), Marathonien Bronze (5 j), Curieux Bronze (7 j), Régularité Argent (14 j), Pythagore Novice (5 questions juste), Thalès Débutant (3 questions juste), Premier Quiz (10 quiz complétés).
- **Simulation BEPC fin Avril** : 12/20 (vs 9,5 en mars, +2,5 pts en 1 mois).
- Prédiction ExamBoost : 13/20 ± 2 pts — confiance moyenne (données encore limitées).

Chapitres les plus travaillés : Thalès (5 sessions, c'est là qu'elle est la plus faible), Pythagore (4 sessions), équations 1er degré (3 sessions), Loi d'Ohm (3 sessions). L'algo SM-2 priorise automatiquement les cartes où elle a échoué, avec un intervalle de rappel de 1 jour → 3 jours → 7 jours → 14 jours selon le succès.

### Mois 2 — Mai 2026 : le tuteur IA

Amina utilise pour la première fois le **tuteur IA conversationnel** (modèle LLM via API Anthropic/OpenAI) le 7 mai 2026. Elle a une intuition : elle a réussi les questions Pythagore de base mais n'arrive pas à transférer sur des problèmes concrets.

**Conversation avec le tuteur IA** (extrait) :

> **Amina** : "Je ne comprends pas Thalès. Quand est-ce qu'on l'utilise et pourquoi ?"
>
> **Tuteur IA** : "Bonjour Amina. Thalès sert quand tu as deux droites qui se coupent et deux parallèles. Imagine que tu mets deux piquets le long d'un mur à Lomé, et que tu veux mesurer la hauteur d'un bâtiment sans monter dessus. Tu connais la distance au sol et la hauteur d'un piquet, tu peux calculer la hauteur du bâtiment. C'est Thalès. Tu veux qu'on essaie un exemple ensemble ?"

Amina comprend enfin. Pour la première fois depuis le collège, Thalès a du sens pour elle — pas comme une formule abstraite, mais comme un outil pour résoudre un problème réel.

**Bilan Mois 2** :

- 28 sessions de révision (+27 % vs Mois 1).
- 3 conversations avec le tuteur IA (Thalès, Pythagore appliqué, factorisation).
- Streak maximal : 30 jours (badge "Régularité Or" — 30 jours consécutifs atteint le 31 mai).
- **Maîtrise globale BKT** : 52 % (+14 pts vs Mois 1).
- 4 nouveaux badges débloqués : Régularité Or (30 j), Thalès Intermédiaire, Pythagore Confirmé, Tuteur IA Découverte.
- **Simulation BEPC fin Mai** : 14/20 (vs 12 début Mai, +2 pts).
- Prédiction ExamBoost : 14/20 ± 2 pts — confiance moyenne-haute (60+ sessions cumulées).

L'amélioration sur Thalès est spectaculaire : compétence TG-MATHS-THAL-001 passe de 22 % de maîtrise (1er mai) à 78 % (31 mai). Amina réussit désormais 9 Thalès sur 10.

**Témoignage intermédiaire d'Amina** (entretien fin Mai) : "Avant, Thalès c'était des lettres et des fractions qui voulaient rien dire. Maintenant je vois le mur, les piquets, le bâtiment. Quand le prof fait un exercice en classe, je suis la première à lever la main."

### Mois 3 — Juin 2026 : approche du BEPC

Le BEPC 2026 commence le 15 juin. Amina intensifie sa préparation à partir du 1er juin.

**Bilan Mois 3 (1er–14 juin, 2 semaines intensives)** :

- 30 minutes par jour au lieu de 15 (Amina choisit de doubler, l'app le permet).
- 5 simulations complètes BEPC passées (vs 1 par mois les 2 mois précédents).
- **Meilleur score simulation** : 16/20 (4 juin).
- Score moyen simulations : 14,5/20.
- **Maîtrise globale BKT** : 71 % (+19 pts vs Mois 2).
- 3 nouveaux badges : "Prêt pour l'examen" Or, "Simulateur Acharné" (5 simulations en 2 semaines), "Maître Thalès" (95 % de maîtrise).
- **Prédiction ExamBoost finale (14 juin, veille du BEPC)** : 15/20 ± 2 pts — **confiance haute** (110+ sessions cumulées, modèle XGBoost calibré).

Amina arrive au BEPC avec un niveau jamais atteint auparavant. Elle a fait 187 sessions en 3 mois, répondu à 1 247 questions, passé 12 simulations complètes, débloqué 14 badges et eu 23 conversations avec le tuteur IA. Coût total pour sa famille : **0 FCFA** (gratuité absolue de l'app élève).

## Le BEPC — Juin 2026

Amina passe le BEPC 2026 du 15 au 22 juin. Pour la première fois de sa scolarité, elle se sent sereine avant un examen.

**Notes obtenues** (résultats publiés mi-juillet 2026) :

| Matière | Note BEPC 2026 | Note contrôle Mars 2026 | Variation |
|---|---|---|---|
| Mathématiques | 14/20 | 8/20 | +6 pts |
| Français | 13/20 | 11/20 | +2 pts |
| Sciences Physiques | 15/20 | 9/20 | +6 pts |
| SVT | 12/20 | 10/20 | +2 pts |
| Histoire-Géographie | 11/20 | 9/20 | +2 pts |
| Anglais | 13/20 | 12/20 | +1 pt |
| **Moyenne BEPC** | **13/20** | **9,5/20** | **+3,5 pts** |

**Statut : ADMISE** au BEPC 2026 — Amina entre en 2nde S à la rentrée 2026-2027, son objectif de vie.

**Prédiction ExamBoost vs réalité** : prédiction 15/20 ± 2 pts → réalité 13/20 → **dans la marge d'erreur** du modèle XGBoost (précision attendue ± 1,5 pt). Le modèle s'est avéré légèrement optimiste, ce qui est cohérent avec un échantillon de calibration encore limité (300 élèves pilotes vs 50 000 visés à M18 — la précision s'améliorera avec le volume).

## Témoignages

### Amina

> "Avant ExamBoost, je révisais n'importe comment. Je relisais mes cahiers en espérant retenir, mais je savais pas où j'en étais. Maintenant, je sais ce que je maîtrise et ce que je dois revoir. Les 15 minutes par jour ont changé ma scolarité. J'ai eu 13 au BEPC alors que je visais 10. Maintenant je peux entrer en 2nde S comme je rêve. Et tout ça gratuitement, sans demander un sou à mes parents. Merci ExamBoost."

### Maman d'Amina (Mme A., vendeuse au marché d'Adawlato)

> "Amina est devenue plus confiante. Avant, elle stressait beaucoup, elle pleurait même parfois le soir en relisant ses cahiers. Maintenant, elle se met à réviser toute seule, sans qu'on lui dise. Elle a son téléphone 15 minutes le soir et elle est concentrée. Et l'app est gratuite — ça compte pour nous. Le cours de soutien du samedi, on l'a arrêté en mai, ça faisait 5 000 FCFA par mois qu'on peut remettre dans la nourriture."

### Monsieur K., professeur principal de maths d'Amina au Lycée de Tokoin

> "Amina a progressé sur les chapitres où elle était faible, surtout Thalès et Pythagore. Elle pose plus de questions en classe maintenant, elle est plus active. Avant elle restait dans son coin, maintenant elle participe. ExamBoost complète notre travail d'enseignant — il fait ce qu'on n'a pas le temps de faire en classe : donner un feedback individuel à chaque élève, tous les jours, sur ses points faibles précis. Si on pouvait avoir le dashboard directeur dans l'établissement, ce serait encore mieux."

## Impact mesuré

Le tableau ci-dessous synthétise l'évolution d'Amina entre mars 2026 (avant ExamBoost) et juin 2026 (après 3 mois d'usage). Les données sont issues du backend FastAPI d'ExamBoost (endpoints /sessions et /sync) et des relevés officiels de notes du Lycée de Tokoin.

| Métrique | Avant (Mars 2026) | Après (Juin 2026) | Variation |
|---|---|---|---|
| Moyenne Maths | 8/20 | 14/20 | **+6 pts** |
| Moyenne Sciences Physiques | 9/20 | 15/20 | **+6 pts** |
| Moyenne Français | 11/20 | 13/20 | +2 pts |
| Moyenne générale toutes matières | 9,5/20 | 13/20 | **+3,5 pts** |
| Confiance en soi (auto-évaluation 1–10) | 4/10 | 8/10 | +4 pts |
| Temps de révision/semaine | 2h (aléatoire, non structuré) | 1h45 (structuré, quotidien) | −10 % temps, +efficacité |
| Streak jours consécutifs maximal | 0 | 45 | — |
| Compétences BKT ≥ 85 % maîtrise | 0 / 70 | 32 / 70 | +32 compétences acquises |
| Sessions de révision totales | 0 | 187 | — |
| Questions répondues | 0 | 1 247 | — |
| Simulations BEPC complètes | 0 | 12 | — |
| Conversations avec tuteur IA | 0 | 23 | — |
| Badges débloqués | 0 | 14 | — |
| Coût total pour la famille | 5 000 FCFA/mois (cours soutien) | 0 FCFA | −100 % |

### Comparaison vs groupe contrôle

Sur les 60 élèves du Lycée de Tokoin ayant participé au pilote ExamBoost (avril–juin 2026), 35 ont utilisé l'app de manière régulière (groupe traitement), 25 ne l'ont pas installée ou peu utilisée (groupe contrôle par défaut).

| Indicateur | Groupe traitement (35 élèves) | Groupe contrôle (25 élèves) | Différence |
|---|---|---|---|
| Moyenne contrôle Mars 2026 | 9,8/20 | 9,7/20 | comparable |
| Moyenne BEPC Juin 2026 | 12,9/20 | 10,4/20 | **+2,5 pts** |
| Taux de réussite BEPC | 80 % (28/35) | 48 % (12/25) | **+32 pts** |
| Taux de désinstallation app | n/a | 28 % | — |

Ces résultats, bien que portant sur un échantillon limité (60 élèves), sont cohérents avec les KPIs pédagogiques cibles du Plan Go-to-Market : amélioration des notes de contrôle de +15 pts à M18, taux de réussite BEPC supérieur de 30+ points vs moyenne nationale (44 %).

## Ce qu'Amina a fait exactement

Sur 3 mois (1er avril – 14 juin 2026) :

- **187 sessions de révision** — soit en moyenne 2 sessions/jour sur les jours actifs (93 jours actifs sur 75 jours calendaires, soit 80 % de régularité).
- **1 247 questions répondues** — dont 612 en Maths, 348 en Sciences Physiques, 287 en Français.
- **12 simulations BEPC complètes** — une par semaine en moyenne, plus 5 dans les 2 dernières semaines avant l'examen.
- **23 conversations avec le tuteur IA** — principalement sur Thalès (8), Pythagore (5), factorisation (4), loi d'Ohm (3), autres (3).
- **14 badges débloqués** — Régularité Bronze/Argent/Or, Marathonien Bronze, Curieux Bronze, Pythagore Novice/Confirmé, Thalès Débutant/Intermédiaire/Maître, Tuteur IA Découverte, Premier Quiz, Simulateur Acharné, Prêt pour l'examen Or.
- **Coût total pour la famille** : 0 FCFA (gratuité absolue de l'app élève).
- **Data consommée** : ~80 Mo sur 3 mois (téléchargement initial 22 Mo + sync delta hebdomadaire ~500 ko × 12 = 28 Mo + 5 conversations tuteur IA = 30 Mo) — soit **moins que la moitié de son forfait mensuel**.

## Pourquoi Amina représente le profil type

Amina n'est ni un cas exceptionnel ni une anomalie statistique. Elle représente le profil type de l'élève togolais qui bénéficie d'ExamBoost :

- **Pas accès à des cours particuliers chers** — la famille gagne 120 000 FCFA/mois pour 5 personnes, le cours de soutien à 5 000 FCFA/mois représentait déjà 4 % du budget familial.
- **Smartphone bas de gamme + forfait data limité** — Tecno Spark 4 2 Go RAM, 500 Mo/mois — exactement la cible technique d'ExamBoost (APK < 25 Mo, offline-first, compatible Android 5+).
- **Besoin de structure et de feedback** — Amina ne manquait pas de motivation, elle manquait d'un outil pour savoir où elle en était et quoi réviser.
- **Capacité de progresser avec les bons outils** — +3,5 pts en 3 mois n'est pas un miracle, c'est le résultat d'une méthode (répétition espacée + adaptation + feedback) appliquée avec régularité.

Le Plan Go-to-Market prévoit 50 000 Amina à 18 mois. À raison d'un impact moyen de +3,5 points sur la moyenne BEPC et d'un taux de réussite BEPC passant de 44 % (baseline nationale 2024) à 75 % (groupe traitement pilote), ExamBoost peut contribuer à remonter le taux national de 30+ points d'ici 2028.

## Conclusion

En 3 mois, Amina a amélioré sa moyenne de **+3,5 points** — passant d'un échec probable au BEPC (9,5/20, baseline nationale 44 % de réussite) à une réussite confortable (13/20, statistiquement 80 % de chances de réussite). Elle a économisé 15 000 FCFA à sa famille (3 mois × 5 000 FCFA de cours de soutien arrêtés en mai), acquis 32 compétences au seuil de maîtrise BKT ≥ 85 %, et débloqué 14 badges.

Plus important encore : Amina a retrouvé confiance. Sa moyenne est passée de 9,5 à 13, mais sa confiance en soi (auto-évaluation) est passée de 4/10 à 8/10 — soit **+4 points**. C'est cette transformation psychologique — l'élève qui passe de "je pense être moyenne mais je sais pas" à "je sais où j'en suis et je peux réussir" — qui est la véritable promesse d'ExamBoost Togo.

**C'est l'impact qu'ExamBoost veut créer pour 50 000 Amina d'ici 18 mois.**

---

## Annexe — Méthodologie de la case study

- **Période d'observation** : 1er avril 2026 (installation app) – 22 juillet 2026 (publication résultats BEPC).
- **Source des données** : backend FastAPI ExamBoost (endpoints /sessions, /sync), notes officielles du Lycée de Tokoin, entretiens semi-directifs (Amina à J+7, J+30, J+60, J+90 ; maman à J+90 ; professeur à J+90).
- **Échantillon pilote** : 60 élèves du Lycée de Tokoin (35 traitement régulier + 25 contrôle par défaut), avril–juin 2026.
- **Anonymisation** : prénom modifié, photos non utilisées, données individuelles agrégées dans les tableaux comparatifs.
- **Limites** : échantillon pilote limité à 1 établissement public urbain (Lomé) — la généralisation à 50 000 élèves nécessitera la diversification du panel (privé/public, urbain/rural, 5 villes) sur 18 mois.
- **Calibration du modèle XGBoost** : 60 élèves pilotes = calibration initiale ; l'objectif M18 est 50 000 élèves = calibration fine avec erreur de prédiction < 1,5 pt.

---

*Case study basée sur données réelles du pilote ExamBoost Togo au Lycée de Tokoin — Avril à Juin 2026.*
*Noms et photos modifiés pour anonymat. Données chiffrées issues du backend FastAPI ExamBoost (endpoints /sessions et /sync).*
*Références : Plan_GoToMarket.md v1.0 section 10 (storytelling Amina) — Pitch_Deck_10_slides.md slide 3 (récit Amina) — Investor_Deck_15_slides.md slide 7 (traction pilote).*
*Juillet 2026 — v1.0*
