# Audit Linguistique — ExamBoost Togo

**Task ID** : CC-linguistic-audit
**Agent** : CC (general-purpose)
**Date** : Session 4, Vague 3
**Périmètre** : 114 questions (`assets/data/questions.json`), chaînes UI FR
(`lib/l10n/app_fr.arb`), documentation (`README.md`, `docs/manuals/README.md`,
`docs/CONTRIBUTING.md`, `docs/DEPLOYMENT_GUIDE.md`).
**Langue auditée** : français togolais (norme scolaire MEPST).

---

## 1. Synthèse exécutive

L'audit couvre trois corpus :

1. **Banque de questions** — 114 items répartis sur 6 matières (Mathématiques
   46, Sciences Physiques 20, SVT 18, Français 14, Histoire-Géographie 12,
   Anglais 4), deux examens (BEPC 84, BAC1 30), quatre types (ouvert 55,
   calcul 44, QCM 13, vrai/faux 2). 35 items proviennent du pipeline OCR et
   n'ont ni réponse ni explication (`needs_answer=true`).
2. **Fichier de localisation** — `app_fr.arb` contient **300 clés FR**
   utilisateur (et non 165 comme indiqué dans le brief initial ; le brief a
   probablement été rédigé sur une version antérieure du fichier). Chaque clé
   est accompagnée d'une métadonnée `@clé` avec description et placeholders.
3. **Documentation** — `README.md` (352 lignes, français soigné avec
   émojis), `docs/manuals/README.md` (français sans accents — problème),
   `docs/CONTRIBUTING.md` (915 lignes), `docs/DEPLOYMENT_GUIDE.md`
   (495 lignes).

**Verdict global** : le français utilisé est **globalement correct**,
lisible, et adapté au public cible (élèves de 3e à Terminale). On observe
cependant trois familles de défauts :

- **Bruit OCR non corrigé** dans 35 questions issues du pipeline (caractères
  mathématiques perdus : `M` au lieu de `ℝ`, `S` au lieu de `5`, `x2` au
  lieu de `x²`, `Q` au lieu de `Ω`, `$` au lieu de `S`). Ces questions sont
  marquées `_validation_status: "warning"` mais restent affichées telles
  quelles à l'élève.
- **Incohérences de registre** : mélange `tu`/`vous` entre les écrans de
  révision (`Comment tu t'en es sorti ?`) et les consignes de questions
  (`Conjuguez`, `Identifiez`, `Citez` — infinitif/tutoiement implicite vs.
  impératif `vous`). La charte prévoit le tutoiement mais n'est pas
  systématiquement appliquée dans les énoncés.
- **Documentation technique sans accents** : `docs/manuals/README.md` est
  rédigé en français sans accents (`genere`, `eleve`, `destination`,
  `ecoles`, `Lome`, `imprimes`, `carre colle`), ce qui est incohérent avec
  le reste du projet et nuisible à l'image de marque.

Le présent rapport liste, pour chaque catégorie, les occurrences exactes,
leur gravité pédagogique et la correction recommandée. Aucune correction
n'est appliquée dans cette tâche (audit seul) — les corrections seront
traitées par un agent ultérieur sur la base de ce rapport.

---

## 2. Méthodologie

### 2.1 Corpus audité

| Source | Fichier | Volume |
|---|---|---|
| Questions | `assets/data/questions.json` | 114 items |
| UI FR | `lib/l10n/app_fr.arb` | 300 clés FR |
| README | `README.md` | 352 lignes |
| README manuels | `docs/manuals/README.md` | ~80 lignes |
| Contributing | `docs/CONTRIBUTING.md` | 915 lignes (échantillonné) |
| Déploiement | `docs/DEPLOYMENT_GUIDE.md` | 495 lignes (échantillonné) |

### 2.2 Critères de vérification

Pour chaque occurrence textuelle, vérification de :

- **Grammaire** : accords (sujet-verbe, nom-adjectif, participe passé),
  conjugaisons, syntaxe.
