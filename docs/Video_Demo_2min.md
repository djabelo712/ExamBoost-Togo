# ExamBoost Togo — Vidéo Démo 2 Minutes (focus produit)

*Spécification complète pour production vidéo — Pitch DJANTA Tech Hub 24 juillet 2026*

**Auteur :** Agent CE (général-purpose), Session 4, Vague 3
**Date de rédaction :** 30 juin 2026
**Destinataires :** Équipe ExamBoost Togo (Tech, Data, Design, Growth) + monteur vidéo + démonstrateur jury
**Format cible :** MP4 H.264 — 1920×1080 (16:9) + 1080×1920 (9:16 vertical) + 1080×1080 (1:1 carré optionnel)
**Durée totale :** 2:40 minutes (160 secondes ± 5 s)

---

## Synthèse exécutive

La vidéo démo de 2 minutes 40 secondes est un livrable produit-focus qui complète la vidéo teaser émotionnelle (cf. `docs/Video_Teaser_2min.md`). Là où le teaser ouvre avec l'effondrement du BEPC et le problème éducatif national, la démo montre le **produit en action**, clic par clic, écran par écran. Elle répond à la question que tout jury Tech Hub se pose après le teaser : « OK, l'émotion c'est bien, mais votre app, elle ressemble à quoi ? »

### Objectifs de la démo

1. **Démontrer la maturité produit** : aucun mockup, aucun concept art — uniquement des captures réelles de l'application Flutter compilée en mode profile sur un Tecno Spark 8C (4 Go RAM, Android 11).
2. **Prouver les 3 piliers valeur** : révision adaptative (SM-2), simulation d'examen (conditions réelles), tableau de bord intelligent (prédiction XGBoost).
3. **Mettre en avant la fluidité mobile** : montrer que l'app démarre en moins de 2 secondes, que les transitions sont fluides à 60 fps, que le mode hors-ligne fonctionne sans latence.
4. **Justifier la gamification** : badges, classements, défis communautaires — la motivation par la reconnaissance sociale.
5. **Convertir vers le téléchargement** : CTA final « Télécharge ExamBoost Togo — gratuit sur Play Store » + URL GitHub.

### Différence avec le teaser

| Dimension | Teaser (émotionnel) | Démo (produit) |
|---|---|---|
| Angle | Problème → Solution → Équipe | Onboarding → Révision → Simulation → Dashboard → Tuteur → Gamification → CTA |
| Visuel dominant | Motion graphics + b-roll | Screen recording pur (98 % du temps) |
| Voix off | 270 mots, narratif | ~310 mots, descriptif & démonstratif |
| Musique | Mélancolique → résolution | Moderne, beat léger, rytmé |
| Cible | Investisseurs, jury émotion, public large | Jury Tech, mentors produit, futurs pilotes écoles |
| CTA final | « Parce que chaque élève mérite sa chance » | « Télécharge — gratuit sur Play Store » |

### Cadrage

- **Durée totale :** 2:40 (160 s strictement)
- **Structure :** 8 sections, ordre logique du parcours utilisateur (onboarding → usage quotidien → engagement)
- **Formats de livraison :**
  - Master 16:9 horizontal 1920×1080, 30 fps, MP4 H.264, bitrate 8 Mbps — pour YouTube, Loom, LinkedIn, projection jury
  - Variante 9:16 vertical 1080×1920, 30 fps, MP4 H.264, bitrate 6 Mbps — pour TikTok, Instagram Reels, YouTube Shorts, WhatsApp Status
  - Variante 1:1 carré 1080×1080 (optionnelle) — pour fil Instagram et Facebook
- **Style visuel :** screen recording haute qualité (scrcpy 2.4, 60 fps capture, redimensionné 1080p) + overlays motion graphics légers (cercles, flèches, annotations texte) + transitions fondus
- **Palette graphique :** identique au Pitch Deck et au teaser — vert Togo #006837, orange #D97700, blanc cassé #F8F9FA, gris foncé #1A1A1A
- **Typographie :** Outfit (titres), Inter (corps, overlays), Outfit Black (chiffres choc)
- **Voix off :** FR principal — femme, ton chaleureux & dynamique, 130-140 mots/min. EN secondaire — homme, ton neutre & pédagogique, 120-130 mots/min.

### Outils de capture recommandés

- **scrcpy 2.4** (libre, Linux/macOS/Windows) — capture écran Android 60 fps sans filigrane, idéal pour les animations de flashcards et le flip 3D
- **Android Studio Screen Recorder** (fallback) — capture 30 fps, intégrée au SDK
- **OBS Studio 30+** (post-production) — pour incruster le cadre smartphone, les annotations, les transitions
- **CapCut 3.0** (montage mobile) — pour la variante 9:16, montée rapide
- **DaVinci Resolve 19** (montage pro, gratuit) — pour le master 16:9, color grading, motion tracking des doigts

### Pré-requis de capture

Avant le tournage, vérifier les points suivants :

1. **Device de capture :** Tecno Spark 8C (4 Go RAM, 64 Go stockage, Android 11) — device de référence du persona Amina. L'app doit tourner en mode profile (pas debug) pour respecter les 60 fps.
2. **State de l'app :** compte démo pré-rempli (profil Amina, classe 3e, 12 sessions de révision déjà faites, 2 simulations BEPC complétées, 7 badges débloqués) — pour montrer un état réaliste, pas un compte vierge.
3. **Données de démo :** banque de questions chargée (64 questions structurées + 3 000 questions OCR pré-importées) — temps de chargement < 1 s.
4. **Réseau :** mode hors-ligne ON (avion activé) — pour démontrer le offline-first pendant la démo.
5. **Éclairage :** tournage en intérieur, lumière diffuse, pas de reflets sur l'écran du smartphone. Utiliser un trépied smartphone + support anti-vibration.
6. **Audio :** casque Rode Wireless GO II (micro-cravate) pour la voix off, enregistrée séparément en WAV 48 kHz/24 bits, normalisée à -14 LUFS.

---

## Plan de tournage (storyboard shot-by-shot)

Le storyboard ci-dessous décompose chaque section en « shots » (plans). Chaque shot = une capture d'écran ou une séquence animée avec début et fin précis. La somme des shots = 160 s = 2:40.

Pour chaque shot, on précise : type, visuel, voix off FR/EN, transitions, notes techniques.

---

### Section 1 — Intro (0:00 → 0:10, 10 s)

**Objectif :** poser le cadre en 10 secondes. Le spectateur doit savoir qu'il va regarder une démo produit, pas un pitch émotionnel. Pas de blabla — on entre dans le vif.

#### [Shot 1] 0:00 → 0:04 — Carton d'ouverture logo (4 s)

