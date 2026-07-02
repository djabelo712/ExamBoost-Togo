# Guide du français togolais — ExamBoost Togo

**Task ID** : CC-linguistic-audit
**Agent** : CC (general-purpose)
**Date** : Session 4, Vague 3
**Usage** : Référence pour toute l'équipe (rédacteurs de questions,
développeurs UI, rédacteurs de documentation, support).
**Objectif** : Garantir la cohérence linguistique de l'application en
français togolais scolaire (norme MEPST).

---

## Sommaire

1. Particularités du français togolais
2. Vocabulaire scolaire
3. Adresser l'élève
4. Termes à éviter
5. Unités et mesures
6. Nombres, dates, heures
7. Exemples culturels à privilégier
8. Ponctuation et typographie
9. Syntaxe et registre
10. Conjugaison et accords
11. Règles pour la rédaction de questions
12. Règles pour la rédaction d'explications
13. Règles pour l'UI
14. Règles pour la documentation
15. Anti-patterns et erreurs fréquentes
16. Glossaire
17. Checklist de relecture

---

## 1. Particularités du français togolais

Le français togolais est une variété du français d'Afrique francophone,
proche du français ivoirien et béninois. Il partage avec ces variétés :

- L'usage d'un vocabulaire scolaire hérité du système français
  (BEPC, BAC, lycée, devoir, composition, interrogation écrite).
- Une phonologie influencée par les langues nationales (Éwé, Kabyè,
  Mina, Tem, etc.) — sans impact sur l'écrit normatif.
- Des calques et emprunts à l'anglais (via le Ghana frontalier) :
  « dash » (cadeau), « chop » (manger), « booking » (réservation).
- Une tendance au registre formel à l'écrit (sujets d'examens), mais à
  un registre plus familier à l'oral.

**Pour ExamBoost**, nous adoptons la norme suivante :

- **Écrit scolaire** (questions, explications, sujets) : français
  académique, conforme aux sujets BEPC/BAC togolais.
- **UI** (boutons, messages, hint) : tutoiement amical mais respectueux,
  registre courant.
- **Documentation** (README, manuels) : français professionnel soigné,
  sans émojis sauf dans les READMEs techniques.
- **Communications marketing** (landing, pitch deck) : français moderne,
  autorisé à utiliser l'anglais pour les termes techniques (IA, ML, API).

---

## 2. Vocabulaire scolaire

### 2.1 Termes normalisés

| Terme standard | Terme togolais | Notes |
|---|---|---|
| Collège | Lycée | Au Togo, "lycée" désigne l'ensemble du secondaire (6e en Terminale). "Collège" est parfois utilisé pour le 1er cycle, mais "lycée" est générique. |
| Brevet | BEPC | Acronyme spécifique : Brevet d'Études du Premier Cycle. Jamais "brevet des collèges". |
| Baccalauréat | BAC | Acronyme accepté ; "Baccalauréat" en forme longue. |
| Professeur | Prof / Enseignant | "Prof" à l'oral et en UI informelle ; "Enseignant" ou "Professeur" en contexte formel. |
| Élève | Élève | À préférer à "étudiant" (réservé au supérieur). |
| Étudiant | Étudiant | Réservé à l'université. |
| Devoir | Devoir | Conformité standard. |
| Examen | Examen | Conformité standard. |
| Annales | Annales / Sujets | "Annales" = recueil d'anciens sujets ; "Sujets" = énoncés d'examen. |
| Composition | Composition | Devoir trimestriel de synthèse. |
| Interrogation écrite | Interro / IE | Évaluation courte. |
| Probatoire | Probatoire | Examen de fin de 1ère (= BAC 1). |
| BAC 1 / BAC 2 | BAC 1 / BAC 2 | BAC 1 = Probatoire ; BAC 2 = BAC final (Terminale). |
| Coefficient | Coefficient | Poids d'une matière à l'examen. |
| Mention | Mention | Assez bien, Bien, Très Bien, Félicitations du jury. |
| Premier cycle | 1er cycle | 6e à 3e (pré-BEPC). |
| Second cycle | 2e cycle | 2nde à Terminale (pré-BAC). |
| Série A | Série A | Littéraire (philosophie, langues). |
| Série B | Série B | Sciences économiques. |
| Série C | Série C | Mathématiques et sciences physiques. |
| Série D | Série D | Sciences naturelles (SVT dominant). |
| Série F | Série F1/F2/F3 | Technique (F1 = construction, F2 = électrique, F3 = mécanique). Préférer la sous-série si connue. |
| trimestre | trimestre | L'année scolaire togolaise en compte 3. |
| Semestre | Semestre | Réservé à l'université. |
| Programme | Programme | Au Togo, "programme officiel MEPST". |
| Compétence | Compétence | Notion pédagogique moderne (approche par compétences). |
| Chapitre | Chapitre | Unité de cours. |
| Leçon | Leçon | Sous-unité du chapitre. |