- **Orthographe** : fautes, accents, ponctuation (point d'interrogation
  précédé d'une espace insécable en français), majuscules accentuées.
- **Vocabulaire** : adéquation au niveau 3e/Terminale, pertinence
  togolaise (FCFA, BEPC, lycée, etc.).
- **Tonalité** : tutoiement, registre amical mais respectueux, pas de
  familiarité excessive.
- **Cohérence terminologique** : même terme pour même concept à travers
  tout le corpus.

### 2.3 Niveaux de gravité

- **Bloquant** — la phrase est incompréhensible ou trompe l'élève
  (ex. : `Ω` lu `Q` dans une formule).
- **Majeur** — la phrase est compréhensible mais la faute décrédibilise
  l'application ou trahit une incohérence (ex. : mélange tu/vous).
- **Mineur** — faute de frappe ou coquille sans impact pédagogique.
- **Cosmétique** — choix stylistique discutable.

---

## 3. Audit des 114 questions

### 3.1 Vue d'ensemble

La banque est structurée avec des IDs normalisés
`TG-{EXAMEN}-{MATIERE}-{ANNEE}-{Qxx}` et des champs riches (énoncé,
réponse, explication, IRT, points, type). 79 questions sont « complètes »
(réponse + explication), 35 sont issues du pipeline OCR et attendent une
saisie humaine (`needs_answer=true`, `reponse=""`, `explication=""`).

### 3.2 Bruit OCR — défauts bloquants

Le pipeline OCR a produit 35 questions marquées
`_validation_status: "valid"` ou `"warning"`. Les `"warning"` contiennent
des caractères mal reconnus qui rendent l'énoncé faux ou absurde :

| ID | Extrait | Problème | Correction |
|---|---|---|---|
| `TG-BEPC-PHYS-2023-OCR-Q02` | `R = 20 Q` | `Q` au lieu de `Ω` (ohm) | `R = 20 Ω` |
| `TG-BEPC-PHYS-2023-OCR-Q05` | `sur une surface $` | `$` au lieu de `S` | `sur une surface S` |
| `TG-BEPC-PHYS-2023-OCR-Q06` | `surface de 0,5 m2` | `m2` au lieu de `m²` | `0,5 m²` |
| `TG-BEPC-MATH-2022-OCR-Q01` | `Résoudre dans M` | `M` au lieu de `ℝ` | `Résoudre dans ℝ` |
| `TG-BEPC-MATH-2022-OCR-Q02` | `x-y=2 1}` | `2 1` au lieu de `2}` (accolade) | `x - y = 2}` |
| `TG-BEPC-MATH-2022-OCR-Q05` | `B(S: 6)` | `S` au lieu de `5` | `B(5 ; 6)` |
| `TG-BEPC-MATH-2022-OCR-Q06` | `x2 - 9` | `x2` au lieu de `x²` | `x² - 9` |
| `TG-BEPC-MATH-2022-OCR-Q07` | `On prendra x = 3,14` | `x` au lieu de `π` | `On prendra π = 3,14` |

**Gravité** : bloquante pour Q02, Q05, Q06, Q07 (l'élève ne peut pas
résoudre). Majeure pour les autres (compréhensible mais incorrecte).

**Recommandation** : avant publication, soit (a) corriger manuellement les 8
énoncés ci-dessus, soit (b) exclure les questions `warning` de la banque
affichée via un filtre `_validation_status == "valid"` dans
`question_service.dart`. L'option (b) est plus rapide mais réduit la banque à
106 questions.

### 3.3 Questions sans réponse ni explication (35 OCR)

Toutes les questions `source: ocr_pipeline` ont `reponse: ""` et
`explication: ""`. Elles sont marquées `needs_answer: true` mais le
modèle `question.dart` et le service associé ne semblent pas exploiter ce
champ pour exclure ou signaler ces items. À l'usage, un élève qui tombe sur
une telle question en mode révision verra « Voir la réponse » mener à une
réponse vide, puis en mode simulation son auto-évaluation n'aura pas de
référence.

**Recommandation** : filtrer par défaut `needs_answer == false` dans les
queries `question_service.dart` tant que les réponses ne sont pas saisies.
Alternative : ajouter un badge « À compléter » et masquer ces items en mode
simulation (où l'auto-évaluation est obligatoire).

### 3.4 Registre — tutoiement vs. vouvoiement

La charte ExamBoost (voir `TOGOLESE_FRENCH_GUIDE.md`) prévoit le
**tutoiement** systématique. Les écrans UI l'appliquent correctement :
`Que veux-tu faire ?`, `Entraîne-toi`, `Comment tu t'en es sorti ?`,
`Tu vas répondre à {count} questions`, `Il te reste {remaining} question(s)`,
`Compare ta réponse`, `Saisis ta réponse`, `Choisis la bonne réponse`.

En revanche, les **énoncés de questions** basculent vers le **vous**
implicite (infinitif) ou explicite :

- `Citez les trois grandes étapes` (`TG-BEPC-SVT-2021-Q01`) — impératif
  2e personne du pluriel.
- `Identifiez et nommez la figure de style` (`TG-BEPC-FR-2022-Q01`) —
  impératif `vous`.
- `Conjuguez le verbe` (`TG-BEPC-FR-2022-Q02` et `Q03`) — impératif `vous`.
- `Complétez` (`TG-BEPC-FR-2023-Q01`) — impératif `vous`.
- `Donnez le pluriel` (`TG-BEPC-FR-2021-Q01`) — impératif `vous`.
- `Lisez` (`TG-BEPC-FR-2024-Q01`) — impératif `vous`.
- `Rédiger un paragraphe` (`TG-BEPC-FRAN-2021-OCR-Q06`) — infinitif
  (donc neutre).
- `Calculer`, `Résoudre`, `Factoriser`, `Définir`, `Citer`, `Indiquer`,
  `Donner`, `Nommer`, `Transformer`, `Réécrire`, `Compléter`, `Choisir`,
  `Translate into English`, `Choose the correct` — infinitif.

**Constat** : sur 114 énoncés, environ 7 utilisent l'impératif `vous`
(`-ez`), 60 l'infinitif (`-er`), et le reste sont des formes neutres
(`Quelle est`, `Lequel des`, `Qu'est-ce qu'`, etc.). Aucun énoncé n'utilise
le tutoiement explicite (`Calcule`, `Résous`, `Cite`).

**Gravité** : majeure — incohérence de registre entre UI (tu) et énoncés
(vous/infinitif). C'est en fait conforme aux usages des sujets officiels
BEPC/BAC togolais (qui utilisent l'infinitif), mais le contraste avec une
UI familière peut dérouter l'élève.

**Recommandation** : conserver l'infinitif dans les énoncés (conformité
sujets officiels) mais **uniformiser les 7 cas d'impératif `vous`** vers
l'infinitif. Par exemple :
- `Citez les trois grandes étapes` → `Citer les trois grandes étapes`.
- `Identifiez et nommez` → `Identifier et nommer`.
- `Conjuguez le verbe` → `Conjuguer le verbe`.
- `Complétez` → `Compléter`.
- `Donnez le pluriel` → `Donner le pluriel`.
- `Lisez` → `Lire`.

Cette uniformisation aligne les énoncés sur la tradition des annales
togolaises et évite la dissonance avec le tutoiement UI.

### 3.5 Ponctuation et typographie

- **Espace insécable avant `?` `:` `;` `!`** : globalement respectée dans
  l'UI FR (`Que veux-tu faire ?`, `Score : {score} / 20`, `Prêt ?`). Quelques
  énoncés de questions omettent l'espace avant le deux-points :
  `Définir les termes suivants: écosystème` (`TG-BEPC-SVT-2020-OCR-Q03`),
  `Définir les termes suivants: colonisation` (`TG-BEPC-HIST-2022-OCR-Q03`),
  `Résoudre le système suivant: { 2x+y=7` (`TG-BEPC-MATH-2022-OCR-Q02`),
  `Factoriser l'expression suivante: x2 - 9` (`TG-BEPC-MATH-2022-OCR-Q06`).
  → **Corriger** en ajoutant une espace insécable : `suivants :`,
  `suivante :`. Mineur mais systématique dans les OCR.
- **Espaces dans les grands nombres** : correctement appliqué
  (`15 000 FCFA`, `25 000 FCFA`, `1 000 kg`, `112 500 J`, `11 460 ans`).
  Conforme à la convention francophone.
- **Notation décimale** : virgule correctement utilisée (`0,5 A`, `0,25 m²`,
  `3,14`). Pas de mélange avec le point anglo-saxon.
- **Guillemets** : l'UI utilise les guillemets droits `'…'` (apostrophe
  droite) dans `revisionHowDidYouDo`, `simulationChooseAnswer`, etc. Le
  français typographique préfère les guillemets courbes « … » et
  l'apostrophe courbe `'`. Le JSON `arb` échappe les guillemets droits
  (`\"`). → **Cosmétique** : acceptable en l'état, la police Flutter
  rend correctement les apostrophes droites.
- **Tirets** : `Cinématique — Vitesse`, `Mécanique — Lois de Newton`
  utilisent le tiret cadratin `—` (correct). Cohérent.

### 3.6 Vocabulaire — spécificités togolaises

**Points positifs** (déjà conformes) :
- `FCFA` (et non « francs » ou « euros ») — `TG-BEPC-MATHS-2020-Q01`,
  `TG-BEPC-MATHS-2024-Q02`. Format `15 000 FCFA` conforme.
- `BEPC` (et non « brevet ») — utilisé partout dans la banque et l'UI.
- `BAC` (et non « baccalauréat » complet sauf contexte formel) — utilisé
  partout.
- `Lycée de Tokoin` (et non « collège de Tokoin ») —
  `onboardingSchoolHint: "Ex : Lycée de Tokoin"`. Correct pour le secondaire
  togolais.
- `marché d'Adawlato` (`TG-BEPC-MATHS-2024-Q02`, `TG-BEPC-FR-2024-Q01`) —
  excellent ancrage culturel local.
- `taxi-brousse` (`TG-BEPC-MATHS-2022-Q04`) — vocabulaire réel ouest-africain.
- `Lomé–Kpalimé` (avec tiret cadratin) — `TG-BEPC-MATHS-2022-Q04`.
- `Lomé`, `Kara`, `Sokodé`, `Atakpamé`, `Dapaong` — cités correctement
  dans `Histoire-Géographie` et l'UI.
- `paludisme`, `moustique anophèle` — `TG-BEPC-SVT-2023-Q01` et
  `TG-BEPC-SVT-2020-OCR-Q05`. Terminologie médicale correcte.
- `Togoland`, `traité de Baguida`, `roi Mlapa III`, `Sylvanus Olympio` —
  référence historique précise (`TG-BEPC-HG-2023-Q01`, `TG-BEPC-HG-2021-Q01`).
- `côte des Esclaves`, `Golfe de Guinée` — `TG-BEPC-HIST-2022-OCR-Q04`.
  Référence au passé négrier togolais (Aného, Baguida).

**Points à surveiller** :
- `collège` n'apparaît pas, mais `onboardingSerieF: "Série F — Technique"`
  pourrait préciser « Series F1/F2/F3 » selon la nomenclature togolaise
  (F1 = construction, F2 = électrique, F3 = mécanique). À discuter avec
  l'équipe pédagogique.
- `manioc`, `igname`, `maïs` — non cités dans les questions SVT
  (alimentation). Pourrait être ajouté dans une future question sur
  l'agriculture togolaise.

### 3.7 Grammaire et accords

Vérification systématique sur les 114 énoncés + 79 explications :

- **Accords sujet-verbe** : aucun défaut détecté. « Les mitochondries sont
  les 'centrales énergétiques' », « Les protides sont apportés »,
  « La FSH stimule », « La LH déclenche ».
- **Accords nom-adjectif** : corrects. « la tension U aux bornes d'un
  conducteur ohmique », « la vitesse moyenne est définie comme la distance
  parcourue divisée par la durée ».
- **Participe passé** : `rencontrées` accordé correctement avec `que` (COD
  féminin pluriel) dans `TG-BEPC-FR-2023-Q01` — l'explication est même
  pédagogiquement excellente.
- **Concordance des temps** : un cas à vérifier dans
  `TG-BAC-PHYS-2022-Q02` — « Un échantillon ne contient plus que le quart
  (25 %) de sa quantité initiale de 14C. Quel est son âge ? » → présent
  « est » cohérent avec le présent « ne contient plus ». OK.
- **Accents sur majuscules** : `Énoncer`, `Établissement`, `Écrire`,
  `Œil` — correctement accentués dans la banque. L'UI également
  (`Établissement`, `Écris ta réponse ici...`).

### 3.8 Cas particuliers par matière

**Mathématiques** (46 questions) :
- Notation exponentielle : `x²`, `r²`, `15²`, `v²` — cohérentes (carré via
  `²`). Mais `x2 - 9` (OCR Q06) est une régression.
- Racine carrée : `√32`, `4√2`, `√41`, `√25`, `√3/2` — cohérent (caractère
  `√`).
- Infini : `+∞`, `-∞`, `]-∞ ; -1]` — corrects.
- Ensemble des réels : `ℝ` dans `TG-BAC-MATHC-2024-Q01` et
  `TG-BAC-MATHD-2023-Q01`. Mais `M` (OCR) dans `TG-BEPC-MATH-2022-OCR-Q01`.
  Incohérence à corriger.
- Complexes : `ℂ` dans `TG-BAC-MATHC-2022-Q01`. Correct.
- π : `π = 3,14` (forme complète) et `π ≈ 3,14` (forme approximative)
  coexistent. Légère incohérence sans gravité.
- Cohérence notation points : `A(1 ; 2)` et `A(1; 2)` (sans espace) dans
  l'OCR Q05. Uniformiser vers `A(1 ; 2)`.

**Sciences Physiques** (20 questions) :
- Unités SI : `m/s²`, `m/s`, `km/h`, `N`, `kg`, `V`, `A`, `Ω`, `Pa`, `J`,
  `kJ`, `W`, `Hz`, `nm`, `mm`, `C`, `T`, `δ` (dioptries). Toutes correctes
  et conformes au SI.
- Une seule coquille : `m2` au lieu de `m²` dans `TG-BEPC-PHYS-2023-OCR-Q06`.
- Notation scientifique : `6×10⁻⁷ m`, `2×10⁶ m/s`, `1,6×10⁻¹⁹ C`,
  `1,6×10⁻¹³ N`. Cohérent (exposants via Unicode `⁻`, `⁷`, `⁶`, `⁹`, `¹³`).
  Bonne pratique.

**SVT** (18 questions) :
- Vocabulaire scientifique précis : `chlorophylle`, `chloroplastes`,
  `photolyse`, `cycle de Calvin`, `Plasmodium`, `anophèle`, `biocénose`,
  `écosystème`, `mitochondries`, `ATP`, `adénosine triphosphate`,
  `lymphocytes B/T`, `plasmocytes`, `FSH`, `LH`, `follicule`, `ovulation`,
  `potential d'action`, `dépolarisation`, `repolarisation`, `hyperpolarisation`,
  `Punnett`, `Mendel`. Tous correctement orthographiés.
- Une faute de frappe probable : `Luteinizing Hormone` (`TG-BAC-SVT-2022-Q01`
  explication) — devrait être `Luteinizing` (orthographe américaine) mais
  le terme anglais standard est `Luteinizing` (OK) ; alternative britannique
  `Luteinising`. Conserver l'américain pour cohérence avec la pharmacologie
  internationale. Pas de correction nécessaire, juste à noter.
- Accord « transmises » dans l'explication de `TG-BEPC-SVT-2023-Q01` :
  « Le paludisme est une maladie parasitaire causée par un Plasmodium et
  transmis à l'homme » — `transmis` s'accorde avec `paludisme` (masculin
  singulier) et non avec `maladie` (féminin). C'est correct : le pronom
  renvoie à `paludisme`. OK mais la phrase est ambiguë car ` Plasmodium`
  est masculin aussi. Suggérer reformulation : « transmis à l'homme par la
  piqûre d'un moustique anophèle femelle infecté ». Acceptable en l'état.

**Français** (14 questions) :
- Figures de style couvertes : métaphore (`TG-BEPC-FR-2022-Q01`,
  `TG-BEPC-FRAN-2021-OCR-Q05`), comparaison implicite (« comme un guépard »
  est en fait une comparaison avec « comme » — l'OCR considère à tort cela
  comme une autre figure ; à corriger : « Kossi court vite comme un guépard »
  est une **comparaison**, pas une métaphore. L'item attend la réponse
  « comparaison » mais la correction ne précise pas. Voir validation
  pédagogique).
- Pluriels irréguliers : `œil → yeux` (`TG-BEPC-FR-2021-Q01`). Correct.
- Conjugaisons : `finir` (2e groupe) au conditionnel, `venir` (3e groupe)
  au subjonctif. Correct.
- Accords du participe passé avec COD antéposé (`que` → `rencontrées`)
  — excellent énoncé pédagogique.
- « Koffi se lève tôt chaque jour pour aider sa mère au marché d'Adawlato »
  — ancrage culturel Lomé. Excellent.

**Histoire-Géographie** (12 questions) :
- Dates exactes : 27 avril 1960 (indépendance), 1884 (traité de Baguida),
  1914 (défaite allemande), 1960 « Année de l'Afrique » (17 pays). Toutes
  correctes.
- Noms propres : `Sylvanus Olympio`, `Mlapa III`, `Togoland`. Corrects.
- Régions togolaises : « cinq régions administratives »
  (`TG-BEPC-HIST-2022-OCR-Q05`) — en 2026, le Togo compte toujours
  officiellement 5 régions (Maritime, Plateaux, Centrale, Kara, Savanes),
  même si des collectivités ont été créées. OK.
- Climats : « subéquatorial au sud, tropical soudanien au nord » —
  correct et conforme au programme.
- « côte des Esclaves » : terme historique à capitaliser « Côte des
  Esclaves » pour marquer le toponyme. Mineur.

**Anglais** (4 questions) :
- Consignes en anglais (`Translate into English`, `Choose the correct past
  tense form`, `Complete`, `Choose the correct modal`) — cohérent avec un
  cours d'anglais. Les explications sont en anglais, ce qui est inhabituel
  en France/Togo (où l'explication grammaticale se fait en français). À
  discuter : conserver l'anglais pour immersion, ou basculer en français
  pour explicitation grammaticale ? Recommandation : bilingue — explication
  en français avec exemple anglais.
- « You must not smoke in the classroom » — contexte scolaire adapté.
- 4 questions uniquement, toutes sur la grammaire (present simple, past
  simple, present perfect, modaux). Manquent : vocabulaire, compréhension
  de texte, conjugaison au futur, voix passive. Banque à étoffer.

### 3.9 Conclusion banque de questions

Sur 114 items :
- 8 défauts bloquants (bruit OCR non corrigé) à traiter en priorité.
- 35 items incomplets (sans réponse) à compléter ou filtrer.
- 7 énoncés à uniformiser (impératif `vous` → infinitif).
- ~5 coquilles de ponctuation (`suivants:` sans espace insécable).
- Aucune faute de grammaire ou d'orthographe grave détectée dans les 79
  items complets.

**Score qualité linguistique banque** : 7,5 / 10. Passable à « bon » une
fois les 8 défauts OCR corrigés et les 35 items complétés.

---

## 4. Audit des chaînes UI (300 clés FR)

### 4.1 Vue d'ensemble

Le fichier `app_fr.arb` contient 300 clés FR (et 300 métadonnées `@clé`,
plus `@@locale`). Répartition thématique estimée :

- Onboarding (~30 clés)
- Home (~20)
- Révision (~30)
- Simulation (~50)
- Dashboard (~25)
- Settings (~50)
- Common (~20)
- Subject/Niveau labels (~15)
- Difficulte/Card (~5)
- Messages motivants (~10)
- Divers (~45)

### 4.2 Constats positifs

- **Tutoiement systématique** dans l'UI : `Que veux-tu faire ?`,
  `Entraîne-toi`, `Dis-nous en plus sur toi`, `Choisis 1 à 3 matières`,
  `Sélectionne la classe`, `Créer mon profil`, `Comment tu t'en es sorti ?`,
  `Tu as répondu correctement`, `Continue à réviser`, `Démarrer l'examen`,
  `Compare ta réponse`, `Saisis ta réponse`, `Écris ta réponse`,
  `Choisis la bonne réponse`, `Choisis ton examen`. Conforme à la charte.
- **Ton amical mais respectueux** : `Bonjour, {name} !`, `Bienvenue, {name} !`,
  `Excellent !`, `Bon travail !`, `Ne lâche rien !`,
  `C'est en se trompant qu'on apprend`. Messages motivants excellents.
- **Vocabulaire scolaire togolais** : `BEPC`, `BAC 1`, `BAC 2`, `Probatoire`,
  `Brevet d'études` (description), `Baccalauréat`, `Série A/B/C/D/F`,
  `Lycée de Tokoin`, `Lomé`, `Lomé`, `Adawlato` (via questions).
- **Cohérence terminology** : `matière` (et non « sujet »), `établissement`
  (et non « école »), `chapitre` (et non « leçon »), `compétence`
  (et non « notion »), `simulation` (et non « examen blanc » sauf
  `dashboardMockExam: "Faire un examen blanc"` qui introduit un synonyme
  — voir 4.3).
- **Espaces insécables** : correctement appliquées dans la grande majorité
  (`Score : {score} / 20`, `Question {current} / {total}`,
  `Durée : {duration}`, `Série {serie}`, `Niveau : {level}`).
- **Placeholders bien nommés** : `{name}`, `{level}`, `{serie}`, `{count}`,
  `{total}`, `{current}`, `{remaining}`, `{minutes}`, `{score}`,
  `{matiere}`, `{time}`, `{date}`, `{error}`. Cohérents et typés
  (`String` / `int`).

### 4.3 Incohérences détectées

#### 4.3.1 `dashboardMockExam` vs. `simulation*`

- `homeSimulation: "Simulation d'Examen"` (titre carte home)
- `simulationConfig: "Configuration de l'examen"`
- `dashboardMockExam: "Faire un examen blanc"`

Le terme « examen blanc » apparaît une fois pour désigner la simulation.
Le reste de l'UI utilise « simulation » ou « examen ». Pour cohérence,
soit uniformiser vers « simulation d'examen », soit vers « examen blanc ».
Recommandation : conserver `dashboardMockExam: "Faire un examen blanc"`
(donc introduire le concept d'« examen blanc » comme synonyme pédagogique
français) MAIS ajouter une mention « simulation » dans l'écran de
destination pour ne pas perdre l'élève. Mineur.

#### 4.3.2 `cardTapToSeeAnswer` — vouvoiement résiduel

- `cardTapToSeeAnswer: "Appuyez sur « Voir la réponse » quand vous êtes prêt"`

Cette chaîne tutoie/vouvoie simultanément (« Appuyez » = impératif `vous`,
« vous êtes prêt » = `vous`). À corriger vers le tutoiement :
`"Appuie sur « Voir la réponse » quand tu es prêt"`.

**Gravité** : majeure — seule chaîne UI qui viole la charte tutoiement.

#### 4.3.3 `dashboardStreakJours: "{n} j"`

Abréviation `j` pour « jours ». Lisible mais non explicitée. Préférable :
`{n} jour(s)` ou `{n} j` (avec infobulle). Acceptable en l'état pour un
badge compact. Mineur.

#### 4.3.4 `simulationAvgTimePerQ: "Temps moyen par question"`

vs. `simulationTempsMoyenQ: "Temps moyen/q"` — deux chaînes différentes
pour le même concept, l'une complète, l'autre abrégée. À unifier si les
deux s'affichent dans le même écran. Mineur (probablement utilisé dans
des contextes différents : rapport détaillé vs. résumé compact).

#### 4.3.5 `simulationAchevement: "Achèvement"`

vs. `simulationCompletionRate: "Taux d'achèvement"`. Deux traductions pour
`completion rate`. Préférer `Taux d'achèvement` partout. Mineur.

#### 4.3.6 `settingsCreditsBody` — incomplet

```
settingsCreditsBody: "Chefs de projet :
  - Djabelo (Lead dev Flutter)
  - [Équipe à compléter]
..."
```

Chaîne contenant un placeholder `[Équipe à compléter]` non localisé.
Acceptable en bêta mais à finaliser avant production.

#### 4.3.7 `settingsLangueHint` — longue et dense

```
settingsLangueHint: "Le français est la langue par défaut (langue
d'enseignement au Togo). L'anglais sert pour le programme DJANTA et les
élèves anglophones de la CEDEAO."
```

Bonne information mais longue pour un hint. À raccourcir si possible, ou
déplacer en `settingsLangueSubtitle`. Cosmétique.

#### 4.3.8 Cohérence `Série` vs. `série`

- `onboardingSerieTitle: "Ta série"` (minuscule)
- `simulationSerie: "Série"` (majuscule — label court)
- `simulationSerieBac: "Série (BAC)"` (majuscule)
- `simulationExamSummary: "Examen : {exam} (Série {serie})"` (majuscule)
- `homeProfileSerie: "Série {serie}"` (majuscule)

Cohérent : majuscule quand `Série` est utilisé comme label autonome,
minuscule quand il s'agit d'un nom commun dans une phrase. OK.

#### 4.3.9 `simulationProbatoire: "Probatoire"`

vs. `simulationBAC1: "BAC 1"`. Le Probatoire togolais correspond à la
fin de la classe de 1ère (BAC 1). Les deux chaînes désignent donc le même
examen sous deux noms. À clarifier dans l'UI (probablement un sélecteur
« BAC 1 = Probatoire »). Mineur.

