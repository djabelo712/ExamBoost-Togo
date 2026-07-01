# Rapport d'Enquete Terrain ExamBoost Togo — Juin 2026

> **Modele a remplir** apres collecte des 30 reponses d'enquete.
> Les sections `[PLACEHOLDER: ...]` doivent etre completees manuellement ou remplacees par le contenu du rapport automatique (`analyse_enquete.py`).
> Source de donnees : `analyse/enquete_examboost_lome_2026-06.csv`.

---

## Informations generales

| Champ | Valeur |
|---|---|
| Titre | Rapport d'Enquete Terrain ExamBoost Togo |
| Periode d'enquete | 9 au 13 juin 2026 |
| Lieu | Lome, Togo (5 quartiers : Tokoin, Lome centre, Be, Adidogome, Aflao) |
| Echantillon | 30 eleves (15 BEPC + 15 BAC) |
| Methode | Questionnaire structure 30 questions, administration face-a-face + Google Forms |
| Equipe enquete | [A COMPLETER] |
| Date du rapport | [A COMPLETER] |
| Auteur du rapport | Agent N — ExamBoost Togo |
| Commanditaire | DJANTA Tech Hub (programme Idée-Action) |

---

## Sommaire

1. Resume executif
2. Methodologie
3. Echantillon
4. Resultats clés — Habitudes de révision
5. Resultats clés — Douleurs et besoins
6. Resultats clés — Réaction au concept ExamBoost
7. Insights pour le pitch
8. Recommandations produit
9. Limites methodologiques
10. Conclusion
11. Annexes

---

## 1. Resume executif

[A COMPLETER apres analyse automatique — cf. `analyse_enquete.py`]

> Exemple de structure :
>
> - **Echantillon** : 30 eleves (15 BEPC + 15 BAC) interroges dans 5 quartiers de Lome sur 5 jours.
> - **KPI 1** : [X]% des eleves interroges n'ont pas d'outil numerique adapte pour reviser (cible > 80%).
> - **KPI 2** : [X]% sont prets a utiliser ExamBoost si l'application est gratuite (cible > 85%).
> - **KPI 3** : NPS moyen de [X]/10 (cible > 7).
> - **Conclusion** : [1-2 phrases sur la validation ou non de la traction pour le pitch DJANTA].

Insight principal pour le pitch :
> « Nous avons interrogé 30 élèves de Lomé : [X] % disent n'avoir aucun outil numérique de préparation aux examens. [Y] % seraient prêts à utiliser ExamBoost. Le directeur du Lycée [NOM] a déjà exprimé son intérêt pour un pilote. »

---

## 2. Methodologie

### 2.1 Conception du questionnaire

Le questionnaire de 30 questions est structure en 5 sections (A — Identification, B — Habitudes de revision, C — Douleurs et besoins, D — Reaction au concept ExamBoost, E — Feedback ouvert). Cf. `Questionnaire_Eleve.md` pour le detail integral.

### 2.2 Mode de collecte

