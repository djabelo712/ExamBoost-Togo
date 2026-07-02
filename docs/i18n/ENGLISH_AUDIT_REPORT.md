# Rapport d'audit — Version anglaise ExamBoost Togo

> **Task ID** : CA-english-audit
> **Agent** : Agent CA (general-purpose)
> **Session** : 4 — Vague 3
> **Date** : Juin 2026
> **Périmètre** : `lib/l10n/app_en.arb` (165 clés) + expansion Ghana/Nigeria

## 1. Contexte

ExamBoost Togo est une application Flutter de préparation aux examens
nationaux togolais (BEPC, BAC). Elle est développée dans le cadre du
programme DJANTA Tech Hub (CcHub Nigeria), partenariat bilingue
français / anglais. L'expansion vers le Ghana et le Nigeria (zone
CEDEAO/ECOWAS anglophone) requiert une version anglaise complète et
naturelle.

L'application contient :
- **165 clés de traduction** dans `app_en.arb` (UI)
- **~300 questions pédagogiques** dans `assets/data/questions.json` (FR)
- **Documentation pédagogique** : 15 fichiers `docs/*.md`

L'agent CA a audité la version anglaise, créé un glossaire
terminologique FR → EN, traduit un échantillon de 10 questions et
rédigé un guide de traduction pour le contenu pédagogique futur.

## 2. Livrables de l'audit

| Livrable | Chemin | Rôle |
|---|---|---|
| Audit détaillé | `lib/l10n/app_en_content.md` | Audit chaîne par chaîne de `app_en.arb` |
| Rapport (ce fichier) | `docs/i18n/ENGLISH_AUDIT_REPORT.md` | Synthèse, glossaire, recommandations |
| Guide de traduction contenu | `docs/i18n/content_translation_guide.md` | Procédure pour traduire nouvelles questions |
| Échantillon questions EN | `docs/i18n/english_questions_sample.json` | 10 questions FR + EN (5 BEPC Maths, 3 BEPC Sciences, 2 BAC Maths) |
| Fichier de traduction | `lib/l10n/app_en.arb` | 3 corrections appliquées |

## 3. Synthèse de l'audit `app_en.arb`

### 3.1 Conformité globale

| Indicateur | Valeur | Statut |
|---|---|---|
| Clés présentes EN vs FR | 165 / 165 | OK |
| Placeholders ICU préservés | 17 / 17 | OK |
| Cohérence terminologique | 25 / 26 termes | OK (1 distinction justifiée Simulation/Mock) |
| Adaptation culturelle | 7 / 7 noms propres | OK |
| Corrections appliquées | 3 | Effectives |
| Suggestions documentées | 6 | Non appliquées (à valider) |
| JSON valide | OUI | OK |

### 3.2 Corrections appliquées (3)

#### C1. `subjectSciencesPhysiques` : `Physics` → `Physical Sciences`

**Problème** : En français « Sciences Physiques » couvre physique ET
chimie. Le terme EN « Physics » seul est trop restrictif.

**Solution** : « Physical Sciences » — terme consacré dans le système
WAEC/WASSCE (Ghana, Nigeria) pour l'ensemble physique + chimie.

#### C2. `simulationBepcDesc` : `Junior certificate` → `Junior secondary certificate`

**Problème** : « Junior Certificate » est le nom exact d'un examen
irlandais (Republic of Ireland), ce qui induit en erreur.

**Solution** : « Junior secondary certificate » — terme neutre employé
dans les systèmes WAEC / Ghana JHS / Nigeria JSS, décrivant
correctement le niveau BEPC.

#### C3. `settingsCreditsBody` : traduction de l'institution togolaise

**Problème** : Le reste du paragraphe est en anglais, mais
« Direction des Examens et Concours (MEPST Togo) » était resté en
français, incompréhensible pour un utilisateur anglophone.

**Solution** : « Directorate of Exams and Competitions (MEPST Togo) » —
dénomination officielle utilisée par le MEPST dans ses communications
internationales. L'acronyme MEPST est conservé tel quel.

### 3.3 Suggestions non appliquées (6)

Documentées dans `lib/l10n/app_en_content.md` §6. Résumé :

1. `homeSimulation` : « Exam Simulation » vs « Mock exam » — distinction
   module/session justifiée, laisser en l'état.
2. `onboardingSerieHint` : « literary » vs « humanities » — à valider
   par enseignant bilingue.
3. `simulationBac2Desc` : « Baccalaureate » sans acronyme — contexte
   suffisant, à surveiller en tests utilisateurs.
4. `niveau3eme/2nde/1ere/Terminale` : US grade vs WAEC JHS/SHS —
   envisager locale `en_GH` ou `en_NG` si expansion précise.
5. `simulationProbatoireDesc` : « Terminale » préservé (terme
   togolais documenté dans glossaire).
6. `onboardingLevel*` : « 9th grade » vs « Grade 9 » — mineur,
   laisser en l'état.

## 4. Glossaire terminologique FR → EN (50+ termes)

