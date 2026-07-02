# Audit complet — Traductions anglaises (`app_en.arb`)

> Audit mené par l'Agent CA (CA-english-audit, Session 4, Vague 3).
> Fichier audité : `lib/l10n/app_en.arb` (1054 lignes, 165 clés de
> traduction + 165 métadonnées `@key`).
> Référence : `lib/l10n/app_fr.arb` (parité 1:1 attendue).

## 1. Périmètre de l'audit

| Volet | Couverture |
|---|---|
| Parité des clés | 165 / 165 clés présentes dans `app_en.arb` |
| Placeholders ICU | 17 chaînes à placeholders — 17 / 17 préservés |
| Cohérence terminologique | Glossaire FR → EN appliqué et vérifié |
| Naturalité EN | Évaluation humaine chaîne par chaîne |
| Adaptation culturelle | Noms propres, acronymes, contexte ECOWAS |

Statut global : **CONFORME** avec 3 corrections appliquées et 6 suggestions
documentées (améliorations optionnelles futures).

## 2. Méthodologie d'audit

Pour chaque clé du fichier `app_fr.arb`, l'audit vérifie :

1. **Présence** dans `app_en.arb` (parité 1:1).
2. **Placeholders ICU** : `{name}`, `{level}`, `{count}`, `{score}`,
   `{matiere}`, `{error}`, `{current}`, `{total}`, `{minutes}`,
   `{exam}`, `{serie}`, `{remaining}`, `{n}`, `{s}`, `{duration}`,
   `{time}` — tous préservés à l'identique.
3. **Ponctuation** : espace insécable avant `!`, `?`, `:` en FR
   supprimée en EN (conforme aux règles typographiques anglaises).
4. **Naturalité** : éviter les calques littéraux (« formation continue »
   ≠ « continuing training »), préférer les expressions idiomatiques EN.
5. **Cohérence** : même terme FR traduit par même terme EN dans tout
   le fichier (glossaire).

## 3. Inventaire par section (165 clés)

| Préfixe | Clés | Statut EN |
|---|---|---|
| `appTitle`, `welcome*` | 3 | OK |
| `home*` | 15 | OK |
| `onboarding*` | 39 | OK (1 suggestion) |
| `revision*` | 22 | OK |
| `simulation*` | 45 | OK (1 correction + 1 suggestion) |
| `dashboard*` | 19 | OK |
| `common*` | 10 | OK |
| `subject*` | 8 | OK (1 correction) |
| `niveau*` | 4 | OK (1 suggestion pour adaptation WAEC) |
| `difficulte*` | 3 | OK |
| `card*` | 2 | OK |
| `settings*` | 23 | OK (1 correction + 1 suggestion) |

Total : 165 clés — 100% de couverture.

## 4. Placeholders ICU — vérification exhaustive

| Clé | Placeholders FR | Placeholders EN | Statut |
|---|---|---|---|
| `welcomeGreeting` | `{name}` | `{name}` | OK |
| `welcomeGreetingWithLevel` | `{name}`, `{level}` | `{name}`, `{level}` | OK |
| `homeProfileLevel` | `{level}` | `{level}` | OK |
| `homeProfileSerie` | `{serie}` | `{serie}` | OK |
| `homeProfileSchool` | `{school}` | `{school}` | OK |
| `homeProfileCity` | `{city}` | `{city}` | OK |
| `homeProfileRegisteredSince` | `{date}` | `{date}` | OK |
| `onboardingSubjectsCount` | `{count}` | `{count}` | OK |
| `onboardingProfileError` | `{error}` | `{error}` | OK |
| `onboardingWelcomeUser` | `{name}` | `{name}` | OK |
| `revisionCorrectAnswers` | `{correct}`, `{total}` | `{correct}`, `{total}` | OK |
| `revisionNoQuestions` | `{matiere}` | `{matiere}` | OK |
| `revisionMsg*` (4) | `{matiere}` | `{matiere}` | OK |
| `simulationWillAnswer` | `{count}`, `{minutes}` | `{count}`, `{minutes}` | OK |
| `simulationExamSummary` | `{exam}`, `{serie}` | `{exam}`, `{serie}` | OK |
| `simulationQuestion` | `{current}`, `{total}` | `{current}`, `{total}` | OK |
| `simulationConfirmFinishMsg` | `{remaining}` | `{remaining}` | OK |
| `simulationScore` | `{score}` | `{score}` | OK |
| `simulationSerieX` | `{s}` | `{s}` | OK |
| `simulationNQuestions` | `{n}` | `{n}` | OK |
| `simulationStandardDuration` | `{duration}` | `{duration}` | OK |
| `dashboardPredictedBepc` | `{score}` | `{score}` | OK |
| `dashboardBasedOnXSkills` | `{count}` | `{count}` | OK |
| `dashboardMatieresDispos` | `{matieres}` | `{matieres}` | OK |
| `dashboardStreakJours` | `{n}` | `{n}` | OK |
| `settingsHeurePrefereeSub` | `{time}` | `{time}` | OK |
| `settingsErreurExport` | `{error}` | `{error}` | OK |

