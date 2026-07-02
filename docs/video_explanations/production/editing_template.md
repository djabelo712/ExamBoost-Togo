# Template de montage CapCut / Premiere Pro — ExamBoost Togo

Ce template décrit la structure de timeline, les transitions, le style des textes overlay, le placement SFX et les réglages d'export à appliquer à toutes les vidéos ExamBoost Togo. L'objectif est d'assurer une cohérence visuelle et sonore entre les 10 vidéos du catalogue.

## 1. Configuration du projet

### CapCut (desktop)
- **Type de projet** : Vidéo 16:9
- **Résolution** : 1280×720 (720p)
- **Frame rate** : 30 fps
- **Couleur** : sRGB (par défaut)
- **Nom du projet** : `q{NN}_{theme}_capcut` (ex : `q01_pythagore_capcut`)

### Premiere Pro (si Adobe CC disponible)
- **Preset** : Digital SLR → 720p → DSLR 720p30
- **Sequence name** : `q{NN}_{theme}_premiere`
- **Working color space** : Rec.709

## 2. Structure de la timeline (5 pistes)

```
┌─────────────────────────────────────────────────────────────┐
│ Piste 5 (texte) : sous-titres FR + EN                       │
├─────────────────────────────────────────────────────────────┤
│ Piste 4 (audio) : musique de fond (optionnel, -25 dBFS)     │
├─────────────────────────────────────────────────────────────┤
│ Piste 3 (audio) : SFX (ding, craie, pop, jingle)            │
├─────────────────────────────────────────────────────────────┤
│ Piste 2 (audio) : voix off principale (FR)                  │
├─────────────────────────────────────────────────────────────┤
│ Piste 1 (vidéo) : animation Canva/Manim complète            │
└─────────────────────────────────────────────────────────────┘
```

### Rationale
- Piste 1 (vidéo) en bas : c'est la base visuelle
- Piste 2 (voix) juste au-dessus : le son le plus important
- Piste 3 (SFX) : effets ponctuels calés sur la voix
- Piste 4 (musique) : optionnelle, toujours en-dessous de la voix pour ne pas masquer
- Piste 5 (texte) au sommet : sous-titres visibles par-dessus tout

## 3. Timeline type (8 plans sur 30 s)

Basée sur le storyboard Q01 Pythagore, à adapter pour les autres vidéos.

| Timecode | Piste 1 (vidéo) | Piste 2 (voix) | Piste 3 (SFX) | Piste 4 (musique) | Piste 5 (sous-titres) |
|---|---|---|---|---|---|
| 0:00-0:03 | Logo + titre "Pythagore" | (silence) | jingle_debut.mp3 (0-0,5s) | (silence) | "[ExamBoost Togo] Pythagore" |
| 0:03-0:07 | Triangle dessiné | "Pour calculer l'hypoténuse..." | — | musique -25 dB | "Pour calculer l'hypoténuse..." |
| 0:07-0:12 | Formule BC²=AB²+AC² | "...on utilise Pythagore..." | ding à 0:07,5 | musique -25 dB | "...on utilise Pythagore..." |
| 0:12-0:16 | Valeurs AB=6, AC=8 | "Ici, AB = 6, AC = 8." | — | musique -25 dB | "Ici, AB = 6, AC = 8." |
| 0:16-0:21 | Calcul 6²+8²=100 | "Donc BC² = 36 + 64..." | craie à 0:16,5 et 0:18 | musique -25 dB | "Donc BC² = 36 + 64, ça donne 100." |
| 0:21-0:25 | √100=10 | "Et la racine de 100..." | pop à 0:21,5 | musique -25 dB | "Et la racine de 100, c'est 10." |
| 0:25-0:28 | BC=10 cm + checkmark | "Donc BC = 10 cm..." | jingle_fin à 0:27 | musique -25 dB | "Donc BC = 10 cm. Le triplet 6-8-10 est un classique, retiens-le !" |
| 0:28-0:30 | Outro + QR | (silence) | — | musique fondu 0:28-0:30 | "Télécharge l'app" |

## 4. Transitions recommandées

### Entre plans 1 → 2 (logo → contenu)
- **Transition** : Cross Dissolve (fondu enchaîné)
- **Durée** : 0,3 s
- **Rationale** : passe du fond vert au fond blanc en douceur

### Entre plans 2 → 3, 3 → 4, 4 → 5, 5 → 6, 6 → 7
- **Transition** : CUT SEC (pas de transition)
- **Rationale** : la voix off enchaîne naturellement, l'animation évolue sans rupture visuelle

### Entre plans 7 → 8 (résultat → outro)
- **Transition** : Fade to Black (fondu au noir) puis fondu vers vert Togo
- **Durée** : 0,5 s
- **Rationale** : clôture visuelle marquée avant l'outro

