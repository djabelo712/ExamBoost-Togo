# Demo Script Live — ExamBoost Togo (90 secondes)

> Script pas-à-pas pour la démo live au jury DJANTA Tech Hub.
> Profil démo : **Amina Kossi**, élève en 3e au Lycée de Tokoin.
> Durée cible : **90 secondes strictes**, clic par clic.
> Préparer le téléphone **avant** d'entrer dans la salle.

---

## Préparation avant démo

### Checklist 10 items (à valider 15 min avant le pitch)

- [ ] Téléphone Android chargé à 80%+ (batterie pleine idéale)
- [ ] APK debug ExamBoost installé (`flutter install` ou `adb install`)
- [ ] Profil démo "Amina Kossi" créé via Onboarding (3e, Lycée de Tokoin, Lomé)
- [ ] 5 compétences BKT initialisées : 3 moyennes (P(L) ≈ 0.55-0.65), 2 faibles (P(L) ≈ 0.25-0.35)
- [ ] 12 badges débloqués manuellement en DB Hive (dont "Régularité Argent" 30 jours)
- [ ] Streak 14 jours configuré (dateInscription ajustée ou champ `streakDays: 14`)
- [ ] Mode avion OFF, Wi-Fi/4G actif (nécessaire pour Tuteur IA — fallback offline si coupure)
- [ ] Luminosité écran à 80%+ (visible au projecteur)
- [ ] Cable USB de secours + laptop avec captures d'écran de backup ouvertes
- [ ] App lancée une fois, écran d'accueil affiché, téléphone en veille (tap pour réveiller = ouverture instantanée)

### Captures d'écran de backup (à ouvrir sur laptop en arrière-plan)
- `ecran_1_accueil.png` — Home avec salutation "Bonjour Amina"
- `ecran_3_revision.png` — Flashcard flip
- `ecran_4_simulation.png` — Timer + question
- `ecran_5_dashboard.png` — Score 68% + prédiction 12/20

---

## Script pas-à-pas

### 0:00-0:05 — Introduction (5 sec)

**Dire :** "Je vais vous montrer comment ExamBoost prépare Amina au BEPC."

**Faire :**
- Tap sur l'écran pour réveiller le téléphone
- Logo ExamBoost visible (splash déjà passé, app en cache)

**Annotations :** voix posée, regard vers le jury, téléphone tenu à hauteur de poitrine.

---

### 0:05-0:15 — Accueil (10 sec)

**Dire :** "Amina est en 3e au Lycée de Tokoin. Voici son tableau de bord."

**Faire :**
- Tap sur la carte **"Mon Tableau de Bord"** (3e carte, bleue, icône bar_chart)
- Écran Dashboard s'affiche
- Pointer le **Score global : 68%** (en haut, grand chiffre vert)
- Pointer la **Prédiction BEPC : 12/20** (badge orange sous le score)

**Annotations :** nommer les chiffres à voix haute ("68%, prédiction 12 sur 20"). Le jury doit entendre les résultats, pas seulement les voir.

---

### 0:15-0:35 — Révision adaptative (20 sec)

**Dire :** "Amina révise 15 minutes par jour. L'IA choisit les questions."

**Faire :**
- Tap sur le bouton retour Android (ou flèche back AppBar) → retour accueil
- Tap sur la carte **"Révision Adaptative"** (1re carte, verte, icône flash_on)
- Flashcard s'affiche (question face recto)
- Tap sur le bouton **"Voir la réponse"** → animation flip 3D, verso révélé
- Tap sur le bouton **"Facile"** (vert) → SM-2 met à jour l'intervalle, question suivante s'affiche
- La question suivante est plus difficile (adaptation IRT visible)

**Annotations :** marquer un temps sur l'animation flip (1 sec) pour laisser le jury la voir. Prononcer "Facile" en tapant pour ancrer le geste.

---

### 0:35-0:55 — Simulation d'examen (20 sec)

**Dire :** "Une fois par semaine, Amina fait une simulation complète."