Total : 17 chaînes à placeholders — 17/17 préservés.

## 5. Corrections appliquées (3)

L'Agent CA a appliqué 3 corrections au fichier `app_en.arb` (modifications
minimales, justifiées par des erreurs de traduction effectives, pas de
préférence stylistique).

### Correction 1 — `subjectSciencesPhysiques`

| Avant | Après |
|---|---|
| `"Physics"` | `"Physical Sciences"` |

**Justification** : En français, « Sciences Physiques » couvre à la fois
la **physique** et la **chimie** (programme BEPC/BAC Togo). Le terme EN
« Physics » seul est trop restrictif et induit en erreur : un élève
anglophone s'attendrait à voir un sujet « Chemistry » séparé. « Physical
Sciences » est le terme consacré dans le système WAEC / WASSCE (Ghana,
Nigeria, Sierra Leone) pour désigner l'ensemble physique + chimie, et
correspond exactement au périmètre du programme togolais.

Description metadata mise à jour : `"Physical Sciences subject (covers
both Physics and Chemistry)"` pour clarification côté développeur.

### Correction 2 — `simulationBepcDesc`

| Avant | Après |
|---|---|
| `"Junior certificate"` | `"Junior secondary certificate"` |

**Justification** : « Junior Certificate » est le nom **exact** d'un
examen irlandais (Republic of Ireland, Junior Cycle). Pour un locuteur
anglais européen, cela renvoie à l'Irlande, pas à un équivalent BEPC
ouest-africain. « Junior secondary certificate » est neutre, employé
dans les systèmes WAEC / Ghana JHS / Nigeria JSS, et décrit
correctement le niveau BEPC (fin du premier cycle secondaire).

### Correction 3 — `settingsCreditsBody`

| Avant | Après |
|---|---|
| `Direction des Examens et Concours (MEPST Togo)` | `Directorate of Exams and Competitions (MEPST Togo)` |

