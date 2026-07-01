# Enquete Terrain — ExamBoost Togo

> Dossier complet pour mener et analyser l'enquete terrain aupres de 30 eleves BEPC/BAC a Lome.
> Exigence : preuve de traction pour le pitch DJANTA Tech Hub (24 juillet 2026).

---

## 1. Contexte

ExamBoost Togo est candidate au programme **DJANTA Tech Hub — Idée-Action** (pitch le 24 juillet 2026 a Lome). Pour passer le cap de la selection, le jury exige une **preuve de traction** : il faut demontrer que le probleme est reel et que les eleves sont prets a utiliser la solution.

L'enquete aupres de **30 eleves de Lome** (15 BEPC + 15 BAC) fournit :
- Des donnees quantitatives (% d'interet, % sans outil adequat, NPS)
- Des citations qualitatives pour le pitch deck (slide 8 — Traction)
- Une base de contacts pour le programme beta-testeur (septembre 2026)

> Reference : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf` — Section S2.3 « Realiser l'enquete terrain ».

---

## 2. Structure du dossier

```
docs/Enquete_Terrain/
├── README.md                       # Ce fichier — guide complet
├── Questionnaire_Eleve.md          # Questionnaire 30 questions en 5 sections
├── Google_Forms_Structure.md       # Structure a recreer dans Google Forms
├── Guide_Administrateur.md         # Guide pour mener l'enquete (formation enqueteurs)
├── Consentement_Eleve.md           # Formulaire de consentement eclaire
├── Plan_Echantillonnage.md         # Plan d'echantillonnage (30 eleves)
├── analyse/
│   ├── analyse_enquete.py          # Script Python d'analyse (6 graphiques + 3 KPIs)
│   ├── requirements.txt            # Dependances (pandas, matplotlib, scipy, jinja2)
│   └── template_results.csv        # Template CSV pour saisie des reponses
└── Rapport_Modele.md               # Modele de rapport final a remplir apres enquete
```

---

## 3. Workflow en 5 etapes

### Etape 1 — Preparation (avant l'enquete, ~1 jour)

1. Lire integralement `Guide_Administrateur.md` (formation enqueteurs).
2. Recreer le formulaire dans Google Forms en suivant `Google_Forms_Structure.md`.
3. Imprimer 10 copies de `Questionnaire_Eleve.md` (backup papier).
4. Imprimer 10 copies de `Consentement_Eleve.md`.
5. Pre-charger 30 credits data de 200 FCFA (Moov / Togocom) pour compensation.
6. Verifier le plan d'echantillonnage dans `Plan_Echantillonnage.md`.

### Etape 2 — Collecte terrain (5 jours)

- 6 eleves / jour / enqueteur (total 30 en 5 jours).
- Quartiers : Tokoin, Lome centre, Be, Adidogome, Aflao.
- Format : Google Forms live si reseau OK, sinon papier + saisie le soir.
- Compensation : 200 FCFA de credit data par eleve apres completion.

### Etape 3 — Saisie et validation (en continu)

- Verifier chaque soir que les reponses sont dans Google Sheets.
- Exporter en CSV quotidien : `enquete_examboost_lome_jourN.csv`.
- En fin de semaine : fusionner en `enquete_examboost_lome_2026-06.csv`.

### Etape 4 — Analyse automatique (~30 min)

```bash
cd /home/z/my-project/ExamBoost-Togo/docs/Enquete_Terrain/analyse/

# Installer les dependances (Python 3.11+)
pip install -r requirements.txt

# Lancer l'analyse
python analyse_enquete.py enquete_examboost_lome_2026-06.csv --output-dir ./output

# Resultats :
# - output/figures/*.png (6 graphiques)
# - output/kpis.json (3 KPIs)
# - output/stats.json (statistiques completes)
# - output/rapport_auto.md (rapport markdown automatique)
```

### Etape 5 — Redaction du rapport final (~2h)

1. Ouvrir `Rapport_Modele.md`.
2. Remplir les `[PLACEHOLDER]` avec les resultats du rapport automatique.
3. Inserer les citations qualitatives selectionnees (3-5 max pour le pitch).
4. Faire valider par l'equipe avant presentation au jury DJANTA.

---

## 4. KPIs cibles (pitch DJANTA)

| KPI | Cible | Source question |
|---|---|---|
| % eleves sans outil numerique adapte | > 80% | B2 + B6 |
| % prets a utiliser ExamBoost | > 85% | D3 + D5 |
| NPS moyen (recommandation) | > 7/10 | D7 |

Si au moins 2 KPIs sur 3 sont atteints, la preuve de traction est consideree comme solide.

> Reference : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf` — Slide 8 « La Traction et la Validation ».

---

## 5. Questionnaire — 30 questions en 5 sections

| Section | Theme | Questions | Duree |
|---|---|---|---|
| A | Identification (anonyme) | 5 (A1-A5) | 1 min |
| B | Habitudes de revision | 8 (B1-B8) | 3 min |
| C | Douleurs et besoins | 7 (C1-C7) | 3 min |
| D | Reaction au concept ExamBoost | 7 (D1-D7) | 3 min |
| E | Feedback ouvert | 3 (E1-E3) | 2 min |
| **Total** | | **30** | **12 min** |

Detail integral : `Questionnaire_Eleve.md`.

---

## 6. Budget

| Poste | Quantite | Unite | Total |
|---|---|---|---|
| Credit data (compensation eleves) | 30 | 200 FCFA | 6 000 FCFA |
| Forfait data enqueteurs (5 jours) | 2 | 1 000 FCFA | 2 000 FCFA |
| Impressions (questionnaire + consentement) | 20 | 50 FCFA | 1 000 FCFA |
| Transport enqueteurs (5 jours × 2) | 10 | 500 FCFA | 5 000 FCFA |
| **Total** | | | **14 000 FCFA** (≈ 23 USD) |

Source de financement : budget « Enquetes terrain » de l'Etude de Faisabilite 2025 (5 000 USD prevus pour M1).

---

## 7. Calendrier indicatif

| Date | Action |
|---|---|
| Lundi 2 juin 2026 | Brief equipe + creation Google Forms |
| Mardi 3 juin 2026 | Pre-test du formulaire (3 eleves pilotes) |
| Lundi 9 juin 2026 | Jour 1 — Tokoin (6 eleves) |
| Mardi 10 juin 2026 | Jour 2 — Lome centre (6 eleves) |
| Mercredi 11 juin 2026 | Jour 3 — Be (6 eleves) |
| Jeudi 12 juin 2026 | Jour 4 — Adidogome (6 eleves) |
| Vendredi 13 juin 2026 | Jour 5 — Aflao (6 eleves) |
| Samedi 14 juin 2026 | Buffer (si besoin) |
| Lundi 16 juin 2026 | Lancement analyse automatique + rapport |
| Mercredi 18 juin 2026 | Rapport final valide par l'equipe |
| Vendredi 19 juin 2026 | Integration des insights dans le pitch deck |
| Jeudi 24 juillet 2026 | Pitch DJANTA Tech Hub |

---

## 8. Roles et responsabilites

| Role | Responsable | Taches |
|---|---|---|
| Chef de projet | [A COMPLETER] | Coordination, validation finale, integration pitch |
| Enqueteur principal | [A COMPLETER] | Collecte terrain jours 1-5, saisie quotidienne |
| Enqueteur backup | [A COMPLETER] | Support terrain, gestion des refus, backup papier |
| Analyste donnees | Agent N / [A COMPLETER] | Lancement script Python, remplissage rapport |
| Contact ecoles | [A COMPLETER] | Autorisations lycees, contacts directeurs |

---

## 9. Risques et mitigations

| Risque | Probabilite | Impact | Mitigation |
|---|---|---|---|
| Refus massif des eleves | Moyenne | Eleve | Compensation 200 FCFA + cybercafes en backup |
| Coupure reseau Google Forms | Eleve | Moyen | Backup papier (Option B) |
| Pluie pendant la semaine | Moyenne | Moyen | 2 jours buffer (14 + 16 juin) |
| Moins de 30 reponses | Faible | Eleve | Prolongation 1 journee |
| Biais de selection | Eleve | Faible | Diversification lieux (lycees + cybercafes + arrets bus) |
| Donnees incoherentes | Faible | Faible | Verification quotidienne Google Sheets |

---

## 10. Contact

- Email equipe : examboost.togo@gmail.com
- WhatsApp responsable enquete : +228 90 00 00 00
- Canal Slack/Discord : #enquete-terrain
- Repo GitHub : https://github.com/djabelo712/ExamBoost-Togo

---

## 11. Liens utiles

- Etude de faisabilite : `docs/ExamBoost_Togo_Etude_Faisabilite_2025.pdf`
- Plan strategique DJANTA : `docs/ExamBoost_DJANTA_Plan_Strategique_2026.pdf`
- Pitch deck 10 slides : `docs/Pitch_Deck_10_slides.md`
- Q&A jury anticipe : `docs/QA_jury_anticipe.md`

---

*Document version 1.0 — Juin 2026 — Equipe ExamBoost Togo*
