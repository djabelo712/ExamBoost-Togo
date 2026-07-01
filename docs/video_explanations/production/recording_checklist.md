# Checklist avant enregistrement voix off — ExamBoost Togo

Cette checklist doit être validée intégralement avant chaque session d'enregistrement de voix off. Imprimer cette feuille (ou la garder ouverte sur un 2e écran) et cocher chaque case au fur et à mesure.

## 1. Préparation du script (15 min avant)

- [ ] Script final relu 2 fois (à voix haute, en chronométrant)
- [ ] Durée du script vérifiée : ± 5 % de la durée cible (30 s ± 1,5 s)
- [ ] Mots difficiles à prononcer repérés et notés (ex : "Pythagore", "Thalès", "Pythagoricien")
- [ ] Prononciation de ces mots vérifiée (dictionnaire en ligne, Forvo, ou demande à un natif)
- [ ] Phrases trop longues (> 12 mots) découpées en 2 avec respirations naturelles
- [ ] Numéros et formules mathématiques réécris phonétiquement :
  - "x²" → "ix carré"
  - "√100" → "racine de cent"
  - "0,5" → "zéro virgule cinq" (PAS "zéro point cinq")
  - "20 Ω" → "vingt ohms"
- [ ] Ponctuation ajoutée pour le rythme : "/" pour micro-pause, "//" pour pause longue
- [ ] Script imprimé en gros caractères (Arial 18 pt, interligne 1,5) OU ouvert sur tablette en mode plein écran

## 2. Préparation de la pièce (10 min avant)

- [ ] Pièce choisie : petite, peu réverbérante (chambre avec lit et rideaux, pas de cuisine/salle de bain)
- [ ] Fenêtres fermées (bruit extérieur)
- [ ] Porte verrouillée (interruptions)
- [ ] Téléphone en mode silencieux (pas de vibrations non plus)
- [ ] Animaux domestiques hors de la pièce
- [ ] Ventilateur / climatisation : éteindre si bruyant, sinon le laisser (bruit constant préférable à des allers-retours)
- [ ] Notification ordinateur (mail, Slack, etc.) : mode "Ne pas déranger"
- [ ] Tapis ou couverture épaisse derrière l'ordinateur (pour réduire les échos)

## 3. Préparation du matériel (5 min avant)

- [ ] Micro USB branché et reconnu par l'ordinateur
- [ ] Logiciel d'enregistrement ouvert (Audacity, GarageBand, OBS Studio)
- [ ] Fréquence d'échantillonnage réglée : 44 100 Hz
- [ ] Format d'enregistrement : WAV (non compressé) ou FLAC
- [ ] Niveau d'entrée micro testé : voix normale doit afficher entre -12 dBFS et -6 dBFS
  - Si trop bas (< -20 dBFS) : rapprocher le micro (15-20 cm de la bouche) ou augmenter le gain
  - Si trop haut (> -3 dBFS ou clipping) : éloigner le micro ou baisser le gain