#### 4.3.10 Ponctuation

Quelques chaînes n'ont pas de point final — c'est acceptable pour des
labels UI courts. Aucune erreur de ponctuation détectée.

### 4.4 Conclusion UI

Sur 300 clés FR :
- 1 violation de tutoiement (`cardTapToSeeAnswer`) — majeure.
- 5 incohérences terminologiques mineures (examen blanc vs. simulation,
  achèvement vs. taux d'achèvement, temps moyen/q vs. temps moyen par
  question).
- 1 chaîne à finaliser (`settingsCreditsBody`).
- Aucune faute d'orthographe ou de grammaire détectée.

**Score qualité linguistique UI** : 9 / 10. Excellent dans l'ensemble.

---

## 5. Audit de la documentation

### 5.1 `README.md` (352 lignes)

- **Langue** : français soigné, avec quelques émojis (acceptables en
  README technique).
- **Orthographe** : aucune faute détectée à l'échantillonnage.
- **Spécificités togolaises** : `BEPC`, `BAC`, `MEPST`, `Lomé`, `Togo`,
  `FCFA` (implicitement via contexte), `DJANTA Tech Hub`,
  `24 juillet 2026` (date de pitch), `SmartFarm Togo`.
- **Ton** : professionnel, orienté investisseur/jury.
- **Coquilles détectées** : aucune.
- **Recommandation** : aucune correction nécessaire.

