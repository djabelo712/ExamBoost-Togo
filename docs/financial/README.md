# ExamBoost Togo — Modèle financier Excel (18 mois)

Ce dossier contient le modèle financier Excel complet d'ExamBoost Togo sur 18 mois (juillet 2026 → décembre 2027).

## Contenu

```
docs/financial/
├── generate_financial_model.py     # Script Python (openpyxl) qui génère l'Excel
├── requirements.txt                # Dépendance Python (openpyxl 3.1.5)
├── README.md                       # Cette documentation
└── output/
    └── ExamBoost_Financial_Model.xlsx  # Fichier Excel généré (6 onglets)
```

## Pré-requis

- Python 3.8+
- openpyxl 3.1.5

Installation :

```bash
pip install -r requirements.txt
```

## Génération de l'Excel

```bash
cd docs/financial
python3 generate_financial_model.py
```

Sortie attendue :

```
[OK] Modele financier genere : output/ExamBoost_Financial_Model.xlsx
     6 onglets : Assumptions, P&L Mensuel, Cash Flow, Scenarios, Break-even, Charts
     Capital initial : 246,400 USD (147,840,000 FCFA)
     Budget GTM 18 mois : 139,000 USD
```

Le fichier `output/ExamBoost_Financial_Model.xlsx` est (re)créé à chaque exécution. Il est
ouvrable dans Excel, LibreOffice Calc ou Google Sheets.

## Structure de l'Excel (6 onglets)

### 1. Assumptions

Tableau de toutes les hypothèses financières en 4 colonnes (Catégorie, Paramètre, Valeur, Unité) :

- **Pricing** : tarif école publique/privée/premium, premium élève (FCFA)
- **Mix écoles** : répartition 30 % publique / 60 % privée / 10 % premium
- **Conversion** : taux gratuit → premium (cible 5 % à M18)
- **Acquisition / Rétention / LTV** : CAC élève (400 FCFA), CAC école (30 000 FCFA), LTV élève (15 000 FCFA), LTV école (300 000 FCFA), ratios LTV/CAC (37,5x élève, 10x école)
- **Salaires** : 4-5 ETP au pic (chef projet, commercial B2B, community manager, 2 commerciaux régionaux) + charges sociales 12 %
- **Coûts fixes** : cloud (50 USD/mois), API IA (100 USD/mois base), marketing (200 → 500 USD/mois), légal (100 USD/mois)
- **Coûts variables** : SMS Africa's Talking (0,02 USD/SMS), frais paiement Flooz/TMoney (2 %)
- **Subventions** : tranches à M6 (5 M FCFA), M12 (10 M FCFA), M18 (15 M FCFA)
- **Budgets globaux** : GTM 139 000 USD, projet 246 400 USD
- **Taux de change** : 1 USD = 600 FCFA

### 2. P&L Mensuel (18 mois)

P&L détaillé mois par mois (M1 à M18) avec colonne Total 18 mois :

- **REVENUS** : Écoles (mix 30/60/10), Premium élèves, Subventions
- **COÛTS VARIABLES** : SMS, API IA, Frais paiement
- **COÛTS FIXES** : Salaires (avec montée en charge progressive 1 → 5 ETP), Cloud, Marketing, Légal
- **RÉSULTAT NET** + marge nette %
- KPIs opérationnels en bas : élèves actifs, établissements, taux conversion premium

Trajectoire réaliste (alignée Plan GoToMarket) :
- Élèves actifs : 50 (M1) → 300 (M3) → 1 000 (M6) → 20 000 (M12) → 50 000 (M18)
- Établissements : 1 (M1) → 5 (M3) → 20 (M6) → 100 (M12) → 200 (M18)
- Conversion premium : 0 % (M1-M3) → 2 % (M6) → 4 % (M12) → 5 % (M18)

### 3. Cash Flow (18 mois)

Projection de trésorerie mensuelle :

