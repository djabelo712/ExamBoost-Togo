# ExamBoost Togo — One Pager

*Fiche A4 récapitulative — Juillet 2026 — v1.0*

---

## En 30 secondes

ExamBoost Togo est une application mobile de préparation intelligente aux examens nationaux togolais (BEPC, BAC). Gratuit pour les élèves, monétisée via les établissements (B2B2C). Algorithme adaptatif IRT 3PL + BKT + SM-2, prédiction score XGBoost. Mode hors-ligne complet. Objectif : 50 000 utilisateurs actifs à 18 mois, break-even à M13.

## Le problème

- BEPC 2024 : 44 % de réussite (vs 81 % en 2023, soit −37 points en un an)
- BAC 2 2024 (série D) : 46,71 %
- 86 % des enfants togolais de 10 ans analphabètes fonctionnels (Banque Mondiale — learning poverty)
- 0 outil numérique aligné sur le programme officiel MEPST
- Cours particuliers à 5 000–20 000 FCFA/mois inaccessibles à 95 % des familles

## La solution

Application Flutter (Android 5+, APK < 25 Mo, offline-first) qui combine quatre briques algorithmiques :

- Répétition espacée — SM-2 (rappels au moment optimal)
- Calibration adaptative — IRT 3PL (difficulté question par élève)
- Suivi de maîtrise — BKT (probabilité de compétence acquise)
- Prédiction score — XGBoost (estimation BEPC/BAC ± 5 %)
- Banque 5 000+ questions BEPC/BAC (objectif M9 via pipeline OCR)

## Marché

- Togo : 150 000 candidats BEPC + BAC par an (SAM), 1,36 M élèves secondaire (TAM)
- CEDEAO francophone : 3 M élèves (Bénin, Côte d'Ivoire, Burkina Faso — même tronc BEPC/BAC)
- Objectif M18 : 50 000 utilisateurs actifs, 200 établissements partenaires, 5 000 élèves premium

## Modèle économique

| Segment | Tarif | Cible M18 |
|---|---|---|
| Élève | Gratuit (pour toujours) | 50 000 actifs |
| Élève premium (5 %) | 2 000 FCFA/mois | 5 000 premium |
| Établissement public | 100 000 FCFA/an | 80 écoles |
| Établissement privé | 150 000 FCFA/an | 100 écoles |
| Établissement premium | 300 000 FCFA/an | 20 écoles |
| Subventions (GPE, UNICEF, AFD) | 100–500 k USD/projet | 1 à 2 subventions/an |

Break-even GTM atteint à M13 (100 écoles + 5 000 premium). LTV/CAC : 37× élève premium, 10× établissement.

## Traction

- MVP Flutter fonctionnel (5 écrans : onboarding, révision flashcard animée, simulation chronométrée, dashboard, tuteur IA)
- Backend FastAPI déployé (Railway) — endpoints /predict, /sessions, /sync opérationnels
- 3 algorithmes ML implémentés et testés (SM-2, BKT, IRT 3PL)
- 64 questions structurées JSON, calibration IRT démarrée
- Pipeline OCR Python (Tesseract + GPT-4o Vision, 5 sources, validation jsonschema)
- 111 tests automatisés, 4 contributeurs GitHub actifs
- Pré-sélection DJANTA Tech Hub 2026 — programme Idée-Action — pitch le 24 juillet 2026
- 5 écoles pilotes en négociation à Lomé, enquête terrain 30 élèves (NPS 8,5/10)
- GitHub public : github.com/djabelo712/ExamBoost-Togo

## Équipe

4 profils complémentaires : Chef projet & Lead Tech (AIMS Ghana), Data Scientist ML/OCR (AIMS Ghana), Designer UX (accessibilité élève togolais), Growth & Partenariats (FEDER, MEPST).

Soutien écosystème : AIMS Ghana (validation scientifique IRT/BKT), CcHub Lomé (mentorat investisseurs), SmartFarm Togo (ancrage local). 3 mentors individuels (EdTech Nigeria, chercheur AIMS, directeur de lycée Lomé).

## Ask

Pré-incubation DJANTA Tech Hub (3 mois, juillet–septembre 2026) → validation pilote 5 écoles Lomé → levée Série A 250 000 USD pour runway 18 mois et déploiement phases 2-4 (Lomé → national → CEDEAO).

## Contact

- Email : contact@examboost.togo
- GitHub : github.com/djabelo712/ExamBoost-Togo
- Site : examboost-togo.vercel.app
- Lomé, Togo

---

*Document de production — diffusion investisseurs, mentors DJANTA, partenaires institutionnels.*
*Juillet 2026 — v1.0*