- [ ] Casque de monitoring branché (pour entendre sa propre voix sans latence)
- [ ] Test d'enregistrement de 10 s effectué et relu en écoute
- [ ] Pop-filter placé devant le micro (réduit les "p" et "b" explosifs)
- [ ] Support de micro stable (pas de manipulations pendant l'enregistrement)

## 4. Préparation vocale (5 min avant)

- [ ] Verre d'eau à portée de main (eau à température ambiante, pas glacée)
- [ ] Boire 1-2 gorgées 5 min avant l'enregistrement
- [ ] Échauffement vocal (5 min) :
  - Respiration profonde : 10 inspirations abdominales lentes
  - Bourdonnement "mmm" en montant et descendant les notes
  - "babababa" (articulation des lèvres)
  - "tatatata" (articulation de la pointe de la langue)
  - "kakakaka" (articulation du voile du palais)
  - "mamamama" (articulation combinée)
  - Lire 2 phrases à voix haute, en articulant exagérément
- [ ] Sourire léger avant de parler (la voix paraît plus chaleureuse)
- [ ] Épaules détendues, dos droit, tête dans l'axe du micro

## 5. Enregistrement (30 min pour 1 vidéo)

- [ ] Annonce de début : "Prise 1, q01_pythagore, FR" (sur une piste séparée ou avant le vrai script, à couper au montage)
- [ ] Lecture du script en entier, sans s'arrêter (même en cas d'erreur mineure — on refait une prise complète)
- [ ] Respirations naturelles entre les phrases (ne pas forcer l'expiration)
- [ ] Articulation marquée sur les mots-clés (Pythagore, BC², hypoténuse)
- [ ] Intonation conforme aux notes du script (cf. "Notes de prononciation et d'intonation")
- [ ] Prise 2 enregistrée (mêmes réglages)
- [ ] Prise 3 enregistrée
- [ ] Pause de 5 min entre les prises (boire de l'eau, se dégourdir)
- [ ] Si une 4e prise est nécessaire pour un passage difficile : enregistrer ce passage séparément (en "pickup")
- [ ] Tous les fichiers sauvegardés avec nomenclature : `q01_pythagore_FR_prise1.wav`, `q01_pythagore_FR_prise2.wav`, etc.

## 6. Écoute et sélection (15 min)

- [ ] Écoute des 3 prises en entier, casque sur les oreilles
- [ ] Note des points forts et points faibles de chaque prise :
  - Prise 1 : ...
  - Prise 2 : ...
  - Prise 3 : ...
- [ ] Sélection de la meilleure prise (critères : clarté, rythme, prononciation, énergie)
- [ ] Si nécessaire, combiner des segments de différentes prises dans Audacity (couper-coller)
- [ ] Vérification finale : pas de bruits parasites (clavier, respiration forte, estomac qui gargouille)

## 7. Post-traitement (10 min)

- [ ] Réduction de bruit (Audacity : effet "Réduction de bruit", capture 2 s de silence au début)
- [ ] Normalisation à -3 dBFS (Audacity : effet "Normaliser")
- [ ] Compression (Audacity : effet "Compressseur", ratio 2:1, threshold -20 dB)
- [ ] Optionnel : égaliseur "bass boost" +2 dB à 100 Hz pour voix masculine
- [ ] Optionnel : égaliseur "treble boost" +2 dB à 4000 Hz pour clarté
- [ ] Suppression des silences longues (> 1,5 s) au milieu du script
- [ ] Suppression des bruits de bouche (cliquements) avec l'outil "Effacer" d'Audacity
- [ ] Export final en MP3 192 kbps stéréo, nom : `q01_pythagore_FR.mp3`
- [ ] Stockage dans `ExamBoost-Togo/assets/audio/q01_pythagore_FR.mp3`

## 8. Version anglaise (si applicable)

Refaire les étapes 1 à 7 avec le script EN :
- [ ] Script EN relu (vérifier la prononciation des termes mathématiques en anglais)
- [ ] 3 prises enregistrées
- [ ] Sélection et post-traitement
- [ ] Export `q01_pythagore_EN.mp3`

## 9. Archivage

- [ ] Tous les fichiers bruts (WAV des 3 prises) archivés dans `ExamBoost-Togo/docs/video_explanations/raw_audio/q01_pythagore/`
- [ ] Script annoté (avec notes de prises) archivé dans le même dossier
- [ ] Cette checklist complétée et archivée (trace de production)

## 10. Validation finale

- [ ] MP3 final écouté 1 fois en entier, casque sur les oreilles
- [ ] MP3 synchronisé avec l'animation dans CapCut (test rapide)
- [ ] Aucun problème audible (saturation, bruit, prononciation erronée)
- [ ] Fichier MP3 copié dans `assets/audio/`
- [ ] Durée du MP3 conforme au storyboard (± 0,5 s)

## Signes de fatigue à surveiller
- Voix qui devient rauque → pause de 10 min + eau
- Bouche sèche → boire de l'eau + Repos 5 min
- Toux → stopper l'enregistrement, reprendre plus tard
- Perte de concentration (mots qui se mélangent) → pause de 15 min, marche extérieure si possible

## Si ça ne marche pas
- Si après 5 prises la qualité n'est pas satisfaisante :
  1. Faire une pause de 30 min minimum
  2. Réécouter les prises existantes, identifier le problème (prononciation, rythme, ton)
  3. Reprendre avec une nouvelle approche (changer le ton, ralentir le rythme)
  4. Si toujours insatisfaisant après 10 prises : envisager ElevenLabs (voix synthèse) en backup