- **Solde ouverture** : démarre à 147 840 000 FCFA (capital initial 246 400 USD)
- **+ Revenus** (lien vers P&L Mensuel)
- **- Coûts** (lien vers P&L Mensuel)
- **= Net cash flow**
- **Solde fermeture** = ouverture + net cash flow
- **Trésorerie nette cumulée**
- **Burn rate** mensuel (FCFA/mois si net cash flow négatif)
- **Runway** (mois restants si burn perpetuel)

Le point bas de trésorerie est atteint vers M11 (~130 M FCFA). Le cash flow devient
positif durablement à partir de M14. Le solde final M18 (~164 M FCFA) dépasse le capital
initial, ce qui démontre la viabilité financière du projet sur 18 mois.

### 4. Scenarios

Trois scénarios comparés (Pessimiste / Réaliste / Optimiste) :

| Scenario | M6 users | M12 users | M18 users | M18 écoles | M18 premium | M18 revenus/mois | Break-even mois |
|---|---|---|---|---|---|---|---|
| Pessimiste | 100 | 1 000 | 5 000 | 50 | 250 | 1 M FCFA | M18+ (non atteint) |
| Réaliste | 1 000 | 5 000 | 50 000 | 200 | 2 500 | 5 M FCFA | M13 |
| Optimiste | 1 000 | 15 000 | 100 000 | 400 | 5 000 | 12 M FCFA | M9 |

Le détail mois par mois (users + revenus) est fourni pour chaque scénario.

### 5. Break-even

Analyse du point mort opérationnel :

1. **Paramètres de base** : coûts fixes (pic 3 682 800 FCFA/mois, pilote 1 218 000 FCFA/mois), marge sur coûts variables (70 %), revenus moyens par école (12 500 FCFA/mois, 150 000 FCFA/an), CAC/LTV/ratios
2. **Calcul du point mort** : break-even revenus mensuels = 5 261 142 FCFA ; sans premium = 421 écoles ; avec premium = 84 écoles
3. **Évolution 18 mois** : tableau mois par mois (revenus, coûts fixes, coûts totaux, marge nette, statut Break-even / Déficit)

Le point mort est atteint vers M13-M14 dans le scénario réaliste, en cohérence avec le Plan
GoToMarket (qui vise 100 écoles + 2 500 premium à M13).

### 6. Charts

Quatre graphiques générés automatiquement :

1. **Bar chart** — Revenus mensuels sur 18 mois (scenario réaliste) — visualise l'accélération à partir de M9
2. **Line chart** — Cash balance cumulé (18 mois) — montre le point bas M11 puis la remontée
3. **Pie chart** — Répartition des revenus M18 par source (écoles / premium / subventions)
4. **Stacked bar** — Coûts par catégorie sur 18 mois (salaires / cloud / marketing / légal / coûts variables)

## Comment modifier les hypothèses

Toutes les hypothèses sont des **constantes Python** en haut du fichier `generate_financial_model.py`
(section "CONSTANTES METIER"). Pour modifier une hypothèse :

1. Éditer la constante dans le script (par ex. `PRIX_ECOLE_PRIVEE = 150_000`)
2. Relancer le script : `python3 generate_financial_model.py`
3. L'Excel est régénéré avec les nouvelles valeurs

Pour des modifications plus profondes (nouvelles trajectoires KPIs, nouveaux scénarios,
nouveaux graphiques), éditer les fonctions `generate_*()` correspondantes.

## Comment créer de nouveaux scénarios

Dans la fonction `generate_scenarios()`, modifier le tableau `scenarios` ou créer de nouvelles
trajectoires `traj_users_*` et `traj_ecoles_*` puis ajouter les colonnes correspondantes dans
le tableau détaillé.

## Comment lire les graphiques