**Faire :**
- Tap bouton retour → accueil
- Tap sur la carte **"Simulation d'Examen"** (2e carte, orange, icône timer)
- Écran de config : sélectionner **BEPC** (déjà par défaut), régler **10 questions**, mode **Rapide**
- Tap sur **"Démarrer"** → première question
- Répondre à 2-3 questions (tap sur une réponse, tap "Valider") — le timer décompte en haut
- Tap sur **"Terminer"** (icône flag ou bouton fin) → rapport de simulation
- Voir **score 14/20** affiché en grand + recommandations sous le score

**Annotations :** pointer le timer ("regardez le chrono en haut"), le score final ("14 sur 20"), et les recommandations ("le système lui dit quoi réviser").

---

### 0:55-0:75 — Tuteur IA (20 sec)

**Dire :** "Quand Amina ne comprend pas, elle demande au tuteur IA."

**Faire :**
- Tap bouton retour → accueil
- Tap sur la carte **"Tuteur IA"** (4e carte, violette, icône smart_toy_outlined)
- Écran chat vide avec suggestions cliquables
- Tap sur la suggestion **"Explique-moi Pythagore"**
- Le typing indicator animé (3 points) s'affiche pendant ~2-3 sec
- La réponse IA s'affiche dans une bulle (avatar bot à gauche, explication pédagogique avec formule a²+b²=c²)

**Annotations :** montrer le typing indicator ("l'IA réfléchit"), puis laisser la réponse se dérouler. Ne pas lire toute la réponse — pointer la formule et dire "explication adaptée au niveau 3e".

---

### 0:75-0:85 — Badges (10 sec)

**Dire :** "Amina a débloqué 12 badges. Sa régularité est récompensée."

**Faire :**
- Tap bouton retour → accueil
- Tap sur la carte **"Mes Badges"** (5e carte, or, icône emoji_events_outlined)
- Grille de badges s'affiche : 12 débloqués (colorés), 27 grisés
- Pointer le badge **"Régularité Argent"** (30 jours consécutifs) — en haut, avec icône flamme

**Annotations :** dire "Régularité Argent, 30 jours" en pointant. Le streak de 14 jours d'Amina est affiché quelque part sur l'écran.

---

### 0:85-0:90 — Conclusion (5 sec)

**Dire :** "ExamBoost — gratuit pour l'élève, 100% aligné sur le programme togolais."

**Faire :**
- Tap bouton retour → accueil
- Montrer le logo / la salutation "Bonjour Amina" en haut
- Baisser lentement le téléphone

**Annotations :** regard vers le jury, sourire, voix qui descend à la fin (clôture nette). Ne pas ajouter de phrase.

---

## Notes importantes

### Risques et plans B

| Risque | Plan B (phrase à dire + action) |
|---|---|
| App crash / freeze | "Laissez-moi redémarrer." → tuer l'app, relancer, reprendre à la section en cours ( Profil déjà créé, ~5 sec pour rouvrir) |
| Pas de réseau (Tuteur IA timeout) | "Mode offline — ExamBoost fonctionne sans Internet." → skip la réponse IA, montrer le placeholder offline, passer aux Badges |
| Question bug / flashcard ne flip pas | "Question suivante." → tap bouton skip ou retour accueil, enchaîner la section suivante |
| Timer simulation expiré pendant la démo | "La simulation continue automatiquement." → le système passe à la question suivante ou au rapport, ne pas interrompre |
| Téléphone s'éteint (batterie) | Brancher cable USB de secours + montrer captures d'écran laptop pendant le redémarrage |
| Jury pose une question pendant la démo | "Excellente question, j'y réponds juste après la démo." → ne pas casser le timing |

### Timing

