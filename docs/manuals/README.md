# Manuel eleve + Guide enseignant (ExamBoost Togo)

Ce dossier contient le script Python qui genere les 2 PDFs de
documentation destines a la distribution physique dans les ecoles
pilotes de Lome :

- **Manuel_Eleve_ExamBoost.pdf** (~20 pages) - a destination des
  eleves de 3e, 1ere et Terminale qui utilisent ExamBoost pour
  preparer le BEPC ou le BAC.
- **Guide_Enseignant_ExamBoost.pdf** (~15 pages) - a destination des
  enseignants et directeurs de cursus des etablissements partenaires.

Ces 2 documents sont gratuits, diffusables librement, et concus pour
etre imprimes en noir et blanc ou en couleur (A4 recto-verso, dos
carre colle).

---

## Structure du dossier

```
docs/manuals/
├── README.md                          Ce fichier
├── requirements.txt                   Dependances Python (reportlab)
├── generate_manuals.py                Script de generation ReportLab
└── output/
    ├── Manuel_Eleve_ExamBoost.pdf     Manuel eleve (~20 pages)
    └── Guide_Enseignant_ExamBoost.pdf Guide enseignant (~15 pages)
```

---

## Demarrage rapide

### 1. Installer les dependances

```bash
cd docs/manuals
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Ou directement :

```bash
pip install reportlab==4.2.0
```

### 2. Generer les 2 PDFs

```bash
python3 generate_manuals.py
```

Les PDFs sont ecrits dans `output/`. La generation prend moins de
3 secondes sur une machine standard.

### 3. Verifier le resultat

```bash
ls -la output/
# Manuel_Eleve_ExamBoost.pdf      ~60 Ko, 21 pages
# Guide_Enseignant_ExamBoost.pdf  ~45 Ko, 15 pages
```

---

## Contenu des PDFs

### Manuel eleve (12 sections, ~20 pages)

1. Bienvenue sur ExamBoost - presentation, algorithme SM-2/IRT/BKT
2. Ton premier lancement - installation (Play Store + APK), onboarding
3. Reviser avec les flashcards - auto-evaluation, SM-2, bouton Passer
4. Simuler un examen - configuration, minuteur, rapport de fin
5. Suivre ta progression - dashboard, carte de chaleur, P(L)
6. Le tuteur IA - methode socratique, limites hors-ligne
7. Badges et recompenses - 39 badges, XP, niveaux
8. Communaute ExamBoost - classements, defis, forum
9. Parametres - langue, theme, notifications, accessibilite
10. Conseils pour reussir - regle des 15 min, regularite, etc.
11. FAQ - 8 questions frequentes (data, vieux tel, gratuit, etc.)
12. Support et contact - email, WhatsApp, communautes

### Guide enseignant (8 sections, ~15 pages)

1. Pourquoi ExamBoost en classe ? - constat, cas d'usage, benefices
2. Creer un compte etablissement - inscription B2B, import CSV
3. Module classe temps reel - Kahoot-like, code 6 chiffres, podium
4. Dashboard enseignant - vue agregee, alertes, rapports
5. Integrer ExamBoost dans vos cours - devoirs, simulations, etc.
6. Suivre l'impact - avant/apres, comparaison, temoignages
7. FAQ enseignants - cout, collegues, questions persos, etc.
8. Support et contact - formation 4h/an, webinaires, communaute

---

## Personnalisation

### Remplacer le logo

Le logo ExamBoost est actuellement un dessin vectoriel (toque de
diplome dans un cercle, classe `LogoDrawing` dans `generate_manuals.py`).
Pour le remplacer par le vrai logo officiel :

1. Exportez le logo en PNG transparent (recommande : 600x600 px,
   fond transparent).
2. Dans `generate_manuals.py`, remplacez la classe `LogoDrawing` par
   un `Image('assets/logo_examboost.png', width=110, height=110)` dans
   la fonction `build_cover()`.
3. Regenerer.

### Remplacer les captures d'ecran

Les captures d'ecran sont actuellement des placeholders graphiques
(classe `ScreenshotPlaceholder`). L'equipe design doit :

1. Faire les vraies captures de l'app Flutter (5 ecrans : Accueil,
   Matieres, Revision, Simulation, Dashboard).
2. Exporter en PNG (recommande : 720x1280 px, format portrait mobile).
3. Remplacer les instances de `ScreenshotPlaceholder(label="...")` par
   `Image('assets/screens/accueil.png', width=7.2*cm, height=12.5*cm)`
   dans les fonctions `_student_section_*` et `_teacher_section_*`.
4. Regenerer.

### Ajouter le logo de l'ecole en couverture

Pour les etablissements qui impriment eux-memes, il est possible
d'ajouter leur logo en bas de la couverture :

1. Exportez le logo de l'ecole en PNG (200x200 px).
2. Dans `build_cover()`, ajoutez avant la mention diffusion :

   ```python
   from reportlab.platypus import Image
   flow.append(Spacer(1, 1*cm))
   flow.append(Image('assets/logo_ecole.png', width=60, height=60))
   ```

3. Regenerer.

### Modifier le contenu

Tout le contenu textuel est dans les fonctions `_student_section_*` et
`_teacher_section_*` en haut du fichier `generate_manuals.py`. Les
paragraphes utilisent ReportLab Paragraph avec un mini-subset HTML
(`<b>`, `<i>`, `<font color='...'>`, `<br/>`). Pour modifier :

1. Editez `generate_manuals.py`.
2. Relancez `python3 generate_manuals.py`.
3. Les 2 PDFs sont regeneres en moins de 3 secondes.

---

## Charte graphique

Les 2 PDFs suivent strictement la palette ExamBoost Togo definie dans
le Pitch Deck (juin 2026) :

| Couleur        | Hex       | Usage                              |
|----------------|-----------|------------------------------------|
| Vert Togo      | `#006837` | Primaire - titres, bandeaux, logos |
| Vert fonce     | `#004A26` | Fonds couverture, contrastes       |
| Vert clair     | `#E8F5EE` | Fond encadres Astuce               |
| Orange         | `#D97700` | Accent - chiffres cles, eyebrows   |
| Orange clair   | `#FFF3E0` | Fond encadres Attention            |
| Gris fonce     | `#1A1A1A` | Corps de texte                     |
| Gris clair     | `#F8F9FA` | Fond clair, lignes alternees       |
| Bleu           | `#1565C0` | Encadres Exemple                   |
| Rouge          | `#C62828` | Alertes critiques                  |