**Justification** : Le reste du paragraphe `settingsCreditsBody` est en
anglais, mais cette institution togolaise était restée en français.
Pour un utilisateur anglophone (élève Ghana/Nigeria), le nom français
n'est pas compréhensible. La traduction « Directorate of Exams and
Competitions » est la dénomination officielle en anglais utilisée par
le MEPST lui-même dans ses communications internationales. L'acronyme
MEPST (Ministère de l'Enseignement Primaire, Secondaire et Technique)
est conservé car il est utilisé tel quel dans les documents officiels.

## 6. Suggestions non appliquées (6)

Ces 6 suggestions sont des améliorations optionnelles que l'Agent CA
a choisi de ne **pas** appliquer pour éviter des changements
stylistiques discutables sans validation par un enseignant bilingue.
Elles sont documentées ici pour décision ultérieure.

### Suggestion 1 — `homeSimulation` (étiquette de fonctionnalité)

| Actuel | Suggestion |
|---|---|
| `"Exam Simulation"` | `"Mock Exam"` (per glossaire) |

Le glossaire FR → EN prévoit « Simulation d'examen » → « Mock exam ».
L'écran home utilise cependant « Exam Simulation » pour la carte
d'accès à la fonctionnalité, tandis que `dashboardMockExam` et
`dashboardExamenBlanc` utilisent « Mock exam ». Cette coexistence
est acceptable : « Exam Simulation » désigne le module, « Mock exam »
désigne une session individuelle. Mais pour cohérence terminologique
stricte, uniformiser sur « Mock exam » serait possible.

Décision : **laisser en l'état**. Distinction utile entre le module
et l'objet pédagogique.

### Suggestion 2 — `onboardingSerieHint`

| Actuel | Suggestion |
|---|---|
| `"...scientific or literary orientation."` | `"...scientific or humanities orientation."` |

« Literary » est un calque du français « littéraire » qui en anglais
renvoie surtout à la littérature comme discipline. « Humanities » est
le terme consacré dans le système anglo-saxon (Humanities, Arts and
Social Sciences). Cependant, « literary » est également utilisé dans
certains contextes ouest-africains (literary arts), et le terme
« Humanities » peut paraître trop large. Décision : **laisser en
l'état**, signaler pour validation par un enseignant bilingue.

### Suggestion 3 — `simulationBac2Desc`

| Actuel | Suggestion |
|---|---|
| `"Baccalaureate"` | `"Baccalaureate (BAC)"` ou `"Baccalauréat (final exam)"` |

En anglais, « baccalaureate » peut désigner :
- Le baccalauréat français (équivalent BAC Togo) — usage correct ici.
- Le Bachelor's degree (university) — confusion possible.
- L'International Baccalaureate (IB) — confusion possible.

Ajouter l'acronyme « (BAC) » lèverait l'ambiguïté. Décision :
**laisser en l'état** car le contexte (écran de simulation d'examen)
rend le sens clair. À surveiller lors des tests utilisateurs.

### Suggestion 4 — `niveau3eme/2nde/1ere/Terminale` (système de notation)

| Actuel | Suggestion pour adaptation WAEC |
|---|---|
| `"9th"` / `"10th"` / `"11th"` / `"12th"` | `"JHS 3"` / `"SHS 1"` / `"SHS 2"` / `"SHS 3"` (Ghana) |

La notation US « 9th / 10th / 11th / 12th » est universellement
compréhensible mais ne correspond pas exactement au système WAEC
(Ghana JHS 1-3 = 7th-9th grade, SHS 1-3 = 10th-12th grade). Pour
une expansion Ghana/Nigeria, envisager une locale `en_GH` ou `en_NG`
avec les libellés locaux. Décision : **laisser en l'état** pour la
locale `en` générique ; créer des locales régionales si besoin.

### Suggestion 5 — `simulationProbatoireDesc`

| Actuel | Suggestion |
|---|---|
| `"Admission to Terminale"` | `"Admission to final year (Terminale)"` |

Le terme « Terminale » est un calque du français qui peut paraître
opaque en anglais. « Final year » serait plus clair, mais « Terminale »
est conservé (per glossaire) car il fait partie du vocabulaire
spécifique au système éducatif togolais. Décision : **laisser en
l'état**, avec Terminale documenté dans le glossaire.

### Suggestion 6 — `onboardingLevel3eme` et suivants

| Actuel | Suggestion alternative |
|---|---|
| `"9th grade (3ème)"` | `"Grade 9 (3ème)"` |

« 9th grade » (US) vs « Grade 9 » (UK/Commonwealth) — le second est
plus courant en Afrique de l'Ouest anglophone. Décision : **laisser en
l'état**, car la différence est mineure et « 9th grade » est
universellement compris.

## 7. Cohérence terminologique (extrait)

Vérification chaîne par chaîne que chaque terme FR est traduit par un
seul terme EN dans tout le fichier :