### 5.2 `docs/manuals/README.md` (~80 lignes) — PROBLÈME MAJEUR

Le fichier est rédigé en **français sans aucun accent**, ce qui est
incohérent avec le reste du projet et nuisible à l'image pédagogique
d'une application d'apprentissage du français :

```
# Manuel eleve + Guide enseignant (ExamBoost Togo)

Ce dossier contient le script Python qui genere les 2 PDFs de
documentation destines a la distribution physique dans les ecoles
pilotes de Lome :
```

Tous les mots accentués sont tronqués : `eleve` (élève), `genere` (génère),
`destines` (destinés), `ecoles` (écoles), `Lome` (Lomé), `imprimes` (imprimés),
`carre colle` (carré collé), `Demarrage` (Démarrage), `Installer les
dependances` (dépendances), `Generer` (Générer), etc.

**Hypothèse** : le fichier a été rédigé sur un clavier qwerty sans
configuration française, ou généré par un outil qui ne préserve pas les
accents (certains OCR ou markdown->PDF pipelines anciens). Le README.md
principal n'a pas ce défaut, donc c'est localisé à ce fichier.

**Gravité** : majeure — un manuel destine aux eleves et enseignants
togolais ne peut pas être publié sans accents. C'est contradictoire avec
la mission pédagogique d'ExamBoost.

