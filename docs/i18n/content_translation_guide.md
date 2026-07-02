# Guide de traduction du contenu pédagogique (FR → EN)

> **Task ID** : CA-english-audit
> **Agent** : Agent CA (general-purpose)
> **Scope** : Procédure de traduction des questions, corrections et
> explications pédagogiques d'ExamBoost Togo, du français vers
> l'anglais, pour l'expansion Ghana/Nigeria (CEDEAO/ECOWAS).

## 1. Objectifs

Ce guide explique comment :
1. Traduire une nouvelle question FR → EN en respectant le schéma JSON.
2. Adapter culturellement les exemples (Togo → neutres ECOWAS).
3. Appliquer le glossaire terminologique FR → EN (50+ termes).
4. Valider une traduction par enseignant bilingue.

Ce guide complète `ENGLISH_AUDIT_REPORT.md` (audit UI) et
`app_en_content.md` (audit chaîne par chaîne de l'ARB).

## 2. Schéma JSON d'une question bilingue

### 2.1 Schéma FR actuel (avant expansion)

Le fichier `assets/data/questions.json` utilise ce schéma (~300 questions) :

```json
{
  "id": "TG-BEPC-MATHS-2022-Q01",
  "enonce": "Énoncé en français...",
  "reponse": "Réponse en français...",
  "explication": "Explication en français...",
  "matiere": "Mathématiques",
  "chapitre": "Géométrie — Pythagore",
  "competence_id": "TG-MATH-GEO-001",
  "examen": "BEPC",
  "serie": null,
  "annee": 2022,
  "type": "calcul",
  "choix": null,
  "points": 4,
  "irt": {
    "a": null,
    "b": -0.5,
    "c": null,
    "calibre": false
  },
  "figure_id": null,
  "needs_answer": false
}
```

### 2.2 Schéma FR + EN (après expansion)

Ajouter 3 champs optionnels :

```json
{
  "id": "TG-BEPC-MATHS-2022-Q01",
  "enonce": "Énoncé en français...",
  "reponse": "Réponse en français...",
  "explication": "Explication en français...",
  "enonce_en": "Statement in English...",
  "reponse_en": "Answer in English...",
  "explication_en": "Explanation in English...",
  "matiere": "Mathématiques",
  "chapitre": "Géométrie — Pythagore",
  "competence_id": "TG-MATH-GEO-001",
  "examen": "BEPC",
  "serie": null,
  "annee": 2022,
  "type": "calcul",
  "choix": null,
  "choix_en": null,
  "points": 4,
  "irt": {
    "a": null,
    "b": -0.5,
    "c": null,
    "calibre": false
  },
  "figure_id": null,
  "needs_answer": false
}
```

### 2.3 Règles sur les champs EN optionnels

| Champ | Quand l'ajouter | Quand le laisser `null` |
|---|---|---|
| `enonce_en` | Toujours (chaîne non vide) | Jamais (sauf si `needs_answer: true` et `enonce` vide) |
| `reponse_en` | Si `reponse` FR non vide | Si `reponse` FR vide (question à corriger manuellement) |
| `explication_en` | Si `explication` FR non vide | Si `explication` FR vide (souvent OCR non corrigé) |
| `choix_en` | Si `choix` FR non null (QCM) | Si `choix` FR null (question ouverte/calcul/essay) |

**Comportement attendu côté UI** :
- Si `enonce_en` est non null et la locale est `en`, afficher `enonce_en`.
- Sinon, fallback sur `enonce` (français) avec un badge
  « (French only) » discret.
- Cette logique de fallback doit être implémentée dans
  `lib/services/question_service.dart` (hors scope de l'audit CA).

## 3. Procédure de traduction d'une question

### Étape 1 — Identifier le type de question

| Type FR | Type EN | Notes de traduction |
|---|---|---|
| `qcm` | `mcq` | Traduire chaque option du tableau `choix` |
| `vrai_faux` | `true_false` | « Vrai » → « True », « Faux » → « False » |
| `calcul` | `calculation` | Conserver les unités SI (m, kg, s, A, V, Ω, N, Pa, J, W) |
| `ouvert` | `open` | Traduire l'énoncé et la réponse attendue |
| `redaction` | `essay` | Traduire le sujet, laisser la réponse au correcteur |

### Étape 2 — Traduire l'énoncé (`enonce` → `enonce_en`)

Règles :
1. **Préserver toutes les valeurs numériques** : 3 cm → 3 cm (identique).
2. **Préserver les formules mathématiques** : `BC² = AB² + AC²` → identique.
3. **Préserver les unités SI** : m/s, kg, N, V, Ω, W, J, Pa — identiques.
4. **Adapter les exemples culturels** : voir §4 ci-dessous.
5. **Ponctuation** : supprimer l'espace insécable FR avant `:`, `?`, `!`.
6. **Nombres** : en anglais, le séparateur décimal est le point (`.`),
   pas la virgule (`,`). « 0,5 A » → « 0.5 A ». Mais pour les milliers,
   la virgule est conservée : « 2 000 FCFA » → « 2,000 FCFA ».

### Étape 3 — Traduire la réponse (`reponse` → `reponse_en`)

Règles :
1. **Préserver le résultat numérique** : « 5 cm » → « 5 cm ».
2. **Adapter la formulation** :
   - FR : « x = 5 » → EN : « x = 5 » (identique)
   - FR : « La réponse est 5 cm » → EN : « The answer is 5 cm »
   - FR : « U = 10 V » → EN : « U = 10 V » (identique)
3. **Convention poids** : en FR, le poids se note `P` (poids) ;
   en EN, le poids se note `W` (weight) ou `P` (dans certains manuels
   WAEC). Conserver la convention du manuel WAEC local. Par défaut,
   préférer `W` pour la clarté EN.
4. **Unités** : conserver les unités SI. Pour les unités non SI
   (km/h, g/L), conserver telles quelles.

### Étape 4 — Traduire l'explication (`explication` → `explication_en`)

Règles :
1. **Préserver les formules et étapes de calcul** :
   - FR : `BC² = AB² + AC² = 9 + 16 = 25`
   - EN : `BC² = AB² + AC² = 9 + 16 = 25` (identique)
2. **Adapter les connecteurs logiques** :
   - « Donc » → « Therefore » / « So »
   - « Or » → « But » / « Now » (selon contexte)
   - « Car » → « Because » / « Since »
   - « D'après » → « By » / « According to »
   - « D'où » → « Hence » / « Thus »
3. **Théorèmes et lois** :
   - « Théorème de Pythagore » → « Pythagorean theorem »
   - « Théorème de Thalès » → « Intercept theorem » / « Thales's theorem »
   - « Loi d'Ohm » → « Ohm's law »
   - « Lois de Newton » → « Newton's laws of motion »
   - « Loi de la gravitation universelle » → « Law of universal gravitation »
   - « Théorème de Pythagore » → « Pythagorean theorem »
   - « Théorème des milieux » → « Midpoint theorem »
4. **Démonstrations** :
   - « On a » → « We have »
   - « On en déduit » → « We deduce » / « It follows that »
   - « CQFD » → « QED » (quod erat demonstrandum)

### Étape 5 — Traduire les choix QCM (`choix` → `choix_en`)

Si `choix` est un tableau (QCM), traduire chaque option :
```json
"choix": ["24 filles", "20 filles", "16 filles", "30 filles"],
"choix_en": ["24 girls", "20 girls", "16 girls", "30 girls"]
```

**Important** : l'ordre des options doit être identique pour préserver
l'index de la bonne réponse (qui est calculé côté UI).

## 4. Adaptation culturelle (Togo → ECOWAS)

### 4.1 Principe

L'expansion vise Ghana et Nigeria (pays anglophones CEDEAO). Les
exemples togolais (prénoms, lieux, monnaie, contexte) doivent être
adaptés pour être **neutres** et **accessibles** à un élève anglophone
ouest-africain, sans pour autant gommer la spécificité togolaise.

### 4.2 Noms propres dans les énoncés

| Élément FR | Adaptation EN recommandée |
|---|---|
| Prénom togolais (Koffi, Komlan, Afi) | Conserver (également portés au Ghana) ou remplacer par prénom akan/ewe (Kofi, Komla, Ama) — déjà fait dans `app_en.arb` |
| Prénom exclusivement togolais (Kossi, Mawuko) | Remplacer par équivalent akan/ewe plus largement compris (Kwame, Yaa) |
| Ville togolaise (Lomé, Sokodé, Kara) | Conserver (capitales régionales connues) |
| Établissement (Lycée de Tokoin) | Conserver (référence réelle Togo) |
| Monnaie (FCFA) | Conserver (monnaie CEDEAO commune, y compris Ghana pour échanges transfrontaliers) |
| Marché (Grand Marché de Lomé) | Conserver ou remplacer par « local market » si trop spécifique |

### 4.3 Contextes culturels

| Contexte FR | Adaptation EN |
|---|---|
| « Un sac de riz de 50 kg » | « A 50 kg bag of rice » (identique — riz = aliment de base CEDEAO) |
| « Une classe de 40 élèves » | « A class of 40 students » (identique — tailles de classe similaires) |
| « Un champ de maïs » | « A maize field » (« corn » en US English ; « maize » préféré en WAEC) |
| « Un car de voyageurs » | « A passenger bus » (« car » en FR = bus; « car » en EN = voiture) |
| « Le barrage de Nangbéto » | « The Nangbéto dam » (conserver — infrastructure connue Togo) |
| « Le marché de Lomé » | « The Lomé market » (conserver) |
| « Le plateaulet d'Avépozo » | « The Avépozo plateau » (conserver) |

### 4.4 Systèmes de mesure

Tous les systèmes de mesure sont identiques FR/EN (unités SI).
Pas d'adaptation nécessaire.

## 5. Glossaire terminologique FR → EN (référence rapide)

Voir `ENGLISH_AUDIT_REPORT.md` §4 pour le glossaire complet (50+ termes).

Extrait pour la traduction de contenu pédagogique :

| FR | EN | Contexte |
|---|---|---|
| Calculer | Calculate | Énoncé de question |
| Résoudre | Solve | Équation, problème |
| Déterminer | Determine | Question ouverte |
| Justifier | Justify | Démonstration |
| Démontrer | Prove / Show | Démonstration formelle |
| Construire | Construct | Géométrie |
| Représenter | Represent / Draw | Graphique, figure |
| Compléter | Complete | Tableau, phrase |
| Citer | Give / List | Exemples, définitions |
| Définir | Define | Concept |
| Énoncer | State | Loi, théorème |
| Donner | Give | Expression, formule |
| Calculer la valeur de | Calculate the value of | Variable |
| En déduire | Deduce / Hence find | Étape de raisonnement |
| Vérifier | Verify / Check | Calcul de contrôle |
| Comparer | Compare | Deux grandeurs |
| Commenter | Comment / Discuss | Résultat, graphique |

### Verbes et formules mathématiques

| FR | EN |
|---|---|
| additionner | add |
| soustraire | subtract |
| multiplier | multiply |
| diviser | divide |
| factoriser | factorise (UK) / factor (US) |
| développer | expand |
| simplifier | simplify |
| réduire | reduce |
| dériver | differentiate |
| intégrer | integrate |
| résoudre une équation | solve an equation |
| tracer une droite | draw a line |
| placer un point | plot a point |
| lire graphiquement | read from the graph |

### Termes de géométrie

| FR | EN |
|---|---|
| triangle rectangle | right-angled triangle (UK) / right triangle (US) |
| triangle isocèle | isosceles triangle |
| triangle équilatéral | equilateral triangle |
| cercle circonscrit | circumscribed circle |
| cercle inscrit | inscribed circle |
| hauteur | height / altitude |
| médiane | median |
| médiatrice | perpendicular bisector |
| bissectrice | angle bisector |
| diagonale | diagonal |
| parallèle | parallel |
| perpendiculaire | perpendicular |
| angle droit | right angle |
| angle aigu | acute angle |
| angle obtus | obtuse angle |
| hypothénuse | hypotenuse |
| côté adjacent | adjacent side |
| côté opposé | opposite side |
| cosinus | cosine (cos) |
| sinus | sine (sin) |
| tangente | tangent (tan) |

### Termes de physique-chimie

| FR | EN |
|---|---|
| force | force |
| masse | mass |
| poids | weight (W) |
| vitesse | velocity (v) / speed |
| accélération | acceleration (a) |
| énergie | energy (E) |
| puissance | power (P) |
| travail | work (W) |
| tension (électricité) | voltage (U/V) |
| intensité (électrique) | current (I) |
| résistance | resistance (R) |
| pression | pressure (P) |
| température | temperature (T) |
| chaleur | heat (Q) |
| charge électrique | electric charge (Q) |
| champ magnétique | magnetic field (B) |
| réaction chimique | chemical reaction |
| réactif | reactant |
| produit (chimique) | product |
| équation bilan | balanced equation |
| mole | mole (mol) |
| concentration | concentration (C) |
| solution | solution |
| soluté | solute |
| solvant | solvent |
| acide | acid |
| base | base |
| pH | pH |
| oxydation | oxidation |
| réduction | reduction |

## 6. Validation par enseignant bilingue

### 6.1 Critères de validation

Chaque question traduite doit être validée sur :

1. **Fidélité** : la traduction EN couvre-t-elle exactement le même
   périmètre conceptuel que la version FR ? (Pas de concept ajouté
   ou supprimé.)
2. **Naturalité** : la formulation EN est-elle idiomatique pour un
   élève anglophone ouest-africain (préférer anglais britannique +
   termes WAEC) ?
3. **Correctitude scientifique** : les formules, unités, conventions
   sont-elles correctes en EN ? (Ex : poids noté `W` plutôt que `P`
   si confusion possible.)
4. **Adaptation culturelle** : les exemples sont-ils accessibles à un
   élève ghanéen/nigérian sans trahir la spécificité togolaise ?
5. **Cohérence** : les termes sont-ils cohérents avec le glossaire
   (section 5 de ce guide) ?

### 6.2 Procédure de validation

1. **Traduction initiale** : par un traducteur FR/EN (outil LLM ou
   humain).
2. **Relecture scientifique** : par un enseignant bilingue de la
   matière concernée (maths, sciences, etc.).
3. **Test utilisateurs** : soumettre à 3-5 élèves anglophones (Lycée
   Ghana/Nigeria) pour identifier les formulations obscures.
4. **Révision finale** : intégrer les retours, valider la version
   finale.
5. **Versionning** : stocker la version EN dans le même fichier
   `questions.json` (champs `*_en` optionnels), avec un tag
   `_en_validation_status` (`draft` / `reviewed` / `validated`).

### 6.3 Marqueurs de validation (optionnel)

Ajouter au JSON des champs de métadonnées :

```json
{
  "id": "TG-BEPC-MATHS-2022-Q01",
  "enonce": "...",
  "enonce_en": "...",
  "_en_validation_status": "validated",
  "_en_translator": "agent-ca",
  "_en_reviewer": "teacher-bilingual-001",
  "_en_validated_at": "2026-06-15"
}
```

Convention :
- `draft` : traduction automatique ou initiale, non relue.
- `reviewed` : relu par un traducteur humain, corrections appliquées.
- `validated` : validé par enseignant bilingue, prêt pour production.

## 7. Outils recommandés

### 7.1 Traduction assistée par IA

Pour la traduction initiale à grande échelle (~300 questions) :
- **Claude / GPT-4** : bon pour la fidélité conceptuelle, à relire
  pour la naturalité ouest-africaine.
- **DeepL** : excellent pour la fluidité EN, mais moins bon pour
  les formules mathématiques et le contexte pédagogique.
- **Mistral** : bon compromis, surtout pour le français technique.

Prompt-type recommandé :
```
Translate the following French pedagogical question into English
(British English, WAEC context). Preserve all formulas, numbers, and
SI units. Adapt cultural examples to be accessible to a Ghanaian or
Nigerian student. Use the glossary:
- "Sciences Physiques" → "Physical Sciences"
- "Maîtrise" → "Mastery"
- "Compétence" → "Skill"
- "Révision" → "Revision"
- "Simulation d'examen" → "Mock exam"
- "QCM" → "MCQ"
- "Énoncé" → "Question text"
- "Explication" → "Explanation"
- "BEPC", "BAC", "FCFA" → keep as-is

French question:
{enonce}

Return JSON with keys: enonce_en, reponse_en, explication_en.
```

### 7.2 Validation humaine

- **Togo** : enseignants francophones ayant travaillé avec WAEC/GCE.
- **Ghana** : enseignants anglophones du secondaire (Lycée d'Accra,
  Kumasi, Tamale).
- **Nigeria** : enseignants anglophones du secondary school (Lagos,
  Abuja, Kano).

### 7.3 Outillage de contrôle qualité

- **Script Python** : vérifier que toutes les questions avec
  `enonce_en` non vide ont aussi `reponse_en` et `explication_en`
  (cohérence).
- **Script de check du glossaire** : vérifier qu'aucune occurrence
  de « Physics » seule (sans « Physical Sciences ») n'apparaît dans
  les nouveaux contenus EN.
- **Lint JSON** : `python3 -c "import json; json.load(open('questions.json'))"`
  pour valider la syntaxe.

## 8. Workflow d'ajout d'une nouvelle question bilingue

### Étape 1 — Rédiger la version FR

Suivre le format existant (`assets/data/questions.json`). Attribuer
un `id` unique selon la convention : `TG-{EXAMEN}-{MATIERE}-{ANNEE}-Q{NN}`.

### Étape 2 — Traduire en EN

Appliquer la procédure de la section 3. Utiliser le glossaire de la
section 5. Adapter culturellement (section 4).

### Étape 3 — Ajouter au JSON

Insérer la question dans `assets/data/questions.json` avec les 6
champs FR + 3 champs EN (ou 4 si QCM avec `choix_en`). Ajouter
`_en_validation_status: "draft"` pour traçabilité.

### Étape 4 — Faire relire

Soumettre à un enseignant bilingue. Une fois validée, passer
`_en_validation_status` à `validated`.

### Étape 5 — Tester en UI

Lancer l'app en locale EN, naviguer jusqu'à la question, vérifier
l'affichage. Corriger les soucis de formatage (formules, sauts de
ligne, unités).

## 9. Exemple complet

Voir `english_questions_sample.json` pour 10 exemples complets
(5 BEPC Maths, 3 BEPC Sciences, 2 BAC Maths) avec les 6 champs FR +
3 champs EN.

Extrait :

```json
{
  "id": "TG-BEPC-MATHS-2022-Q01",
  "enonce": "Un triangle ABC est rectangle en A. AB = 3 cm, AC = 4 cm. Calculer la longueur BC.",
  "reponse": "BC = 5 cm",
  "explication": "D'après le théorème de Pythagore, BC² = AB² + AC² = 9 + 16 = 25. Donc BC = 5 cm.",
  "enonce_en": "A right-angled triangle ABC has its right angle at A. AB = 3 cm, AC = 4 cm. Calculate the length of BC.",
  "reponse_en": "BC = 5 cm",
  "explication_en": "By the Pythagorean theorem, BC² = AB² + AC² = 9 + 16 = 25. Therefore BC = 5 cm.",
  "matiere": "Mathématiques",
  "chapitre": "Géométrie — Pythagore",
  "competence_id": "TG-MATH-GEO-001",
  "examen": "BEPC",
  "serie": null,
  "annee": 2022,
  "type": "calcul",
  "choix": null,
  "choix_en": null,
  "points": 4,
  "irt": { "a": null, "b": -0.5, "c": null, "calibre": false },
  "figure_id": null,
  "needs_answer": false,
  "_en_validation_status": "draft",
  "_en_translator": "agent-ca"
}
```

## 10. Maintenance du glossaire

Le glossaire (section 5 de ce guide et section 4 de
`ENGLISH_AUDIT_REPORT.md`) doit être maintenu vivant :

- **Ajout** : quand un nouveau terme FR apparaît dans le contenu
  pédagogique, l'ajouter au glossaire avec sa traduction EN retenue.
- **Révision** : trimestriellement, revoir les traductions EN à la
  lumière des retours d'enseignants bilingues.
- **Versionning** : le glossaire est stocké dans ce fichier Markdown
  (pas de table externe) pour faciliter l'édition collaborative.

## 11. Conclusion

Ce guide fournit le cadre complet pour étendre la version anglaise
d'ExamBoost Togo au contenu pédagogique (questions, corrections,
explications). En suivant ce guide, un traducteur ou un agent IA
peut produire des questions bilingues cohérentes, naturelles et
validables par des enseignants bilingues ouest-africains.

La procédure type est :
1. Traduction initiale (LLM ou humain).
2. Relecture scientifique (enseignant bilingue).
3. Test utilisateurs (élèves anglophones).
4. Validation finale (`_en_validation_status: "validated"`).
5. Mise en production dans `questions.json`.

L'échantillon de 10 questions (`english_questions_sample.json`)
démontre la conformité au schéma et la qualité attendue.
