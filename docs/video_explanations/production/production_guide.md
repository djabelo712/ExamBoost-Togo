# Guide de production vidéo — ExamBoost Togo

Ce guide décrit le workflow complet pour produire une vidéo d'explication de 20 à 40 secondes pour ExamBoost Togo. Il s'adresse à un producteur vidéo, un enseignant ou un bénévole qui souhaite créer une nouvelle vidéo du catalogue.

## 1. Vue d'ensemble du workflow

Le workflow de production comporte 7 étapes :

1. **Choisir la question** (15 min)
2. **Valider le script avec un enseignant** (1-2 jours)
3. **Enregistrer la voix off** (30 min par vidéo)
4. **Créer les animations Canva/Manim** (2-3 heures par vidéo)
5. **Monter avec CapCut** (1 heure par vidéo)
6. **Ajouter les sous-titres FR + EN** (30 min par vidéo)
7. **Exporter et intégrer à l'app** (15 min par vidéo)

**Temps total par vidéo** : environ 4-5 heures de travail actif.
**Temps total pour 10 vidéos** : environ 40-50 heures réparties sur 5 jours (avec validation enseignant en parallèle).

## 2. Choix de la question

### Critères de sélection
Une question est éligible pour une vidéo si :
- Elle porte sur un concept fondamental (chapitre central du programme BEPC/BAC)
- Sa résolution tient en 30-40 secondes (calcul simple ou définition courte)
- Elle est fréquemment posée à l'examen (au moins 3 occurrences sur les 5 dernières années)
- Elle pose des difficultés récurrentes aux élèves (identifiable via IRT b > 0 ou feedback enseignants)

### Banque de questions
- Source principale : `assets/data/questions.json` (64 questions BEPC/BAC)
- Pour ajouter une nouvelle vidéo, sélectionner une question et créer un nouveau script dans `scripts/` + un storyboard dans `storyboards/`
- Nomenclature : `q{NN}_{theme_court}_script.md` (numéro à 2 chiffres, thème en snake_case)

### Question originale vs question adaptée
Si la question originale du JSON est trop longue ou trop complexe pour 30 secondes, il est autorisé de créer une question SIMILAIRE mais simplifiée pour la vidéo. Dans ce cas, mentionner clairement dans les métadonnées du script : "Question adaptée pour la vidéo (originale : ...)".

## 3. Validation du script

### Pourquoi valider
Un script erroné se propage vite. Une seule erreur de calcul ou de définition discrédite la vidéo auprès des enseignants et des élèves.

### Qui valide
- **Enseignant de la matière** (mathématiques, physique, français) — idéalement un professeur de collège/lycée togolais en activité
- À défaut, un étudiant en M1/M2 de la matière ayant passé le BEPC/BAC au Togo (expérience récente)

### Comment valider
1. Envoyer le script Markdown complet à l'enseignant (email ou WhatsApp)
2. Demander une relecture sur 3 points :
   - Exactitude mathématique / scientifique / grammaticale
   - Pertinence pédagogique (clarté pour un élève de 3e/Terminale)
   - Adéquation au programme officiel togolais
3. Recueillir les retours par écrit (échange email)
4. Intégrer les corrections dans le script
5. Demander une validation finale ("OK pour production")

### Délai
- 1 à 2 jours ouvrés selon la disponibilité de l'enseignant
- Prévoir 2 enseignants validateurs en backup si le premier ne répond pas

## 4. Enregistrement de la voix off

### Deux options

#### Option A — Voix humaine (recommandée pour V1)
- **Matériel** : micro USB (Blue Yeti, Rode NT-USB, ou micro-casque Logitech H390 pour budget réduit), pièce silencieuse, ordinateur
- **Logiciel** : Audacity (gratuit, multiplateforme) ou GarageBand (Mac)
- **Voix** : masculine ou féminine, préférence pour un accent togolais/west-africain si possible
- **Avantage** : chaleur humaine, accent local, coût nul après investissement matériel
- **Inconvénient** : temps d'enregistrement (30 min par vidéo), qualité variable selon le matériel