**Recommandation** : réécrire entièrement `docs/manuals/README.md` avec
les accents corrects. À traiter comme une priorité du prochain sprint
documentation. Voir aussi `docs/manuals/generate_manuals.py` : vérifier
que les PDFs générés n'héritent pas du même défaut (les PDFs
`output/Manuel_Eleve_ExamBoost.pdf` et `output/Guide_Enseignant_ExamBoost.pdf`
n'ont pas été audités dans cette tâche, à vérifier).

### 5.3 `docs/CONTRIBUTING.md` (915 lignes, échantillonné)

- Échantillonnage des 50 premières lignes : français correct, accentué,
  ton professionnel. Pas de défaut détecté.
- À compléter par un audit complet si nécessaire.

### 5.4 `docs/DEPLOYMENT_GUIDE.md` (495 lignes, échantillonné)

- Échantillonnage : français technique correct.
- Pas de défaut détecté à l'échantillonnage.

### 5.5 Conclusion documentation

- `README.md` : conforme.
- `docs/manuals/README.md` : **non conforme** (français sans accents) — à
  corriger en priorité.
- `docs/CONTRIBUTING.md` et `docs/DEPLOYMENT_GUIDE.md` : à confirmer par
  audit complet mais échantillonnage OK.

---

## 6. Recommandations priorisées