- **Format principal** : Google Forms en ligne (anonyme, pas de collecte d'email).
- **Format backup** : questionnaire papier en cas de coupure reseau.
- **Compensation** : 200 FCFA de credit data vereses a chaque eleve apres completion.
- **Langue** : Francais.

### 2.3 Procedure terrain

- 2 enqueteurs formes selon `Guide_Administrateur.md`.
- Consentement eclaire signe avant chaque interview (cf. `Consentement_Eleve.md`).
- Duree moyenne par interview : [X] minutes (cible 10-15).
- 5 jours de collecte, 6 eleves / jour.

### 2.4 Traitement et analyse

- Saisie dans Google Sheets (collecte automatique).
- Export CSV : `analyse/enquete_examboost_lome_2026-06.csv`.
- Analyse automatique : `python analyse_enquete.py enquete_examboost_lome_2026-06.csv`.
- Generation de 6 graphiques + 3 KPIs + rapport markdown automatique.

### 2.5 Cadre ethique

- Anonymat integral (pas de nom, pas d'email obligatoire).
- Droit de retrait a tout moment.
- Conservation des donnees brutes : 5 ans sur disque chiffre.
- Aucune vente de donnees a un tiers.

---

## 3. Echantillon

### 3.1 Composition finale

| Critere | Cible | Realise | Ecart |
|---|---|---|---|
| Total eleves | 30 | [X] | [+] |
| BEPC (3e) | 15 | [X] | [+] |
| BAC (1ere + Terminale) | 15 | [X] | [+] |
| Filles | 15 | [X] | [+] |
| Garcons | 15 | [X] | [+] |
| Public | 10 | [X] | [+] |
| Prive confessionnel | 9 | [X] | [+] |
| Prive laic | 6 | [X] | [+] |
| Autre | 5 | [X] | [+] |

### 3.2 Repartition par quartier

| Quartier | Effectif cible | Effectif realise |
|---|---|---|
| Tokoin | 6 | [X] |
| Lome centre | 6 | [X] |
| Be | 6 | [X] |
| Adidogome | 6 | [X] |
| Aflao | 6 | [X] |

### 3.3 Repartition par tranche d'age

| Age | Effectif |
|---|---|
| 14 ans ou moins | [X] |
| 15-16 ans | [X] |
| 17-18 ans | [X] |
| 19-20 ans | [X] |
| 21 ans ou plus | [X] |

### 3.4 Taux de refus

- Total approches : [X] eleves
- Refus : [X] eleves
- Taux de refus : [X]%
- Principales raisons de refus : [A COMPLETER]

---

## 4. Resultats cles — Habitudes de revision

> Cette section reprend les graphiques 1, 2, 3 generes par `analyse_enquete.py`.

### 4.1 Outils de revision utilises (B2)

![Outils de revision](analyse/output/figures/01_outils_revision.png)

[PLACEHOLDER: commentaire automatique du graphique]
Exemple : « Les cahiers de cours restent l'outil le plus repandu (X%), suivis des manuels scolaires (Y%). Seuls Z% des eleves utilisent une application mobile dediee. »

### 4.2 Acces au smartphone (B3)

![Smartphone](analyse/output/figures/02_smartphone.png)

[PLACEHOLDER: commentaire]
Exemple : « X% des eleves ont un smartphone personnel, Y% partagent celui de la famille. Seuls Z% n'ont aucun smartphone. »

### 4.3 Heures de revision par semaine (B1)

![Heures de revision](analyse/output/figures/03_heures_revision.png)

[PLACEHOLDER: commentaire]
Exemple : « La mediane est de X heures/semaine. Y% des eleves revisent moins de 10 heures par semaine. »

### 4.4 Acces Internet (B5)

| Type d'acces | Effectif | % |
|---|---|---|
| Wifi maison | [X] | [X]% |
| Forfait data mobile | [X] | [X]% |
| Cybercafe | [X] | [X]% |
| Ecole uniquement | [X] | [X]% |
| Pas d'acces regulier | [X] | [X]% |

### 4.5 Frequence revision numerique (B6)

| Frequence | Effectif | % |
|---|---|---|
| Jamais | [X] | [X]% |
| 1-2 fois/semaine | [X] | [X]% |
| 3-4 fois/semaine | [X] | [X]% |
| 5+ fois/semaine | [X] | [X]% |

---

## 5. Resultats cles — Douleurs et besoins

> Cette section reprend les graphiques 4 et 5 generes par `analyse_enquete.py`.

### 5.1 Satisfaction des methodes actuelles (C1)

![Satisfaction Likert](analyse/output/figures/05_satisfaction_likert.png)

- Moyenne : [X]/5
- Mediane : [X]/5
- % d'eleves insatisfaits (note ≤ 2) : [X]%

[PLACEHOLDER: commentaire]
Exemple : « X% des eleves sont peu ou pas satisfaits de leurs methodes actuelles. Le besoin d'une meilleure solution est confirme. »

### 5.2 Matieres les plus difficiles (B7)

![Matieres difficiles](analyse/output/figures/04_matieres_difficiles.png)

[PLACEHOLDER: commentaire]
Exemple : « Les mathematiques sont perçues comme la matiere la plus difficile (X%), suivies des sciences physiques (Y%). ExamBoost devra prioriser ces matieres dans sa version 1.0. »

### 5.3 Raisons pour lesquelles les eleves ne font pas de simulations (C5)

| Raison | Effectif | % |
|---|---|---|
| Pas de sujets des annees precedentes | [X] | [X]% |
| Pas le temps | [X] | [X]% |
| Pas motive | [X] | [X]% |
| Ne sait pas comment | [X] | [X]% |
| Fait deja des simulations | [X] | [X]% |

### 5.4 Connaissance du niveau (C6)

| Reponse | Effectif | % |
|---|---|---|
| Oui, niveau precis | [X] | [X]% |
| Non, aucune idee | [X] | [X]% |
| Approximativement | [X] | [X]% |

> Insight : « Seuls [X]% des eleves connaissent leur niveau precis dans chaque matiere. La fonctionnalite de prediction de score d'ExamBoost repond directement a ce manque. »

### 5.5 Ce qui manque le plus (C2 — citations)

> [PLACEHOLDER: 3-5 citations marquees extraites des reponses ouvertes]
>
> - « ... »
> - « ... »
> - « ... »

---

## 6. Resultats cles — Reaction au concept ExamBoost

> Cette section reprend le graphique 6 genere par `analyse_enquete.py`.

### 6.1 Utilite perçue du concept (D1)

- Moyenne : [X]/5
- % d'eleves trouvant le concept utile (note ≥ 4) : [X]%

### 6.2 Fonctionnalites les plus attendues (D2)

![Fonctionnalites interet](analyse/output/figures/06_fonctionnalites_interet.png)

| Fonctionnalite | Effectif | % |
|---|---|---|
| Flashcards adaptatives | [X] | [X]% |
| Simulations chronometrees | [X] | [X]% |
| Prediction du score | [X] | [X]% |
| Classement ecole | [X] | [X]% |
| Mode hors-ligne | [X] | [X]% |
| Notifications | [X] | [X]% |

### 6.3 Intention de telechargement (D3)

| Reponse | Effectif | % |
|---|---|---|
| Oui | [X] | [X]% |
| Non | [X] | [X]% |
| Peut-etre | [X] | [X]% |

### 6.4 Valeur estimee par mois (D4)

| Valeur (FCFA) | Effectif | % |
|---|---|---|
| 0 (gratuit uniquement) | [X] | [X]% |
| 500 | [X] | [X]% |
| 1000 | [X] | [X]% |
| 2000 | [X] | [X]% |
| 5000+ | [X] | [X]% |

> Insight : « La valeur mediane acceptee est de [X] FCFA/mois. Le modele freemium (gratuit + premium ecole) est confirme. »

### 6.5 Interet pour un acces premium via l'ecole (D5)

| Reponse | Effectif | % |
|---|---|---|
| Oui | [X] | [X]% |
| Non | [X] | [X]% |

### 6.6 Freins a l'utilisation (D6)

| Frein | Effectif | % |
|---|---|---|
| Espace stockage | [X] | [X]% |
| Forfait data | [X] | [X]% |
| Pas le temps | [X] | [X]% |
| Pas de smartphone | [X] | [X]% |
| Pas confiance | [X] | [X]% |

### 6.7 NPS — Recommandation a un ami (D7)

- NPS moyen : [X]/10
- % de promoteurs (note 9-10) : [X]%
- % de detracteurs (note 1-6) : [X]%

---

## 7. KPIs cles pour le pitch DJANTA

| KPI | Cible | Resultat | Statut |
|---|---|---|---|
| % eleves sans outil numerique adapte | > 80% | [X]% | [ATTEINT / MANQUE] |
| % prets a utiliser ExamBoost | > 85% | [X]% | [ATTEINT / MANQUE] |
| NPS moyen | > 7/10 | [X] | [ATTEINT / MANQUE] |

Source : `analyse/output/kpis.json`

---

## 8. Insights pour le pitch

> [PLACEHOLDER: 5-7 insights synthetiques a integrer dans le pitch deck (slide 8 — Traction)]

1. **Probleme valide** : [X]% des eleves de Lome n'ont pas d'outil numerique adapte pour reviser.
2. **Demande forte** : [X]% sont prets a telecharger ExamBoost gratuitement.
3. **NPS eleve** : [X]/10 en moyenne, signe d'une recommandation probable.
4. **Fonctionnalite phare** : [TOP 1 fonctionnalite] demandee par [X]% des eleves.
5. **Modele economique** : freemium + B2B ecoles valide par [X]% d'interet pour l'acces premium via l'ecole.
6. **Marche prioritaires** : Maths et Sciences physiques en tete des difficultes — a integrer en premier dans le contenu.
7. **Beta-testeurs** : [X] eleves ont laisse leur contact pour le programme beta de septembre 2026.

### Citations pour le pitch (anonymisees)

> [PLACEHOLDER: 2-3 citations marquantes extraites de E2 (anecdotes)]
>
> - « ... » — Eleve en 3e, Tokoin
> - « ... » — Eleve en Terminale D, Be

---

## 9. Recommandations produit

### 9.1 Fonctionnalites a prioriser pour le MVP

1. **Mode hors-ligne** : critique au Togo ou le forfait data est couteux et instable.
2. **Simulations chronometrees** : fonctionnalite la plus demandee ([X]%).
3. **Sujets des annees precedentes** : manque identifie par [X]% des eleves (C5).
4. **Prediction visuelle du score** : repond a [X]% des eleves ne connaissant pas leur niveau.

### 9.2 Matieres a integrer en priorite

1. Mathematiques
2. Sciences physiques
3. SVT
4. Anglais

### 9.3 Strategie commerciale

- **Version gratuite** : flashcards + 10 simulations / mois.
- **Version premium eleve** : 500 FCFA / mois (illimite + prediction score).
- **Version B2B ecole** : 50 000 FCFA / trimestre / etablissement (acces premium pour tous les eleves + dashboard directeur).

### 9.4 Communication

- Cibler les lycées de Tokoin, Be, Adidogome en priorite (meilleur taux de penetration).
- Partenariats avec 1-2 directeurs de lycée expresses interesse lors de l'enquete.
- Campagne WhatsApp dans les groupes de classe (meme moyen de communication que les PDF actuels).

### 9.5 Beta-testeurs

- [X] eleves ont laisse leur contact (E3).
- Lancer le programme beta-testeur debut septembre 2026.
- Objectif : 30 beta-testeurs actifs sur 2 mois (septembre-octobre 2026).

---

## 10. Limites methodologiques

1. **Taille d'echantillon reduite** : 30 eleves, marge d'erreur de ±18% (IC 95%). Suffisant pour une preuve de traction, insuffisant pour une etude quantitative robuste.
2. **Couverture geographique limitee** : Lome seulement. Les villes secondaires (Kpalime, Atakpame, Sokode, Kara) ne sont pas representees.
3. **Biais de selection** : les eleves qui acceptent l'enquete sont probablement plus motives que la moyenne.
4. **Biais de desirabilite** : la presence de l'enqueteur peut influencer les reponses (notamment D1-D7).
5. **Absence de parite genre garantie** : la variable genre n'est pas collectee dans le questionnaire (parite suivie via le rapport quotidien des enqueteurs).
6. **Compensation** : 200 FCFA peut creer un biais d'interet en faveur de l'enquete.
7. **Periode** : juin 2026, en pleine revision pour le BAC. Les eleves peuvent etre plus sensibles au sujet.

> Une enquete plus large (200 eleves, 5 villes) est prevue en M1 du projet (cf. Etude de Faisabilite 2025).

---

## 11. Conclusion

[PLACEHOLDER: 2-3 paragraphes de conclusion synthetique]

Exemple de structure :
>
> L'enquete terrain menee aupres de 30 eleves de Lome confirme l'existence d'un besoin reel pour une solution numerique dediee a la preparation des examens nationaux togolais. Les trois KPIs cibles pour le pitch DJANTA Tech Hub sont [atteints / partiellement atteints], avec notamment [X]% d'eleves sans outil adequat et [X]% prets a utiliser ExamBoost.
>
> Les citations qualitatives recueillies aupres des eleves renforcent le narratif : « ... ». La fonctionnalite [TOP 1] arrive en tete des attentes, et [X] eleves ont deja laisse leur contact pour devenir beta-testeurs.
>
> Ces resultats, combines au prototype Flutter MVP et au pipeline OCR deja operationnels, positionnent ExamBoost Togo comme une candidature solide pour le programme Idée-Action du DJANTA Tech Hub.

---

## 12. Annexes

### Annexe A — Questionnaire complet
Cf. `Questionnaire_Eleve.md`.

### Annexe B — Consentement eclaire
Cf. `Consentement_Eleve.md`.

### Annexe C — Plan d'echantillonnage
Cf. `Plan_Echantillonnage.md`.

### Annexe D — Donnees brutes
Fichier : `analyse/enquete_examboost_lome_2026-06.csv` (30 lignes, 31 colonnes).

### Annexe E — Statistiques descriptives completes
Fichier : `analyse/output/stats.json` (genere par `analyse_enquete.py`).

### Annexe F — Graphiques
Dossier : `analyse/output/figures/` (6 fichiers PNG).

### Annexe G — Rapport automatique
Fichier : `analyse/output/rapport_auto.md` (genere par `analyse_enquete.py`).

### Annexe H — Contacts beta-testeurs
[A COMPLETER apres enquete — liste des eleves ayant accepte en E3]

---

## Historique des versions

| Version | Date | Auteur | Modifications |
|---|---|---|---|
| 1.0 | Juin 2026 | Agent N | Creation du modele |
| 1.1 | [DATE] | [NOM] | Remplissage avec donnees reelles |

---

*Fin du Rapport Modele — Equipe ExamBoost Togo, juin 2026.*
