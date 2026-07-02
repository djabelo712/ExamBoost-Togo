# Vidéos d'explication — ExamBoost Togo

Ce dossier contient les scripts, storyboards et guides de production pour les **10 vidéos d'explication** d'ExamBoost Togo. Chaque vidéo explique la résolution d'une question clé du BEPC ou du BAC en 20 à 40 secondes.

## Pourquoi des vidéos ?

ExamBoost Togo propose déjà dans son app :
- Le texte de la question et de l'explication
- Une fonctionnalité TTS (Text-To-Speech) pour écouter l'explication

Les vidéos ajoutent une **dimension visuelle animée** qui renforce la compréhension :
- Animations des formules et calculs étape par étape
- Schémas géométriques et électriques animés
- Voix off pédagogique avec intonation adaptée
- Format court (20-40 s) adapté à la révision mobile

## Structure du dossier

```
docs/video_explanations/
├── README.md                              ← ce fichier
├── catalog.md                             ← catalogue récapitulatif des 10 vidéos
├── scripts/                               ← scripts voix off + métadonnées
│   ├── q01_pythagore_script.md
│   ├── q02_thales_script.md
│   ├── q03_factorisation_script.md
│   ├── q04_ohm_script.md
│   ├── q05_metaphore_script.md
│   ├── q06_subjonctif_script.md
│   ├── q07_equation_1er_degre_script.md
│   ├── q08_aire_triangle_script.md
│   ├── q09_derivee_script.md
│   └── q10_integrale_script.md
├── storyboards/                           ← storyboards détaillés shot par shot
│   ├── q01_pythagore_storyboard.md
│   ├── q02_thales_storyboard.md
│   ├── q03_factorisation_storyboard.md
│   ├── q04_ohm_storyboard.md
│   ├── q05_metaphore_storyboard.md
│   ├── q06_subjonctif_storyboard.md
│   ├── q07_equation_1er_degre_storyboard.md
│   ├── q08_aire_triangle_storyboard.md
│   ├── q09_derivee_storyboard.md
│   └── q10_integrale_storyboard.md
└── production/                            ← guides de production
    ├── production_guide.md                ← workflow complet en 7 étapes
    ├── recording_checklist.md             ← checklist avant enregistrement voix off
    └── editing_template.md                ← template de montage CapCut/Premiere
```

## Les 10 vidéos en un coup d'œil

| # | ID | Matière | Chapitre | Examen | Durée |
|---|---|---|---|---|---|
| 1 | q01_pythagore | Maths | Pythagore | BEPC | 30 s |
| 2 | q02_thales | Maths | Thalès | BEPC | 35 s |
| 3 | q03_factorisation | Maths | Identités remarquables | BEPC | 25 s |
| 4 | q04_ohm | Sciences Physiques | Loi d'Ohm | BEPC | 30 s |
| 5 | q05_metaphore | Français | Figures de style | BEPC | 28 s |
| 6 | q06_subjonctif | Français | Conjugaison | BEPC | 32 s |
| 7 | q07_equation_1er_degre | Maths | Équations | BEPC | 25 s |
| 8 | q08_aire_triangle | Maths | Aires | BEPC | 20 s |
| 9 | q09_derivee | Maths | Dérivation | BAC C | 35 s |
| 10 | q10_integrale | Maths | Intégrales | BAC C | 40 s |

**Durée totale** : 5 minutes 00 secondes.
**Répartition** : 5 Maths BEPC + 2 Maths BAC C + 1 Sciences Physiques + 2 Français.

## Comment produire une vidéo ?

### Workflow en 7 étapes (détail dans `production/production_guide.md`)
1. **Choisir la question** depuis `assets/data/questions.json`
2. **Valider le script** avec un enseignant de la matière
3. **Enregistrer la voix off** FR (+ EN) — voir `production/recording_checklist.md`
4. **Créer les animations** dans Canva Pro ou Manim — 8 plans par vidéo selon le storyboard
5. **Monter dans CapCut** — voir `production/editing_template.md` pour le template
6. **Ajouter les sous-titres** FR (+ EN)
7. **Exporter en MP4 720p** et intégrer dans `assets/videos/`

### Temps de production
- 4-5 heures par vidéo (travail actif)
- 45 heures pour les 10 vidéos (étalées sur 5 jours)

### Budget
- **Investissement matériel** : 120-185 € (micro USB + casque + pop-filter)
- **Coûts récurrents** : 0-5 $/mois (ElevenLabs optionnel)
- **Coût total pour 10 vidéos** : ~150 € + temps

## Intégration dans l'app Flutter