### 2.2 Termes spécifiques togolais

- **MEPST** : Ministère de l'Enseignement Primaire, Secondaire et
  Technique (Togo). À utiliser dans la documentation pédagogique.
- **Direction des Examens et Concours** : autorité organisatrice des
  examens nationaux.
- **DJANTA Tech Hub** : incubateur partenaire (CcHub Nigeria).
- **CEDEAO** : Communauté Économique des États de l'Afrique de l'Ouest.
- **AIMS Ghana** : African Institute for Mathematical Sciences, partenaire.

---

## 3. Adresser l'élève

### 3.1 Règle : tutoiement systématique

ExamBoost s'adresse à l'élève à la 2e personne du singulier (`tu`),
comme un tuteur ou un grand frère. C'est un choix pédagogique :
- Crée une proximité bienveillante.
- Réduit la distance entre l'élève et l'outil.
- Encourage l'engagement.

### 3.2 Ton amical mais respectueux

- **OK** : "Bonjour, Kofi !", "Bienvenue !", "Que veux-tu faire ?",
  "Entraîne-toi", "Tu vas réussir", "Continue !".
- **À éviter** : "Salut mec", "Coucou", "Yo", "Wesh" (trop familier).
- **À éviter** : "Vous", "Monsieur", "Mademoiselle" (trop formel).

### 3.3 Termes d'adresse

- **OK** : "Tu", "mon ami", "Kofi" (prénom).
- **À éviter** : "camarade" (trop politique en contexte ouest-africain).
- **À éviter** : "copain", "pote" (trop familier).
- **À éviter** : "vous" (sauf cas spéciaux : tuteur parent, support).

### 3.4 Messages motivants

Préférer des phrases courtes, positives, encourages :

- "Excellent !"
- "Bon travail !"
- "Continue !"
- "Ne lâche rien !"
- "C'est en se trompant qu'on apprend."

Éviter :

- "Bravo" (trop générique).
- "Pas mal" (connoté négativement).
- "Tu peux mieux faire" (démotivant).

### 3.5 Cas spécial : énoncés de questions

Les énoncés de questions (dans `questions.json`) suivent la tradition
des annales BEPC/BAC togolaises : **infinitif** (et non impératif).

- **OK** : "Calculer l'aire d'un triangle...", "Résoudre l'équation...",
  "Définir la photosynthèse...", "Citer les trois modes de transfert
  de la chaleur".
- **À éviter dans les énoncés** : "Calcule l'aire...", "Résous...",
  "Définis..." (impératif tu), "Calculer... vous" (mélange).
- **À éviter dans les énoncés** : "Calculez...", "Résolvez..."
  (impératif vous, non conforme aux annales).

Cette règle crée une dissonance entre l'UI (tutoiement) et les énoncés
(infinitif). C'est conforme aux sujets officiels et ne pose pas de
problème pédagogique — l'élève est habitué.

---

## 4. Termes à éviter

### 4.1 Registre familier (interdit)

- "bled" (familier péjoratif pour "village").
- "boulot" (trop familier, préférer "travail").
- "truc" (trop familier, préférer "chose", "objet", "élément").
- "machin" (vague et familier).
- "bidule" (vague).
- "chouette" (vieilli).
- "cool" (anglicisme, préférer "agréable", "sympa" si nécessaire).
- "ok" / "OK" dans la documentation (acceptable en UI pour un bouton).

### 4.2 Termes politiquement sensibles

- "camarade" (connation politique en contexte ouest-africain).
- "indigène" (colonial, offensant).
- "tribu" (préférer "ethnie" ou "groupe ethnique" ou "peuple").
- "sauvage" (colonial).

### 4.3 Anglicismes à éviter

- "booking" → "réservation".
- "check" → "vérifier".
- "deadline" → "échéance" / "date limite".
- "feedback" → "retour" / "commentaire".
- "meeting" → "réunion".
- "news" → "actualités".
- "pin's" → "pin's" (admis).
- "starter" → "entrée en matière".
- "team" → "équipe".
- "challenge" → "défi".

### 4.4 Termes acceptés en contexte technique

Ces anglicismes sont admis dans la documentation technique et les
commentaires de code :

- "API", "backend", "frontend", "fullstack", "framework", "bug",
  "debug", "log", "token", "hash", "pipeline", "deploy", "commit",
  "pull request", "issue", "repo", "fetch", "parse", "render", "build".

---

## 5. Unités et mesures

### 5.1 Monnaie