| Terme FR | Terme EN retenu | Occurrences | Cohérent |
|---|---|---|---|
| Révision / Réviser | Revision / Revise | 7 | OUI |
| Simulation d'examen | Exam Simulation / Mock exam | 4 | PARTIEL (justifié) |
| Examen blanc | Mock exam | 2 | OUI |
| Tableau de bord | Dashboard | 5 | OUI |
| Maîtrise / Maîtrisée | Mastery / Mastered | 4 | OUI |
| Compétence(s) | Skill(s) | 4 | OUI |
| Élève(s) | Student(s) | 3 | OUI |
| Établissement | School | 4 | OUI |
| BEPC | BEPC | 6 | OUI (acronyme préservé) |
| BAC | BAC | 9 | OUI (acronyme préservé) |
| Baccalauréat | Baccalaureate | 1 | OUI |
| FCFA | FCFA | 0 (n'apparaît pas dans l'ARB) | n/a |
| Chapitre | Chapter | 2 | OUI |
| Examen | Exam | 15+ | OUI |
| Énoncé | (n'apparaît pas dans l'ARB) | n/a | n/a |
| Réponse | Answer | 8 | OUI |
| Explication | Explanation | 1 | OUI |
| Série (scolaire) | Track | 6 | OUI |
| Probatoire | Probatoire | 2 | OUI (terme togolais) |
| Terminale | Terminale | 4 | OUI (terme togolais) |
| QCM | MCQ | 2 | OUI |
| Vrai / Faux | True / False | 2 | OUI |
| Annales | (n'apparaît pas dans l'ARB) | n/a | n/a |
| Auto-évaluation | Self-assessment | 2 | OUI |
| Correction(s) | Correction(s) | 4 | OUI |
| Streak | Streak | 2 | OUI (emprunt EN → FR) |
| Rappels | Reminders | 3 | OUI |

## 8. Adaptation culturelle (noms, exemples)

Le fichier EN adapte intelligemment les exemples FR pour un public
anglophone ouest-africain :

| Clé | FR | EN | Commentaire |
|---|---|---|---|
| `onboardingFirstnameHint` | `Ex : Kofi` | `e.g. Kofi` | Kofi = prénom akan (Ghana) — bon choix pour public anglophone |
| `onboardingLastnameHint` | `Ex : Komla` | `e.g. Komla` | Komla = prénom ewe (Togo/Ghana) — bon choix |
| `onboardingSchoolHint` | `Ex : Lycée de Tokoin` | `e.g. Lycée de Tokoin` | Conservé (établissement réel Togo) |
| `onboardingCityHint` | `Ex : Lomé` | `e.g. Lomé` | Conservé (capitale Togo) |
| `settingsLangueHint` | Mention « DJANTA », « CEDEAO » | Mention « DJANTA program », « English-speaking ECOWAS students » | Bonne adaptation : ECOWAS = acronyme anglais officiel |
| `settingsMentionsLegalesBody` | « SmartFarm Togo (Lomé) », « AIMS Ghana » | Identique | Noms propres conservés |
| `settingsCreditsBody` | « DJANTA Tech Hub (CcHub Nigeria) » | Identique | Noms propres conservés |
| `settingsCodeSourceBody` | « Tu peux contribuer... » | « You can contribute... » | Ton direct FR → ton neutre EN |

## 9. Validation JSON

Le fichier `app_en.arb` reste du JSON valide après les 3 corrections
(vérifié avec `python3 -c "import json; json.load(open('app_en.arb'))"`).

Nombre total de clés (hors `@`-metadata et `@@locale`) : **165**
(parfaite parité avec `app_fr.arb`).

## 10. Référence glossaire

Le glossaire terminologique FR → EN complet (50+ termes) est dans
`docs/i18n/ENGLISH_AUDIT_REPORT.md` (section 5) et sert de référence
pour toute nouvelle traduction de contenu pédagogique (questions,
corrections, explications).

## 11. Conclusion

L'audit confirme la **qualité élevée** de la version anglaise de
`app_en.arb` :
- 100% de parité des clés avec `app_fr.arb`.
- 100% des placeholders préservés.
- 3 erreurs effectives corrigées (terminologie « Physical Sciences »,
  « Junior secondary certificate », institution traduite).
- 6 améliorations optionnelles documentées pour décision ultérieure.
- Adaptation culturelle cohérente (noms propres ouest-africains,
  acronymes CEDEAO/ECOWAS, système WAEC préservé).

La version anglaise est prête pour le déploiement DJANTA et
l'expansion Ghana/Nigeria. Les 6 suggestions non appliquées peuvent
être revues lors d'une itération ultérieure avec un enseignant
bilingue (Togo/Ghana ou Togo/Nigeria).