Le bouton "Voir la vidéo (30s)" sera ajouté dans `lib/widgets/cards/question_card.dart`, sous l'explication texte (après la ligne ~175). Voir le snippet d'intégration dans `scripts/q01_pythagore_script.md` section "Intégration in-app".

### Packages à ajouter au `pubspec.yaml`
```yaml
dependencies:
  video_player: ^2.7.0
  chewie: ^1.7.0  # UI de lecteur avec contrôles
```

### Stockage des fichiers
- **Option A (offline-first, recommandée pour V1)** : `assets/videos/q{NN}_{theme}.mp4` — APK additionnel de 50-80 Mo
- **Option B (streaming)** : URLs YouTube non-listed — pas de surpoids APK, nécessite Internet
- **Option C (hybride)** : streaming par défaut, cache local au 1er visionnage

## Audience cible

- **Primaire** : élèves togolais de 3e (BEPC) et Terminale C (BAC)
- **Âge** : 14-20 ans
- **Langue** : français (langue d'enseignement officielle au Togo)
- **Secondaire** : étudiants francophones d'Afrique de l'Ouest (Ghana, Bénin, Côte d'Ivoire frontaliers)
- **Tertiaire** : étudiants anglophones (version EN des voix off) pour pitch DJANTA international

## Démarrer rapidement

### Si vous voulez produire une nouvelle vidéo (la 11e)
1. Lire `catalog.md` pour identifier une question non encore couverte
2. Lire `scripts/q01_pythagore_script.md` comme template de script
3. Lire `storyboards/q01_pythagore_storyboard.md` comme template de storyboard
4. Suivre `production/production_guide.md` étape par étape
5. Utiliser `production/recording_checklist.md` pour l'enregistrement
6. Suivre `production/editing_template.md` pour le montage

### Si vous voulez modifier une vidéo existante
1. Lire le script et le storyboard de la vidéo concernée
2. Apporter les modifications au script
3. Faire valider par un enseignant
4. Refaire l'animation + voix off + montage selon les modifications
5. Mettre à jour `catalog.md` (version `v1.1` ou `v2.0`)

## Cohérence avec le reste d'ExamBoost Togo

### Palette de couleurs
Reprise de la palette ExamBoost :
- Vert Togo `#006837` — couleur principale, fonds de logo, traits
- Orange Togo `#D97700` — accents, valeurs mises en valeur, étiquettes
- Blanc `#FFFFFF` — fonds plans contenu
- Noir `#000000` — texte principal

### Typographies
- **Outfit** (Google Fonts) — titres, résultats, étiquettes
- **Times New Roman** — formules mathématiques générales
- **Patrick Hand** (Google Fonts) — calculs manuscrits effet tableau noir

### Ton éditorial
- Pédagogique, encourageant, jamais condescendant
- Accent ouest-africain (Togo, Bénin, Côte d'Ivoire) si voix humaine
- Sans emojis (ligne éditoriale ExamBoost)
- Français standard + traduction EN pour version internationale

## Métriques de succès

| Métrique | Cible 1 mois | Cible 3 mois | Cible 6 mois |
|---|---|---|---|
| Vues totales (app + YouTube) | 500 | 5000 | 20000 |
| Taux de clic sur "Voir la vidéo" | 30 % | 40 % | 50 % |
| Taux de complétion | 60 % | 70 % | 80 % |
| Feedback positif | 70 % | 80 % | 85 % |
| Augmentation du taux de réussite | +5 % | +10 % | +15 % |

Détail dans `catalog.md` section "Métriques de succès".

## Roadmap future

### V1 (actuelle, juillet 2026)
- 10 vidéos produites (5 Maths BEPC + 2 Maths BAC C + 1 Sciences + 2 Français)
- Intégration in-app offline-first
- Distribution YouTube non-listed (backup)

### V2 (septembre 2026, rentrée scolaire)
- Extension à 30-50 vidéos
- Nouvelles matières : SVT, Histoire-Géo, Anglais (5 vidéos par matière)
- Distribution YouTube publique + TikTok/Reels (formats verticaux 9:16)
- Bascule streaming par défaut (cache local)

### V3 (2027)
- Série "Erreur classique" (5 vidéos sur erreurs fréquentes)
- Série "Astuce examen" (5 vidéos avec astuces gain de temps)
- Vidéos interactives (questions intégrées pendant la vidéo)
- Personnalisation par profil d'élève (BKT → recommandation vidéo adaptée)

## Contact

- **Repository GitHub** : https://github.com/djabelo712/ExamBoost-Togo
- **Dossier vidéos** : `docs/video_explanations/`
- **Échéance pitch DJANTA** : 24 juillet 2026

Pour toute question sur la production vidéo, se référer aux guides dans `production/` ou au `catalog.md`.