- **FCFA** (Franc CFA, franc de la Communauté Financière en Afrique).
  - Format : `15 000 FCFA` (espace insécable comme séparateur de
    milliers, espace entre le nombre et `FCFA`).
  - Jamais "francs CFA", "F CFA", "XOF" (sauf contexte bancaire technique).
  - Jamais "euros", "dollars", "USD", "EUR" dans les questions.

### 5.2 Distances

- `km` (kilomètres), `m` (mètres), `cm` (centimètres), `mm` (millimètres).
- Format : `120 km`, `5 cm`, `0,5 m`.
- Jamais "miles", "yards", "feet", "inches".

### 5.3 Volumes

- `m³`, `cm³`, `dm³`, `L` (litre), `mL` (millilitre).
- Format : `282,6 cm³`, `1,5 L`.
- Le symbole `³` est en exposant Unicode (U+00B3), pas un `3` précédé
  d'une espace.

### 5.4 Masses

- `kg`, `g`, `mg`, `t` (tonne).
- Format : `1 000 kg`, `50 kg`, `0,5 t`.

### 5.5 Surfaces

- `m²`, `cm²`, `km²`, `hectare` (ha).
- Format : `25 m²`, `0,5 m²`, `10 ha`.

### 5.6 Température

- Degré Celsius : `°C`.
- Format : `25 °C` (espace entre le nombre et `°C`).
- Jamais "Fahrenheit" dans un contexte togolais.

### 5.7 Temps

- Secondes : `s` (pas "sec").
- Minutes : `min` (pas "mn" sauf si conforme au programme).
- Heures : `h`.
- Format : `2 h 30 min`, `30 s`, `14h30` (heure de la journée sans
  espace pour les notifications : `Rappel à 14h30`).

### 5.8 Vitesse

- `km/h`, `m/s`.
- Format : `60 km/h`, `15 m/s`.
- Jamais "mph", "km h", "km.h-1" (notation universitaire acceptable
  mais moins lisible).

### 5.9 Électricité

- Tension : `V` (volts).
- Intensité : `A` (ampères).
- Résistance : `Ω` (ohm, caractère Unicode U+03A9).
- Puissance : `W` (watts), `kW`.
- Énergie : `J` (joules), `kJ`, `kWh`.
- Fréquence : `Hz`, `kHz`, `MHz`.
- Pression : `Pa` (pascals), `kPa`, `bar`.
- Force : `N` (newtons).

### 5.10 Optique et ondes

- Distance focale : `cm`, `m`.
- Vergence : `δ` (dioptrie, caractère Unicode U+03B4).
- Longueur d'onde : `nm` (nanomètres), `μm`.
- Fréquence : `Hz`, `THz`.

### 5.11 Chimie et SVT

- Concentration : `mol/L`, `g/L`.
- pH : sans unité.
- Masse molaire : `g/mol`.

### 5.12 Angles

- Degrés : `°` (ex. : `45°`, sans espace).
- Radians : `rad` (ex. : `π/3 rad`, avec espace).

### 5.13 Notation scientifique

- Format : `1,6×10⁻¹⁹ C` (multiplication par `×` U+00D7, exposants
  Unicode `⁻`, `¹`, `²`, `³`, `⁴`, `⁵`, `⁶`, `⁷`, `⁸`, `⁹`).
- Préférer `×` à `*` (qui est un opérateur informatique).
- Préférer `10⁻¹⁹` à `10^-19` ou `10**-19`.

---

## 6. Nombres, dates, heures

### 6.1 Nombres

- Séparateur de milliers : **espace insécable** (U+00A0), pas de
  virgule, pas de point.
  - **OK** : `1 000`, `15 000 FCFA`, `1 000 000`.
  - **À éviter** : `1,000`, `1.000`, `1000` (sans séparateur).
- Séparateur décimal : **virgule** (et non point anglo-saxon).
  - **OK** : `0,5`, `3,14`, `282,6`.
  - **À éviter** : `0.5`, `3.14`.
- Pourcentage : `20 %` (espace insécable avant le `%`).
  - **OK** : `20 %`, `15 %`, `100 %`.
  - **À éviter** : `20%`, `20 %`.
- Fraction : `3/4`, `5/8`, `1/2`.
  - En formule mathématique : `\frac{3}{4}` (LaTeX) ou `3/4` (plain text).

### 6.2 Dates

- Format long : `24 juillet 2026` (jour en chiffre, mois en lettres,
  année en chiffre, espaces simples).
- Format court : `24/07/2026` ou `24/07/26` (jour/mois/année, séparateur `/`).
- Jamais : `July 24, 2026`, `2026-07-24` (sauf ISO 8601 en log technique).
- Mois abrégés : `janv.`, `févr.`, `mars`, `avr.`, `mai`, `juin`,
  `juil.`, `août`, `sept.`, `oct.`, `nov.`, `déc.`.