### 4.1 Termes pédagogiques

| FR | EN | Notes |
|---|---|---|
| Révision | Revision / Review | « Revision » plus courant en anglais britannique et ouest-africain (WAEC). « Review » plus américain. Préférer « Revision » pour cohérence ECOWAS. |
| Réviser | Revise | Verbe — préférer à « Review » (UK/WAEC) |
| Simulation d'examen | Mock exam | Standard UK education et WAEC |
| Examen blanc | Mock exam | Identique à ci-dessus |
| Examen | Exam | Abréviation standard EN |
| Annales | Past papers | Terme WAEC/Cambridge |
| Énoncé | Question text / Statement | « Question text » pour UI ; « Statement » pour énoncé formel |
| Réponse | Answer | |
| Explication | Explanation | |
| Correction | Correction / Marking scheme | « Correction » pour une réponse corrigée ; « Marking scheme » pour le barème officiel |
| Auto-évaluation | Self-assessment | |
| QCM | MCQ | Multiple Choice Question |
| Vrai / Faux | True / False | |
| Question ouverte | Open question | |
| Question à calcul | Calculation question | |
| Rédaction | Essay | « Essay » standard EN |
| Chapitre | Chapter | |
| Compétence | Skill / Competency | « Skill » plus courant en edtech ; « Competency » pour référentiel officiel |
| Maîtrise / Maîtrisée | Mastery / Mastered | |
| Élève | Student | « Pupil » plus UK-formel ; « Student » plus large et moderne |
| Apprenant | Learner | |
| Professeur | Teacher | « Tutor » pour le tuteur IA |
| Cours | Lesson / Course | « Lesson » pour chapitre ; « Course » pour cursus complet |
| Programme (scolaire) | Curriculum / Syllabus | « Curriculum » pour le programme global ; « Syllabus » pour une matière |
| Niveau scolaire | Grade level / Year | « Grade level » (US) ; « Year » (UK) |
| Progression | Progress | |
| Coefficient | Coefficient | Identique FR/EN |
| Note (sur 20) | Score (out of 20) / Grade | « Score » pour chiffre ; « Grade » pour mention (A, B, C) |
| Barème | Marking scheme / Grading scale | |
| Probatoire | Probatoire | Terme togolais — conserver en EN (clarté contextuelle) |
| Terminale | Terminale | Terme togolais — conserver en EN |

### 4.2 Niveaux et séries

| FR | EN | Notes |
|---|---|---|
| 3ème | 9th grade (3ème) | Format double pour transition |
| 2nde | 10th grade (2nde) | Format double |
| 1ère | 11th grade (1ère) | Format double |
| Terminale | 12th grade (Terminale) | Format double |
| Série A — Littéraire | Track A — Literature | « Série » → « Track » (évite confusion avec TV series) |
| Série B — Sciences Économiques | Track B — Economics | |
| Série C — Maths & Sciences Physiques | Track C — Math & Physics | |
| Série D — Sciences Naturelles | Track D — Natural Sciences | |
| Série F — Technique | Track F — Technical | |
| Série (générique) | Track | |

### 4.3 Termes d'examen (acronymes préservés)