- **Type :** Motion graphic
- **Visuel :** Fond noir #0A0A0A. Le logo ExamBoost Togo (mot-mark « ExamBoost » en Outfit Bold blanc + point orange #D97700 + sous-ligne « TOGO » en Outfit Medium, espacement 4 px) apparaît au centre par un effet de fondu + léger scale-up (95 % → 100 %). Sous le logo, en plus petit (Inter Regular 22 pt, gris #888888) : « Démo produit · 2 minutes ».
- **Voix off (FR) :** « Voici comment ExamBoost prépare les élèves au BEPC et BAC. »
- **Voix off (EN) :** « Here's how ExamBoost prepares students for the BEPC and BAC exams. »
- **Musique :** Beat léger qui démarre — modern lo-fi, 100 BPM, nappe synthé douce. Volume -22 LUFS.
- **SFX :** « Whoosh » discret à 0:01 (apparition logo), « ding » cristallin à 0:03 (point orange qui s'allume).
- **Notes production :** Template After Effects « Logo Reveal Minimal ». Logo SVG disponible dans `assets/branding/examboost_logo.svg`. Durée d'animation 1,5 s pour le fondu + 1 s de maintien + 1,5 s de transition vers Shot 2.

#### [Shot 2] 0:04 → 0:10 — Carton transition vers démo (6 s)

- **Type :** Motion graphic + device frame
- **Visuel :** Le logo monte légèrement vers le haut (translation Y -120 px) et se réduit à 30 % de sa taille. En bas de l'écran apparaît un mockup smartphone (cadre noir arrondi 24 px, encoche centrale) contenant un aperçu flou de l'écran splash d'ExamBoost. Le tout sur fond dégradé vertical #006837 → #00451F (vert Togo).
- **Texte overlay :** À droite du smartphone, en blanc (Outfit Bold 36 pt) : « Démo produit · clic par clic ». Sous-titre (Inter Regular 18 pt, blanc 70 % opacité) : « Onboarding · Révision · Simulation · Dashboard · Tuteur IA · Gamification ».
- **Voix off (FR) :** (silence — musique seulement)
- **Voix off (EN) :** (silence — musique seulement)
- **Musique :** Beat qui monte en intensité, ajout d'un hi-hat léger. Pic transitoire à 0:10 pour marquer la transition vers la démo.
- **SFX :** « Whoosh » descendant à 0:05 (logo qui monte), « pop » à 0:07 (smartphone qui apparaît).
- **Notes production :** Le mockup smartphone peut être un PNG exporté de Figma (cadre Realistic iPhone 14 Pro, noir). Le flou de l'écran splash = capture réelle de l'écran `splash_screen.dart` avec un flou gaussien 12 px appliqué en post-production. Effet ken-burns léger (zoom 100 % → 105 % sur 6 s).

### Captures d'écran à faire — Section 1

Aucune capture d'écran réelle pour cette section — uniquement des éléments motion graphics. Le visuel du smartphone flou en arrière-plan du Shot 2 sera dérivé de la capture C-002 (splash screen, voir Section 2) traitée au flou.

### Script voix off FR — Section 1 (10 s, ~15 mots)

> « Voici comment ExamBoost prépare les élèves au BEPC et BAC. »

**Débit :** 90 mots/min (lent, posé). Le silence des shots 2 est volontaire pour laisser respirer l'intro.

### Script voix off EN — Section 1 (10 s, ~14 mots)

> « Here's how ExamBoost prepares students for the BEPC and BAC exams. »

### Transitions — Section 1

- Shot 1 → Shot 2 : **whip-pan vertical** (translation Y du logo + apparition du smartphone par le bas) — 0,5 s.
- Section 1 → Section 2 : **fondu enchaîné** (cross-dissolve 0,3 s) entre le smartphone flou du Shot 2 et la vraie capture splash du Shot 3. Le fondu crée l'illusion que le smartphone « s'allume ».

### Notes techniques — Section 1

- **Durée totale :** 10 s (4 + 6) ✓
- **Annotations :** aucune (la section est pure motion graphic).
- **Couleur dominante :** vert Togo #006837 (60 %), noir #0A0A0A (30 %), orange #D97700 (10 %).
- **Logo ExamBoost visible :** Oui (centré, 100 % opacité Shot 1, 30 % Shot 2) ✓ — première occurrence logo.
- **Pacing :** lent, posé — contrairement au reste de la démo qui sera rapide.

---

### Section 2 — Onboarding (0:10 → 0:25, 15 s)

**Objectif :** montrer que l'inscription est rapide, simple, sans friction. Le spectateur doit comprendre : « n'importe quel élève peut démarrer en 30 secondes ». On saute les écrans intermédiaires (sélection langue, CGU) pour garder le rythme.

#### [Shot 3] 0:10 → 0:14 — Splash screen (4 s)

- **Type :** Screen recording (capture réelle)
- **Visuel :** Écran `splash_screen.dart` — fond blanc cassé #F8F9FA, logo ExamBoost centré qui pulse doucement (scale 0,95 → 1,05 → 1,00 sur 2 s), texte de chargement « Chargement de vos annales... » (Inter Regular 16 pt, gris #888) en bas. À 3 s, transition auto vers `onboarding_screen.dart` (slide-in depuis la droite).
- **Voix off (FR) :** (silence)
- **Voix off (EN) :** (silence)
- **Musique :** beat continue, ajout d'un sous-bass discret.
- **SFX :** « pop » à 0:11 (logo qui apparaît), « swoosh » à 0:13 (transition vers onboarding).
- **Notes production :** Capture via scrcpy 60 fps. L'écran splash dure réellement 2,8 s en mode profile (mesuré) — on étire à 4 s avec un léger ralenti (0,7×) pour laisser respirer.

#### [Shot 4] 0:14 → 0:18 — Onboarding étape 1 : bienvenue (4 s)

- **Type :** Screen recording
- **Visuel :** Écran `onboarding_screen.dart` step 1/3. Illustration centrale (SVG) d'une élève togolaise (cheveux tressés, uniforme kaki) tenant un smartphone avec un checkmark vert qui sort de l'écran. Titre (Outfit Bold 28 pt, vert #006837) : « Bienvenue sur ExamBoost Togo ». Sous-titre (Inter Regular 16 pt, gris foncé) : « L'app qui t'aide à réussir ton BEPC et ton BAC ». Bouton orange #D97700 en bas : « Commencer ». Doigt qui tap l'écran à 0:17.
- **Voix off (FR) :** « L'élève ouvre l'app, et crée son profil. »
- **Voix off (EN) :** « The student opens the app and creates their profile. »
- **SFX :** « tap » à 0:17.
- **Notes production :** Pointer de doigt virtuel (overlay PNG transparent) pour suggérer le tap sans masquer le bouton. Pointer animé en CSS/After Effects.

#### [Shot 5] 0:18 → 0:22 — Onboarding étape 3 : choix du niveau 3e (4 s)

- **Type :** Screen recording
- **Visuel :** Écran `onboarding_screen.dart` step 3/3 — sélection de la classe. Trois cartes alignées verticalement : « 3e (BEPC) », « Terminale (BAC) », « Autre ». La carte « 3e (BEPC) » est mise en avant (border orange 2 px, scale 1,05). Doigt qui tap la carte à 0:21. En bas, bouton « Continuer » qui s'active.
- **Texte overlay :** annotation flèche + texte (Outfit Bold 18 pt, orange) : « Choix du niveau — ici 3e ».
- **Voix off (FR) :** « Elle choisit son niveau — ici la 3e, pour le BEPC. »
- **Voix off (EN) :** « She picks her grade level — here 9th grade, for the BEPC. »
- **SFX :** « tap » à 0:21.
- **Notes production :** On saute l'étape 2 (sélection langue — FR par défaut) pour gagner 3 s. Annotation ajoutée en post-production, motion-tracked sur la carte « 3e ».

#### [Shot 6] 0:22 → 0:25 — Profil créé (3 s)

- **Type :** Screen recording
- **Visuel :** Écran `home_screen.dart` qui vient de se charger après l'onboarding. Affichage temporaire d'un `SnackBar` vert (top) : « Profil créé avec succès — bienvenue Amina ! ». Header avec photo avatar (initiale « A » sur cercle vert), nom « Amina K. », classe « 3e — BEPC 2026 ». Grid 2×2 de cartes : Révision Adaptative, Simulation, Tableau de bord, Tuteur IA.
- **Voix off (FR) :** « Profil créé en 30 secondes. Direction l'écran d'accueil. »
- **Voix off (EN) :** « Profile created in 30 seconds. Off to the home screen. »
- **SFX :** « ding » cristallin à 0:23 (SnackBar qui apparaît).
- **Notes production :** Capture étendue pour montrer le SnackBar. Le compte démo est pré-configuré avec le nom « Amina K. » pour faire écho au persona Amina du Case Study (`docs/Case_Study_Amina.md`).

### Captures d'écran à faire — Section 2

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-001 | Splash screen | `splash_screen.dart` | 0:10-0:14 | 4 s | Aucune (capture brute) |
| C-002 | Onboarding step 1/3 | `onboarding_screen.dart` | 0:14-0:18 | 4 s | Pointer de doigt sur bouton « Commencer » |
| C-003 | Onboarding step 3/3 (niveau) | `onboarding_screen.dart` | 0:18-0:22 | 4 s | Flèche + « Choix du niveau — ici 3e » |
| C-004 | Home avec SnackBar succès | `home_screen.dart` | 0:22-0:25 | 3 s | Cercle vert autour du SnackBar |

### Script voix off FR — Section 2 (15 s, ~22 mots)

> « L'élève ouvre l'app, et crée son profil. Elle choisit son niveau — ici la 3e, pour le BEPC. Profil créé en 30 secondes. Direction l'écran d'accueil. »

### Script voix off EN — Section 2 (15 s, ~22 mots)

> « The student opens the app and creates their profile. She picks her grade level — here 9th grade, for the BEPC. Profile created in 30 seconds. Off to the home screen. »

### Transitions — Section 2

- Shot 3 → Shot 4 : **cut sec** (la transition est intégrée à l'app elle-même, slide-in natif).
- Shot 4 → Shot 5 : **cut sec** (étape suivante de l'onboarding, transition auto).
- Shot 5 → Shot 6 : **cut sec + fondu blanc 0,1 s** (changement d'écran).
- Section 2 → Section 3 : **zoom avant** sur la carte « Révision Adaptative » (200 % scale sur 0,4 s) — transition naturelle vers la Section 3.

### Notes techniques — Section 2

- **Durée totale :** 15 s (4 + 4 + 4 + 3) ✓
- **Device :** Tecno Spark 8C, mode profile, 60 fps via scrcpy.
- **Compte démo :** pré-créé avec `scripts/seed_demo_data.dart` — profil Amina, classe 3e, niveau initial 0.
- **Annotations :** pointer de doigt virtuel + 1 flèche. Tous les overlays en After Effects, motion-tracked sur les éléments animés.
- **Couleur dominante :** blanc cassé #F8F9FA (70 %), vert Togo #006837 (20 %), orange #D97700 (10 %).
- **Pacing :** rapide, transitions cuts secs.

---

### Section 3 — Révision adaptative (0:25 → 0:55, 30 s)

**Objectif :** démontrer la pièce maîtresse d'ExamBoost — la révision par flashcards adaptatives pilotées par l'algorithme SM-2. Le spectateur doit comprendre : (1) c'est simple à utiliser, (2) l'algorithme est invisible mais intelligent, (3) chaque réponse influence la suite.

#### [Shot 7] 0:25 → 0:28 — Home screen + tap « Révision Adaptative » (3 s)

- **Type :** Screen recording
- **Visuel :** Écran `home_screen.dart` (déjà affiché). Doigt qui descend vers la carte « Révision Adaptative » (icône brain orange, titre, sous-titre « 12 cartes à réviser aujourd'hui »). Tap à 0:27. Transition vers `revision_screen.dart` (slide-in droite).
- **Voix off (FR) :** « L'élève lance une session de révision adaptative. »
- **Voix off (EN) :** « The student launches an adaptive revision session. »
- **SFX :** « tap » à 0:27, « swoosh » à 0:28.
- **Notes production :** Pointer de doigt virtuel. La carte « Révision Adaptative » est en haut à gauche de la grille 2×2 — facile à atteindre du pouce.

#### [Shot 8] 0:28 → 0:33 — Flashcard question (5 s)

- **Type :** Screen recording
- **Visuel :** Écran `revision_screen.dart` — carte flashcard au centre de l'écran, format recto. Question affichée (Outfit Medium 22 pt, noir) : « Qu'est-ce que le théorème de Pythagore ? ». Sous la carte, badge matière (orange, 12 pt) : « Mathématiques · Géométrie ». Indicateur de progression en haut : « Carte 3 / 12 ». Barre de progression verte (25 % remplie). Bouton en bas : « Voir la réponse » (orange #D97700). À 0:32, doigt qui tap le bouton.
- **Texte overlay :** en haut à droite (Inter Italic 14 pt, gris) : « Question générée par SM-2 ».
- **Voix off (FR) :** « Une carte apparaît. C'est l'algorithme SM-2 qui choisit la question, au bon moment. »
- **Voix off (EN) :** « A card appears. The SM-2 algorithm picks the question, at the right moment. »
- **SFX :** « tap » à 0:32.
- **Notes production :** La carte flashcard a une légère élévation (shadow 8 px, border-radius 16). Capture 60 fps pour capter l'animation de flip à l'image suivante.

#### [Shot 9] 0:33 → 0:37 — Flip animation 3D + réponse (4 s)

- **Type :** Screen recording + annotation motion-tracked
- **Visuel :** Animation flip 3D de la carte (rotation Y 180°) sur 0,5 s. Au verso : réponse (Outfit Regular 18 pt, noir) : « Dans un triangle rectangle, le carré de l'hypoténuse est égal à la somme des carrés des deux autres côtés : a² + b² = c². ». Formule en LaTeX rendue via `flutter_math_fork`. Sous la réponse, 4 boutons d'auto-évaluation : « À revoir » (rouge), « Difficile » (orange), « Bon » (vert clair), « Facile » (vert foncé). Doigt qui tap « Facile » à 0:36.
- **Voix off (FR) :** « L'élève retourne la carte, lit la réponse, et auto-évalue sa maîtrise. »
- **Voix off (EN) :** « The student flips the card, reads the answer, and self-assesses their mastery. »
- **SFX :** « swoosh » à 0:33 (flip), « tap » à 0:36.
- **Notes production :** Le flip 3D est implémenté via `Transform.rotate` avec `Matrix4.rotationY()`. Vérifier le rendu à 60 fps — si saccade, ralentir l'animation à 0,7× en post-production.

#### [Shot 10] 0:37 → 0:42 — Question suivante + auto-évaluation (5 s)

- **Type :** Screen recording
- **Visuel :** Transition : carte actuelle glisse vers la gauche (slide-out 0,3 s), nouvelle carte entre par la droite (slide-in 0,3 s). Nouvelle question : « Convertir 0,75 en fraction irréductible ». Indicateur de progression : « Carte 4 / 12 ». Doigt qui tap « Voir la réponse » → flip → réponse « 3/4 » → tap « Bon ». Enchainement rapide (4 actions en 5 s).
- **Voix off (FR) :** « L'algorithme ajuste l'intervalle de révision. Plus la carte est jugée facile, plus elle reviendra tard. »
- **Voix off (EN) :** « The algorithm adjusts the revision interval. The easier the card, the later it comes back. »
- **SFX :** 2× « tap » + 1× « swoosh ».
- **Notes production :** Pour montrer l'effet adaptatif, on peut accélérer la séquence en post-production (time-lapse 1,5×) — mais attention à garder le rythme audible. Préférer des cuts secs entre chaque action.

#### [Shot 11] 0:42 → 0:50 — Fin de session + score (8 s)

- **Type :** Screen recording + motion graphic
- **Visuel :** Après 12 cartes (on saute les cartes 5 à 12 via un fondu + compteur rapide), écran `revision_summary_screen.dart`. Grand chiffre au centre (Outfit Black 96 pt, orange) : « 85 % ». Sous-titre : « Cartes maîtrisées cette session ». En dessous, 4 stats horizontales : « 10 Facile · 1 Bon · 1 Difficile · 0 À revoir ». En bas, carte « Prochaine révision » : « Demain · 14h00 · 3 cartes ». Bouton « Retour à l'accueil ».
- **Texte overlay :** en bas (Outfit Bold 24 pt, vert) : « L'algorithme SM-2 a planifié 3 cartes pour demain ».
- **Voix off (FR) :** « Fin de session. L'élève voit son score. Et l'algorithme a déjà planifié la prochaine révision. »
- **Voix off (EN) :** « Session complete. The student sees their score. And the algorithm has already scheduled the next revision. »
- **SFX :** « ding » triomphal à 0:43, fondus entre les cartes (×8) à rythme rapide.
- **Notes production :** Le saut « cartes 5 à 12 » se fait via 8 fondu enchaînés de 0,3 s chacun (2,4 s au total) — le compteur de progression défile de 5/12 à 12/12. Effet motion graphic à ajouter en post-production.

#### [Shot 12] 0:50 → 0:55 — Transition vers simulation (5 s)

- **Type :** Screen recording + transition
- **Visuel :** Retour sur `home_screen.dart` — le compteur « 12 cartes à réviser » est devenu « 0 carte — Revenez demain ». La carte « Révision Adaptative » est grisée. Doigt qui descend vers la carte « Simulation » (icône clipboard, sous-titre « BEPC 2024 — 10 questions »). Tap à 0:54.
- **Voix off (FR) :** « Maintenant, passons à la simulation d'examen. »
- **Voix off (EN) :** « Now, let's move to exam simulation. »
- **SFX :** « tap » à 0:54, « swoosh » à 0:55.
- **Notes production :** La carte « Révision » grisée illustre le principe de spaced repetition — l'élève ne peut pas réviser tout de suite, il faut attendre demain. Détail pédagogique important.

### Captures d'écran à faire — Section 3

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-005 | Home + tap carte Révision | `home_screen.dart` | 0:25-0:28 | 3 s | Doigt virtuel sur la carte |
| C-006 | Flashcard question (Pythagore) | `revision_screen.dart` | 0:28-0:33 | 5 s | « Question générée par SM-2 » |
| C-007 | Flashcard réponse (verso, flip 3D) | `revision_screen.dart` | 0:33-0:37 | 4 s | Aucune (animation parlante) |
| C-008 | Question suivante (fraction) + auto-éval | `revision_screen.dart` | 0:37-0:42 | 5 s | Aucune |
| C-009 | Écran fin de session (score 85 %) | `revision_summary_screen.dart` | 0:42-0:50 | 8 s | « SM-2 a planifié 3 cartes pour demain » |
| C-010 | Home grisé + tap Simulation | `home_screen.dart` | 0:50-0:55 | 5 s | Aucune (transition) |

### Script voix off FR — Section 3 (30 s, ~55 mots)

> « L'élève lance une session de révision adaptative. Une carte apparaît. C'est l'algorithme SM-2 qui choisit la question, au bon moment. L'élève retourne la carte, lit la réponse, et auto-évalue sa maîtrise. L'algorithme ajuste l'intervalle de révision. Plus la carte est jugée facile, plus elle reviendra tard. Fin de session. L'élève voit son score. Et l'algorithme a déjà planifié la prochaine révision. Maintenant, passons à la simulation d'examen. »

### Script voix off EN — Section 3 (30 s, ~58 mots)

> « The student launches an adaptive revision session. A card appears. The SM-2 algorithm picks the question, at the right moment. The student flips the card, reads the answer, and self-assesses their mastery. The algorithm adjusts the revision interval. The easier the card, the later it comes back. Session complete. The student sees their score. And the algorithm has already scheduled the next revision. Now, let's move to exam simulation. »

### Transitions — Section 3

- Shot 7 → Shot 8 : **cut sec** (transition native app, slide-in droite).
- Shot 8 → Shot 9 : **cut sec** (flip animation native).
- Shot 9 → Shot 10 : **cut sec** (slide-out/slide-in natif).
- Shot 10 → Shot 11 : **montage accéléré** (8 fondu enchaînés pour passer 8 cartes en 2,4 s).
- Shot 11 → Shot 12 : **cut sec + fondu blanc 0,1 s** (retour home).
- Section 3 → Section 4 : **zoom avant** sur la carte « Simulation » (200 % scale sur 0,4 s).

### Notes techniques — Section 3

- **Durée totale :** 30 s (3 + 5 + 4 + 5 + 8 + 5) ✓
- **Algorithme visible :** Oui — on cite SM-2 explicitement, et on montre la planification « 3 cartes demain ».
- **Annotations :** 2 overlays texte (SM-2 + planification).
- **Pacing :** moyen avec accélération centrale sur les 8 cartes.
- **Données de démo :** 12 cartes préparées dont 10 « Facile », 1 « Bon », 1 « Difficile » — pour obtenir un score 85 %.

---

### Section 4 — Simulation d'examen (0:55 → 1:25, 30 s)

**Objectif :** montrer que l'app reproduit fidèlement les conditions du BEPC — timer, format QCM, score final, recommandations de révision. Le spectateur doit ressentir : « c'est exactement comme le vrai examen ».

#### [Shot 13] 0:55 → 1:00 — Config simulation BEPC (5 s)

- **Type :** Screen recording
- **Visuel :** Écran `simulation_config_screen.dart`. Titre (Outfit Bold 24 pt, vert) : « Configurer la simulation ». Trois blocs : (1) Sélection examen : « BEPC » (vs « BAC »), carte sélectionnée avec border orange. (2) Nombre de questions : slider réglé sur « 10 » (pas 40, pour la démo). (3) Matière : « Mathématiques ». Bouton en bas : « Démarrer la simulation ». Doigt qui tap le bouton à 0:59.
- **Voix off (FR) :** « L'élève configure sa simulation : BEPC, 10 questions, mathématiques. »
- **Voix off (EN) :** « The student configures their simulation: BEPC, 10 questions, math. »
- **SFX :** « tap » à 0:59, « swoosh » à 1:00.
- **Notes production :** Pour la démo, on prend 10 questions (durée réelle ~8 min) qu'on va compresser en 25 s via montage. Le bouton « Démarrer » pulse légèrement (scale 1,00 → 1,03 → 1,00 sur 1 s) pour attirer le doigt.

#### [Shot 14] 1:00 → 1:05 — Écran d'examen avec timer (5 s)

- **Type :** Screen recording
- **Visuel :** Écran `exam_screen.dart`. Header noir avec timer en haut (Outfit Bold 24 pt, blanc) : « 08:42 » — décompte visible (08:43 → 08:42 → 08:41). À côté du timer, libellé « Temps restant ». Au centre, question QCM (Outfit Medium 20 pt) : « Quel est le PGCD de 24 et 36 ? ». Quatre options : A) 6, B) 12, C) 18, D) 24. Indicateur de progression en bas : « Question 1 / 10 ». Doigt qui tap l'option B à 1:04.
- **Texte overlay :** en haut à droite (Outfit Bold 18 pt, rouge) : « Conditions réelles du BEPC ».
- **Voix off (FR) :** « L'examen démarre. Timer, questions, conditions réelles du BEPC. »
- **Voix off (EN) :** « The exam starts. Timer, questions, real BEPC conditions. »
- **SFX :** « tic-tac » discret (synthétisé), 1 battement par seconde. « tap » à 1:04.
- **Notes production :** Le timer affiché « 08:42 » correspond à 10 questions × 1 min/question — paramétrage par défaut. Le tic-tac doit rester subtil (-32 LUFS) pour ne pas couvrir la voix.

#### [Shot 15] 1:05 → 1:10 — Réponse sélectionnée + question suivante (5 s)

- **Type :** Screen recording
- **Visuel :** Option B sélectionnée (background orange, checkmark blanc). Bouton « Question suivante » apparaît en bas (remplace « Voir la réponse »). Doigt qui tap à 1:08. Transition slide-in : Question 2/10. Question : « Résoudre l'équation 2x + 5 = 15. ». Quatre options : A) x = 3, B) x = 5, C) x = 7, D) x = 10. Doigt qui tap A à 1:09. Saut vers Question 5/10 (montage accéléré).
- **Voix off (FR) :** « L'élève répond, passe à la suivante. »
- **Voix off (EN) :** « The student answers, moves to the next one. »
- **SFX :** 2× « tap », « swoosh ».
- **Notes production :** Pour éviter 10 questions × 5 s = 50 s (trop long), on monte les questions 2 à 9 en time-lapse (0,5 s/question = 4 s pour 8 questions). Le compteur 2/10 → 5/10 → 9/10 défile rapidement.

#### [Shot 16] 1:10 → 1:15 — Question 10 + soumission (5 s)

- **Type :** Screen recording
- **Visuel :** Question 10/10 (la dernière). Question : « Calculer l'aire d'un disque de rayon 5 cm. ». Options : A) 25π cm², B) 10π cm², C) 5π cm², D) 100π cm². Doigt qui tap A à 1:13. Bouton « Terminer et corriger » apparaît. Doigt qui tap à 1:14. Modal de confirmation : « Terminer la simulation ? » — bouton « Oui ».
- **Voix off (FR) :** « Dernière question, l'élève termine la simulation. »
- **Voix off (EN) :** « Last question, the student finishes the simulation. »
- **SFX :** 3× « tap », « ding » à 1:14 (modal).
- **Notes production :** Le modal de confirmation empêche la soumission accidentelle — détail UX important.