- Jours de la semaine : `lundi`, `mardi`, `mercredi`, `jeudi`,
  `vendredi`, `samedi`, `dimanche` (minuscule en français).
- L'indépendance du Togo : `27 avril 1960`.

### 6.3 Heures

- Format : `14h30` (pour une heure de la journée, sans espace).
- Format : `2 h 30 min` (pour une durée, avec espaces).
- Jamais : `2:30 PM`, `14:30` (sauf dans un timestamp ISO technique).

### 6.4 Années scolaires

- `Année scolaire 2025-2026` (année civile début-année civile fin,
  séparateur tiret).
- Trimestres : `1er trimestre`, `2e trimestre`, `3e trimestre`
  (avec exposant `er`, `e`).

---

## 7. Exemples culturels à privilégier

### 7.1 Villes togolaises

- **Lomé** (capitale, région Maritime).
- **Sokodé** (2e ville, région Centrale).
- **Kara** (région Kara).
- **Atakpamé** (région Plateaux).
- **Kpalimé** (région Plateaux, près du Ghana).
- **Dapaong** (région Savanes, nord).
- **Aného** (côte, ancienne capitale coloniale allemande).
- **Tsévié** (région Maritime).
- **Baguida** (proche de Lomé, traité de 1884).
- **Niamtougou** (nord, aéroport).
- **Badou** (région Plateaux).

### 7.2 Marchés et lieux emblématiques

- **Marché Adawlato** (ou Grand Marché de Lomé) — plus grand marché
  de Lomé, lieu emblématique.
- **Marché de Tokoin** — marché de quartier.
- **Place de l'Indépendance** (Lomé).
- **Monument de l'Indépendance** (Lomé).
- **Stade de Kégué** (Lomé, ~30 000 places).
- **Stade Municipal de Kara**.
- **Port autonome de Lomé** — seul port en eau profonde de la côte
  ouest-africaine.
- **Aéroport International Gnassingbé Eyadéma** (Lomé).

### 7.3 Entreprises et institutions togolaises