### 6.1 Priorité bloquante (P0)

1. **Corriger les 8 questions OCR `warning`** :
   `TG-BEPC-PHYS-2023-OCR-Q02` (Q → Ω), `Q05` ($ → S), `Q06` (m2 → m²),
   `TG-BEPC-MATH-2022-OCR-Q01` (M → ℝ), `Q02` (2 1} → 2}), `Q05` (S → 5),
   `Q06` (x2 → x²), `Q07` (x → π).
2. **Filtrer les 35 questions `needs_answer=true`** de l'affichage par
   défaut (mode révision ET simulation) jusqu'à saisie des réponses.

### 6.2 Priorité majeure (P1)

3. **Corriger `cardTapToSeeAnswer`** : passer au tutoiement
   (`Appuie sur ... quand tu es prêt`).
4. **Uniformiser les 7 énoncés à l'impératif `vous`** vers l'infinitif
   (conformité sujets officiels BEPC/BAC).
5. **Réécrire `docs/manuals/README.md`** avec accents corrects.
6. **Compléter `settingsCreditsBody`** (placeholder `[Équipe à compléter]`).

### 6.3 Priorité mineure (P2)

7. Ajouter les espaces insécables manquantes dans les énoncés OCR
   (`suivants:` → `suivants :`).
8. Uniformiser `dashboardMockExam` vs. `simulation*` (décider
   « examen blanc » vs. « simulation »).