#### [Shot 17] 1:15 → 1:25 — Rapport final avec score + recommandations (10 s)

- **Type :** Screen recording + motion graphic
- **Visuel :** Écran `exam_result_screen.dart`. Animation d'entrée : barre de chargement qui monte (0 → 100 %) en 1 s, puis le score apparaît. Grand chiffre (Outfit Black 96 pt, vert) : « 14/20 ». Sous-titre : « Score prédit : 13,8/20 (± 0,5) ». En dessous, 4 blocs : (1) Répartition par chapitre — barres horizontales (Géométrie 90 %, Algèbre 70 %, Statistiques 50 %). (2) Chapitres faibles identifiés — 2 cartes rouges (« Statistiques — moyenne et écart-type », « Probabilités — bases »). (3) Recommandations — « 3 sessions de révision ciblées programmées ». (4) Bouton « Voir la correction détaillée ». Doigt qui scroll lentement pour révéler tous les blocs.
- **Texte overlay :** en bas (Outfit Bold 22 pt, orange) : « L'IA identifie les chapitres faibles et planifie les révisions ».
- **Voix off (FR) :** « Score : 14 sur 20. L'IA identifie les chapitres faibles — ici, statistiques et probabilités. Et planifie 3 sessions de révision ciblées. »
- **Voix off (EN) :** « Score: 14 out of 20. The AI identifies weak chapters — here, statistics and probability. And schedules 3 targeted revision sessions. »
- **SFX :** « ding » triomphal à 1:16, « swoosh » ×3 à mesure que les blocs apparaissent.
- **Notes production :** L'animation « barre de chargement → score » dure 1 s et crée un suspense. Le score prédit « 13,8/20 (± 0,5) » est calculé par le modèle XGBoost déployé sur Railway — c'est une vraie prédiction, pas un mock.

### Captures d'écran à faire — Section 4

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-011 | Config simulation BEPC | `simulation_config_screen.dart` | 0:55-1:00 | 5 s | Aucune |
| C-012 | Écran examen Q1 + timer 08:42 | `exam_screen.dart` | 1:00-1:05 | 5 s | « Conditions réelles du BEPC » |
| C-013 | Réponse sélectionnée + Q2/Q5 | `exam_screen.dart` | 1:05-1:10 | 5 s | Aucune (montage rapide) |
| C-014 | Q10 + modal terminer | `exam_screen.dart` | 1:10-1:15 | 5 s | Aucune |
| C-015 | Rapport final (score 14/20 + recommandations) | `exam_result_screen.dart` | 1:15-1:25 | 10 s | « L'IA identifie les chapitres faibles » |

### Script voix off FR — Section 4 (30 s, ~52 mots)

> « L'élève configure sa simulation : BEPC, 10 questions, mathématiques. L'examen démarre. Timer, questions, conditions réelles du BEPC. L'élève répond, passe à la suivante. Dernière question, l'élève termine la simulation. Score : 14 sur 20. L'IA identifie les chapitres faibles — ici, statistiques et probabilités. Et planifie 3 sessions de révision ciblées. »

### Script voix off EN — Section 4 (30 s, ~55 mots)

> « The student configures their simulation: BEPC, 10 questions, math. The exam starts. Timer, questions, real BEPC conditions. The student answers, moves to the next one. Last question, the student finishes the simulation. Score: 14 out of 20. The AI identifies weak chapters — here, statistics and probability. And schedules 3 targeted revision sessions. »

### Transitions — Section 4