- **Moov Africa Togo** (télécoms).
- **Togo Telecom** (télécoms historique, filiale YAS pour le mobile).
- **Orabank Togo**, **Ecobank Togo**, **Banque Atlantique** (banques).
- **Togocom** (télécoms).
- **ContourGlobal Togo** (centrale électrique au charbon, Lomé).
- **Barrage de Nangbeto** (hydroélectricité, fleuve Mono).
- **CEET** (Compagnie d'Énergie Électrique du Togo).
- **SOTRAL** (transport en commun de Lomé).
- **OTR (Office National des Télécommunications et des Postes)**.

### 7.4 Personnalités togolaises

- **Sylvanus Olympio** (1er président, 1960-1963).
- **Nicolas Grunitzky** (2e président, 1963-1967).
- **Gnassingbé Eyadéma** (président 1967-2005).
- **Faure Gnassingbé** (président depuis 2005).
- **Félix Couchoro** (écrivain, pionnier de la littérature togolaise).
- **David Ananou** (écrivain, romancier).
- **Pyabélo Chaabou** (écrivaine).
- **Kossi Agassa** (footballeur international).
- **Emmanuel Adebayor** (footballeur international).

### 7.5 Sports

- **Football** : sport roi au Togo.
  - **Étoile Filante de Lomé** (club historique).
  - **AS Togo-Port** (club).
  - **AC Semassi FC** (club de Sokodé).
  - **Maritime FC** (club).
  - **Éperviers** (surnom de l'équipe nationale).

### 7.6 Médias

- **Télévision Togolaise (TVT)**.
- **Radio Lomé**.
- **Togo Presse** (agence de presse).
- **Journal « Togo-Presse »** (quotidien).

### 7.7 Culture et arts

- **Fêtes d'Epe-Ekpe** (célébration Guin à Aného, début janvier).
- **Evala** (lutte traditionnelle, Kabyè, région de Kara, juillet).
- **Kamou** (cérémonie d'initiation Kabyè).
- **Hogbetsotso** (fête ewe — mais plutôt célébré au Ghana voisin).
- **Togo Fashion Week** (Lomé).
- **FESPAM** (festival panafricain de musique — partagé avec le Congo).

### 7.8 Agriculture et alimentation

- Cultures vivrières : **manioc**, **igname**, **maïs**, **mil**, **sorgho**,
  **niébé**, **tarot** (macabo).
- Cultures de rente : **café**, **cacao**, **coton**, **karité**,
  **palmier à huile**.
- Plats emblématiques : **fufu** (pâte d'igname ou de manioc),
  **akoumé** (pâte de maïs), **ademe** (sauce feuille), **gboma dessi**
  (sauce feuille verte), **pâte d'arachide**.
- Boissons : **choukoutou** (bière de mil), **sodabi** (gin de palme),
  **bissap** (jus d'hibiscus), **jus de gingembre**.

### 7.9 Climat et géographie

- Climats : subéquatorial (sud, 2 saisons des pluies), tropical
  soudanien (nord, 1 saison des pluies).
- Fleuves : **Mono** (ouest, barrage de Nangbeto), **Oti** (nord-est).
- Lac **Togo** (lagune côtière).
- Mont Agou (pic d'Agou, point culminant, ~986 m).
- Chaîne de l'Atakora (nord).
- Forêt tropicale (région Plateaux), mangroves (côte).

### 7.10 Santé publique

- **Paludisme** : 1ère cause de mortalité infantile au Togo.
- **Maladies tropicales négligées** : onchocercose, bilharziose,
  filariose lymphatique, trachome, ulcère de Buruli.
- **VIH/SIDA** : prévalence ~2,3 % (2023).
- **Tuberculose**.
- **Fièvre jaune** (vaccination obligatoire).
- **Choléra** (épidémies saisonnières).

---

## 8. Ponctuation et typographie

### 8.1 Espaces insécables

En français, les signes doubles (`:`, `;`, `!`, `?`, `%`) sont
précédés d'une **espace insécable** (U+00A0). Les signes simples
(`.`, `,`) n'ont pas d'espace avant.

- **OK** : `Question 1 : Pythagore`, `Prêt ?`, `Excellent !`, `20 %`.
- **À éviter** : `Question 1: Pythagore`, `Prêt?`, `20%`.

Dans un fichier JSON `.arb`, l'espace insécable est représentée par
`\u00A0` ou insérée directement si l'éditeur supporte l'UTF-8.

### 8.2 Guillemets

- Guillemets français : `«` (U+00AB) et `»` (U+00BB), avec espaces
  insécables à l'intérieur : `« Voir la réponse »`.
- Apostrophe courbe : `'` (U+2019) préférée à l'apostrophe droite `'`.
  - En JSON, utiliser `\'` ou directement `'` en UTF-8.
- Guillemets droits `"..."` : réservés au code et aux chaînes JSON.
- Guillemets anglais `"..."` : à éviter en français.

### 8.3 Tirets

- Tiret cadratin `—` (U+2014) : pour les incises et les oppositions.
  - OK : `Cinématique — Vitesse`, `Lomé — Kpalimé`.
- Tiret demi-cadratin `–` (U+2013) : pour les intervalles.
  - OK : `pages 12–15`, `2025–2026`.
- Tiret court `-` (U+002D) : pour les mots composés.
  - OK : `taxi-brousse`, `Histoire-Géographie`, `Sciences Physiques`.
- Moins `−` (U+2212) : opérateur mathématique (préféré au tiret court).
  - OK : `−5`, `x − 3`.

### 8.4 Points de suspension

- `…` (U+2026), et non trois points `...`.
- Accepté en UI pour indiquer un chargement : `Chargement…`.
- En JSON ExamBoost : `revisionLoading: "Chargement des questions..."` —
  utilise `...` (3 points). Acceptable mais à harmoniser vers `…`.

### 8.5 Majuscules

- Majuscule accentuée : obligatoire en français.
  - **OK** : `Énoncer`, `À propos`, `Établissement`, `Œil`.
  - **À éviter** : `Enoncer`, `A propos`, `Etablissement`, `Oeil`.
- Majuscule en début de phrase.
- Majuscule aux noms propres (Lomé, Kara, Olympio).
- Pas de majuscule après un deux-points (sauf citation directe).

### 8.6 Italique et gras

- Italique : pour les titres d'œuvres, les mots étrangers, les exemples.
  - En Markdown : `*italique*` ou `_italique_`.
  - En Flutter Text : `TextStyle(fontStyle: FontStyle.italic)`.
- Gras : pour l'emphase, les termes techniques.
  - En Markdown : `**gras**`.
  - En Flutter : `TextStyle(fontWeight: FontWeight.bold)`.

---

## 9. Syntaxe et registre

### 9.1 Phrases courtes et claires

L'élève togolais de 3e à Terminale doit comprendre immédiatement.
Préférer :

- Phrases de 15-20 mots maximum (énoncés).
- Phrases de 25-30 mots maximum (explications).
- Une idée par phrase.

### 9.2 Structure des énoncés

Format recommandé pour un énoncé de question :

```
[Verbe à l'infinitif] + [objet] + [contexte/données] + [?]
```

Exemples :
- `Calculer l'aire d'un triangle de base 8 cm et de hauteur 5 cm.`
- `Résoudre dans ℝ l'équation : 3x + 7 = 22.`
- `Citer les trois modes de transfert de la chaleur.`
- `Définir la photosynthèse et donner l'équation bilan simplifiée.`

### 9.3 Structure des explications

Format recommandé pour une explication :

```
[Formule/règle générale] : [application au cas] = [résultat].
[Phrase de contexte pédagogique].
```

Exemple :
```
La pression est définie par P = F / S, avec F en newtons (N) et S en m².
Donc P = 50 / 0,25 = 200 Pa (pascals).
```

### 9.4 Éviter

- Phrases passives trop longues.
- Subordonnées imbriquées (`qui... que... dont...`).
- Pronoms ambigus (`il`, `elle`, `le`, `la` sans antécédent clair).
- Adverbes creux (`évidemment`, `naturellement`, `bien sûr`).

---

## 10. Conjugaison et accords

### 10.1 Temps à privilégier

- **Présent de l'indicatif** : règle générale, fait scientifique.
  - "La vitesse moyenne est définie comme la distance parcourue..."
- **Passé composé** : fait accompli.
  - "Le Togo a accédé à l'indépendance le 27 avril 1960."
- **Futur simple** : prédiction, conséquence.
  - "L'œuf migrera ensuite vers l'utérus."
- **Impératif** : consignes UI (à la 2e personne du singulier).
  - "Choisis ton examen", "Saisis ta réponse".
- **Infinitif** : énoncés de questions.
  - "Calculer...", "Résoudre...", "Citer...".

### 10.2 Temps à éviter

- Passé simple : trop littéraire pour un contexte pédagogique.
- Subjonctif imparfait : trop littéraire.
- Conditionnel passé : trop complexe.

### 10.3 Accords particuliers

- **Participe passé avec COD antéposé** : accord en genre et nombre.
  - "Les filles que j'ai rencontrées" (COD `que` = `les filles`,
    féminin pluriel → `rencontrées`).
- **Participe passé avec être** : accord avec le sujet.
  - "Les mitochondries sont situées dans le cytoplasme."
- **Verbes pronominaux** : cas général accord avec le sujet, sauf
  COD postposé.
- **Noms composés** : variable. Ex. `taxi-brousse` → `taxis-brousses`.

### 10.4 Pièges fréquents

- `quelque` vs `quel que` : `quel que soit le cas` (locution).
- `quelques` vs `quelques-uns` : `quelques élèves` (déterminant) vs
  `quelques-uns` (pronom).
- `parmi` : toujours avec `parmi` et pas de `entre` (sauf 2 éléments).
- `malgré` : ne prend pas de `que` (≠ `bien que`).
- `à cause de` (négatif) vs `grâce à` (positif).

---

## 11. Règles pour la rédaction de questions

### 11.1 Structure d'un énoncé

1. Verbe à l'infinitif (5-15 premiers mots).
2. Objet de la question.
3. Données chiffrées (avec unités).
4. Contexte (optionnel).
5. Point final `.` (sauf question directe qui prend `?`).

### 11.2 Types de questions

- **Calcul** : `Calculer [grandeur] de [objet] sachant [données].`
- **Ouvert** : `Définir [concept].` / `Citer [liste].` / `Expliquer
  [phénomène].`
- **QCM** : `[Question] ?\nA. ...\nB. ...\nC. ...\nD. ...`
- **Vrai/Faux** : `[Affirmation].` → réponse attendue : `Vrai` ou `Faux`.

### 11.3 Erreurs à éviter

- Verbe à l'impératif (`Calcule`, `Résous`) : non conforme aux annales.
- Verbe au futur (`Calculeras`) : non conforme.
- Données sans unités : `R = 20` (sans `Ω`) → toujours préciser l'unité.
- Plusieurs questions en une : `Calculer X et Y et Z.` → diviser en
  sous-questions.
- Énoncé ambigu : `Le cube du double de x` → préférer `(2x)³` ou
  `2³ × x³` selon l'intention.

### 11.4 Exemple de bonne question

```json
{
  "id": "TG-BEPC-MATHS-2022-Q04",
  "enonce": "La distance Lomé–Kpalimé est d'environ 120 km. Un taxi-brousse met 2 heures pour parcourir cette distance. Quelle est sa vitesse moyenne ?",
  "reponse": "60 km/h",
  "explication": "Vitesse moyenne = distance / temps = 120 / 2 = 60 km/h. C'est une application directe de la relation v = d/t."
}
```

Pourquoi c'est bon :
- Verbe infinitif (`Quelle est` est acceptable car c'est une question
  directe).
- Contexte culturel togolais (Lomé-Kpalimé, taxi-brousse).
- Données avec unités (`120 km`, `2 heures`).
- Réponse avec unité (`60 km/h`).
- Explication claire, formule + application numérique + contexte.

---

## 12. Règles pour la rédaction d'explications

### 12.1 Structure

1. Règle ou formule générale (1 phrase).
2. Application au cas (1-2 phrases).
3. Résultat numérique avec unité.
4. Phrase pédagogique de conclusion (optionnel).

### 12.2 Longueur

- 30-80 mots pour une question simple.
- 80-150 mots pour une question complexe.
- Pas plus de 200 mots (sinon découper en étapes).

### 12.3 Style

- Phrases déclaratives.
- Présent de l'indicatif.
- Vocabulaire précis (pas de "truc", "machin").
- Liens logiques : `Donc`, `Ainsi`, `Par conséquent`, `Or`, `Car`,
  `Puisque`, `Étant donné que`.

### 12.4 Symboles mathématiques

- `×` pour la multiplication (et non `*` ou `x`).
- `÷` pour la division (ou utiliser la fraction `/`).
- `=` pour l'égalité.
- `≈` pour l'approximation.
- `≠` pour la différence.
- `≤`, `≥` pour les inégalités.
- `√` pour la racine carrée.
- `²`, `³` pour les puissances (exposants Unicode).
- `π` pour pi.
- `∞` pour l'infini.
- `ℝ`, `ℕ`, `ℤ`, `ℚ`, `ℂ` pour les ensembles de nombres.
- `∈` pour l'appartenance.
- `∪`, `∩` pour l'union et l'intersection.

---

## 13. Règles pour l'UI

### 13.1 Longueur des chaînes

- Boutons : 1-3 mots (ex. `Commencer`, `Suivant`, `Voir la réponse`).
- Titres : 2-6 mots (ex. `Révision Adaptative`, `Configuration de
  l'examen`).
- Sous-titres : 5-15 mots.
- Messages : 1-2 phrases.
- Hints : 1 phrase, max 15 mots.

### 13.2 Tutoiement

- Toujours `tu` (et non `vous`).
- Exception : message à un parent ou un enseignant (écran parent/admin).

### 13.3 Placeholders

- Format : `{name}` (camelCase, sans espace).
- Typage dans `@clé` : `{"type": "String"}` ou `{"type": "int"}`.
- Exemple : `"revisionCorrectAnswers": "Tu as répondu correctement à
  {correct} questions sur {total}"`.

### 13.4 Messages d'erreur

- Ton : informatif, non accusateur.
- Ex. : `"Erreur lors de la création du profil : {error}"`.
- Pas de : `"Erreur !!"`, `"Échec"`, `"Vous avez fait une erreur"`.

### 13.5 Messages motivants

- Toujours positifs, même en cas d'échec.
- Ex. : `"C'est en se trompant qu'on apprend."` (pas `"Tu t'es trompé."`).

---

## 14. Règles pour la documentation

### 14.1 READMEs

- Français soigné.
- Émojis acceptés pour les titres de section (mais pas dans le corps).
- Code blocks avec coloration syntaxique.
- Liens relatifs pour la navigation interne.

### 14.2 Manuels PDF

- Français académique.
- Pas d'émojis.
- Pas d'anglicismes (sauf termes techniques admis).
- Accentuation obligatoire (voir problème `docs/manuals/README.md`).

### 14.3 Code source — commentaires

- Français autorisé dans les commentaires.
- Anglais dans les identifiants (variables, fonctions, classes).
- Docstrings : français ou anglais (cohérence par fichier).

---

## 15. Anti-patterns et erreurs fréquentes

### 15.1 Bruit OCR non corrigé

Symptômes :
- `Ω` lu `Q` ou `W`.
- `ℝ` lu `M` ou `R`.
- `π` lu `x` ou `n`.
- `²` lu `2` ou absent.
- `³` lu `3` ou absent.
- `√` absent ou lu `V`.
- `≈` lu `~` ou absent.
- `→` absent ou lu `->`.

Solution : ne jamais publier une question OCR sans relecture humaine.
Filtrer `_validation_status == "warning"` ou corriger manuellement.

### 15.2 Mélange tu/vous

- UI en `tu`, énoncés en `infinitif`, messages en `vous` (erreur).
- Règle : UI = `tu`, énoncés = `infinitif`, documentation = `vous`
  (accepté) ou `infinitif` (préféré).

### 15.3 Unités manquantes

- `R = 20` (sans `Ω`).
- `v = 60` (sans `km/h` ou `m/s`).
- `P = 200` (sans `Pa`, `W`, ou `N`).

Règle : toute grandeur physique doit avoir son unité.

### 15.4 Confusion singulier/pluriel

- `Est-ce que les élèves a compris ?` (faux : `ont`).
- `La majorité des élèves ont réussi` (acceptable en français moderne,
  mais `a` est plus strict).

### 15.5 Anglicismes cachés

- `réaliser` pour `faire` (anglicisme : `réaliser un projet` ≠
  `faire un projet`).
- `adresser` pour `traiter` (anglicisme : `adresser un problème` ≠
  `traiter un problème`).
- `initier` pour `lancer` (anglicisme).

### 15.6 Faux-amis

- `actuellement` (FR : "en ce moment") ≠ `actually` (EN : "en fait").
- `demander` (FR : "poser une question") ≠ `to demand` (EN : "exiger").
- `librairie` (FR : "magasin de livres") ≠ `library` (EN : "bibliothèque").

---

## 16. Glossaire

### 16.1 Termes pédagogiques

- **Approche par compétences (APC)** : pédagogie centrée sur les
  compétences à acquérir, en vigueur au Togo depuis les années 2010.
- **Compétence** : savoir + savoir-faire + savoir-être, évaluable.
- **Chapitre** : unité de cours regroupant plusieurs leçons.
- **Leçon** : unité de cours d'une séance.
- **Séquence** : ensemble de séances围绕 un même objectif.
- **Évaluation diagnostique** : en début de chapitre.
- **Évaluation formative** : en cours d'apprentissage.
- **Évaluation sommative** : en fin de chapitre/trimestre.

### 16.2 Termes ExamBoost

- **Carte SRS** : carte de révision espacée (SM-2).
- **Compétence suivie** : compétence explicitement associée à un
  ensemble de questions, avec score BKT.
- **BKT** : Bayesian Knowledge Tracing, modèle de maîtrise.
- **IRT** : Item Response Theory, calibration de questions.
- **FSRS** : Free Spaced Repetition Scheduler, algorithme futur de SRS.
- **Banque** : ensemble des questions disponibles.
- **Calibration IRT** : estimation des paramètres a, b, c d'un item.

---

## 17. Checklist de relecture

Avant de publier une question, un écran UI, ou un document, vérifier :

### 17.1 Questions

- [ ] Énoncé à l'infinitif (pas d'impératif `vous`).
- [ ] Données avec unités SI.
- [ ] Réponse avec unité.
- [ ] Explication claire (formule + application + résultat).
- [ ] Pas de bruit OCR (`Ω`, `π`, `ℝ`, `²` présents).
- [ ] Vocabulaire togolais (FCFA, BEPC, lieux locaux si pertinent).
- [ ] Ponctuation correcte (espace insécable avant `:` `?`).
- [ ] Accords vérifiés.
- [ ] Compréhensible par un élève de 3e ou Terminale.

### 17.2 UI

- [ ] Tutoiement systématique.
- [ ] Pas de `vous` (sauf écran parent/admin).
- [ ] Placeholders typés dans `@clé`.
- [ ] Espace insécable avant `:` `?` `!` `%`.
- [ ] Majuscules accentuées.
- [ ] Messages motivants positifs.
- [ ] Longueur adaptée (boutons courts, titres moyens).

### 17.3 Documentation

- [ ] Français accentué (pas de `docs/manuals/README.md` style).
- [ ] Ton professionnel.
- [ ] Terminologie cohérente avec le glossaire.
- [ ] Pas d'anglicismes (sauf termes techniques admis).
- [ ] Majuscules aux noms propres (Lomé, Kara, Olympio).
- [ ] Date au format `24 juillet 2026`.
- [ ] Heure au format `14h30`.
- [ ] Monnaie en `FCFA`.

---

## 18. Références

- **Programme officiel MEPST** (Togo) — pour la conformité des
  contenus pédagogiques.
- **Annales BEPC et BAC togolaises** — pour la formulation des énoncés.
- **Rectifications orthographiques de 1990** — pour les tolérances
  (ex. `évènement` ≠ `événement`).
- **Lexique des règles typographiques en usage à l'Imprimerie nationale**
  (édition 2002) — pour la ponctuation.
- **Banque de termes terminologiques de FranceTerme** (ÉDUC) — pour
  les néologismes.

---

## 19. Versioning

- **Version 1.0** : présente version, rédigée par l'Agent CC en
  Session 4 Vague 3.
- **Mises à jour futures** : toute évolution du guide doit être
  tracée dans le worklog et annoncée à l'équipe pédagogique.

---

*Guide rédigé par l'Agent CC — ExamBoost Togo, Session 4 Vague 3.*
*Pour toute question ou suggestion, contacter l'équipe pédagogique.*