**Typographie** : Helvetica (et variantes Bold/Oblique) - police
standard PDF, aucun embed necessaire, garantie d'affichage identique
sur tous les lecteurs PDF.

**Format** : A4 (210 x 297 mm), marges 2,5 cm gauche/droite, 2 cm
haut/bas, pied de page sur toutes les pages interieures avec numero
de page et copyright.

---

## Distribution recommandee (pilote Lome)

Quantite recommandee pour le pilote Lome (juillet 2026 - septembre 2026,
5 etablissements, 300 eleves testeurs) :

| Document             | Quantite | Cout estime (impression N&B A4) |
|----------------------|----------|--------------------------------|
| Manuel eleve         | 500      | ~75 000 FCFA (150 FCFA/ex)     |
| Guide enseignant     | 100      | ~25 000 FCFA (250 FCFA/ex)     |
| Total                | 600      | ~100 000 FCFA                  |

Canaux de distribution :

- **Cyber cafés** de Lome (Adawlatam, Hedzranawoe, Tokoin) - depots
  gratuits, affichage poster
- **Ecoles pilotes** - distribution en main propre par le charge de
  compte B2B
- **Salons education** (Salon de l'Education Togo, Forum EDU Togo) -
  stands ExamBoost
- **Centres de lecture** (Bibliotheque Nationale, mediatheques
  municipales) - exemplaires de consultation
- **WhatsApp** - version PDF compressée partageable via le canal
  officiel @ExamBoostTogo

---

## Maintenance et mise a jour

Les PDFs doivent etre regeneres a chaque nouvelle version d'ExamBoost
Togo (nouvelles fonctionnalites, nouvelle banque de questions, etc.).
Procedure :

1. Mettre a jour le contenu dans `generate_manuals.py` (sections
   concernees).
2. Mettre a jour la ligne `VERSION_LINE` en haut du fichier.
3. Regenerer : `python3 generate_manuals.py`.
4. Verifier visuellement les 2 PDFs.
5. Archiver l'ancienne version dans `output/archive/` (creer le
   dossier si necessaire).
6. Distribuer la nouvelle version aux canaux listes ci-dessus.

Frequence recommandee : 1 mise a jour par trimestre (en phase pilote),
puis 1 mise a jour par semestre (en phase deploiement national).

---

## Chiffres cles references (coherence Pitch Deck + Plan GoToMarket)

Les chiffres utilises dans les 2 PDFs sont coherents avec :

- **Pitch_Deck_10_slides.md** : BEPC 2024 = 44 % (vs 81 % en 2023,
  chute de 37 pts), BAC 2 = 46,71 %, 86 % des enfants de 10 ans ne
  lisent pas couramment, 800 000 eleves secondaire, +15 points
  objectif, <25 Mo APK, Android 5+, 5 etablissements pilote.
- **Plan_GoToMarket.md** : 100 000 FCFA/an licence public, 150 000
  FCFA/an prive, 5 % conversion premium, 2 000 FCFA/mois premium,
  300 eleves testeurs pilote, 50 000 utilisateurs cibles M18.
- **README.md** : 64 questions en V1, 3 000+ questions cible, 3
  algorithmes (SM-2, BKT, IRT 3PL), FastAPI backend, Flutter offline.

---

## Contact

Pour toute question sur le contenu ou la generation de ces PDFs :

- **Equipe ExamBoost Togo** : support@examboost.tg
- **Depot GitHub** : https://github.com/djabelo712/ExamBoost-Togo
- **Dossier source** : `docs/manuals/generate_manuals.py`

---

*Document produit par l'Agent BB (Session 3, Vague 3b) - Juillet 2026.
Projet candidat DJANTA Tech Hub - Idee-Action Challenge 2026.*