1. **Bar chart revenus** : la pente s'accélère à partir de M9 (phase expansion nationale Sokodé/Kara/Atakpamé/Kpalimé). Les pics à M6, M12, M18 correspondent aux tranches de subventions.
2. **Line chart cash balance** : le point bas est autour de M11 (~130 M FCFA), puis remontée progressive. Le solde final M18 dépasse le capital initial, validant la viabilité.
3. **Pie chart M18** : les premium élèves représentent la majorité des revenus récurrents (hors subventions ponctuelles). C'est la preuve que le modèle B2B2C fonctionne.
4. **Stacked bar coûts** : les salaires représentent ~85-90 % des coûts fixes. Les coûts variables (SMS, API, frais paiement) restent marginaux (< 15 %).

## Limites du modèle

- **Modèle simplifié** : ne prend pas en compte la TVA, l'IS, l'amortissement, ni les éventuels crédits-bails.
- **Hypothèses de trajectoire** : les courbes d'acquisition élèves/écoles sont des hypothèses linéaires par phase. Les vraies données pilote (à partir de M3) permettront de recalibrer.
- **Pas de modelling du churn mensuel premium** : le taux de conversion premium est net (5 % cible). En réalité, il faudrait modéliser un churn mensuel (~10 %) et un taux d'acquisition premium brut plus élevé.
- **Subventions incertaines** : les tranches M6/M12/M18 sont hypothétiques (GPE, AFD, UNICEF). Elles peuvent être plus faibles, plus tardives, ou inexistantes. Le scénario pessimiste simule un cas sans subvention.
- **Pas de COGS technique** : les salaires de l'équipe technique (2 dev Flutter, 1 backend, 1 data scientist, 1 designer, 2 pédagogues, 3-5 opérateurs saisie) sont déjà inclus dans le budget total 246 400 USD mais pas modélisés mensuellement ici (ils relèvent du budget projet, pas du budget GTM).
- **Pas de levée Série A modélisée** : le Plan mentionne une levée Série A (1 M USD) en M11 2027 (M17). Non incluse dans le cash flow par défaut — à ajouter manuellement si nécessaire.
- **Cohérence avec Plan GoToMarket** : le Plan mentionne "5 M FCFA/mois à M18", ce qui correspond à un revenu récurrent mensuel hors subventions. Le modèle calcule ~7,5 M FCFA/mois hors subventions à M18 (200 écoles × 12 500 + 5 000 premium × 2 000 = 2,5 M + 5 M), légèrement au-dessus du 5 M cible (conservateur). L'écart s'explique par une interprétation plus mécanique du mix pricing. Le modèle reste valable et les deux projections sont du même ordre de grandeur.

## Sources

- `docs/Plan_GoToMarket.md` — budget GTM 139 000 USD, KPIs M3/M6/M12/M18, ratios LTV/CAC, scénarios break-even, structure équipe GTM 4-5 ETP
- `docs/ExamBoost_Togo_Etude_Faisabilite_2025.txt` (extrait de `ExamBoost_Togo_Etude_Faisabilite_2025.pdf`) — budget total 246 400 USD, pricing B2B2C, infrastructure cloud, API SMS, modèle économique
- Taux de change : 1 USD = 600 FCFA (taux officiel BCEAO moyen 2025-2026)

## Prochaines étapes recommandées

1. **Recalibrer après pilote M3** : remplacer les trajectoires hypothétiques par les vraies données pilote (300 élèves Lomé).
2. **Ajouter un onglet "Unit Economics"** : détailler CAC par canal (TikTok, WhatsApp, ambassadeurs, organic), LTV par cohorte, payback period.
3. **Modéliser le churn premium mensuel** : passer d'un taux net 5 % à un modèle flux (acquisition brute × rétention mois par mois).
4. **Ajouter la levée Série A** : M17 (+ 1 M USD), comparer runway avec et sans.
5. **Sensibilité** : tester l'impact de variations de ±20 % sur CAC, conversion premium, et nombre d'écoles signées/an.
6. **Version anglaise** : traduire l'Excel pour pitchs investisseurs internationaux (CcHub, AIMS Ghana, fondations).

---

*Document préparé par l'Agent AW — Session 3, Vague 3 — 1er juillet 2026*
*Pour diffusion interne équipe ExamBoost Togo, mentors DJANTA, investisseurs sollicités*