#### Option B — Voix de synthèse (ElevenLabs)
- **Service** : ElevenLabs (https://elevenlabs.io), offre Starter 5 $/mois pour 30 000 caractères
- **Voix recommandées** : "Antoni" (FR masculin), "Rachel" (FR féminin), "Bella" (FR féminin enfantin)
- **Procédure** : copier le script FR dans ElevenLabs → générer le MP3 → vérifier la prononciation → régénérer si nécessaire
- **Avantage** : rapide, qualité constante, multilingue natif
- **Inconvénient** : coût mensuel, accent parfois trop "français de France" (moins authentique)

### Réglages d'enregistrement (Option A)
- Fréquence d'échantillonnage : 44 100 Hz
- Format : WAV (non compressé) ou FLAC pour archivage, MP3 192 kbps pour production
- Niveau d'enregistrement : pic entre -12 dBFS et -6 dBFS (jamais au 0 dBFS = saturation)
- Traitement post-enregistrement dans Audacity :
  - Réduction de bruit (effet "Réduction de bruit", capture 2 s de silence)
  - Normalisation à -3 dBFS
  - Compression (ratio 2:1, threshold -20 dB) pour lisser les variations
  - Optionnel : égaliseur "bass boost" +2 dB à 100 Hz pour voix masculine

### Préparation de la voix (Option A)
- Boire de l'eau 30 min avant (voix hydratée)
- Échauffement vocal 5 min : "bbbb", "mamama", "kikikiki"
- Lire le script à voix haute 1 fois pour repérer les difficultés
- Prévoir 3 prises minimum, choisir la meilleure

## 5. Création des animations

### Outil 1 — Canva Pro (recommandé pour débuter)

#### Configuration
- Créer un compte Canva Pro éducation (gratuit avec adresse .edu ou GitHub Student Pack)
- Créer un design "Vidéo 1280×720" (16:9, 30 fps)

#### Workflow Canva
1. Pour chaque plan du storyboard, créer une "page" Canva
2. Ajouter les éléments : formes (triangles, rectangles), texte (Outfit, Times New Roman, Patrick Hand), images (logo)
3. Animer : Canva propose des animations prédéfinies (fade-in, slide, pop). Les appliquer aux éléments
4. Transitions entre pages : "Cut" (par défaut), ou "Fade" pour les transitions marquantes
5. Durée de chaque page : régler via le timecode en haut (par défaut 5 s, ajuster selon le storyboard)
6. Export : "Télécharger → MP4 → 720p"

#### Limites de Canva
- Pas d'animations mathématiques complexes (transformations de formules, morphing algébrique)
- Pas de contrôle fin sur les courbes d'animation (seulement "lent/rapide")
- Pour les vidéos BAC C (dérivée, intégrale), préférer Manim

### Outil 2 — Manim (Python, pour animations mathématiques)

#### Installation
```bash
pip install manim
# Dépendances système : FFmpeg, LaTeX (TeX Live ou MikTeX)
sudo apt install ffmpeg texlive-full  # Ubuntu/Debian
```

#### Workflow Manim
1. Créer un fichier Python par vidéo : `manim_scenes/q01_pythagore.py`
2. Définir une classe `Scene` par plan (ou une seule classe avec plusieurs `self.play()`)
3. Utiliser `MathTex` pour les formules LaTeX, `Text` pour le texte simple
4. Animer avec `Write`, `FadeIn`, `Transform`, `TransformMatchingTex`
5. Rendre avec : `manim -pql q01_pythagore.py Pythagore` (preview low quality) puis `manim -pqh q01_pythagore.py Pythagore` (high quality 1080p)

#### Snippet de démarrage (Q01 Pythagore)
```python
from manim import *

class Pythagore(Scene):
    def construct(self):
        # Plan 2 : Triangle
        triangle = Polygon(
            [-3, -2, 0], [-3, 2, 0], [3, -2, 0],
            color="#006837", stroke_width=4
        )
        angle_droit = Square(side_length=0.3, color=BLACK).move_to([-2.7, -1.7, 0])
        labels = VGroup(
            Text("A", font_size=24).move_to([-3.3, -2.3, 0]),
            Text("B", font_size=24).move_to([-3.3, 2.3, 0]),
            Text("C", font_size=24).move_to([3.3, -2.3, 0]),
        )
        self.play(Create(triangle), Create(angle_droit), run_time=1.5)
        self.play(Write(labels))

        # Plan 3 : Formule
        formule = MathTex(r"BC^2 = AB^2 + AC^2", font_size=48)
        formule.to_edge(UP)
        self.play(Write(formule))

        # Plan 5 : Calcul
        calcul = MathTex(r"6^2 + 8^2 = 36 + 64 = 100", font_size=36, color="#D97700")
        calcul.to_edge(DOWN)
        self.play(Write(calcul))

        self.wait(2)
```

### Outil 3 — Fallback simple (slides animées)
Pour une production minimaliste sans animation : créer 8 slides PowerPoint/Google Slides (1 par plan), enregistrer la voix off séparément, puis synchroniser dans CapCut.

## 6. Montage avec CapCut

### Import des assets
1. Ouvrir CapCut (version desktop recommandée, gratuite)
2. Créer un nouveau projet "16:9"
3. Importer la vidéo d'animation (Canva ou Manim)
4. Importer la voix off (MP3 ou WAV)
5. Importer les SFX (jingle, ding, craie, pop) — bibliothèque Pixabay Music

### Timeline type (30 s)
- Piste 1 (vidéo) : animation complète 30 s
- Piste 2 (audio principal) : voix off (FR)
- Piste 3 (audio SFX) : jingle début (0,5 s), ding (ponctuels), craie (calculs), pop (résultats), jingle fin
- Piste 4 (audio musique) : optionnel, musique de fond à -25 dBFS (sous la voix)
- Piste 5 (sous-titres) : auto-caption + correction

### Synchronisation
- Aligner la voix off avec l'animation : la voix dit "BC² = AB² + AC²" exactement quand la formule apparaît à l'écran
- Caler les SFX sur les moments-clés : ding à l'apparition d'une formule, pop à l'apparition du résultat, craie pendant les calculs
- Vérifier le timecode total : doit correspondre au storyboard (30,0 s ± 0,5 s)

### Transitions
- Entre plans : CUT SEC (par défaut), sauf transitions marquantes (début/fin) en fondu
- Éviter les transitions tape-à-l'œil (zoom, rotation) : elles distrait l'élève

## 7. Sous-titres

### Pourquoi sous-titres
- Accessibilité : élèves malentendants, environnements bruyants (transport en commun), regard dans une bibliothèque
- Apprentissage : lecture en parallèle de l'écoute renforce la mémorisation
- SEO YouTube : les sous-titres indexent la vidéo dans les recherches

### Méthode
1. **Auto-caption** : CapCut propose une transcription automatique (précision 90 % en français clair). Activer "Auto-captions" sur la piste voix off
2. **Correction manuelle** : vérifier chaque segment, corriger la ponctuation, ajouter les majuscules en début de phrase
3. **Style** : Outfit 24 px, blanc sur fond noir semi-transparent (opacité 60 %), position bas-centre
4. **Sous-titres EN** : traduire depuis le script EN, créer une 2e piste de sous-titres (vidéo YouTube : piste alternative)

### Format d'export
- CapCut : les sous-titres sont intégrés à la vidéo par défaut ("burn-in")
- Pour vidéo YouTube : exporter aussi en .srt ou .vtt (fichier séparé) pour permettre la sélection de langue par l'utilisateur

## 8. Export et intégration

### Réglages d'export
- Format : MP4 (H.264 vidéo, AAC audio)
- Résolution : 1280×720 (720p) — bon compromis qualité/taille
- Frame rate : 30 fps
- Bitrate vidéo : 4-8 Mbps (cible < 10 Mo pour stockage offline)
- Bitrate audio : 192 kbps stéréo
- Container : .mp4

### Stockage
- **Option A (offline-first, recommandée)** : copier le MP4 dans `ExamBoost-Togo/assets/videos/q{NN}_{theme}.mp4`. Ajouter la déclaration au `pubspec.yaml` :
  ```yaml
  flutter:
    assets:
      - assets/videos/
  ```
  L'APK grossit de ~50-80 Mo pour 10 vidéos — acceptable.
- **Option B (streaming)** : uploader sur YouTube en non-listed, récupérer l'URL, stocker dans une map `video_urls.json`. L'app utilise `youtube_player_flutter` ou similaire pour streamer.
- **Option C (hybride)** : streaming par défaut, téléchargement local au 1er visionnage (cache Hive, pattern de `audio_cache_service.dart`).

### Intégration Flutter
Voir `scripts/q01_pythagore_script.md` section "Intégration in-app" pour le snippet de bouton "Voir la vidéo".

Ajouter au `pubspec.yaml` :
```yaml
dependencies:
  video_player: ^2.7.0
  chewie: ^1.7.0  # UI de lecteur avec contrôles
```

### Test
1. Lancer l'app en mode debug
2. Aller sur une question avec `videoExplanationId`
3. Taper "Voir la vidéo (30s)"
4. Vérifier : ouverture du BottomSheet, lecture automatique, contrôles play/pause/progress, bouton "Fermer"
5. Vérifier le son (mute si nécessaire)
6. Vérifier la consommation de données (offline pour Option A)

## 9. Distribution multi-plateformes

### App ExamBoost (priorité 1)
- Stockage des MP4 dans `assets/videos/`
- Intégration via `video_player` + `chewie`
- Bouton "Voir la vidéo" sous chaque explication de question

### YouTube (priorité 2)
- Créer une chaîne YouTube "ExamBoost Togo"
- Uploader les 10 vidéos en mode "Non-listed" (accessible uniquement par lien direct)
- Récupérer les URLs, les stocker dans une map pour fallback streaming
- Avantage : bande passante gratuite, sous-titres multi-langues natifs, recommandations YouTube

### TikTok / Reels (priorité 3, variante verticale)
- Recadrer chaque vidéo en 9:16 (1080×1920) pour format vertical
- Réduire la durée à 15-20 s (version courte pour attention mobile)
- Ajouter un hook visuel dans les 3 premières secondes (ex : "Tu sais résoudre ça en 10 s ?")
- Distribution : TikTok @examboost_togo, Instagram Reels, YouTube Shorts
- Lien en bio : https://examboost.tg/app

## 10. Maintenance et mise à jour

### Fréquence de mise à jour
- Vérifier chaque vidéo avant la nouvelle session d'examens (juin de chaque année)
- Recueillir le feedback des élèves (via bouton "Utile ? Oui/Non" sous la vidéo)
- Mettre à jour les vidéos avec un taux de "Non" > 30 %

### Ajout de nouvelles vidéos
- Suivre le même workflow (1 à 7)
- Nomenclature : `q{NN}_{theme}.mp4` avec NN incrémental
- Mettre à jour `catalog.md` et `README.md`

### Retrait de vidéos obsolètes
- Si une question est retirée du programme officiel togolais, retirer la vidéo correspondante
- Garder l'archive des MP4 dans `docs/video_explanations/archive/` pour référence historique

## 11. Checklist finale (avant publication)

- [ ] Script validé par un enseignant (écrit)
- [ ] Voix off enregistrée (FR), 3 prises minimum, meilleure sélectionnée
- [ ] Voix off EN enregistrée (si version internationale)
- [ ] Animations créées (8 plans, durée conforme au storyboard)
- [ ] SFX placés (jingle, ding, craie, pop)
- [ ] Montage assemblé dans CapCut
- [ ] Sous-titres FR ajoutés et corrigés
- [ ] Sous-titres EN ajoutés (si version internationale)
- [ ] Durée totale conforme (± 0,5 s par rapport au storyboard)
- [ ] Export MP4 < 10 Mo (ou < 15 Mo pour vidéos > 35 s)
- [ ] Test de lecture sur 1 appareil Android physique
- [ ] Copie dans `assets/videos/`
- [ ] Déclaration dans `pubspec.yaml`
- [ ] Mise à jour de `catalog.md` (statut "Produit")
- [ ] Mise à jour de `README.md` (tableau récapitulatif)
- [ ] Upload YouTube non-listed (backup streaming)
- [ ] Test in-app final (bouton "Voir la vidéo" fonctionne)

## 12. Coûts et budget

### Investissement initial (one-shot)
- Micro USB (Blue Yeti ou équivalent) : 80-120 €
- Casque de monitoring : 30-50 € (optionnel)
- **Total investissement** : 80-170 €

### Coûts récurrents (mensuels)
- ElevenLabs Starter (si voix synthèse) : 5 $/mois (30000 caractères)
- Canva Pro éducation : 0 € (gratuit pour enseignants)
- Hébergement YouTube : 0 €
- **Total mensuel** : 0-5 $/mois

### Coût pour 10 vidéos
- Si voix humaine : 0 € (hors investissement matériel) + 40-50 heures de travail
- Si voix synthèse : 5 $ (1 mois ElevenLabs) + 30-40 heures de travail
- **Budget total recommandé** : 100-200 € (incluant investissement matériel) pour produire puis réutiliser sur 50+ vidéos futures

## 13. Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Erreur mathématique dans le script | Moyenne | Critique | Validation par enseignant obligatoire |
| Voix off mal prononcée (termes techniques) | Moyenne | Faible | 3 prises + relecture par un natif |
| Animation qui ne sync pas avec la voix | Élevée | Moyen | Caler les SFX sur des mots-clés précis |
| Vidéo trop lourde (> 15 Mo) | Faible | Faible | Ré-export en 480p si besoin |
| Question retirée du programme | Faible | Moyen | Vérifier chaque année avec le Ministère |
| Voix synthèse ElevenLabs qui change de timbre | Faible | Faible | Pré-générer toutes les voix en 1 mois |

## 14. Contacts et ressources

### Équipe ExamBoost Togo
- Chef de projet : djabelo712 (GitHub)
- Repository : https://github.com/djabelo712/ExamBoost-Togo

### Enseignants validateurs (à contacter)
- Prof de maths BEPC : à identifier (Inspection académique de Lomé)
- Prof de physique BEPC : à identifier
- Prof de français BEPC : à identifier
- Prof de maths BAC C : à identifier (Lycée de Tokoin, Lycée de Bè)

### Ressources externes
- Canva Pro éducation : https://www.canva.com/education/
- ElevenLabs : https://elevenlabs.io
- Pixabay Music (SFX gratuits) : https://pixabay.com/music/
- Manim (Python) : https://www.manim.community/
- CapCut : https://www.capcut.com/
- Whisper (sous-titres auto) : https://github.com/openai/whisper