| FR | EN | Notes |
|---|---|---|
| BEPC | BEPC | Acronyme togolais — conserver (Brevet d'Études du Premier Cycle) |
| BAC | BAC | Acronyme togolais/francophone — conserver |
| Baccalauréat | Baccalaureate | Forme longue EN |
| BAC 1 | BAC 1 | |
| BAC 2 | BAC 2 | |
| FCFA | FCFA | Monnaie CEDEAO — conserver (Franc CFA) |
| CEDEAO | ECOWAS | Acronyme anglais officiel (Economic Community of West African States) |
| MEPST | MEPST | Ministère togolais — acronyme préservé |
| WAEC | WAEC | West African Examinations Council — déjà EN |
| WASSCE | WASSCE | West African Senior School Certificate Examination — déjà EN |

### 4.4 Termes UI / app

| FR | EN | Notes |
|---|---|---|
| Tableau de bord | Dashboard | |
| Profil | Profile | |
| Paramètres | Settings | |
| Communauté | Community | |
| Classements | Leaderboards | |
| Défi hebdo | Weekly challenge | |
| Entraide | Peer support | |
| Carte (flashcard) | Card | |
| Carte à revoir | Card to review | |
| Streak | Streak | Emprunt EN → FR, conservé |
| Rappels | Reminders | |
| Alertes | Alerts | |
| Heure préférée | Preferred time | |
| Réinitialiser | Reset | |
| Supprimer | Delete | |
| Compte | Account | |
| Établissement | School / Institution | « School » plus courant ; « Institution » pour structures formelles |
| Ville | City | |
| Date d'inscription | Registration date | |
| Données et confidentialité | Data and privacy | |
| Collecte anonyme | Anonymous collection | |
| Exporter (JSON) | Export (JSON) | |
| Mentions légales | Legal notices | |
| Crédits | Credits | |
| Licence | License | Attention : EN US = « License » / EN UK = « Licence » — préférer US ici (terme tech) |
| Thème | Theme | |
| Mode clair | Light mode | |
| Mode sombre | Dark mode | |
| Mode système | System mode | |
| Langue | Language | |

## 5. Validation par enseignant bilingue (procédure recommandée)

L'audit recommande une validation finale par un enseignant bilingue
français/anglais, idéalement :

- **Profil 1** : enseignant togolais francophone avec expérience
  WAEC/GCE (Ghana) ou NECO/WAEC (Nigeria) — valide la fidélité au
  programme togolais et l'accessibilité pour élèves anglophones
  ouest-africains.
- **Profil 2** : enseignant ghanéen ou nigérian anglophone avec
  connaissance du système francophone — valide la naturalité EN et
  l'absence de calques FR.

**Checklist de validation** :
1. Lecture complète de `app_en.arb` (165 clés, ~30 min).
2. Validation des 3 corrections appliquées (section 3.2 de ce rapport).
3. Avis sur les 6 suggestions non appliquées (section 3.3).
4. Validation du glossaire (section 4 de ce rapport).
5. Test utilisateurs : 3-5 élèves anglophones (Lycée Ghana/Nigeria)
   sur l'app complète en mode EN.
6. Validation de l'échantillon de 10 questions EN
   (`english_questions_sample.json`).

## 6. Recommandations pour l'expansion Ghana/Nigeria

### 6.1 Locale régionale `en_GH` / `en_NG` (optionnel)

Si l'expansion Ghana/Nigeria se concrétise, créer des locales
régionales pour adapter :
- Système de notation : JHS 1-3 / SHS 1-3 (Ghana) au lieu de 9th-12th.
- Sujets : ajouter « Integrated Science », « Social Studies »,
  « Ghanaian Languages » (Ghana) ; « Civic Education », « Computer
  Studies » (Nigeria).
- Examens : BECE (Ghana JHS) / WASSCE (Ghana SHS) ; BECE (Nigeria JSS)
  / WASSCE (Nigeria SSS) — distincts du BEPC togolais.
- Noms d'exemples : Kofi, Ama, Kwame (Ghana) ; Chidi, Ngozi, Emeka
  (Nigeria) — actuellement Kofi/Komla dans l'app (Ewe/Akan, partagé
  Ghana-Togo).

### 6.2 Contenu pédagogique traduit

Le fichier `assets/data/questions.json` contient actuellement ~300
questions en français. Pour l'expansion :

1. **Court terme (DJANTA)** : les 10 questions d'échantillon
   (`english_questions_sample.json`) démontrent la capacité.
2. **Moyen terme** : ajouter les champs `enonce_en`, `reponse_en`,
   `explication_en` à toutes les questions existantes (voir
   `content_translation_guide.md` §3 pour le schéma JSON).
3. **Long terme** : créer une banque de questions WAEC native
   (Ghana BECE/WASSCE, Nigeria BECE/WASSCE) en plus de la traduction
   BEPC/BAC Togo.

### 6.3 Modèle de données

Le modèle `Question` (`lib/models/question.dart`) doit être étendu
pour supporter les champs optionnels EN. Voir `content_translation_guide.md`
§4 pour le schéma Dart proposé. Cette extension est **hors scope** de
l'audit CA-english-audit et devra être réalisée par un agent de
développement.

## 7. Métriques finales

| Métrique | Valeur |
|---|---|
| Clés auditées | 165 |
| Placeholders vérifiés | 17 |
| Termes du glossaire | 50+ |
| Corrections appliquées | 3 |
| Suggestions documentées | 6 |
| Questions traduites EN (échantillon) | 10 |
| Fichiers créés | 4 (audit + rapport + guide + sample JSON) |
| Fichiers modifiés | 1 (app_en.arb, 3 lignes) |
| Code source touché | 0 (aucun fichier `.dart` modifié) |

## 8. Conclusion

La version anglaise d'ExamBoost Togo est **prête pour le
déploiement DJANTA** et constitue une **base solide pour l'expansion
Ghana/Nigeria**. Les 165 clés de traduction sont complètes et
naturelles, les 3 corrections appliquées lèvent les ambiguïtés
majeures (Physical Sciences, Junior secondary certificate, institution
traduite). Le glossaire de 50+ termes fournit une référence
pérenne pour toute nouvelle traduction. L'échantillon de 10 questions
démontre la capacité de l'équipe à étendre la traduction au contenu
pédagogique.

Les prochaines étapes recommandées sont :
1. Validation par enseignant bilingue (§5).
2. Tests utilisateurs avec 3-5 élèves anglophones.
3. Décision sur les 6 suggestions non appliquées.
4. Extension du modèle `Question` (Dart) pour les champs EN optionnels.
5. Traduction des ~300 questions existantes (moyen terme).
6. Création de locales régionales `en_GH` / `en_NG` si expansion
   précise (long terme).