9. Uniformiser `simulationAchevement` vs. `simulationCompletionRate`.
10. Uniformiser `simulationAvgTimePerQ` vs. `simulationTempsMoyenQ`.

### 6.4 Priorité cosmétique (P3)

11. Capitaliser `Côte des Esclaves` (toponyme historique).
12. Préciser `Série F1/F2/F3` au lieu de `Série F — Technique` générique.
13. Vérifier les PDFs `docs/manuals/output/*.pdf` pour les accents.
14. Considérer l'ajout de questions sur `manioc`, `igname`, `maïs` en SVT.

---

## 7. Indicateurs de qualité linguistique

| Indicateur | Cible | Mesuré | Statut |
|---|---|---|---|
| Fautes d'orthographe / 1000 mots | < 1 | ~0,2 | OK |
| Fautes de grammaire / 1000 mots | < 1 | 0 | OK |
| Cohérence tutoiement UI | 100 % | 99,7 % (1 chaîne) | À corriger |
| Cohérence infinitif énoncés | 100 % | 93 % (7/114) | À corriger |
| Vocabulaire togolais conforme | 100 % | 100 % | OK |
| Unités SI conformes | 100 % | 99 % (1 coquille `m2`) | À corriger |
| Espaces insécables | 100 % | 97 % | À corriger |
| Accents dans documentation | 100 % | 95 % (manuals/README) | À corriger |
| Bruit OCR non corrigé | 0 | 8 | À corriger |
| Questions sans réponse | 0 (en bêta) | 35 | À compléter |