- **Total : 90 sec strictes** (chronométrer en interne, ne pas le montrer au jury)
- **Si retard (>5 sec sur une section) :** skip la section Badges (10 sec gagnées) — conclusion directe après Tuteur IA
- **Si avance (<5 sec d'avance cumulée) :** sur le Dashboard, montrer les stats détaillées par matière (radar de maîtrise, 10 sec bonus)
- **Buffer sécurité :** viser 85 sec réelles pour absorber un imprévu sans dépasser

### Profil démo à préparer (Amina Kossi)

| Champ | Valeur |
|---|---|
| `prenom` | Amina |
| `nom` | Kossi |
| `niveauScolaire` | 3eme |
| `etablissement` | Lycée de Tokoin |
| `ville` | Lomé |
| `bktMaitrise` | 5 entrées : `math_algebre: 0.62`, `math_geometrie: 0.28`, `fr_grammaire: 0.58`, `fr_conjugaison: 0.31`, `svt: 0.65` (3 moyennes, 2 faibles) |
| Badges débloqués | 12 (dont `regularite_argent` 30j, `premier_examen`, `streak_7j`, `streak_14j`, `revisions_50`, etc.) |
| `streakDays` | 14 |
| Historique simulations | 3 simulations passées (moyenne 12/20) pour alimenter la prédiction |

### Checklist matériel (à avoir sur soi le jour J)

- [ ] Téléphone Android chargé (80%+)
- [ ] APK debug installé (dernière version main)
- [ ] Profil Amina créé et vérifié (ouvrir l'app, vérifier la salutation)
- [ ] Mode avion OFF (pour Tuteur IA)
- [ ] Cable USB de secours + chargeur portable
- [ ] Capture d'écran de backup sur laptop (4 écrans clés ouverts en onglets)
- [ ] Chronomètre discret (montre ou téléphone secondaire)
- [ ] Bouteille d'eau (la gorge seèche sous stress)

---

## Variantes

### Version 60 sec (si timing très court demandé par le jury)

Skip Tuteur IA + Badges. Focus : **Accueil → Révision → Simulation → Dashboard**.

| Section | Timing |
|---|---|
| 0:00-0:05 | Introduction |
| 0:05-0:15 | Accueil + Dashboard (score 68%, prédiction 12/20) |
| 0:15-0:30 | Révision adaptative (flip + "Facile") |
| 0:30-0:55 | Simulation (config + 2 questions + rapport 14/20) |
| 0:55-0:60 | Conclusion |

### Version 120 sec (si le jury demande d'aller plus loin)

Ajouter après Badges :

| Section | Timing | Action |
|---|---|---|
| 0:85-0:95 | Mode Flash 5 min (BO) | Tap "Révision Adaptative" → toggle "Mode Flash 5 min" → démarrer, montrer le mini-timer 5:00 |
| 0:95-0:110 | Recherche questions (AM) | Tap "Rechercher" → filtres : BEPC, Mathématiques, 2023, difficile → 8 résultats → tap sur une question |
| 0:110-0:120 | Conclusion étendue | "ExamBoost — gratuit, offline, aligné Togo, 39 badges, orientation post-BAC." |

---

## Q&A post-démo probables

| Question du jury | Réponse courte |
|---|---|
| "Combien de temps pour créer le profil Amina ?" | 30 secondes (onboarding 4 écrans : nom, niveau, établissement, objectif BEPC) |
| "L'app fonctionne vraiment offline ?" | Oui, 100% des features core (révision, simulation, badges, dashboard). Seul le Tuteur IA nécessite le réseau — fallback message pédagogique offline. |
| "Le tuteur IA coûte cher en API ?" | 0,003 USD par échange (GLM-4-flash). 30 USD/mois pour 10 000 échanges. Rentable dès 100 élèves actifs. |
| "Comment sont créées les questions ?" | 20 questions démo en JSON. V2 : pipeline OCR des annales BEPC/BAC togolais (MEPST) + validation enseignants. |
| "Et la prédiction 12/20, c'est fiable ?" | Modèle BKT + XGBoost entraîné sur données simulées. Précision cible ±2 points. S'affine avec chaque réponse de l'élève. |
| "Combien d'élèves testés ?" | Enquête terrain 100 élèves Lomé (juillet 2026). Pilote 50 élèves en septembre 2026 dans 2 lycées. |
| "Le business model ?" | Gratuit pour l'élève. Monétisation : écoles (abonnement 500 FCFA/élève/mois), particuliers premium (2000 FCFA/mois), partenaires institutionnels. |

---

## Rappels finaux au présentateur

1. **Respirer** avant de commencer — 1 inspiration profonde, 90 sec ça passe vite.
2. **Ne pas lire l'écran** — connaître les chiffres par cœur (68%, 12/20, 14/20, 12 badges).
3. **Voix haute et posée** — le jury doit entendre même sans voir l'écran.
4. **Si bug, pas d'excuse** — enchaîner avec le plan B sans commenter l'incident.
5. **Conclure net** — "gratuit, aligné Togo" puis se taire. Ne pas rajouter de phrase.