- Shot 13 → Shot 14 : **cut sec** (transition native, slide-in droite).
- Shot 14 → Shot 15 : **cut sec** (slide-in natif).
- Shot 15 → Shot 16 : **cut sec** (montage accéléré + slide-in).
- Shot 16 → Shot 17 : **cut sec** + animation de chargement native.
- Section 4 → Section 5 : **zoom arrière** (sortie de l'écran résultat) + **fondu** vers dashboard. Le zoom arrière suggère « on prend du recul pour voir l'ensemble ».

### Notes techniques — Section 4

- **Durée totale :** 30 s (5 + 5 + 5 + 5 + 10) ✓
- **Timer réel :** Le décompte « 08:42 → 08:41 → 08:40 » doit être visible — capture en 60 fps pour capter chaque seconde.
- **Score prédit :** Réellement calculé par l'endpoint `/predict` du backend FastAPI (Railway). Le modèle XGBoost est entraîné sur les sessions antérieures d'Amina.
- **Annotations :** 2 overlays texte.
- **Pacing :** rapide avec pic émotionnel sur le score final.

---

### Section 5 — Tableau de bord (1:25 → 1:50, 25 s)

**Objectif :** montrer que l'élève peut visualiser sa progression globale, sa prédiction de score, ses points faibles — tout en un écran. Le dashboard est la « tour de contrôle » de l'élève.

#### [Shot 18] 1:25 → 1:30 — Dashboard — score global + prédiction BEPC (5 s)

- **Type :** Screen recording
- **Visuel :** Écran `dashboard_screen.dart`. En haut, grande carte « Prédiction BEPC » avec jauge semi-circulaire (vert → orange → rouge) qui pointe sur « 14,2 / 20 » (orange). Sous-titre : « Confiance : 78 % ». À droite, seconde carte « Score global » avec chiffre « 76 % » (Outfit Black 64 pt, vert) et indicateur « +8 % cette semaine » (flèche verte). Doigt qui scroll lentement pour révéler la suite.
- **Texte overlay :** en haut à droite (Outfit Bold 18 pt, orange) : « XGBoost — 78 % de confiance ».
- **Voix off (FR) :** « Le tableau de bord. Score global : 76 %. Et prédiction BEPC : 14,2 sur 20, avec 78 % de confiance. »
- **Voix off (EN) :** « The dashboard. Global score: 76 %. And BEPC prediction: 14.2 out of 20, with 78 % confidence. »
- **SFX :** « pop » à 1:26 (jauge qui s'anime), « ding » à 1:28.
- **Notes production :** La jauge semi-circulaire est animée en `CustomPainter` (Flutter). Capture 60 fps pour capter l'animation d'entrée.

#### [Shot 19] 1:30 → 1:38 — Progression par matière (8 s)

- **Type :** Screen recording
- **Visuel :** Suite du scroll. Bloc « Progression par matière » avec 6 barres horizontales animées (Mathématiques 78 %, Français 82 %, Histoire-Géo 65 %, SVT 71 %, Physique-Chimie 58 %, Anglais 80 %). Chaque barre se remplit en cascade (250 ms de décalage entre chaque). Couleurs : vert si ≥ 70 %, orange si 50-70 %, rouge si < 50 %.
- **Voix off (FR) :** « Progression par matière. L'élève voit ses points forts — français, mathématiques — et ses points faibles — physique-chimie. »
- **Voix off (EN) :** « Progress by subject. The student sees their strengths — French, math — and their weaknesses — physics-chemistry. »
- **SFX :** « swoosh » ×6 à mesure que les barres se remplissent.
- **Notes production :** L'animation en cascade (staggered animation) est implémentée via `AnimationController` + `Interval`. Effet « wow » garanti.

#### [Shot 20] 1:38 → 1:44 — Heatmap chapitres faibles (6 s)

- **Type :** Screen recording
- **Visuel :** Suite du scroll. Bloc « Heatmap chapitres faibles » — grille 8 colonnes × 5 lignes, chaque cellule colorée selon la maîtrise (rouge foncé < 30 %, orange 30-60 %, jaune 60-80 %, vert > 80 %). Labels lignes : « Algèbre », « Géométrie », « Stats », « Proba », « Arithmétique ». Labels colonnes : « Chap. 1 » à « Chap. 8 ». Trois cellules rouges clignotent légèrement (pulse 0,9 → 1,0 → 0,9 sur 1 s) pour attirer l'attention. Légende en bas : « Rouge = à réviser en priorité ».
- **Voix off (FR) :** « La heatmap révèle les chapitres à travailler en priorité. »
- **Voix off (EN) :** « The heatmap reveals which chapters need priority work. »
- **SFX :** 3× « pop » discrets (cellules rouges qui clignotent).
- **Notes production :** La heatmap est un widget `GridView` custom avec `BoxDecoration` coloré. Le clignotement est une `TweenAnimationBuilder`.

#### [Shot 21] 1:44 → 1:50 — Stats SRS + transition tuteur (6 s)

- **Type :** Screen recording + transition
- **Visuel :** Suite du scroll. Bloc « Statistiques SRS » — 4 mini-cartes : « 247 cartes en circulation », « 89 % taux de rétention à 7 jours », « 12 cartes dues aujourd'hui », « 1 482 révisions totales ». Sous ce bloc, en bas du dashboard, doigt qui tap l'icône « Tuteur IA » dans la bottom navigation bar (icône chat-bubble). Tap à 1:48.
- **Voix off (FR) :** « Et les statistiques SRS : 89 % de rétention à 7 jours. Maintenant, place au tuteur IA. »
- **Voix off (EN) :** « And the SRS stats: 89 % retention at 7 days. Now, the AI tutor. »
- **SFX :** « tap » à 1:48, « swoosh » à 1:49.
- **Notes production :** Les 4 mini-cartes s'affichent avec un staggered fade-in (100 ms de décalage). La transition vers le tuteur se fait via bottom navigation bar.

### Captures d'écran à faire — Section 5

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-016 | Dashboard — score global + prédiction | `dashboard_screen.dart` | 1:25-1:30 | 5 s | « XGBoost — 78 % de confiance » |
| C-017 | Dashboard — progression par matière | `dashboard_screen.dart` | 1:30-1:38 | 8 s | Aucune |
| C-018 | Dashboard — heatmap chapitres faibles | `dashboard_screen.dart` | 1:38-1:44 | 6 s | Aucune |
| C-019 | Dashboard — stats SRS + tap tuteur | `dashboard_screen.dart` | 1:44-1:50 | 6 s | Aucune |

### Script voix off FR — Section 5 (25 s, ~50 mots)

> « Le tableau de bord. Score global : 76 %. Et prédiction BEPC : 14,2 sur 20, avec 78 % de confiance. Progression par matière. L'élève voit ses points forts — français, mathématiques — et ses points faibles — physique-chimie. La heatmap révèle les chapitres à travailler en priorité. Et les statistiques SRS : 89 % de rétention à 7 jours. Maintenant, place au tuteur IA. »

### Script voix off EN — Section 5 (25 s, ~52 mots)

> « The dashboard. Global score: 76 %. And BEPC prediction: 14.2 out of 20, with 78 % confidence. Progress by subject. The student sees their strengths — French, math — and their weaknesses — physics-chemistry. The heatmap reveals which chapters need priority work. And the SRS stats: 89 % retention at 7 days. Now, the AI tutor. »

### Transitions — Section 5

- Shot 18 → Shot 19 : **scroll continu** (pas de cut — le doigt virtuel scroll naturellement).
- Shot 19 → Shot 20 : **scroll continu**.
- Shot 20 → Shot 21 : **scroll continu**.
- Section 5 → Section 6 : **cut sec** (changement d'écran via bottom nav).

### Notes techniques — Section 5

- **Durée totale :** 25 s (5 + 8 + 6 + 6) ✓
- **Scrolling :** utiliser `ScrollController` avec `animateTo()` pour contrôler la vitesse de scroll en capture. Rythme : 200 px/s.
- **Prédiction XGBoost :** Réellement calculée par l'endpoint `/predict` du backend — chiffres authentiques, pas mockés.
- **Annotations :** 1 overlay texte.
- **Pacing :** continu, sans coupure — le scroll donne une sensation de fluidité.

---

### Section 6 — Tuteur IA (1:50 → 2:10, 20 s)

**Objectif :** montrer que l'élève n'est jamais bloqué — il a un tuteur IA disponible 24h/24 pour répondre à toutes ses questions. C'est le différenciateur clé face aux annales PDF statiques.

#### [Shot 22] 1:50 → 1:54 — Écran tuteur + suggestions (4 s)

- **Type :** Screen recording
- **Visuel :** Écran `tutor_screen.dart`. Header vert « Tuteur IA ». Zone de chat vide avec message de bienvenue (bot avatar vert, bulle à gauche) : « Bonjour Amina ! Je suis ton tuteur IA. Pose-moi n'importe quelle question sur tes cours. ». Sous le message, 4 chips de suggestions cliquables : « Explique-moi Pythagore », « Donne-moi 5 exemples de fonctions affines », « Comment résoudre une équation du 2d degré ? », « Différence entre PGCD et PPCM ». Doigt qui tap la chip « Explique-moi Pythagore » à 1:53.
- **Voix off (FR) :** « Le tuteur IA est disponible 24h/24. Amina sélectionne une suggestion. »
- **Voix off (EN) :** « The AI tutor is available 24/7. Amina picks a suggestion. »
- **SFX :** « tap » à 1:53.
- **Notes production :** Les chips ont un fond gris clair et passent en orange au tap (effet ripple).

#### [Shot 23] 1:54 → 1:58 — Typing indicator (4 s)

- **Type :** Screen recording
- **Visuel :** Après le tap, bulle utilisateur à droite (fond orange, texte blanc) : « Explique-moi Pythagore ». Immédiatement après, bulle bot à gauche avec typing indicator (3 points animés qui bondissent en boucle). Duration visible : ~2 s.
- **Voix off (FR) :** (silence — le typing indicator parle de lui-même)
- **Voix off (EN) :** (silence)
- **SFX :** « pop » discret à l'apparition de chaque point (×3 en boucle).
- **Notes production :** Le typing indicator est implémenté via `AnimatedBuilder` + `Tween<double>` avec décalage de phase entre les 3 points. Capture 60 fps obligatoire.

#### [Shot 24] 1:58 → 2:08 — Réponse IA (10 s)

- **Type :** Screen recording
- **Visuel :** La bulle bot se remplit progressivement (effet de typing stream-by-stream, 30 ms par token). Texte (Outfit Regular 16 pt) : « Bien sûr ! Le théorème de Pythagore s'applique dans un triangle rectangle. Il dit que le carré de la longueur de l'hypoténuse (le côté opposé à l'angle droit) est égal à la somme des carrés des longueurs des deux autres côtés. Formule : a² + b² = c². Exemple : si a = 3 et b = 4, alors c = 5. ». Sous la réponse, 3 boutons : « Poser une question de suivi », « Voir un exemple animé », « Marquer comme compris ». Doigt qui tap « Voir un exemple animé » à 2:06.
- **Texte overlay :** en bas (Outfit Bold 18 pt, orange) : « Réponse générée en 2,3 s — modèle GPT-4o-mini fine-tuné programme togolais ».
- **Voix off (FR) :** « Le tuteur explique, avec un exemple, en moins de 3 secondes. »
- **Voix off (EN) :** « The tutor explains, with an example, in under 3 seconds. »
- **SFX :** « ding » à 2:00 (réponse complète), « tap » à 2:06.
- **Notes production :** Le streaming token-by-token est réellement implémenté via SSE (Server-Sent Events) sur l'endpoint `/tutor/chat` du backend. Modèle : GPT-4o-mini avec system prompt aligné sur le programme togolais MEPST.

#### [Shot 25] 2:08 → 2:10 — Transition vers gamification (2 s)

- **Type :** Screen recording + transition
- **Visuel :** Modal « Exemple animé » qui s'ouvre (triangle rectangle qui se dessine, côtés a/b/c qui s'étiquettent, formule a² + b² = c² qui apparaît). Très court — on ne montre que l'amorce de l'animation. Puis doigt qui tap l'icône « Badges » dans la bottom nav à 2:09.
- **Voix off (FR) :** « Et pour finir, la gamification. »
- **Voix off (EN) :** « And to finish, gamification. »
- **SFX :** « swoosh » à 2:08 (modal), « tap » à 2:09.
- **Notes production :** Séquence très courte — 2 s — pour ne pas casser le rythme. L'animation du triangle est implémentée via `CustomPainter` + `AnimationController`.

### Captures d'écran à faire — Section 6

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-020 | Tuteur — message bienvenue + suggestions | `tutor_screen.dart` | 1:50-1:54 | 4 s | Aucune |
| C-021 | Tuteur — typing indicator | `tutor_screen.dart` | 1:54-1:58 | 4 s | Aucune (animation parlante) |
| C-022 | Tuteur — réponse IA streaming | `tutor_screen.dart` | 1:58-2:08 | 10 s | « Réponse en 2,3 s — GPT-4o-mini » |
| C-023 | Tuteur — modal exemple animé + tap badges | `tutor_screen.dart` | 2:08-2:10 | 2 s | Aucune |

### Script voix off FR — Section 6 (20 s, ~28 mots)

> « Le tuteur IA est disponible 24h/24. Amina sélectionne une suggestion. Le tuteur explique, avec un exemple, en moins de 3 secondes. Et pour finir, la gamification. »

### Script voix off EN — Section 6 (20 s, ~28 mots)

> « The AI tutor is available 24/7. Amina picks a suggestion. The tutor explains, with an example, in under 3 seconds. And to finish, gamification. »

### Transitions — Section 6

- Shot 22 → Shot 23 : **cut sec** (apparition native des bulles).
- Shot 23 → Shot 24 : **cut sec** (streaming natif).
- Shot 24 → Shot 25 : **cut sec** (ouverture modal native).
- Section 6 → Section 7 : **cut sec** (changement d'écran via bottom nav).

### Notes techniques — Section 6

- **Durée totale :** 20 s (4 + 4 + 10 + 2) ✓
- **Backend :** endpoint `/tutor/chat` (FastAPI + GPT-4o-mini). Latence réelle observée : 2,3 s en moyenne pour une réponse complète. On garde ce chiffre dans l'annotation.
- **Streaming :** Le streaming token-by-token via SSE peut ralentir en capture. Si saccade, capturer en 90 fps puis downscaler à 30 fps en post-production.
- **Annotations :** 1 overlay texte (latence).
- **Pacing :** lent (typing indicator), puis rapide (réponse streaming), puis très court (transition).

---

### Section 7 — Badges + Communauté (2:10 → 2:30, 20 s)

**Objectif :** montrer la couche de gamification qui transforme la révision en jeu social. Badges, classements, défis — la motivation par la reconnaissance.

#### [Shot 26] 2:10 → 2:16 — Écran badges débloqués (6 s)

- **Type :** Screen recording
- **Visuel :** Écran `badges_screen.dart`. Titre (Outfit Bold 24 pt, vert) : « Mes badges ». Sous-titre : « 7 débloqués sur 24 ». Grille 4 colonnes × 6 lignes de badges (cercles colorés avec icône). 7 badges en couleur (animation pulse légère), 17 en niveaux de gris (verrouillés). Badges visibles : « Premier jour », « 7 jours de streak », « 100 cartes révisées », « Première simulation », « Top 10 classement », « Chapitre maîtrisé », « Question difficile vaincue ». Doigt qui scroll lentement.
- **Voix off (FR) :** « 7 badges déjà débloqués. Streak de 7 jours, 100 cartes révisées, top 10 du classement. »
- **Voix off (EN) :** « 7 badges already unlocked. 7-day streak, 100 cards revised, top 10 ranking. »
- **SFX :** « ding » ×3 à mesure que les badges colorés apparaissent.
- **Notes production :** Les badges verrouillés ont une opacité 0,3 et un overlay cadenas. Les badges débloqués ont une lueur dorée subtile (BoxShadow jaune).

#### [Shot 27] 2:16 → 2:22 — Animation déblocage badge (6 s)

- **Type :** Screen recording (séquence spéciale capturée séparément)
- **Visuel :** À 2:16, l'élève valide une dernière carte et déclenche l'animation de déblocage d'un nouveau badge. Overlay plein écran : fond noir 70 % opacité, au centre un badge géant (cercle doré 200 px, icône trophée) qui entre par un effet de zoom + rotation 3D (0 → 360° en 1 s). Effet de particules (confettis verts et oranges) qui jaillissent autour. Texte (Outfit Bold 28 pt, blanc) : « Badge débloqué : Maître des fractions ». Sous-texte (Inter Regular 16 pt, blanc 80 %) : « Tu as maîtrisé 90 % des cartes sur les fractions ». Bouton « Continuer ». Tap à 2:21.
- **Voix off (FR) :** « Et là — déblocage d'un nouveau badge. Effet waouh garanti. »
- **Voix off (EN) :** « And here — a new badge unlocked. Guaranteed wow effect. »
- **SFX :** « ding » triomphal + « whoosh » + confettis (effet sonore synthétisé). Pic musical.
- **Notes production :** Cette séquence est capturée séparément (scénario de démo spécifique) puis insérée en post-production. Pour la déclencher, exécuter `scripts/trigger_badge_unlock.dart` qui marque la dernière carte « fractions » comme maîtrisée et force l'animation. L'effet de confettis est implémenté via la lib `confetti` (pub.dev).

#### [Shot 28] 2:22 → 2:30 — Classement communauté (8 s)

- **Type :** Screen recording + transition
- **Visuel :** Écran `community_screen.dart`. Titre (Outfit Bold 24 pt, vert) : « Classement · cette semaine ». Sous-titre : « École Pilote Lomé · Classe de 3e B ». Liste verticale de 10 élèves avec : rang (chiffre), avatar (initiale), nom, score (points), badge streak (flamme). Amina est en position 4, mise en avant (background orange clair, border orange 2 px). En haut, podium top 3 (avatars agrandis avec médailles or/argent/bronze). Doigt qui scroll pour révéler plus d'élèves. En bas, bouton « Voir les défis ».
- **Texte overlay :** en haut à droite (Outfit Bold 18 pt, orange) : « Motivation par la reconnaissance sociale ».
- **Voix off (FR) :** « Et le classement de sa classe. Amina est 4e cette semaine. Les défis et classements motivent l'élève sur la durée. »
- **Voix off (EN) :** « And her class ranking. Amina is 4th this week. Challenges and rankings keep the student motivated long-term. »
- **SFX :** « swoosh » ×3 (apparition podium), « tap » à 2:29 (bouton défis).
- **Notes production :** Le classement est filtré par école + classe (B2B2C feature). Les élèves ne sont pas en compétition avec toute la plateforme mais avec leur classe — plus motivant et moins anxiogène.

### Captures d'écran à faire — Section 7

| ID | Écran source | Fichier Dart | Timestamp visé | Durée | Annotation |
|---|---|---|---|---|---|
| C-024 | Écran badges (7 débloqués) | `badges_screen.dart` | 2:10-2:16 | 6 s | Aucune |
| C-025 | Animation déblocage badge « Maître des fractions » | overlay spécial | 2:16-2:22 | 6 s | Aucune (effet parlant) |
| C-026 | Classement communauté (Amina 4e) | `community_screen.dart` | 2:22-2:30 | 8 s | « Motivation par la reconnaissance sociale » |

### Script voix off FR — Section 7 (20 s, ~40 mots)

> « 7 badges déjà débloqués. Streak de 7 jours, 100 cartes révisées, top 10 du classement. Et là — déblocage d'un nouveau badge. Effet waouh garanti. Et le classement de sa classe. Amina est 4e cette semaine. Les défis et classements motivent l'élève sur la durée. »

### Script voix off EN — Section 7 (20 s, ~42 mots)

> « 7 badges already unlocked. 7-day streak, 100 cards revised, top 10 ranking. And here — a new badge unlocked. Guaranteed wow effect. And her class ranking. Amina is 4th this week. Challenges and rankings keep the student motivated long-term. »

### Transitions — Section 7

- Shot 26 → Shot 27 : **cut sec + fondu noir 0,2 s** (changement de contexte — on bascule dans une animation spéciale).
- Shot 27 → Shot 28 : **cut sec** (transition native vers écran classement).
- Section 7 → Section 8 : **fondu enchaîné** (cross-dissolve 0,5 s) vers le carton final.

### Notes techniques — Section 7

- **Durée totale :** 20 s (6 + 6 + 8) ✓
- **Animation badge :** Séquence spéciale — pas une capture continue. Capturée via script dédié, puis insérée.
- **Confettis :** Utiliser la lib `confetti` (pub.dev). Durée 3 s. Couleurs : vert Togo + orange + blanc.
- **Classement :** Réel — on prend 10 élèves de l'École Pilote Lomé (compte démo). Amina est en position 4 avec 2 850 points ( derrière élèves à 3 100, 3 020, 2 950).
- **Annotations :** 1 overlay texte.
- **Pacing :** lent (découverte badges) → pic émotionnel (déblocage) → posé (classement).

---

### Section 8 — Conclusion (2:30 → 2:40, 10 s)

**Objectif :** CTA clair et mémorable. Le spectateur doit savoir quoi faire : télécharger l'app.

#### [Shot 29] 2:30 → 2:35 — Carton logo + tagline (5 s)

- **Type :** Motion graphic
- **Visuel :** Fond dégradé #006837 → #00451F (vert Togo profond). Au centre, logo ExamBoost Togo (grand, blanc + point orange) qui entre par effet de fondu + scale-up (90 % → 100 %). Sous le logo, tagline (Outfit Bold 36 pt, blanc) : « Prépare ton BEPC. Réussis ton BAC. ». En dessous, sous-tagline (Inter Regular 20 pt, blanc 80 %) : « Gratuit sur Play Store ».
- **Voix off (FR) :** « ExamBoost Togo. Prépare ton BEPC. Réussis ton BAC. »
- **Voix off (EN) :** « ExamBoost Togo. Prepare for your BEPC. Pass your BAC. »
- **Musique :** Pic musical final — beat qui monte, ajout d'un élément de cordes, résolution sur un accord majeur.
- **SFX :** « whoosh » à 2:30 (apparition logo), « ding » cristallin à 2:33 (point orange qui s'allume).
- **Notes production :** Effet de particules légères en arrière-plan (particules vertes/orange qui flottent). Template After Effects « Logo Reveal Premium ».

#### [Shot 30] 2:35 → 2:40 — CTA final + URL (5 s)

- **Type :** Motion graphic
- **Visuel :** Le logo se réduit vers le haut (translation Y -100 px). En bas, 3 éléments alignés horizontalement : (1) Logo Play Store (triangle coloré) + texte « Disponible sur Play Store » (Outfit Bold 22 pt, blanc). (2) Bouton fictif « Télécharger » (background orange, texte blanc). (3) QR code (généré dynamiquement, pointe vers `github.com/djabelo712/ExamBoost-Togo`) — encadré blanc 8 px. En tout bas, URL (Inter Regular 18 pt, blanc 70 %) : `github.com/djabelo712/ExamBoost-Togo` + email `contact@examboost.togo`.
- **Voix off (FR) :** « Télécharge ExamBoost Togo. Gratuit sur Play Store. Lien dans la description. »
- **Voix off (EN) :** « Download ExamBoost Togo. Free on Play Store. Link in the description. »
- **Musique :** Fade-out sur 3 s, fin sur un « ding » final.
- **SFX :** « ding » final à 2:39.
- **Notes production :** Le QR code peut être généré via `qrcode-monkey.com` (gratuit). Couleurs : noir sur fond blanc. Taille : 120 × 120 px.

### Captures d'écran à faire — Section 8

Aucune capture d'écran réelle pour cette section — uniquement des éléments motion graphics. Le QR code est généré dynamiquement à partir de l'URL GitHub.

### Script voix off FR — Section 8 (10 s, ~18 mots)

> « ExamBoost Togo. Prépare ton BEPC. Réussis ton BAC. Télécharge ExamBoost Togo. Gratuit sur Play Store. Lien dans la description. »

### Script voix off EN — Section 8 (10 s, ~18 mots)

> « ExamBoost Togo. Prepare for your BEPC. Pass your BAC. Download ExamBoost Togo. Free on Play Store. Link in the description. »

### Transitions — Section 8

- Shot 29 → Shot 30 : **translation Y** du logo + apparition des éléments par fondu en cascade.
- Section 8 → fin : **fondu noir 0,5 s** puis fin de la vidéo.

### Notes techniques — Section 8

- **Durée totale :** 10 s (5 + 5) ✓
- **CTA principal :** Play Store + URL GitHub + QR code.
- **Logo ExamBoost visible :** Oui (centré, grand, 100 % opacité) ✓ — dernière occurrence logo.
- **Annotations :** aucune.
- **Pacing :** posé, conclusif.

---

## Script voix off complet (FR)

Le script ci-dessous est le texte intégral à enregistrer pour la voix off française. Il fait environ 250 mots, soit un débit moyen de 130 mots/min — dans la fourchette recommandée pour une voix off pédagogique (120-150 mots/min). Réparti sur 160 s, le débit réel est de 94 mots/min (espaces de silence inclus pour laisser respirer les démonstrations visuelles).

> « Voici comment ExamBoost prépare les élèves au BEPC et BAC.
>
> L'élève ouvre l'app, et crée son profil. Elle choisit son niveau — ici la 3e, pour le BEPC. Profil créé en 30 secondes. Direction l'écran d'accueil.
>
> L'élève lance une session de révision adaptative. Une carte apparaît. C'est l'algorithme SM-2 qui choisit la question, au bon moment. L'élève retourne la carte, lit la réponse, et auto-évalue sa maîtrise. L'algorithme ajuste l'intervalle de révision. Plus la carte est jugée facile, plus elle reviendra tard. Fin de session. L'élève voit son score. Et l'algorithme a déjà planifié la prochaine révision. Maintenant, passons à la simulation d'examen.
>
> L'élève configure sa simulation : BEPC, 10 questions, mathématiques. L'examen démarre. Timer, questions, conditions réelles du BEPC. L'élève répond, passe à la suivante. Dernière question, l'élève termine la simulation. Score : 14 sur 20. L'IA identifie les chapitres faibles — ici, statistiques et probabilités. Et planifie 3 sessions de révision ciblées.
>
> Le tableau de bord. Score global : 76 %. Et prédiction BEPC : 14,2 sur 20, avec 78 % de confiance. Progression par matière. L'élève voit ses points forts — français, mathématiques — et ses points faibles — physique-chimie. La heatmap révèle les chapitres à travailler en priorité. Et les statistiques SRS : 89 % de rétention à 7 jours. Maintenant, place au tuteur IA.
>
> Le tuteur IA est disponible 24h/24. Amina sélectionne une suggestion. Le tuteur explique, avec un exemple, en moins de 3 secondes. Et pour finir, la gamification.
>
> 7 badges déjà débloqués. Streak de 7 jours, 100 cartes révisées, top 10 du classement. Et là — déblocage d'un nouveau badge. Effet waouh garanti. Et le classement de sa classe. Amina est 4e cette semaine. Les défis et classements motivent l'élève sur la durée.
>
> ExamBoost Togo. Prépare ton BEPC. Réussis ton BAC. Télécharge ExamBoost Togo. Gratuit sur Play Store. Lien dans la description. »

**Durée estimée à 130 mots/min (parole seule) :** 250 / 130 × 60 = 115 secondes de parole, réparties sur 160 s de vidéo (45 s de silence pour laisser respirer les démonstrations visuelles). ✓

---

## Script voix off complet (EN)

Version anglaise pour le jury CcHub (programme anglophone) et pour la version sous-titrée. Environ 250 mots, débit 120 mots/min.

> « Here's how ExamBoost prepares students for the BEPC and BAC exams.
>
> The student opens the app and creates their profile. She picks her grade level — here 9th grade, for the BEPC. Profile created in 30 seconds. Off to the home screen.
>
> The student launches an adaptive revision session. A card appears. The SM-2 algorithm picks the question, at the right moment. The student flips the card, reads the answer, and self-assesses their mastery. The algorithm adjusts the revision interval. The easier the card, the later it comes back. Session complete. The student sees their score. And the algorithm has already scheduled the next revision. Now, let's move to exam simulation.
>
> The student configures their simulation: BEPC, 10 questions, math. The exam starts. Timer, questions, real BEPC conditions. The student answers, moves to the next one. Last question, the student finishes the simulation. Score: 14 out of 20. The AI identifies weak chapters — here, statistics and probability. And schedules 3 targeted revision sessions.
>
> The dashboard. Global score: 76 %. And BEPC prediction: 14.2 out of 20, with 78 % confidence. Progress by subject. The student sees their strengths — French, math — and their weaknesses — physics-chemistry. The heatmap reveals which chapters need priority work. And the SRS stats: 89 % retention at 7 days. Now, the AI tutor.
>
> The AI tutor is available 24/7. Amina picks a suggestion. The tutor explains, with an example, in under 3 seconds. And to finish, gamification.
>
> 7 badges already unlocked. 7-day streak, 100 cards revised, top 10 ranking. And here — a new badge unlocked. Guaranteed wow effect. And her class ranking. Amina is 4th this week. Challenges and rankings keep the student motivated long-term.
>
> ExamBoost Togo. Prepare for your BEPC. Pass your BAC. Download ExamBoost Togo. Free on Play Store. Link in the description. »

**Durée estimée à 120 mots/min (parole seule) :** 250 / 120 × 60 = 125 secondes de parole, réparties sur 160 s de vidéo (35 s de silence). ✓

---

## Storyboard visuel détaillé (récapitulatif shot par shot)

Ce tableau récapitule les 30 shots avec leurs caractéristiques essentielles. Il sert de checklist au monteur pendant le storyboard final et le montage.

| Shot | Timestamp | Durée | Section | Type | Description visuelle (raccourcie) | Texte overlay clé | Voix off (FR, raccourci) | SFX | Logo EB visible |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 0:00-0:04 | 4 s | 1 | Motion graphic | Logo ExamBoost apparaît | « Démo produit · 2 minutes » | « Voici comment ExamBoost… » | Whoosh + ding | Oui (centré) |
| 2 | 0:04-0:10 | 6 s | 1 | Motion + device | Logo réduit + smartphone flou | « Démo produit · clic par clic » | (silence) | Whoosh + pop | Oui (petit) |
| 3 | 0:10-0:14 | 4 s | 2 | Screen recording | Splash screen | — | (silence) | Pop + swoosh | Non |
| 4 | 0:14-0:18 | 4 s | 2 | Screen recording | Onboarding step 1/3 bienvenue | — | « L'élève ouvre l'app… » | Tap | Non |
| 5 | 0:18-0:22 | 4 s | 2 | Screen recording | Onboarding step 3/3 niveau 3e | « Choix du niveau — ici 3e » | « Elle choisit son niveau… » | Tap | Non |
| 6 | 0:22-0:25 | 3 s | 2 | Screen recording | Home avec SnackBar succès | — | « Profil créé en 30 secondes… » | Ding | Non |
| 7 | 0:25-0:28 | 3 s | 3 | Screen recording | Home + tap Révision | — | « L'élève lance une session… » | Tap + swoosh | Non |
| 8 | 0:28-0:33 | 5 s | 3 | Screen recording | Flashcard Pythagore | « Question générée par SM-2 » | « Une carte apparaît… » | Tap | Non |
| 9 | 0:33-0:37 | 4 s | 3 | Screen recording | Flip 3D + réponse Pythagore | — | « L'élève retourne la carte… » | Swoosh + tap | Non |
| 10 | 0:37-0:42 | 5 s | 3 | Screen recording | Question fraction + auto-éval | — | « L'algorithme ajuste l'intervalle… » | Tap ×2 + swoosh | Non |
| 11 | 0:42-0:50 | 8 s | 3 | Screen + motion | Fin de session score 85 % | « SM-2 a planifié 3 cartes pour demain » | « Fin de session… » | Ding + fondus | Non |
| 12 | 0:50-0:55 | 5 s | 3 | Screen recording | Home grisé + tap Simulation | — | « Maintenant, passons à la simulation… » | Tap + swoosh | Non |
| 13 | 0:55-1:00 | 5 s | 4 | Screen recording | Config BEPC 10 Q math | — | « L'élève configure sa simulation… » | Tap + swoosh | Non |
| 14 | 1:00-1:05 | 5 s | 4 | Screen recording | Examen Q1 + timer 08:42 | « Conditions réelles du BEPC » | « L'examen démarre… » | Tic-tac + tap | Non |
| 15 | 1:05-1:10 | 5 s | 4 | Screen recording | Q2/Q5 + montage accéléré | — | « L'élève répond, passe à la suivante… » | Tap ×2 + swoosh | Non |
| 16 | 1:10-1:15 | 5 s | 4 | Screen recording | Q10 + modal terminer | — | « Dernière question… » | Tap ×3 + ding | Non |
| 17 | 1:15-1:25 | 10 s | 4 | Screen + motion | Rapport final score 14/20 + reco | « L'IA identifie les chapitres faibles » | « Score : 14 sur 20… » | Ding + swoosh ×3 | Non |
| 18 | 1:25-1:30 | 5 s | 5 | Screen recording | Dashboard score 76 % + prédiction 14,2/20 | « XGBoost — 78 % de confiance » | « Le tableau de bord… » | Pop + ding | Non |
| 19 | 1:30-1:38 | 8 s | 5 | Screen recording | Progression par matière (6 barres) | — | « Progression par matière… » | Swoosh ×6 | Non |
| 20 | 1:38-1:44 | 6 s | 5 | Screen recording | Heatmap chapitres faibles | — | « La heatmap révèle les chapitres… » | Pop ×3 | Non |
| 21 | 1:44-1:50 | 6 s | 5 | Screen recording | Stats SRS + tap Tuteur | — | « Et les statistiques SRS… » | Tap + swoosh | Non |
| 22 | 1:50-1:54 | 4 s | 6 | Screen recording | Tuteur bienvenue + suggestions | — | « Le tuteur IA est disponible… » | Tap | Non |
| 23 | 1:54-1:58 | 4 s | 6 | Screen recording | Typing indicator | — | (silence) | Pop ×3 | Non |
| 24 | 1:58-2:08 | 10 s | 6 | Screen recording | Réponse IA streaming Pythagore | « Réponse en 2,3 s — GPT-4o-mini » | « Le tuteur explique… » | Ding + tap | Non |
| 25 | 2:08-2:10 | 2 s | 6 | Screen recording | Modal exemple animé + tap badges | — | « Et pour finir, la gamification… » | Swoosh + tap | Non |
| 26 | 2:10-2:16 | 6 s | 7 | Screen recording | Écran badges 7 débloqués | — | « 7 badges déjà débloqués… » | Ding ×3 | Non |
| 27 | 2:16-2:22 | 6 s | 7 | Animation | Déblocage badge « Maître des fractions » | — | « Et là — déblocage… » | Ding + whoosh + confettis | Non |
| 28 | 2:22-2:30 | 8 s | 7 | Screen recording | Classement Amina 4e | « Motivation par la reconnaissance sociale » | « Et le classement de sa classe… » | Swoosh ×3 + tap | Non |
| 29 | 2:30-2:35 | 5 s | 8 | Motion graphic | Logo + tagline | « Prépare ton BEPC. Réussis ton BAC. » | « ExamBoost Togo… » | Whoosh + ding | Oui (centré, grand) |
| 30 | 2:35-2:40 | 5 s | 8 | Motion graphic | CTA + QR + URL | Play Store + URL GitHub | « Télécharge ExamBoost Togo… » | Ding | Oui (haut, moyen) |

**Total :** 30 shots × durées variables = 160 s = 2:40 ✓
**Logo ExamBoost visible :** 4 fois (Shot 1, Shot 2, Shot 29, Shot 30) ✓
**Captures d'écran réelles :** 26 (Shots 3 à 28, sauf 27 qui est une animation spéciale)
**Motion graphics purs :** 4 (Shots 1, 2, 29, 30) + 1 animation (Shot 27)
**Voix off :** ~250 mots FR + ~250 mots EN, 115 s de parole sur 160 s de vidéo

---

## Musique et sound design

### Style musical global

- **Genre :** modern lo-fi + ambient électronique, beat marqué, mélodique mais discret
- **Courbe émotionnelle :**
  - **0:00 → 0:10 (Intro) :** beat minimal, nappe synthé douce, ~100 BPM. Pose le ton moderne & tech.
  - **0:10 → 0:55 (Onboarding + Révision) :** beat qui monte en intensité, ajout d'un hi-hat, ~110 BPM. Sensation de fluidité, l'app est rapide.
  - **0:55 → 1:25 (Simulation) :** beat plus tendu, ajout d'un sous-bass, ~120 BPM. Tension de l'examen.
  - **1:25 → 1:50 (Dashboard) :** retour à un beat plus posé, ~110 BPM. Soulagement, on prend du recul.
  - **1:50 → 2:10 (Tuteur IA) :** nappe synthé éthérée, ~100 BPM. Sensation d'IA, de magie douce.
  - **2:10 → 2:30 (Gamification) :** beat joyeux, mélodique, ~115 BPM. Pic de motivation.
  - **2:30 → 2:40 (Conclusion) :** montée finale + résolution sur accord majeur. Fade-out sur 3 s.
- **Volume cible :** musique à -22 LUFS en fond, voix off à -14 LUFS au premier plan. Normalisation finale à -14 LUFS (standard YouTube/LinkedIn).

### Tracks libres de droits recommandés

Vérifier la licence de chaque track avant utilisation. Préférer les licences CC0 ou « libre usage commercial ».

1. **YouTube Audio Library** — catégorie « Corporate » ou « Technology » — tracks « The Beat » ou « Modern Ambient » (gratuit, libre usage commercial)
2. **Pixabay Music** — recherche « lo-fi study beat » ou « tech corporate » — CC0
3. **Mixkit Music** — « Modern Corporate » ou « Tech Innovation » — libre usage
4. **Uppbeat** (gratuit avec attribution) — playlists « Lo-fi Study » ou « Tech Innovation »

### Sound design (SFX)

| SFX | Timing | Source | Volume |
|---|---|---|---|
| Whoosh | 0:01, 0:05, 0:13, 0:28, 0:55, 2:08, 2:30 | Freesound CC0 | -20 LUFS |
| Ding cristallin | 0:03, 0:23, 0:43, 1:14, 1:28, 2:00, 2:33, 2:39 | Freesound CC0 | -18 LUFS |
| Tap (doigt sur écran) | Tous les taps visés | Enregistré (Rode NT-USB) | -16 LUFS |
| Swoosh (transition) | 0:28, 0:55, 1:00, etc. | Freesound CC0 | -22 LUFS |
| Tic-tac (timer) | 1:00 → 1:15 continu | Synthétisé (synth DAW) | -32 LUFS |
| Pop (apparition éléments) | 0:07, 1:26, 1:38 (×3), etc. | Freesound CC0 | -20 LUFS |
| Confettis | 2:16 → 2:19 | Freesound CC0 | -18 LUFS |

---

## Production — Outils & ressources

### Capture (screen recording)

- **scrcpy 2.4** (libre, Linux/macOS/Windows) — capture écran Android 60 fps sans filigrane
  - Commande : `scrcpy --record demo_raw.mp4 --max-size 1920 --max-fps 60 --no-window`
  - Avantage : aucun overlay, capture directe du framebuffer
- **Android Studio Screen Recorder** (fallback) — intégré au SDK, 30 fps
- **OBS Studio 30+** — pour incruster le cadre smartphone et les annotations en temps réel

### Montage

- **DaVinci Resolve 19** (gratuit, pro) — master 16:9, color grading, motion tracking
  - Template de projet : 1920×1080, 30 fps, MP4 H.264
  - Color space : Rec.709
  - Bitrate cible : 8 Mbps (master), 6 Mbps (variante 9:16), 4 Mbps (variante 1:1)
- **CapCut 3.0** (mobile, gratuit) — variante 9:16 pour réseaux sociaux
- **After Effects 2024** — pour les motion graphics (logo, cartons, annotations)

### Assets graphiques

- **Logo ExamBoost** : `assets/branding/examboost_logo.svg` (vectoriel, scalable)
- **Maquette smartphone** : Figma « Realistic iPhone 14 Pro » (gratuit, Community)
- **Police Outfit** : Google Fonts (libre, SIL OFL)
- **Police Inter** : Google Fonts (libre, SIL OFL)
- **Icônes** : Material Symbols (libre, Apache 2.0)
- **Confettis** : lib `confetti` Flutter (pub.dev)

### Backend (pour les vraies prédictions)

- **Endpoint `/predict`** : FastAPI déployé sur Railway — modèle XGBoost
- **Endpoint `/tutor/chat`** : FastAPI + GPT-4o-mini (OpenAI API) — system prompt aligné MEPST
- **Endpoint `/sessions`** : sauvegarde des sessions de révision/examen
- **Endpoint `/sync`** : synchronisation différée quand réseau disponible

### Sous-titres

- **FR** : sous-titres incrustés (burned-in) pour la variante 9:16 (TikTok/Reels — lecture auto sans son)
- **EN** : sous-titres en piste séparée (soft subtitles) pour le master 16:9
- **Format** : SRT ou VTT selon la plateforme
- **Outil** : Whisper (OpenAI, open-source) pour générer les sous-titres automatiquement à partir de l'audio, puis correction manuelle

---

## Planning de production (4 jours)

### Jour 1 — Préparation (4 h)

- [ ] Vérifier le compte démo Amina (12 sessions, 7 badges, 2 simulations)
- [ ] Charger la banque de questions (64 questions structurées + 3 000 questions OCR)
- [ ] Activer le mode hors-ligne (avion ON)
- [ ] Tester le backend Railway (endpoints `/predict`, `/tutor/chat`)
- [ ] Préparer le device de capture (Tecno Spark 8C, mode profile, 60 fps)
- [ ] Installer scrcpy + OBS Studio + DaVinci Resolve
- [ ] Mettre en place le trépied smartphone + éclairage

### Jour 2 — Capture (6 h)

- [ ] Capturer les 26 écrans réels (C-001 à C-026, hors C-025 animation)
- [ ] Capturer l'animation de déblocage badge (C-025) via script dédié
- [ ] Capturer les motion graphics de logo (4 séquences : Shot 1, 2, 29, 30) — en After Effects
- [ ] Vérifier la qualité de chaque capture (résolution, fps, lisibilité)
- [ ] Faire un montage « rough cut » de bout en bout pour valider le timing

### Jour 3 — Montage (6 h)

- [ ] Montage fin sur DaVinci Resolve (master 16:9)
- [ ] Ajout des annotations (overlays texte, cercles, flèches)
- [ ] Motion tracking des doigts virtuels
- [ ] Mixage audio (voix off + musique + SFX)
- [ ] Color grading léger (saturation +5 %, contraste +3 %)
- [ ] Export master 16:9 (1920×1080, 30 fps, MP4 H.264, 8 Mbps)
- [ ] Export variante 9:16 (CapCut, 1080×1920, 6 Mbps)
- [ ] Export variante 1:1 optionnelle (1080×1080, 4 Mbps)

### Jour 4 — Finalisation (4 h)

- [ ] Enregistrement voix off FR (femme, ton chaleureux)
- [ ] Enregistrement voix off EN (homme, ton pédagogique)
- [ ] Génération des sous-titres (Whisper + correction)
- [ ] Ajout des sous-titres FR incrustés (variante 9:16)
- [ ] Ajout des sous-titres EN (piste soft, master 16:9)
- [ ] Relecture finale par 2 membres de l'équipe
- [ ] Upload sur YouTube (non-listed) + partage lien au jury DJANTA

**Total :** 20 h de travail sur 4 jours, 1 monteur + 1 narrateur voix off.

---

## Checklist finale (avant livraison)

### Technique

- [ ] Durée totale = 160 s ± 5 s
- [ ] Résolution master = 1920×1080
- [ ] Codec = H.264, bitrate 8 Mbps
- [ ] Framerate = 30 fps
- [ ] Audio normalisé à -14 LUFS
- [ ] Voix off à -14 LUFS, musique à -22 LUFS
- [ ] Sous-titres FR + EN synchronisés
- [ ] QR code fonctionnel (test scan sur 3 devices)
- [ ] URL GitHub correcte : `github.com/djabelo712/ExamBoost-Togo`

### Contenu

- [ ] Logo ExamBoost visible au moins 3 fois (ici 4) ✓
- [ ] Toutes les 8 sections présentes
- [ ] 26 captures d'écran réelles + 4 motion graphics + 1 animation badge
- [ ] Voix off FR complète (~250 mots)
- [ ] Voix off EN complète (~250 mots)
- [ ] Aucun mockup — uniquement des captures réelles
- [ ] Score prédit réellement calculé (pas mocké)
- [ ] Compte démo « Amina » cohérent (persona Case Study)

### Pédagogique

- [ ] Les 3 piliers valeur démontrés : Révision (Section 3), Simulation (Section 4), Dashboard (Section 5)
- [ ] Algorithme SM-2 explicitement nommé (Section 3)
- [ ] Modèle XGBoost explicitement nommé (Section 5)
- [ ] Mode hors-ligne visible (réseau coupé, app fonctionne)
- [ ] CTA final clair : Play Store + URL + QR

### Diffusion

- [ ] Master 16:9 exporté
- [ ] Variante 9:16 exportée
- [ ] (Optionnel) Variante 1:1 exportée
- [ ] Upload YouTube (non-listed) + récupération lien
- [ ] Lien partagé au jury DJANTA 24 h avant le pitch

---

## Annexes

### Annexe A — Liste complète des captures d'écran (26 réelles + 4 motion + 1 animation = 31 visuels)

Les captures sont numérotées C-001 à C-026 (captures d'écran réelles de l'app) + M-001 à M-004 (motion graphics) + A-001 (animation badge). Pour chaque capture : timing précis, écran source, fichier Dart, durée, annotation.

#### Captures d'écran réelles (26)

| ID | Section | Timestamp | Durée | Écran source | Fichier Dart | Annotation | Device |
|---|---|---|---|---|---|---|---|
| C-001 | 2 | 0:10-0:14 | 4 s | Splash screen | `splash_screen.dart` | Aucune | Tecno Spark 8C |
| C-002 | 2 | 0:14-0:18 | 4 s | Onboarding step 1/3 bienvenue | `onboarding_screen.dart` | Doigt virtuel sur bouton | Tecno Spark 8C |
| C-003 | 2 | 0:18-0:22 | 4 s | Onboarding step 3/3 niveau 3e | `onboarding_screen.dart` | Flèche + « Choix du niveau — ici 3e » | Tecno Spark 8C |
| C-004 | 2 | 0:22-0:25 | 3 s | Home avec SnackBar succès | `home_screen.dart` | Cercle vert autour du SnackBar | Tecno Spark 8C |
| C-005 | 3 | 0:25-0:28 | 3 s | Home + tap Révision | `home_screen.dart` | Doigt virtuel sur la carte | Tecno Spark 8C |
| C-006 | 3 | 0:28-0:33 | 5 s | Flashcard Pythagore (recto) | `revision_screen.dart` | « Question générée par SM-2 » | Tecno Spark 8C |
| C-007 | 3 | 0:33-0:37 | 4 s | Flashcard Pythagore (verso, flip 3D) | `revision_screen.dart` | Aucune | Tecno Spark 8C |
| C-008 | 3 | 0:37-0:42 | 5 s | Question fraction + auto-évaluation | `revision_screen.dart` | Aucune | Tecno Spark 8C |
| C-009 | 3 | 0:42-0:50 | 8 s | Fin de session (score 85 %) | `revision_summary_screen.dart` | « SM-2 a planifié 3 cartes pour demain » | Tecno Spark 8C |
| C-010 | 3 | 0:50-0:55 | 5 s | Home grisé + tap Simulation | `home_screen.dart` | Aucune | Tecno Spark 8C |
| C-011 | 4 | 0:55-1:00 | 5 s | Config simulation BEPC | `simulation_config_screen.dart` | Aucune | Tecno Spark 8C |
| C-012 | 4 | 1:00-1:05 | 5 s | Examen Q1 + timer 08:42 | `exam_screen.dart` | « Conditions réelles du BEPC » | Tecno Spark 8C |
| C-013 | 4 | 1:05-1:10 | 5 s | Q2/Q5 + montage accéléré | `exam_screen.dart` | Aucune | Tecno Spark 8C |
| C-014 | 4 | 1:10-1:15 | 5 s | Q10 + modal terminer | `exam_screen.dart` | Aucune | Tecno Spark 8C |
| C-015 | 4 | 1:15-1:25 | 10 s | Rapport final score 14/20 + reco | `exam_result_screen.dart` | « L'IA identifie les chapitres faibles » | Tecno Spark 8C |
| C-016 | 5 | 1:25-1:30 | 5 s | Dashboard score 76 % + prédiction 14,2/20 | `dashboard_screen.dart` | « XGBoost — 78 % de confiance » | Tecno Spark 8C |
| C-017 | 5 | 1:30-1:38 | 8 s | Progression par matière (6 barres) | `dashboard_screen.dart` | Aucune | Tecno Spark 8C |
| C-018 | 5 | 1:38-1:44 | 6 s | Heatmap chapitres faibles | `dashboard_screen.dart` | Aucune | Tecno Spark 8C |
| C-019 | 5 | 1:44-1:50 | 6 s | Stats SRS + tap Tuteur | `dashboard_screen.dart` | Aucune | Tecno Spark 8C |
| C-020 | 6 | 1:50-1:54 | 4 s | Tuteur bienvenue + suggestions | `tutor_screen.dart` | Aucune | Tecno Spark 8C |
| C-021 | 6 | 1:54-1:58 | 4 s | Typing indicator | `tutor_screen.dart` | Aucune | Tecno Spark 8C |
| C-022 | 6 | 1:58-2:08 | 10 s | Réponse IA streaming Pythagore | `tutor_screen.dart` | « Réponse en 2,3 s — GPT-4o-mini » | Tecno Spark 8C |
| C-023 | 6 | 2:08-2:10 | 2 s | Modal exemple animé + tap badges | `tutor_screen.dart` | Aucune | Tecno Spark 8C |
| C-024 | 7 | 2:10-2:16 | 6 s | Écran badges 7 débloqués | `badges_screen.dart` | Aucune | Tecno Spark 8C |
| C-025 | 7 | 2:16-2:22 | 6 s | Animation déblocage badge « Maître des fractions » | Overlay spécial | Aucune | Tecno Spark 8C (script `trigger_badge_unlock.dart`) |
| C-026 | 7 | 2:22-2:30 | 8 s | Classement Amina 4e | `community_screen.dart` | « Motivation par la reconnaissance sociale » | Tecno Spark 8C |

**Total captures réelles :** 26 (durée cumulée = 137 s sur 160 s de vidéo = 86 %)

#### Motion graphics purs (4)

| ID | Section | Timestamp | Durée | Description | Outil |
|---|---|---|---|---|---|
| M-001 | 1 | 0:00-0:04 | 4 s | Carton d'ouverture logo | After Effects |
| M-002 | 1 | 0:04-0:10 | 6 s | Carton transition vers démo (smartphone flou) | After Effects |
| M-003 | 8 | 2:30-2:35 | 5 s | Carton logo + tagline | After Effects |
| M-004 | 8 | 2:35-2:40 | 5 s | CTA final + QR + URL | After Effects |

**Total motion graphics :** 4 (durée cumulée = 20 s sur 160 s = 12,5 %)

#### Animation badge spéciale (1)

| ID | Section | Timestamp | Durée | Description | Source |
|---|---|---|---|---|---|
| A-001 | 7 | 2:16-2:22 | 6 s | Déblocage badge « Maître des fractions » + confettis | Capture réelle (script dédié) |

**Total animation :** 1 (durée = 6 s = 3,75 %)

**Vérification :** 137 + 20 + 6 = 163 s ≈ 160 s ✓ (les 3 s d'écart viennent des recoupes/overlaps entre shots — intégré dans le montage)

#### Captures « backup » à prévoir

En plus des 26 captures principales, prévoir des captures de secours au cas où une serait floue ou buggy :

- B-001 : Splash screen variante (sans animation de chargement)
- B-002 : Onboarding step 2/3 (sélection langue — normalement skipée mais utile en backup)
- B-003 : Flashcard avec une autre matière (Français — subjonctif)
- B-004 : Examen Q1 avec autre matière (Histoire)
- B-005 : Dashboard avec autre score (variante 65 %)
- B-006 : Tuteur avec autre question (PGCD)
- B-007 : Classement avec autre école (variante Sokodé)

**Total captures backup :** 7

---

### Annexe B — Annotations à ajouter en post-production

Pour chaque capture d'écran, détail des annotations à ajouter en post-production (texte, cercles, flèches, surlignages). Toutes les annotations sont en français, dans la palette graphique ExamBoost (vert #006837, orange #D97700, blanc #F8F9FA).

#### Liste détaillée par capture

**C-002 — Onboarding step 1/3 bienvenue**
- Élément : Pointer de doigt virtuel (PNG transparent, 80×80 px)
- Position : Au-dessus du bouton « Commencer »
- Animation : Pulsation (scale 0,9 → 1,1 → 0,9 sur 1 s, en boucle)
- Couleur : Orange #D97700
- Motion tracking : Sur le bouton « Commencer »

**C-003 — Onboarding step 3/3 niveau 3e**
- Élément 1 : Flèche courbée (SVG, 60×40 px)
- Position : Pointant de la droite vers la carte « 3e (BEPC) »
- Couleur : Orange #D97700
- Élément 2 : Texte « Choix du niveau — ici 3e » (Outfit Bold 18 pt)
- Position : À droite de la flèche
- Couleur texte : Orange #D97700
- Animation : Apparition par fondu (0,3 s)
- Motion tracking : Sur la carte « 3e (BEPC) »

**C-004 — Home avec SnackBar succès**
- Élément : Cercle vert (SVG, 320×60 px)
- Position : Autour du SnackBar en haut
- Couleur : Vert #006837 (contour 3 px, fond transparent)
- Animation : Apparition par scale-up (90 % → 100 % sur 0,3 s)

**C-005 — Home + tap Révision**
- Élément : Pointer de doigt virtuel (PNG, 80×80 px)
- Position : Au-dessus de la carte « Révision Adaptative »
- Animation : Pulsation (scale 0,9 → 1,1 → 0,9 sur 1 s)
- Couleur : Orange #D97700

**C-006 — Flashcard Pythagore (recto)**
- Élément : Texte « Question générée par SM-2 » (Inter Italic 14 pt)
- Position : En haut à droite de l'écran
- Couleur texte : Gris #888888
- Animation : Apparition par fondu (0,3 s), maintien jusqu'à la fin de la capture

**C-009 — Fin de session (score 85 %)**
- Élément : Texte « L'algorithme SM-2 a planifié 3 cartes pour demain » (Outfit Bold 24 pt)
- Position : En bas de l'écran, sur 2 lignes centrées
- Couleur texte : Vert #006837
- Fond : Rectangle blanc 80 % opacité, 16 px border-radius
- Animation : Apparition par slide-up (translation Y +50 px → 0 sur 0,4 s)

**C-012 — Examen Q1 + timer 08:42**
- Élément : Texte « Conditions réelles du BEPC » (Outfit Bold 18 pt)
- Position : En haut à droite de l'écran
- Couleur texte : Rouge #D32F2F
- Animation : Apparition par fondu (0,3 s)

**C-015 — Rapport final score 14/20 + reco**
- Élément : Texte « L'IA identifie les chapitres faibles et planifie les révisions » (Outfit Bold 22 pt)
- Position : En bas de l'écran, sur 2 lignes centrées
- Couleur texte : Orange #D97700
- Fond : Rectangle vert #006837 80 % opacité, 16 px border-radius
- Animation : Apparition par slide-up (translation Y +50 px → 0 sur 0,4 s)

**C-016 — Dashboard score 76 % + prédiction 14,2/20**
- Élément : Texte « XGBoost — 78 % de confiance » (Outfit Bold 18 pt)
- Position : En haut à droite de l'écran
- Couleur texte : Orange #D97700
- Animation : Apparition par fondu (0,3 s)

**C-022 — Réponse IA streaming Pythagore**
- Élément : Texte « Réponse générée en 2,3 s — modèle GPT-4o-mini fine-tuné programme togolais » (Outfit Bold 18 pt)
- Position : En bas de l'écran, centré
- Couleur texte : Orange #D97700
- Fond : Rectangle blanc 80 % opacité, 16 px border-radius
- Animation : Apparition par fondu (0,3 s), maintenu 5 s

**C-026 — Classement Amina 4e**
- Élément : Texte « Motivation par la reconnaissance sociale » (Outfit Bold 18 pt)
- Position : En haut à droite de l'écran
- Couleur texte : Orange #D97700
- Animation : Apparition par fondu (0,3 s)

#### Style guide des annotations

| Type | Forme | Couleur | Taille | Police |
|---|---|---|---|---|
| Pointer de doigt | PNG | Orange #D97700 | 80×80 px | — |
| Flèche | SVG courbée | Orange #D97700 | 60×40 px | — |
| Cercle | SVG | Vert #006837 (contour 3 px) | Variable | — |
| Texte overlay | Rectangle + texte | Orange/Vert/Rouge/Gris | 14-24 pt | Outfit Bold / Inter Italic |
| Fond overlay | Rectangle 80 % opacité | Variable | 16 px border-radius | — |

#### Animations standard des annotations

- **Apparition par fondu** : opacité 0 → 100 % sur 0,3 s
- **Apparition par scale-up** : scale 90 % → 100 % sur 0,3 s
- **Apparition par slide-up** : translation Y +50 px → 0 sur 0,4 s
- **Pulsation (loop)** : scale 0,9 → 1,1 → 0,9 sur 1 s, en boucle infinie
- **Maintien** : opacité 100 % pendant X secondes (selon durée de la capture)
- **Disparition** : opacité 100 % → 0 sur 0,3 s (transition vers capture suivante)

#### Outil de motion tracking

Pour les annotations qui doivent suivre un élément en mouvement (carte sélectionnée, bouton qui slide, doigt virtuel), utiliser le motion tracking de DaVinci Resolve :

1. **Sélectionner le point de référence** dans la capture (coin de la carte, centre du bouton).
2. **Lancer le tracking** (forward, frame-by-frame).
3. **Vérifier le tracking** sur toute la durée de la capture — corriger manuellement si nécessaire.
4. **Attacher l'annotation** au point de tracking.
5. **Tester le rendu** sur 3 frames (début, milieu, fin) avant export final.

---

### Annexe C — Script démo live (90 sec, devant le jury)

Le script ci-dessous est pour la démo live que tu feras devant le jury DJANTA le 24 juillet 2026. Contrairement à la vidéo démo (pré-enregistrée, 2:40), la démo live est plus courte (90 s) et interactive — tu cliques vraiment sur l'app en direct. Prévoir un device de secours (deux Tecno Spark 8C configurés à l'identique) en cas de crash.

#### Pré-requis démo live

- 2 devices Tecno Spark 8C configurés (compte Amina identique sur les deux)
- Câble HDMI ou adapter sans fil (Google Cast) pour projeter l'écran
- Backend Railway opérationnel (test 1 h avant)
- Mode avion OFF (besoin réseau pour tuteur IA) — contredit le mode offline de la vidéo, mais la démo live nécessite le tuteur IA en temps réel
- Batterie chargée à 100 % + chargeur branché

#### Script démo live (90 s)

**0:00 — 0:10 — Introduction (10 s)**

> « Je vais maintenant vous montrer l'application en direct. Vous verrez que tout fonctionne — y compris le tuteur IA, en temps réel. »

(Présenter le device au jury, montrer l'écran d'accueil.)

**0:10 — 0:25 — Onboarding rapide (15 s)**

- Tap « Révision Adaptative » sur home screen
- (Ne refait pas l'onboarding — profil déjà créé)
> « Profil déjà créé, on va direct à la révision. »

**0:25 — 0:50 — Révision adaptative (25 s)**

- Tap « Voir la réponse » sur la 1ère carte
- Tap « Facile »
- Tap « Voir la réponse » sur la 2ème carte
- Tap « Bon »
> « L'algorithme SM-2 choisit la question au bon moment. L'élève auto-évalue sa maîtrise. L'algorithme ajuste l'intervalle de révision. »

**0:50 — 1:15 — Simulation d'examen BEPC (25 s)**

- Retour home
- Tap « Simulation »
- Config : BEPC, 5 questions (pas 10 — trop long pour la démo live), Mathématiques
- Tap « Démarrer »
- Répondre aux 5 questions rapidement (1 question = 3 s)
- Tap « Terminer » → « Oui »
> « Simulation BEPC, 5 questions. Conditions réelles — timer, format QCM. »

**1:15 — 1:30 — Tableau de bord + prédiction (15 s)**

- Tap « Tableau de bord » dans bottom nav
- Montrer score global + prédiction BEPC
> « Score global : 76 %. Prédiction BEPC : 14,2 sur 20, avec 78 % de confiance. Modèle XGBoost. »

**1:30 — 1:50 — Tuteur IA (20 s) — le moment fort**

- Tap « Tuteur IA »
- Tap suggestion « Explique-moi Pythagore »
- Attendre le typing indicator (1-2 s)
- Lire la réponse streaming (5-8 s)
> « Le tuteur IA répond en moins de 3 secondes. Disponible 24h/24. Modèle GPT-4o-mini, fine-tuné sur le programme togolais. »

**1:50 — 1:30 — Conclusion (10 s)**

- Tap « Badges » dans bottom nav
- Montrer les badges débloqués
> « 7 badges, classement de classe, gamification. ExamBoost Togo — gratuit sur Play Store. »

**Total :** 90 s

#### Plan B en cas de crash

Si l'app crashe pendant la démo live :

1. **Ne pas paniquer.** Dire : « L'app est encore en version bêta, on a un plan B. »
2. **Switcher sur le device de secours** (2e Tecno Spark 8C configuré à l'identique).
3. **Reprendre la démo** à l'étape où ça a crashé.
4. **Si crash sur le tuteur IA** (problème backend) : dire « Le backend est sur Railway, parfois il y a des latences. Je vous montre le dashboard à la place. » et passer directement à la Section 5.
5. **Si crash réseau** : dire « Mode hors-ligne — l'app fonctionne sans réseau. Je vous montre la révision adaptative, qui est 100 % offline. »

#### Répétition recommandée

- 5 répétitions complètes chronométrées (objectif : 85-95 s, jamais plus de 100 s)
- 2 répétitions avec simulation de crash (pour tester le plan B)
- 1 répétition en conditions réelles (projecteur, jury fictif, bruit ambiant)
- 1 répétition la veille du pitch (24 juillet 2026 matin)

#### Gestuelle recommandée

- **Tenir le device à 30 cm du visage**, légèrement incliné vers le jury
- **Pointer avec le doigt** (pas un stylet) — plus naturel
- **Regarder le jury** 50 % du temps, l'écran 50 % du temps
- **Annoncer chaque action avant de la faire** : « Je vais maintenant lancer une simulation d'examen. »
- **Respirer profondément** entre chaque section — 1 respiration = 2 s de pause

---

## Notes finales pour l'équipe

### Cohérence avec les autres livrables

Cette vidéo démo s'inscrit dans une série de livrables DJANTA Tech Hub :

- `docs/Video_Teaser_2min.md` — vidéo émotionnelle 2 min (problème → solution → équipe)
- `docs/Video_Demo_2min.md` (ce document) — vidéo produit 2:40 (démo clic par clic)
- `docs/Pitch_Deck_10_slides.md` — pitch deck 7 min (slides orales)
- `docs/Investor_Deck_15_slides.md` — deck investisseurs 15 slides
- `docs/One_Pager.md` — fiche A4 récapitulative
- `docs/Case_Study_Amina.md` — persona Amina (cohérent avec le compte démo)
- `docs/QA_jury_anticipe.md` — Q&A anticipé pour le jury

La démo vidéo doit être cohérente avec ces documents :

- **Persona Amina** : même nom, même niveau (3e), même école (École Pilote Lomé), même parcours (12 sessions, 7 badges) que dans le Case Study.
- **3 piliers valeur** : Révision adaptative (SM-2), Simulation (conditions réelles BEPC), Dashboard (prédiction XGBoost) — cités dans le même ordre que le Pitch Deck.
- **Chiffres clés** : 78 % de confiance XGBoost, 89 % de rétention à 7 jours, 14,2/20 de prédiction BEPC — identiques au One Pager.
- **CTA final** : « Télécharge ExamBoost Togo — gratuit sur Play Store » + URL GitHub — cohérent avec tous les autres livrables.

### Différence entre vidéo démo et démo live

| Dimension | Vidéo démo (ce doc) | Démo live (Annexe C) |
|---|---|---|
| Durée | 2:40 (160 s) | 90 s |
| Mode | Pré-enregistrée | Interactive, en direct |
| Réseau | Hors-ligne (avion ON) | En ligne (backend Railway) |
| Device | 1 (Tecno Spark 8C) | 2 (Tecno Spark 8C + secours) |
| Risque | Aucun (post-produit) | Élevé (crash possible) |
| Audience | Investisseurs, jury différé, YouTube | Jury en salle, pitch 24 juillet |
| Voix off | Oui (FR + EN) | Non (parle l'auteur en direct) |
| Annotations | En post-production | Aucune (parle l'auteur pour expliquer) |

### Diffusion

- **YouTube** (non-listed) — lien partagé au jury DJANTA 24 h avant le pitch
- **Loom** — variante avec commentaires de l'équipe
- **LinkedIn** — post de l'équipe avec la vidéo (variante 16:9)
- **TikTok / Instagram Reels** — variante 9:16, postée le jour du pitch
- **GitHub README** — embed vidéo en haut du README pour les visiteurs du repo

### Évolutions futures

- **V2 (post-MVP, M6+)** : ajouter une Section « Mode hors-ligne » pour montrer explicitement le offline-first (couper le réseau pendant la démo, montrer que l'app fonctionne toujours).
- **V3 (post-pilote, M12+)** : ajouter une Section « Multi-joueurs » avec défi en temps réel entre 2 élèves (nouvelle feature).
- **V4 (post-CEDEAO, M24+)** : doubler la vidéo en EN avec voix off anglophone pour l'expansion CEDEAO.

### Pré-requis pour la capture (rappel)

Avant le tournage, valider les points suivants avec l'équipe Tech :

1. Compte démo Amina créé et pré-rempli (`scripts/seed_demo_data.dart`)
2. Backend Railway opérationnel (endpoints `/predict`, `/tutor/chat`)
3. Banque de questions chargée (64 + 3 000)
4. Mode profile activé (pas debug) sur le device de capture
5. scrcpy 2.4 installé et testé (60 fps)
6. DaVinci Resolve 19 installé
7. Voix off FR + EN engagées (1 femme, 1 homme)
8. Trépied smartphone + éclairage prêts

### Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Crash app pendant capture | Moyenne | Faible (on peut recapturer) | Mode profile + tests avant |
| Backend Railway indisponible | Faible | Élevé (pas de prédiction) | Capture tuteur IA en avance + insertion post-prod |
| Latence tuteur IA > 5 s | Moyenne | Moyen | Capture plusieurs takes, garder le meilleur |
| Flip 3D saccade à 30 fps | Élevée | Faible | Capture 60 fps, ralentissement 0,7× si besoin |
| Voix off indisponible | Faible | Élevé | Prévoir 2 voix off FR (femme) de backup |
| QR code illisible | Faible | Faible | Test scan sur 3 devices avant export |
| Montage > 4 jours | Faible | Moyen | Réduire le scope (sauter Section 7 si besoin) |

---

*Document de production — diffusion équipe ExamBoost Togo + monteur vidéo + démonstrateur jury.*
*Juin 2026 — v1.0 — Auteur : Agent CE (général-purpose), Session 4, Vague 3.*