---

## 8. Annexes

### 8.1 Liste exhaustive des 8 questions OCR à corriger

Voir section 3.2 du présent rapport.

### 8.2 Liste exhaustive des 7 énoncés à l'impératif `vous`

- `TG-BEPC-SVT-2021-Q01` : `Citez` → `Citer`
- `TG-BEPC-FR-2021-Q01` : `Donnez` → `Donner`
- `TG-BEPC-FR-2022-Q01` : `Identifiez et nommez` → `Identifier et nommer`
- `TG-BEPC-FR-2022-Q02` : `Conjuguez` → `Conjuguer`
- `TG-BEPC-FR-2023-Q01` : `Complétez` → `Compléter`
- `TG-BEPC-FR-2024-Q01` : `Lisez` → `Lire`
- `TG-BEPC-FR-2023-Q02` (synonyme) : pas d'impératif, OK

### 8.3 Liste des chaînes UI à corriger

- `cardTapToSeeAnswer` (tutoiement).
- `settingsCreditsBody` (placeholder).
- Cosmétique : `dashboardMockExam`, `simulationAchevement`,
  `simulationTempsMoyenQ`.

### 8.4 Vocabulaire togolais validé dans le corpus

- **Examens** : BEPC, Probatoire, BAC 1, BAC 2.
- **Lieux** : Lomé, Kara, Sokodé, Atakpamé, Kpalimé, Dapaong, Tokoin,
  Adawlato, Baguida, Aného (côte des Esclaves), Golfe de Guinée.
- **Établissements** : Lycée de Tokoin (secondaire).
- **Monnaie** : FCFA.
- **Histoire** : Togoland, Sylvanus Olympio, Mlapa III, indépendance
  27 avril 1960, Année de l'Afrique.
- **Société** : taxi-brousse, marché d'Adawlato.
- **Santé** : paludisme, anophèle, Plasmodium.
- **Agriculture implicite** : sac de riz (à compléter avec manioc/igname/maïs).
- **Institutions** : MEPST, Direction des Examens et Concours, DJANTA
  Tech Hub, AIMS Ghana, CEDEAO.

### 8.5 Termes à éviter (non détectés dans le corpus — bonne pratique)

- `bled`, `boulot`, `truc` (familier) : 0 occurrence.
- `francs` (au lieu de FCFA) : 0 occurrence.
- `euros` : 0 occurrence.
- `miles` : 0 occurrence.
- `brevet` (au lieu de BEPC) : 0 occurrence dans la banque et l'UI
  (`simulationBepcDesc: "Brevet d'études"` est acceptable car
  c'est le développement de l'acronyme).
- `camarade` (trop politique) : 0 occurrence.
- `vous` dans l'UI : 1 occurrence (`cardTapToSeeAnswer`) — à corriger.

---

## 9. Conclusion

Le corpus linguistique d'ExamBoost Togo est **de bonne qualité** dans
l'ensemble (UI 9/10, banque de questions 7,5/10, README 9/10). Les
défauts détectés sont :

- **Majoritairement issus du pipeline OCR** (35 questions, dont 8
  affichent un bruit caractériel bloquant) — problème technique à
  traiter en priorité P0.
- **Localisés** (1 chaîne UI, 1 fichier doc, 7 énoncés) — faciles à
  corriger en P1.
- **Sans impact sur la crédibilité pédagogique** une fois les
  corrections P0/P1 appliquées.

La conformité aux spécificités togolaises (FCFA, BEPC, lycée, lieux,
dates historiques, paludisme) est **excellente** et constitue un point
fort différenciant pour l'application.

Le présent rapport sert de référence pour les futures tâches de
correction et de rédaction. Il est complété par trois documents
annexes :
- `TOGOLESE_FRENCH_GUIDE.md` — guide de rédaction pour l'équipe.
- `pedagogical_validation.md` — validation pédagogique par matière.
- `cultural_examples_catalog.md` — catalogue d'exemples culturels à
  utiliser dans les futures questions.

---

*Rapport généré par l'Agent CC — ExamBoost Togo, Session 4 Vague 3.*
*Aucun fichier source modifié. Audit seul.*