### À ÉVITER
- Transitions tape-à-l'œil : zoom, rotation, push, slide latéral
- Effets 3D : cube, fold
- Filtres colorés vintage ou film grain
- Texte animé avec rebonds excessifs

## 5. Style des textes overlay

### Sous-titres (piste 5)
- **Police** : Outfit (Google Fonts, télécharger et installer)
- **Taille** : 24 pt
- **Graisse** : Regular (400)
- **Couleur texte** : Blanc #FFFFFF
- **Fond** : Noir #000000 semi-transparent (opacité 60 %), padding 8 px horizontal / 4 px vertical, coins arrondis 4 px
- **Position** : Bas-centre, marges 40 px du bas
- **Durée par sous-titre** : 2-4 s (jamais plus de 6 s, découper en 2)
- **Césure** : 1-2 lignes max par sous-titre, max 35 caractères par ligne

### Étiquettes volantes (dans l'animation Canva/Manim, pas en overlay)
- **Police** : Outfit (étiquettes courtes) ou Times New Roman (formules)
- **Taille** : 14-18 pt selon le contexte
- **Couleur** : Noir ou Orange #D97700 pour les valeurs mises en valeur
- **Animation d'apparition** : Fade-in 0,3 s

### Titres de plan (overlay optionnel, piste 5)
- Non utilisé dans les vidéos ExamBoost V1 (les plans sont suffisamment clairs sans titres redondants)

## 6. Music bed (piste 4)

### Choix de la musique
- **Genre** : Lo-fi hip-hop instrumentale (beats calmes, sans voix)
- **BPM** : 80-100 (lent à modéré, pédagogique)
- **Volume** : -25 dBFS (très en dessous de la voix à -12 dBFS)
- **Source** : YouTube Audio Library (gratuit, libre de droits) ou Pixabay Music
- **Playlist recommandée** : "ExamBoost_bgm_v1" (à créer sur YouTube Audio Library)

### Quand utiliser la musique
- **OUI** : durant tout le corps de la vidéo (plans 2 à 7), à -25 dBFS
- **NON** : durant le logo (plan 1) et l'outro (plan 8) — laisser le jingle seul

### Fondu musique
- Fade-in musique : 0,5 s au début du plan 2
- Fade-out musique : 1,0 s à la fin du plan 7 (avant le jingle_fin)

## 7. SFX placement (piste 3)

### Bibliothèque SFX (à constituer)
| Nom | Source | Durée | Volume | Usage |
|---|---|---|---|---|
| jingle_debut.mp3 | Pixabay Music | 0,5 s | -6 dBFS | Logo début (plan 1) |
| jingle_fin.mp3 | Pixabay Music | 0,5 s | -6 dBFS | Conclusion (plan 7) |
| ding.mp3 | Freesound.org | 0,2 s | -12 dBFS | Apparition formule/clé |
| craie.mp3 | Freesound.org | 0,3 s | -15 dBFS | Calcul écrit |
| pop.mp3 | Freesound.org | 0,15 s | -10 dBFS | Apparition résultat |
| son_stylo.mp3 | Freesound.org | 0,4 s | -18 dBFS | Annotation |
| shimmer.mp3 | Freesound.org | 0,5 s | -15 dBFS | Effet scintillement (métaphore) |
| son_scan.mp3 | Freesound.org | 0,5 s | -18 dBFS | Recherche (loupe) |

### Règles de placement
- **Ding** : à chaque apparition de formule clé (Pythagore, Thalès, U=RI, etc.) ou d'étiquette importante (métaphore, subjonctif)
- **Craie** : pendant les calculs écrits (6²+8², 3x=15, etc.), synchronisé sur l'animation d'écriture
- **Pop** : à l'apparition du résultat final (BC=10 cm, x=5, A=20 cm², etc.)
- **Jingle_debut** : sur le logo du plan 1, sans chevauchement avec la voix
- **Jingle_fin** : à la fin du plan 7 (résultat), 0,5 s avant la transition vers l'outro
- **Stylo** : pendant les annotations manuscrites (a=x, b=3, etc.)

### À ÉVITER
- SFX continu (sons d'ambiance type "forêt" ou "ville") — distrait
- SFX trop fort (> -10 dBFS) — masque la voix
- Plus de 3 SFX par 10 s — surcharge cognitive

## 8. Color grading (léger)

### Objectif
Pas de correction colorimétrique lourde — les couleurs sont volontairement saturées pour le style éducatif. Juste un léger ajustement pour cohérence.

### Réglages (à appliquer sur la piste 1 entière)
- **Luminosité** : +5 % (clarifier légèrement)
- **Contraste** : +10 % (renforcer les couleurs)
- **Saturation** : +5 % (couleurs plus vives, surtout le vert Togo)
- **Température** : 0 (neutre, ne pas réchauffer)
- **Teinte** : 0 (neutre)

### LUTs
- Pas de LUT (Look-Up Table) — garder l'aspect naturel

## 9. Export settings

### CapCut
- **Format** : MP4
- **Résolution** : 1280×720
- **Frame rate** : 30 fps
- **Codec vidéo** : H.264 (par défaut)
- **Bitrate vidéo** : 6 Mbps (cible < 10 Mo pour 30 s)
- **Codec audio** : AAC
- **Bitrate audio** : 192 kbps
- **Canaux audio** : Stéréo
- **Sample rate** : 44 100 Hz

### Premiere Pro (si utilisé)
- **Format** : H.264
- **Preset** : Match Source - High bitrate
- **VBR 2-pass** : target 6 Mbps, max 8 Mbps
- **Audio** : AAC, 192 kbps, 48 kHz, Stéréo

### Nomenclature fichier exporté
- `q{NN}_{theme}.mp4` (ex : `q01_pythagore.mp4`)
- Tout en minuscules, snake_case, pas d'espaces ni d'accents

## 10. Fichiers de sortie (par vidéo)

| Fichier | Format | Destination | Taille attendue |
|---|---|---|---|
| `q{NN}_{theme}.mp4` | MP4 720p H.264 | `assets/videos/` | 5-10 Mo |
| `q{NN}_{theme}_FR.srt` | WebVTT | `assets/videos/subtitles/` | 2-5 Ko |
| `q{NN}_{theme}_EN.srt` | WebVTT | `assets/videos/subtitles/` | 2-5 Ko |
| `q{NN}_{theme}_FR.mp3` | MP3 192 kbps | `assets/audio/` | 1-2 Mo |
| `q{NN}_{theme}_EN.mp3` | MP3 192 kbps | `assets/audio/` | 1-2 Mo |
| `q{NN}_{theme}_thumbnail.jpg` | JPG 1280×720 | `docs/video_explanations/thumbnails/` | 100-200 Ko |

### Thumbnail (vignette YouTube)
- Frame extraite du plan 7 (résultat final)
- Ajout du logo ExamBoost en haut à droite (50×50 px)
- Ajout du titre de la vidéo en bas ("Pythagore en 30 secondes") Outfit 36 px gras blanc avec ombre portée
- Format : JPG, 1280×720, qualité 90 %

## 11. Versioning et archivage

### Versioning
- Chaque vidéo a un numéro de version : `v1.0`, `v1.1` (correction mineure), `v2.0` (refonte majeure)
- Le nom du fichier ne contient PAS la version (toujours `q01_pythagore.mp4`)
- La version est tracée dans `catalog.md` colonne "Version"

### Archivage
- Projet CapCut/Premiere archivé dans `docs/video_explanations/raw_projects/q{NN}_{theme}/`
- Tous les assets (animations Canva exportées, voix off brutes, SFX utilisés) dans le même dossier
- Permet de re-monter la vidéo sans tout refaire si une correction est nécessaire

## 12. Validation finale avant publication

- [ ] Timeline conforme au storyboard (8 plans, durées correctes)
- [ ] Voix off synchronisée avec l'animation (pas de décalage > 0,2 s)
- [ ] SFX placés aux bons moments (ding, craie, pop, jingle)
- [ ] Sous-titres FR corrects et bien placés
- [ ] Sous-titres EN corrects (si version internationale)
- [ ] Musique de fond à -25 dBFS (audible mais pas envahissante)
- [ ] Pas de bruits parasites (clavier, respiration, estomac)
- [ ] Color grading appliqué (luminosité +5 %, contraste +10 %, saturation +5 %)
- [ ] Durée totale conforme (± 0,5 s du storyboard)
- [ ] Export MP4 < 10 Mo (ou < 15 Mo pour vidéos > 35 s)
- [ ] Thumbnail généré
- [ ] Fichiers de sortie copiés aux bons endroits (`assets/videos/`, `assets/audio/`, etc.)
- [ ] Vérification visuelle finale (regarder la vidéo en entier 1 fois)

## 13. Variantes futures

### Variante verticale 9:16 (TikTok / Reels / Shorts)
- Recadrer le projet en 1080×1920
- Déplacer les éléments vers le centre (pas de coupures sur les côtés)
- Ajouter un hook visuel dans les 3 premières secondes (texte "Tu sais ?")
- Réduire la durée à 15-20 s (version courte)
- Export : MP4 H.264, 1080×1920, 30 fps, 8 Mbps

### Variante "Astuce examen"
- À partir du même storyboard, créer une version "astuce" qui mentionne le raccourci (ex : "0,5 = 1/2 donc 20×0,5 = 10")
- Durée identique (30 s), mais ton plus "décontracté"
- SFX différents (jingle plus rythmé, pop plus marqué)

### Variante "Erreur classique"
- 5 vidéos courtes (15-20 s) montrant les erreurs fréquentes
- Ex : "Pythagore dans un triangle NON rectangle : erreur fréquente"
- Format : écran partagé (erreur à gauche, correction à droite)
- Distribution : TikTok et Instagram Reels
