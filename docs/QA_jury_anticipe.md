# ExamBoost Togo — Q&A Jury Anticipé
*Préparation au pitch DJANTA Tech Hub — 24 juillet 2026*

> Document interne de préparation. 77 questions probables du jury, classées par thème, avec réponses calibrées (30-60 secondes à l'oral), chiffres clés à citer et pièges à éviter. À répéter en équipe avant le 20 juillet 2026.

---

## Comment utiliser ce document

- **77 questions** organisées en 11 thèmes couvrant l'intégralité du spectre probable d'interrogation du jury DJANTA Tech Hub. Les thèmes 1-10 reprennent les questions fondamentales (produit, business, ML, concurrence, équipe, marché, risques, impact, pièges) ; le thème 11 couvre les nouveaux modules des Sessions 3-4 (tuteur IA, badges, sync cloud, ML avancé, parent, devoirs, niveaux XP, orientation, multijoueur, sécurité OWASP).
- Pour chaque question, vous trouverez trois éléments :
  - **Réponse courte (30-60 sec à l'oral)** : 2 à 4 phrases claires, directes, prêtes à être prononcées.
  - **Chiffres clés à citer** : 2 à 4 statistiques précises à intégrer dans la réponse orale.
  - **À éviter** : piège identifié et reformulation correcte.
- **Plan d'entraînement recommandé** : répéter les thèmes 1-5 avant le 14 juillet, puis les thèmes 6-10 avant le 18 juillet, puis le thème 11 (nouveaux modules) le 19 juillet, puis simulation complète des 77 questions le 20 juillet en condition réelle (chronomètre + film).
- **Règle d'or** : en cas de question difficile, prendre 2 secondes, reformuler la question, répondre honnêtement. Ne jamais dire « je ne sais pas » seul — toujours compléter par « voici ce que nous savons aujourd'hui, et voici comment nous allons approfondir ce point ».
- **Ton** : professionnel, chiffré, sans jargon excessif. Valoriser la profondeur de la localisation togolaise, l'honnêteté sur les risques, et la traction déjà accumulée.

---

## Thème 1 — Problème & Solution (7 questions)

### Q1. Pourquoi le BEPC est-il passé de 81 % à 44 % en un an ?

**Réponse courte (30-60 sec) :**
La chute du BEPC de 81 % en 2023 à 44 % en 2024 n'est pas un accident : c'est l'effet immédiat de la réforme « Approche Par Compétences » (APC) introduite par le MEPST sans formation suffisante des enseignants. Les élèves ont découvert un format d'épreuve nouveau le jour de l'examen, sans préparation adaptée. ExamBoost cible exactement ce gap : on entraîne les élèves sur le nouveau format d'évaluation, avec des questions alignées sur l'APC et des corrigés qui expliquent ce qui est attendu.

**Chiffres clés à citer :**
- BEPC 2023 : 81 % → BEPC 2024 : 44,09 % (chute de 37 points en un an)
- Probatoire : 80,96 % → 71 % (−10 pts) ; BAC 1 : 78,5 % → 71,73 % (−6,8 pts)
- BAC 2 2024 : 46,71 % — préoccupant

**À éviter :**
- Ne pas dire « les élèves sont devenus moins bons » — c'est faux et blessant.
- Ne pas blâmer publiquement le MEPST — dire « transition difficile » et non « échec du Ministère ».

---

### Q2. Pourquoi les élèves n'arrivent-ils pas à se préparer efficacement ?

**Réponse courte (30-60 sec) :**
Quatre causes structurelles : (1) la réforme APC a changé le format des épreuves sans fournir d'outils de préparation adaptés ; (2) il n'existe aucune plateforme numérique alignée sur le programme togolais — les élèves utilisent des PDF scannés WhatsApp non structurés ; (3) les cours de soutien privés sont concentrés à Lomé et inaccessibles à un élève de Kara ou Dapaong ; (4) la majorité des élèves découvrent le format réel de l'épreuve le jour J. ExamBoost attaque les quatre causes simultanément : contenu aligné, app mobile gratuite, mode offline, et simulations d'examen réelles.

**Chiffres clés à citer :**
- 86 % d'élèves togolais incapables de lire correctement à 10 ans (Banque Mondiale, Learning Poverty)
- 0 plateforme existante alignée sur le programme MEPST
- Inégalité d'accès aux cours de soutien privés : concentrés à Lomé

**À éviter :**
- Ne pas dire « les élèves ne révisent pas » — ils révisent, mais sans outils.
- Ne pas minimiser le rôle des enseignants — dire « transition difficile » et non « enseignants incompétents ».

---

### Q3. En quoi ExamBoost est-il différent de Khan Academy ?

**Réponse courte (30-60 sec) :**
Khan Academy est une excellente plateforme — 140 millions d'utilisateurs mondial — mais elle n'est pas alignée sur le programme MEPST togolais. Khan propose des cours génériques en vidéo, sans annales BEPC/BAC, sans mode offline robuste, et sans calibration IRT sur le curriculum local. ExamBoost est 100 % aligné sur le programme togolais (séries A, B, C, D, F du BAC, 8 matières du BEPC), utilise les annales officielles 2010-2025, fonctionne hors-ligne sur un Tecno Spark 4 Go de RAM, et applique la répétition espacée plus l'IRT pour adapter chaque question au niveau de l'élève.

**Chiffres clés à citer :**
- Khan Academy : +16 % de notes en Inde (étude CEPR/J-PAL), mais 0 % d'alignement BEPC/BAC
- ExamBoost : 3 000 à 6 000 questions togolaises, IRT 3PL calibré, app offline < 30 Mo

**À éviter :**
- Ne pas dénigrer Khan Academy — c'est une référence scientifique solide. Dire « complémentaire mais non adapté au contexte togolais ».
- Ne pas promettre des résultats supérieurs à Khan sans preuves pilotes.

---

### Q4. Pourquoi une app mobile plutôt qu'une plateforme web ?

**Réponse courte (30-60 sec) :**
Parce que le terminal dominant au Togo est le smartphone d'entrée de gamme, pas le laptop. Selon l'ARCEP Togo (T3-2025), le taux de pénétration mobile dépasse 100 %, et 42 % des terminaux sont déjà 4G. Les lycéens togolais consultent WhatsApp sur leur Tecno, Itel ou Infinix — pas sur un ordinateur. Une app mobile native Flutter permet le mode offline complet (téléchargement des épreuves à l'avance, sync différée), des notifications push pour rappeler les révisions, et une expérience fluide même en 2G/3G. Une plateforme web aurait exigé une connexion permanente et aurait exclu la moitié rurale du pays.

**Chiffres clés à citer :**
- Pénétration mobile > 100 % (ARCEP T3-2025)
- 41 % des terminaux encore 2G uniquement (ARCEP T1-2025)
- APK ExamBoost < 25 Mo, compatible Android 5+

**À éviter :**
- Ne pas dire « les jeunes préfèrent le mobile » sans chiffrer.
- Ne pas exclure une version web future pour les enseignants et directeurs (prévue en phase 2).

---

### Q5. Pourquoi le mode offline est-il si important ?

**Réponse courte (30-60 sec) :**
Parce que la couverture réseau togolaise est inégale hors de Lomé. Si la 4G performe à Lomé et dans les grandes villes, les régions de Kara, des Savanes et des Plateaux souffrent encore de taux de non-conformité des opérateurs atteignant 46 à 57 % en 2023 (ARCEP). Un élève de Dapaong ou Mango ne peut pas dépendre d'une connexion permanente pour réviser. ExamBoost télécharge une fois les épreuves (en WiFi ou en 4G à Lomé lors d'un déplacement), puis fonctionne 100 % offline : questions, corrigés, algorithme SM-2, tableau de bord. La synchronisation delta se fait quand le réseau revient.

**Chiffres clés à citer :**
- 46-57 % de taux de non-conformité opérateurs en 2023 (régions rurales, ARCEP)
- SQLite + Hive (Flutter) = stockage offline robuste, sync différée
- Synchro delta = seuls les changements sont transférés (pas de re-téléchargement)

**À éviter :**
- Ne pas promettre « offline 100 % parfait » sans expliquer la stratégie de sync.
- Ne pas minimiser le défi des mises à jour de contenu (prévoir un mécanisme de notification « nouvelle session disponible »).

---

### Q6. Comment savez-vous que les élèves veulent cet outil ? (enquête terrain)

**Réponse courte (30-60 sec) :**
Nous avons interrogé 30 élèves de Lomé en juin 2026 : 87 % disent n'avoir aucun outil numérique de préparation aux examens, et 94 % seraient prêts à utiliser ExamBoost gratuitement. Une enquête plus large est planifiée en M1-M2 auprès de 200 élèves dans 5 villes (Lomé, Kpalimé, Atakpamé, Sokodé, Kara) pour valider les hypothèses d'usage, les modèles d'appareils utilisés, et la disposition à payer. Nous avons déjà un contact avec un lycée de Lomé intéressé par un pilote. La demande est massive et documentée — ce n'est pas une hypothèse.

**Chiffres clés à citer :**
- 30 élèves sondés à Lomé (juin 2026) : 87 % sans outil numérique, 94 % prêts à utiliser ExamBoost
- Enquête terrain planifiée : 200 élèves, 5 villes, M1-M2
- 100 000+ candidats au BAC 2 en 2025 (hausse 30 % vs 2024)

**À éviter :**
- Ne pas exagérer le nombre d'enquêtés (« des milliers d'élèves ») si on n'en a interrogé que 30.
- Ne pas dire « tous les élèves veulent ExamBoost » — dire « 94 % des sondés expriment un intérêt ».

---

### Q7. Quel est le lien entre votre solution et la réforme APC ?

**Réponse courte (30-60 sec) :**
L'APC (Approche Par Compétences) est précisément la cause principale de la chute du BEPC de 81 % à 44 %. Elle introduit des épreuves qui n'évaluent plus seulement la restitution, mais la mobilisation de compétences dans des situations complexes. Le problème : les enseignants n'ont pas été suffisamment formés à l'APC, et il n'existe pas de banque de questions APC pour les élèves. ExamBoost répond directement à cela : chaque question est taguée par compétence (carte des compétences MEPST), le modèle BKT trace la maîtrise de chaque compétence en temps réel, et le tableau de bord montre à l'élève (et à son enseignant) quelles compétences doivent être renforcées.

**Chiffres clés à citer :**
- BEPC −37 pts en un an = effet direct de l'APC mal préparée
- Carte des compétences MEPST : ~200-300 pages de référentiel à numériser
- BKT : mise à jour de P(L) après chaque réponse, seuil de maîtrise P(L) ≥ 0,85

**À éviter :**
- Ne pas dire « l'APC est une mauvaise réforme » — c'est une bonne réforme mal outillée.
- Ne pas promettre « nous allons former les enseignants » — ce n'est pas notre rôle, c'est celui du MEPST. Notre rôle est d'outiller les élèves.

---

## Thème 2 — Modèle économique (7 questions)

### Q8. Comment allez-vous gagner de l'argent si l'app est gratuite pour les élèves ?

**Réponse courte (30-60 sec) :**
Modèle B2B2C inspiré d'EDVES Nigeria et Kahoot ! L'élève accède gratuitement à l'app — parce qu'un élève togolais ne peut pas payer 5 USD/mois avec un revenu par habitant de 2 390 USD PPP. Les revenus viennent de trois sources : (1) licences annuelles aux établissements scolaires à 100 000 FCFA/an (tableau de bord agrégé, alertes élèves à risque, rapports trimestriels) ; (2) subventions de bailleurs (GPE, UNICEF Innovation Fund, AFD) ; (3) premium élève optionnel à 2 000 FCFA/mois pour des fonctionnalités avancées. Le gratuit crée l'adoption massive, le B2B génère les revenus récurrents.

**Chiffres clés à citer :**
- Revenu/habitant Togo : 2 390 USD PPP (Banque Mondiale 2021)
- Licence établissement : 100 000 FCFA/an (50 000-150 000 selon taille)
- Premium élève : 2 000 FCFA/mois (optionnel, ciblé sur 5 % des utilisateurs)

**À éviter :**
- Ne pas dire « on rendra l'app payante plus tard » — cela tue l'adoption.
- Ne pas promettre des revenus premium élèves élevés — la cible est 5 % des utilisateurs, pas 50 %.

---

### Q9. Les écoles togolaises privées ont-elles le budget pour payer 100 000 FCFA/an ?

**Réponse courte (30-60 sec) :**
Oui, pour trois raisons. D'abord, 100 000 FCFA/an représente environ 150 USD pour une école — moins que le coût d'un seul manuel scolaire imprimé pour toute une classe. Ensuite, les lycées privés togolais ont des budgets informatique et communication : 100 000 FCFA est très en dessous de ce qu'ils dépensent en impressions, en photocopies, en fournitures. Enfin, le tableau de bord que nous offrons (suivi agrégé de classe, alertes élèves à risque, rapports trimestriels automatiques) leur fait économiser des dizaines d'heures-enseignant par an. Pour les écoles publiques, nous visons un financement via les partenaires institutionnels (GPE, UNICEF, AFD) qui peuvent subventionner les licences.

**Chiffres clés à citer :**
- 100 000 FCFA ≈ 150 USD/an/établissement (vs coût d'un manuel scolaire pour une classe)
- 500+ lycées privés au Togo = marché B2B direct
- Écoles publiques : financement via GPE, UNICEF, AFD (modèle subventionné)

**À éviter :**
- Ne pas dire « toutes les écoles privées peuvent payer » — certaines petites écoles ne le pourront pas, d'où la grille tarifaire 50 000-150 000 FCFA selon taille.
- Ne pas promettre l'adhésion du secteur public sans bailleur — c'est illusoire.

---

### Q10. Quel est votre point d'équilibre ?

**Réponse courte (30-60 sec) :**
Le seuil de rentabilité est estimé à 300-400 établissements partenaires, atteignable à la fin de la deuxième année. Avec 150 écoles à 100 000 FCFA/an, nous atteignons 15 millions FCFA de revenus annuels récurrents — ce qui couvre déjà une partie significative des charges opérationnelles de la phase 2. À 300-400 écoles, nous atteignons 30-40 millions FCFA/an, ce qui couvre l'équipe opérationnelle complète. D'ici là, le financement initial (programme DJANTA + grants + prime d'incubation CcHub) couvre les coûts de développement et de pilote.

**Chiffres clés à citer :**
- Seuil de rentabilité : 300-400 établissements (fin année 2)
- 150 écoles × 100 000 FCFA = 15 millions FCFA/an récurrents
- Projection an 2 : 50 écoles partenaires (KPI M12)

**À éviter :**
- Ne pas dire « nous serons rentables en 6 mois » — c'est faux et peu crédible.
- Ne pas confondre « point d'équilibre opérationnel » et « retour sur investissement » — préciser.

---

### Q11. Que faites-vous si aucune école ne veut payer ?

**Réponse courte (30-60 sec) :**
Notre modèle n'est pas monocanal : le B2B écoles est un pilier, mais nous avons aussi le B2B bailleurs (GPE, UNICEF, AFD financent activement les EdTech en Afrique subsaharienne), le premium élève optionnel (ciblé à 5 % des utilisateurs actifs), et à terme l'API de données MEPST (contrat institutionnel). Si aucune école privée ne paie spontanément, nous pivotons vers un modèle 100 % subventionné : les bailleurs paient les licences pour les écoles, comme le fait Génie OCP au Maroc. Mais nous avons déjà un lycée de Lomé intéressé par un pilote — la demande est réelle.

**Chiffres clés à citer :**
- 4 sources de revenus diversifiées (B2B écoles, B2B bailleurs, premium élève, API MEPST)
- Bailleurs actifs en EdTech Afrique : GPE, UNICEF Innovation Fund, AFD, Banque Mondiale
- Précédent : Génie OCP Maroc = modèle 100 % gouvernemental

**À éviter :**
- Ne pas paraître paniqué ou défensif — garder le ton confiant et pivot-ready.
- Ne pas dire « ça ne peut pas arriver » — c'est un risque réel, montrer qu'on a un plan B.

---

### Q12. Comment allez-vous payer les serveurs et la maintenance ?

**Réponse courte (30-60 sec) :**
Coûts infrastructure maîtrisés dès la conception : Railway ou Render pour le backend FastAPI (50-80 USD/mois en phase MVP), PostgreSQL cloud pour la base principale, SQLite sur l'app pour l'offline, Africa's Talking pour les SMS (0,02 USD/SMS), GPT-4o Vision pour l'OCR initial (100-200 USD pour tout le pipeline initial). Total infrastructure MVP : moins de 100 USD/mois. Le coût réel est l'équipe (10-13 personnes à pleine charge), pas les serveurs. En phase 2, le coût cloud passe à ~8 000 USD sur 10 mois — reste marginal vs salaires.

**Chiffres clés à citer :**
- Backend cloud : 50-80 USD/mois (Railway/Render)
- SMS Africa's Talking : 0,02 USD/SMS
- OCR GPT-4o Vision : 100-200 USD pour la phase initiale complète
- Budget infrastructure phase 1 : 3 000 USD sur 8 mois

**À éviter :**
- Ne pas citer des coûts AWS/GCP élevés — cela effraie le jury.
- Ne pas oublier le coût mobile money (Flooz/TMoney) dans les projections.

---

### Q13. Pourquoi pas un modèle freemium classique comme Duolingo ?

**Réponse courte (30-60 sec) :**
Parce que Duolingo fonctionne dans un contexte où 5 USD/mois est abordable pour la majorité des utilisateurs — ce qui n'est pas le cas au Togo. Le revenu par habitant togolais est de 2 390 USD PPP, et la majorité des lycéens n'ont pas de revenu personnel. Un modèle freemium avec paywall après 5 questions par jour exclurait les élèves qui en ont le plus besoin. Notre approche inverse : l'élève a tout gratuitement, c'est l'établissement (qui a un budget) ou le bailleur institutionnel (qui a une mission) qui paie. Cela aligne aussi les intérêts : l'école veut que ses élèves réussissent, donc elle paie pour les suivre.

**Chiffres clés à citer :**
- Revenu/habitant Togo : 2 390 USD PPP (vs 65 000 USD en France)
- 95 % des élèves togolais incapables de payer 5 USD/mois (étude faisabilité)
- Duolingo : 40 millions d'utilisateurs payants — modèle inadapté au Togo

**À éviter :**
- Ne pas dire « le freemium ne marche pas en Afrique » — c'est faux, ça marche pour les classes moyennes urbaines, mais pas pour les lycéens ruraux.
- Ne pas jeter Duolingo — citer leur science algorithmique (SRS, IRT) comme référence.

---

### Q14. Quelle est votre stratégie de prix pour les écoles publiques vs privées ?

**Réponse courte (30-60 sec) :**
Tarification différenciée selon la capacité de paiement. Les lycées privés paient 100 000 FCFA/an standard (50 000 pour les petites écoles, 150 000 pour les grandes). Pour les lycées publics, le modèle est différent : nous ne facturons pas l'école, mais nous facturons un bailleur institutionnel (GPE, UNICEF, AFD) qui subventionne les licences pour 5 à 20 écoles publiques à la fois. C'est le modèle de Génie OCP au Maroc et de nombreuses EdTech subventionnées en Afrique. Cela évite que les écoles publiques — qui n'ont pas de budget propre — soient exclues.

**Chiffres clés à citer :**
- Privé : 50 000-150 000 FCFA/an selon taille
- Public : 0 FCFA pour l'école, subventionné par bailleur (10-20 écoles par contrat)
- Précédent : Génie OCP Maroc, Zaya Labs Inde (modèles subventionnés ruraux)

**À éviter :**
- Ne pas dire « les écoles publiques ne paient rien » — dire « financées par bailleur ».
- Ne pas promettre un accès public avant signature d'un bailleur — c'est un risque.

---

## Thème 3 — Technologie & IA (8 questions)

### Q15. Pouvez-vous expliquer simplement ce qu'est l'IRT ?

**Réponse courte (30-60 sec) :**
L'IRT (Théorie de la Réponse aux Items) est une méthode statistique utilisée par le GRE, le GMAT, le TOEFL et Duolingo pour calibrer la difficulté des questions. Au lieu de dire « 60 % des élèves ont réussi cette question » (méthode classique, qui dépend du groupe d'élèves), l'IRT estime trois paramètres par question : la difficulté b, la discrimination a (capacité de distinguer les bons des mauvais), et la chance c (probabilité de répondre juste au hasard). On peut alors calculer pour chaque élève son niveau θ et lui proposer une question dont la difficulté correspond exactement à son niveau — ni trop facile (ennui), ni trop difficile (découragement). C'est l'essence de l'adaptatif.

**Chiffres clés à citer :**
- IRT utilisée par GRE, GMAT, TOEFL, Duolingo
- 3 paramètres par question : a (discrimination), b (difficulté), c (chance)
- Volume minimum calibrage : 200-300 élèves par question (phase pilote 300-500 élèves)

**À éviter :**
- Ne pas réciter la formule 3PL complète au jury — c'est trop technique. Garder la formule pour la doc.
- Ne pas dire « l'IRT est parfaite » — elle a des limites (données nécessaires, calibration initiale).

---

### Q16. Pourquoi SM-2 plutôt que FSRS plus moderne ?

**Réponse courte (30-60 sec) :**
SM-2 est l'algorithme historique (Piotr Wozniak, 1987), utilisé par Anki et plus de 10 millions d'utilisateurs. Il est simple, prouvé, et documenté. FSRS (2022) est effectivement plus moderne — il modélise explicitement la stabilité de la mémoire et améliore les prédictions d'oubli de 20 à 40 % par rapport à SM-2. Mais FSRS nécessite une base de données significative pour bien fonctionner. Notre stratégie est pragmatique : démarrer avec SM-2 (qui fonctionne avec 0 donnée préalable, juste des règles), puis migrer vers FSRS dès que la base utilisateurs atteint 10 000 révisions. C'est exactement la démarche recommandée par les benchmarks scientifiques.

**Chiffres clés à citer :**
- SM-2 : 1987, Wozniak, utilisé par Anki (10M+ utilisateurs)
- FSRS : 2022, +20-40 % de précision sur prédictions d'oubli
- Migration prévue à 10 000 révisions collectées

**À éviter :**
- Ne pas dire « SM-2 est obsolète » — c'est faux, c'est le standard de l'industrie.
- Ne pas promettre la migration FSRS à court terme — c'est une évolution phase 3.

---

### Q17. Comment fonctionne la prédiction du score à l'examen ?

**Réponse courte (30-60 sec) :**
Un modèle XGBoost (gradient boosting, 100-500 arbres) prend en entrée six features : la probabilité de maîtrise BKT par matière, le score moyen aux 3 dernières simulations, la régularité d'utilisation (sessions/semaine sur 4 semaines), le temps moyen par question (indicateur de fluence), le taux d'achèvement du programme, et le θ IRT global estimé. Le modèle est entraîné sur les données réelles — après le BEPC 2026, on comparera les prédictions aux notes réelles pour calibrer. Validation croisée 5-fold systématique. Métrique cible : RMSE < 2 points sur 20 en production. Le score prédit est affiché à l'élève comme indicateur de préparation, motivant la pratique régulière.

**Chiffres clés à citer :**
- XGBoost : 100-500 arbres, RMSE cible < 2 pts/20
- 6 features : P(L) par matière, score simulations, régularité, temps/question, achèvement, θ IRT
- Données minimum : 1 000 élèves pour XGBoost (vs 200 pour Ridge/LASSO au pilote)

**À éviter :**
- Ne pas dire « nous prédisons la note exacte » — c'est faux, c'est une estimation à ±2 pts.
- Ne pas promettre la prédiction au lancement — elle arrive en phase 2 (post-BEPC 2026).

---

### Q18. Combien de données faut-il pour que l'IA soit fiable ?

**Réponse courte (30-60 sec) :**
Cela dépend du modèle, et nous avons une stratégie par paliers. Pour l'IRT 1PL (Rasch), 100 réponses par question suffisent au lancement. Pour l'IRT 2PL/3PL (calibrage complet), 300-500 élèves par question au pilote. Pour le BKT standard, 500 séquences minimum (AUC cible 0,70-0,75). Pour XGBoost de prédiction de score, 1 000 élèves (RMSE 1,5-2,5 pts/20). Avant le pilote, nous utilisons des valeurs par défaut raisonnables : a = 1, c = 0 pour questions ouvertes (ou 1/k pour QCM à k choix), b estimé par inversion du taux de réussite historique dans les annales. L'IA s'améliore donc progressivement — pas de « cold start ».

**Chiffres clés à citer :**
- IRT 1PL : 100 réponses/q ; 2PL/3PL : 300-500 élèves/q
- BKT standard : 500 séquences, AUC 0,70-0,75
- XGBoost : 1 000 élèves, RMSE 1,5-2,5 pts/20

**À éviter :**
- Ne pas dire « l'IA marche tout de suite » — c'est faux, il faut du palier.
- Ne pas dire « il faut 100 000 utilisateurs pour que ça marche » — c'est décourageant et inexact.

---

### Q19. Quels modèles ML utilisez-vous exactement ?

**Réponse courte (30-60 sec) :**
Cinq familles de modèles, chacune avec un rôle précis. (1) IRT 1PL/2PL/3PL avec py-irt (Python) pour calibrer chaque question (a, b, c). (2) SM-2 implémenté en Dart dans Flutter, puis migration FSRS à 10 000 révisions. (3) BKT (Bayesian Knowledge Tracing) avec pyBKT (Berkeley) pour tracer la maîtrise par compétence. (4) XGBoost / Ridge pour prédire le score à l'examen. (5) Régression LASSO ou Random Forest pour détecter les élèves à risque de décrochage (rappel cible ≥ 80 %). Tous sont open-source, éprouvés scientifiquement, et documentés. Pas de chatbot, pas de LLM générique — de la psychométrie et du ML classique, robuste et interprétable.

**Chiffres clés à citer :**
- IRT : py-irt (Python) ou mirt (R)
- BKT : pyBKT (Berkeley), AUC cible 0,72
- 5 familles ML au total : IRT, SM-2/FSRS, BKT, XGBoost, LASSO/RF

**À éviter :**
- Ne pas dire « on utilise GPT-4 pour tout » — c'est faux et trompeur. GPT-4o Vision est utilisé seulement pour l'OCR initial, pas pour la prédiction.
- Ne pas surenchérir avec du deep learning — Random Forest et XGBoost suffisent pour nos volumes.

---

### Q20. Pourquoi Flutter plutôt que React Native ?

**Réponse courte (30-60 sec) :**
Trois raisons. D'abord, Flutter génère un vrai code natif Android et iOS depuis une seule codebase Dart, avec des performances quasi-natives — critique pour des animations fluides (flashcard, transitions). React Native reste bridé par le bridge JavaScript. Ensuite, Flutter est optimisé pour Android 5+, ce qui couvre 98 % des smartphones togolais. Le compilateur AOT de Flutter produit un APK léger (< 25 Mo), essentiel pour les téléphones d'entrée de gamme avec 8-16 Go de stockage. Enfin, l'écosystème Flutter pour l'offline (Hive, sqflite) est mature, et la communauté Flutter en Afrique francophone est en forte croissance — facilité de recrutement local.

**Chiffres clés à citer :**
- APK ExamBoost : < 25 Mo (cible < 30 Mo)
- Android 5+ couvert = 98 % du parc smartphone togolais
- Hive + sqflite = stack offline mature Flutter

**À éviter :**
- Ne pas dire « React Native est mauvais » — c'est faux, c'est juste moins adapté à notre cas.
- Ne pas oublier que l'équipe maîtrise déjà Flutter (code déjà écrit dans le repo).

---

### Q21. Comment garantissez-vous que l'app fonctionne sur un Tecno Spark 4 Go de RAM ?

**Réponse courte (30-60 sec) :**
C'est un critère de conception non négociable. Trois mesures concrètes. (1) APK < 25 Mo avec images compressées WebP et lazy loading, ce qui laisse de la place sur des appareils avec 8 Go de stockage. (2) Stockage local SQLite + Hive optimisé — pas de base de données lourde en mémoire, pas de vidéo en streaming. (3) Mode nuit automatique et économie d'énergie pour préserver la batterie. Nous testons sur des appareils réels Tecno, Itel et Infinix (marques dominantes au Togo selon ARCEP) avant chaque release. Un Tecno Spark 4 Go de RAM est précisément notre appareil de référence de test.

**Chiffres clés à citer :**
- Appareils dominants Togo : Tecno, Itel, Infinix (entrée de gamme)
- Cible : RAM 2 Go minimum, stockage 16 Go
- APK : < 25 Mo (vs limite recommandée < 30 Mo)

**À éviter :**
- Ne pas dire « ça marche sur tous les téléphones » — préciser la cible.
- Ne pas promettre une compatibilité 2G-only — les terminaux 2G (41 % du parc) ne sont pas des smartphones.

---

### Q22. Que faites-vous si la calibration IRT donne des résultats aberrants ?

**Réponse courte (30-60 sec) :**
C'est un risque identifié, et nous avons trois gardes-fous. D'abord, la calibration n'est lancée qu'avec un volume suffisant (300-500 élèves minimum par question) — en dessous, on reste sur les valeurs par défaut. Ensuite, après chaque recalibration mensuelle, nous appliquons des règles de sanity check : retirer les questions avec a < 0,3 (peu discriminantes) ou c > 0,4 (trop de chance), qui sont renvoyées en validation pédagogique. Enfin, tout changement de paramètres IRT supérieur à 20 % d'un cycle à l'autre déclenche une alerte humaine — un data scientist examine manuellement la question. L'IRT ne remplace jamais le jugement pédagogique, elle l'augmente.

**Chiffres clés à citer :**
- Volume minimum calibration : 300-500 élèves/q
- Règles de rejet : a < 0,3 ou c > 0,4
- Alerte humaine si delta > 20 % d'un cycle à l'autre

**À éviter :**
- Ne pas dire « ça ne peut pas arriver » — c'est faux, ça arrive toujours.
- Ne pas dire « on fait confiance à l'IA » — toujours expliquer la supervision humaine.

---

## Thème 4 — Données & Contenu (6 questions)

### Q23. D'où viennent vos questions ?

**Réponse courte (30-60 sec) :**
Trois couches de données. Couche 1 : annales officielles BEPC et BAC 2010-2025, disponibles publiquement sur des sites comme epreuvesetcorriges.com, banquedesepreuves.com, examens-concours.net, fomesoutra.com. Ces sources permettent d'extraire 800 à 1 200 sujets PDF, soit 3 000 à 6 000 questions structurées après OCR et annotation. Couche 2 : le programme MEPST officiel (à négocier via partenariat formel) pour taguer chaque question par compétence. Couche 3 : examens blancs générés par LLM (GPT-4o ou Mistral fine-tuné) dans le style des annales, validés obligatoirement par un enseignant avant publication. Toute question générée par IA est validée humainement.

**Chiffres clés à citer :**
- 800-1 200 sujets PDF disponibles (2010-2025)
- 3 000-6 000 questions structurées après OCR
- 60-70 % des corrigés officiels disponibles en ligne

**À éviter :**
- Ne pas dire « on a déjà 3 000 questions » — on a un plan pour les produire, pas encore le volume.
- Ne pas citer uniquement les sources officielles sans mentionner les sources libres.

---

### Q24. Avez-vous l'autorisation du MEPST pour utiliser les annales officielles ?

**Réponse courte (30-60 sec) :**
Démarche en cours. Les annales publiées sont dans le domaine public une fois l'examen passé — c'est la jurisprudencestandard. Mais nous cherchons un partenariat formel avec le MEPST pour trois raisons : (1) accéder aux programmes officiels numérisés (qui ne sont pas publics en format structuré), (2) obtenir une validation institutionnelle qui rassure les écoles, (3) envisager à terme une intégration avec le SIGE (Système d'Information de Gestion des Établissements). La lettre de demande de partenariat est en préparation, à envoyer en M1-M2. En cas de non-réponse, nous avons une stratégie alternative : reconstruction par ingénierie inverse à partir des annales elles-mêmes (qui couvrent l'essentiel du curriculum).

**Chiffres clés à citer :**
- Annales publiées = domaine public (jurisprudence)
- Partenariat MEPST demandé : programmes numériques + validation institutionnelle
- Plan B : reconstruction du curriculum à partir des annales 2015-2025

**À éviter :**
- Ne pas dire « on n'a pas besoin du MEPST » — c'est faux stratégiquement, on a besoin de leur bénédiction.
- Ne pas dire « on a déjà signé » — la lettre est en cours, pas envoyée.

---

### Q25. Comment gérez-vous la qualité des questions OCR-isées ?

**Réponse courte (30-60 sec) :**
Pipeline en cinq étapes avec contrôle humain à chaque étape critique. Étape 1 : acquisition — scraping et téléchargement systématique des PDF organisés par (examen / année / matière / série). Étape 2 : OCR — Tesseract pour le texte français standard, GPT-4o Vision pour les formules mathématiques et chimiques (plus précis). Étape 3 : segmentation automatique — découpage en (numéro / énoncé / points / réponse), avec règles heuristiques + LLM pour les cas ambigus. Étape 4 : annotation humaine par 3 opérateurs à mi-temps pendant 3 mois (matière, chapitre, type, difficulté). Étape 5 : validation pédagogique par 2 enseignants experts qui vérifient la correction des réponses. Une question erronée publiée détruit la confiance — nous préférons publier moins de questions mais validées.

**Chiffres clés à citer :**
- Tesseract + GPT-4o Vision (formules) = combinaison OCR robuste
- 3 opérateurs × 3 mois × mi-temps = 3 000-6 000 questions annotées
- 2 enseignants experts en validation finale

**À éviter :**
- Ne pas dire « l'OCR est parfait » — il y a toujours des erreurs sur les formules.
- Ne pas oublier l'étape de validation humaine — c'est critique pour la crédibilité.

---

### Q26. Combien de questions avez-vous actuellement ? Quel objectif ?

**Réponse courte (30-60 sec) :**
Aujourd'hui, dans le repo GitHub public, nous avons 20 questions de démonstration BEPC Maths (JSON structuré) — c'est suffisant pour la démo pitch. L'objectif est ambitieux mais atteignable : 3 000 questions structurées et validées d'ici la fin du programme de pré-incubation (M3-M5), avec priorité aux 3 matières critiques (Mathématiques, Français, Sciences Physiques) pour le BEPC. À terme (M18), nous visons 6 000 questions couvrant BEPC + BAC toutes séries (A, B, C, D, F). C'est aligné sur la couverture des annales disponibles 2010-2025.

**Chiffres clés à citer :**
- Aujourd'hui : 20 questions démo (BEPC Maths)
- Cible M3-M5 : 3 000 questions (3 matières prioritaires BEPC)
- Cible M18 : 6 000 questions (BEPC + BAC toutes séries)

**À éviter :**
- Ne pas dire « on a 3 000 questions » — on en a 20 aujourd'hui, le reste est un plan.
- Ne pas promettre 10 000 questions en 3 mois — c'est irréaliste avec annotation humaine.

---

### Q27. Que faites-vous si une question comporte une erreur ?

**Réponse courte (30-60 sec) :**
Trois mécanismes. D'abord, la prévention : validation pédagogique systématique par 2 enseignants experts avant publication — aucune question n'entre dans l'app sans double validation. Ensuite, la détection : un mécanisme in-app de signalement (« cette question semble incorrecte ») est accessible à chaque élève, et toute question signalée est immédiatement suspendue de la rotation IRT jusqu'à re-vérification. Enfin, la correction : une question erronée est retirée, corrigée, re-validée, puis réintroduite avec un nouveau calibrage IRT. Si l'erreur a affecté un grand nombre d'élèves (mauvaise note de simulation), nous recalculons leurs scores a posteriori. La transparence est essentielle : un changelog public des corrections est maintenu.

**Chiffres clés à citer :**
- Double validation pédagogique systématique avant publication
- Mécanisme de signalement in-app (1 clic par élève)
- Changelog public des corrections

**À éviter :**
- Ne pas dire « ça n'arrivera pas » — ça arrivera, l'important est la réaction.
- Ne pas cacher les erreurs — la transparence construit la confiance.

---

### Q28. Comment allez-vous maintenir le contenu à jour ?

**Réponse courte (30-60 sec) :**
Trois leviers. D'abord, la mise à jour annuelle : après chaque session d'examen (BEPC juillet, BAC juillet), nous intégrons les nouveaux sujets dans le pipeline OCR + annotation, ce qui ajoute 50-100 questions par an. Ensuite, la maintenance du programme : si le MEPST met à jour le curriculum (cas de l'APC en 2024), nous alignons le tagging des compétences en M1-M2 de l'année scolaire. Enfin, la génération LLM continue : GPT-4o ou Mistral fine-tuné peut générer des nouvelles questions dans le style officiel, validées humainement, pour combler les gaps (chapitres sous-représentés dans les annales). Le contenu n'est jamais figé — il est vivant.

**Chiffres clés à citer :**
- 50-100 nouvelles questions/an après chaque session d'examen
- 1 data scientist + 2 enseignants experts en maintenance continue
- Génération LLM supervisée pour les gaps

**À éviter :**
- Ne pas dire « le contenu est figé » — c'est faux, c'est un avantage concurrentiel d'avoir un contenu vivant.
- Ne pas oublier que la maintenance a un coût (enseignants à payer).

---

## Thème 5 — Concurrence & Différenciation (5 questions)

### Q29. Que faites-vous si Afrilearn (Nigeria) s'implante au Togo ?

**Réponse courte (30-60 sec) :**
Afrilearn est une excellente plateforme nigériane, mais elle est alignée sur le curriculum WAEC/NECO/JAMB, pas sur le programme MEPST togolais. Pour s'implanter au Togo, Afrilearn devrait : (1) traduire tout le contenu en français, (2) recalibrer chaque question sur le programme togolais, (3) obtenir un partenariat avec le MEPST. C'est 12 à 18 mois de travail, avec un coût élevé. Notre avantage : nous serons les premiers, avec une localisation profonde (français togolais, exemples contextualisés, annales officielles). La localisation est un fossé défensif majeur — c'est ce qui a fait le succès d'Afrilearn au Nigeria et ce qui le rendrait difficile à répliquer au Togo.

**Chiffres clés à citer :**
- Afrilearn : curriculum WAEC/NECO, anglais, ~12-18 mois pour adapter au Togo
- Notre avance : 6-12 mois si nous signons en premier avec le MEPST
- Précédent : Afrilearn n'est pas encore entré en Côte d'Ivoire ni au Bénin

**À éviter :**
- Ne pas sous-estimer Afrilearn — ils ont une traction énorme au Nigeria.
- Ne pas dire « ils ne viendront jamais » — ils pourraient, mais nous serons installés.

---

### Q30. Pourquoi pas juste traduire Khan Academy en français ?

**Réponse courte (30-60 sec) :**
Khan Academy existe déjà en français — le problème n'est pas la langue, c'est l'alignement. Khan Academy enseigne des concepts mathématiques universels (Pythagore, équations), mais ne propose pas de questions tirées des annales BEPC ou BAC togolaises. Les élèves togolais qui utilisent Khan apprennent les mathématiques, mais ne s'entraînent pas au format spécifique de l'examen (coefficients, types de questions, barème APC). C'est la différence entre « apprendre les maths » et « réussir le BEPC ». ExamBoost fait les deux : on enseigne et on entraîne sur le format exact. Khan Academy est complémentaire (cours conceptuels), ExamBoost est spécifique (préparation à l'examen national).

**Chiffres clés à citer :**
- Khan Academy existe déjà en français — pas un problème de langue
- Khan : 0 % d'alignement BEPC/BAC togolais
- ExamBoost : 100 % alignement, annales officielles, format APC

**À éviter :**
- Ne pas dire « Khan ne sert à rien » — c'est faux, c'est complémentaire.
- Ne pas promettre qu'ExamBoost remplacera Khan en contenu conceptuel — on se concentre sur la préparation d'examen.

---

### Q31. Les PDF WhatsApp gratuits ne suffisent-ils pas ?

**Réponse courte (30-60 sec) :**
Les PDF WhatsApp ont trois limites critiques. (1) Ils sont génériques et statiques — pas d'adaptation au niveau de l'élève, pas de planification des révisions. (2) Ils ne donnent aucun feedback — l'élève ne sait pas s'il a réussi, ni pourquoi. (3) Ils sont dispersés et non structurés — pas de carte de progression, pas de vue d'ensemble. ExamBoost fait tout ce que les PDF ne font pas : sélection adaptative IRT, planification SM-2, explications immédiates, tableau de bord de progression, prédiction de score. Et c'est tout aussi gratuit pour l'élève. Le coût marginal de passage du PDF à ExamBoost est nul ; le bénéfice est massif.

**Chiffres clés à citer :**
- PDF WhatsApp : 0 adaptation, 0 feedback, 0 progression
- ExamBoost : IRT adaptatif + SM-2 + BKT + XGBoost prédiction
- Gratuit pour l'élève = même coût que le PDF WhatsApp

**À éviter :**
- Ne pas dénigrer les groupes WhatsApp — c'est l'outil actuel des élèves, il faut montrer qu'on l'améliore, pas qu'on le remplace.
- Ne pas dire « les PDF sont nuls » — dire « ils sont statiques et non structurés ».

---

### Q32. Comment réagissez-vous si le gouvernement lance sa propre app ?

**Réponse courte (30-60 sec) :**
Ce ne serait pas une menace, ce serait une validation du marché et une opportunité. Si le MEPST lance sa propre app, c'est qu'il y a un besoin — ce que nous défendons depuis le début. Notre stratégie serait alors de nous positionner en complément : le gouvernement fait l'app officielle de gestion (inscriptions, résultats), ExamBoost reste l'app de préparation adaptative (le cœur pédagogique). Précédent : au Nigeria, EDVES coexiste avec les plateformes gouvernementales ; au Maroc, Génie OCP coexiste avec les initiatives privées. Et puis, le gouvernement togolais n'a pas vocation à développer un algorithme IRT + BKT — ce n'est pas son cœur de métier.

**Chiffres clés à citer :**
- Précédents : EDVES Nigeria, Génie OCP Maroc (coexistence public/privé)
- Notre cœur de métier : adaptatif IRT + psychométrie (pas gestion administrative)
- Le gouvernement a d'autres priorités (gestion examens, résultats)

**À éviter :**
- Ne pas dire « le gouvernement ne sait pas faire » — c'est arrogant et faux.
- Ne pas dire « on sera rachetés » — c'est présomptueux à ce stade.

---

### Q33. Quelle est votre "moat" (défense contre la concurrence) ?

**Réponse courte (30-60 sec) :**
Quatre fossés défensifs. (1) Localisation profonde : contenu 100 % aligné sur le programme MEPST, en français togolais, avec annales officielles — barrière de 12-18 mois pour un concurrent étranger. (2) Données d'usage : plus nous avons d'utilisateurs, plus l'IRT se calibre précisément, plus le BKT s'affine — c'est un effet réseau de données qu'un nouveau entrant ne peut pas répliquer instantanément. (3) Partenariats institutionnels : relation avec le MEPST et les lycées pilotes créée un verrou relationnel. (4) Stack technique spécialisée : IRT + SM-2 + BKT + XGBoost intégrés nécessitent une expertise psychométrique rare en Afrique de l'Ouest. La combinaison de ces quatre fossés rend une réplication difficile et longue.

**Chiffres clés à citer :**
- Localisation : 12-18 mois d'avance pour un concurrent étranger
- Effet réseau de données : calibration IRT améliorée à chaque utilisateur
- Expertise psychométrique rare en Afrique de l'Ouest

**À éviter :**
- Ne pas dire « nous n'avons pas de concurrents » — c'est faux (Khan, Afrilearn, PDF WhatsApp).
- Ne pas surenchérir avec des brevets — pas pertinent à ce stade.

---

## Thème 6 — Équipe & Exécution (6 questions)

### Q34. Pourquoi cette équipe est-elle la bonne pour réussir ?

**Réponse courte (30-60 sec) :**
Quatre raisons. (1) Connexion directe avec le contexte togolais — nous sommes togolais, nous avons passé le BEPC et le BAC nous-mêmes, nous connaissons les failles du système. (2) Expertise IA/ML via la connexion à AIMS Ghana (African Institute for Mathematical Sciences), qui nous donne accès à des chercheurs en IA appliquée à l'éducation. (3) Profils complémentaires : Tech/Flutter, Data/IA, Design/UX, Marketing/Communication — nous couvrons toute la chaîne de valeur. (4) Passion personnelle pour l'éducation en Afrique — ce n'est pas un projet opportuniste, c'est une mission. Et nous avons déjà démarré le développement, ce qui prouve notre engagement.

**Chiffres clés à citer :**
- 4 profils complémentaires (Tech, Data, Design, Marketing)
- Connexion AIMS Ghana (réseau IA panafricain)
- Développement déjà démarré (20 questions démo, repo GitHub public)

**À éviter :**
- Ne pas dire « nous n'avons pas d'expérience » — valoriser chaque compétence réelle.
- Ne pas promettre des CV impressionnants si on ne les a pas — rester honnête mais confiant.

---

### Q35. Quels sont vos rôles respectifs ?

**Réponse courte (30-60 sec) :**
Quatre rôles clairement assignés. Profil Tech / Développeur : responsable de l'application Flutter + backend FastAPI, maintient le repo GitHub, code les écrans et l'intégration. Profil Data / IA : responsable des algorithmes (IRT, SRS, BKT, XGBoost), du pipeline OCR, du calibrage. Profil Design / UX : responsable des maquettes Figma, de l'expérience utilisateur adaptée aux élèves togolais, du design system. Profil Marketing / Communication : responsable du go-to-market, des relations lycées, de la présence réseaux sociaux (LinkedIn, Instagram), et de l'enquête terrain. Le chef de projet coordonne l'ensemble et gère le fundraising.

**Chiffres clés à citer :**
- 4 profils complémentaires (Tech, Data, Design, Marketing)
- 1 chef de projet coordonnateur
- Équipe complète cible (étude faisabilité) : 10-13 personnes en phase 2

**À éviter :**
- Ne pas être flou sur les rôles (« on fait tous tout ») — c'est un signal négatif pour le jury.
- Ne pas oublier le chef de projet — sans coordination, l'équipe échoue.

---

### Q36. Que faites-vous si vous n'êtes pas sélectionné au DJANTA ?

**Réponse courte (30-60 sec) :**
Nous continuons. DJANTA accélérerait notre trajectoire, mais le projet existe indépendamment. Nous avons déjà démarré le développement — repo GitHub public, 20 questions de démo, écran Flutter fonctionnel. Sans DJANTA, nous poursuivons en bootstrapping : MVP à 40 000-70 000 USD sur 6-8 mois avec une équipe squelette de 4 personnes, focus Lomé uniquement, modèle B2B avec les 10-15 lycées privés de Lomé. Nous postulerons également à d'autres programmes (UNICEF Innovation Fund, AFD Digital Africa, GPE EdTech) qui financent l'EdTech en Afrique. DJANTA est un catalyseur, pas une condition de survie.

**Chiffres clés à citer :**
- MVP bootstrap : 40 000-70 000 USD (équipe squelette 4 personnes)
- Cible sans DJANTA : 10-15 lycées privés Lomé en an 1
- Alternatives : UNICEF Innovation Fund, AFD Digital Africa, GPE EdTech

**À éviter :**
- Ne pas dire « on abandonne » — c'est un signal négatif.
- Ne pas dire « DJANTA ne sert à rien » — c'est faux et impoli.

---

### Q37. Combien de temps pour le MVP complet ?

**Réponse courte (30-60 sec) :**
Six à huit mois depuis le démarrage effectif. Décomposition : M1-M2 = fondations (enquête terrain 200 élèves, partenariat MEPST, recrutement équipe, base de données légale d'annales). M2-M3 = données (OCR + annotation de 2 000 questions BEPC/BAC, calibrage IRT initial, validation pédagogique par 2 enseignants experts). M3-M5 = MVP Flutter (Android only, module révision SRS fonctionnel, simulation BEPC, tableau de bord basique). M5-M6 = pilote (test avec 5 établissements et 300 élèves à Lomé, mesure d'impact sur les notes de contrôle). M7-M8 = itération post-pilote (ajout iOS, prédiction de score, mobile money). Avec le support de la pré-incubation DJANTA, nous visons le pilote 5 lycées à la fin des 3 mois.

**Chiffres clés à citer :**
- MVP complet : 6-8 mois
- Pilote 5 lycées Lomé : fin des 3 mois de pré-incubation DJANTA
- KPI M6 : 300 utilisateurs actifs, 5 établissements partenaires

**À éviter :**
- Ne pas dire « 3 mois pour tout » — c'est irréaliste.
- Ne pas être trop prudent non plus (« 2 ans ») — ça manque d'ambition.

---

### Q38. Avez-vous déjà testé le produit avec de vrais élèves ?

**Réponse courte (30-60 sec) :**
Honnêtement, pas encore en production. Nous avons un prototype papier (mockups Figma des 5 écrans) que nous avons montré à 5 élèves de Terminale à Lomé — leurs retours ont validé l'ergonomie et le besoin. Le prototype Flutter fonctionnel (écran flashcard animé) est prêt et installable. L'enquête terrain (30 élèves sondés) a confirmé la demande : 87 % n'ont aucun outil numérique, 94 % prêts à utiliser ExamBoost. Le premier test utilisateur réel avec APK installable est planifié en M3-M4 avec un groupe de 10-20 élèves volontaires. Nous ne mentons pas sur la traction — nous sommes en phase de validation pré-lancement.

**Chiffres clés à citer :**
- Prototype papier testé sur 5 élèves (retours ergonomie positifs)
- Prototype Flutter fonctionnel (écran flashcard) installable
- Enquête terrain : 30 élèves sondés, 94 % d'intérêt
- Test utilisateurs réel planifié en M3-M4 (10-20 élèves)

**À éviter :**
- Ne pas mentir sur la traction (« des milliers d'utilisateurs ») — le jury s'en rendra compte.
- Ne pas dire « on n'a rien testé » — on a testé le prototype papier et l'enquête terrain.

---

### Q39. Comment allez-vous recruter des enseignants pour valider le contenu ?

**Réponse courte (30-60 sec) :**
Trois canaux. D'abord, le réseau personnel : nous avons déjà identifié 2 enseignants de Lomé (Mathématiques et Français) prêts à valider bénévolement les premières questions, en échange de visibilité. Ensuite, le réseau AIMS Ghana qui connecte avec des enseignants-chercheurs en éducation. Enfin, à partir de M2, nous approchons les syndicats d'enseignants togolais (SNEP, etc.) pour proposer une mission rémunérée de validation pédagogique (2 enseignants experts à temps partiel, budget 15 000 USD sur la phase 1). La validation pédagogique est non négociable — aucune question n'entre dans l'app sans double validation humaine.

**Chiffres clés à citer :**
- 2 enseignants déjà identifiés (Maths + Français) pour validation bénévole initiale
- Budget validation pédagogique phase 1 : 15 000 USD (étude faisabilité)
- Réseau AIMS Ghana pour expertise complémentaire

**À éviter :**
- Ne pas dire « les enseignants valideront gratuitement » — il faut les rémunérer pour un travail sérieux.
- Ne pas oublier les syndicats — ils sont des relais puissants au Togo.

---

## Thème 7 — Marché & Expansion (4 questions)

### Q40. Pourquoi commencer par le Togo et pas directement le Nigeria ?

**Réponse courte (30-60 sec) :**
Trois raisons stratégiques. D'abord, l'éligibilité : nous sommes togolais, nous connaissons le programme MEPST, nous parlons français togolais — notre avantage concurrentiel est au Togo. Le Nigeria est un marché immense mais saturé (Afrilearn, StudyAI, EDVES y sont déjà installés). Ensuite, la profondeur de localisation : pour réussir au Nigeria, il faudrait tout refaire en anglais, sur le curriculum WAEC, avec des partenariats locaux — 12 à 18 mois de travail. Enfin, le Togo est un marché test idéal : 800 000 élèves du secondaire, un écosystème tech naissant (Hub Togo, CTIC, DJANTA Tech Hub), un gouvernement qui digitalise l'éducation. Une fois validés au Togo, nous nous étendons en Afrique de l'Ouest francophone.

**Chiffres clés à citer :**
- Marché Togo : 800 000 élèves du secondaire (TAM)
- Marché Nigeria : saturé (Afrilearn, StudyAI, EDVES installés)
- Coût d'entrée Nigeria : 12-18 mois de localisation anglaise

**À éviter :**
- Ne pas dire « le Togo est trop petit » — c'est faux, c'est un marché test idéal.
- Ne pas promettre l'expansion Nigeria en an 2 — c'est irréaliste.

---

### Q41. Comment allez-vous vous étendre à la CEDEAO ?

**Réponse courte (30-60 sec) :**
Cible : Afrique de l'Ouest francophone — Bénin, Côte d'Ivoire, Burkina Faso, Niger, Guinée — qui partagent des curriculums BEPC/BAC très proches du Togo. Stratégie en trois temps. An 1-2 : consolidation Togo (50 000 utilisateurs actifs, 200 établissements partenaires). An 3 : entrée Bénin et Côte d'Ivoire (curriculums quasi identiques, adaptation principalement linguistique mineure et taguage des annales locales). An 4-5 : Burkina Faso, Niger, Guinée (adaptation plus significative mais marché cumulé de 3 millions d'élèves). Le produit (app Flutter, algorithmes) est réutilisable à 90 % ; seul le contenu (annales + programme MEPST local) doit être re-produit. Modèle économique identique : B2B2C avec bailleurs locaux.

**Chiffres clés à citer :**
- Marché CEDEAO francophone : ~3 millions d'élèves (Bénin, CI, BF, Niger, Guinée)
- An 3 : entrée Bénin + Côte d'Ivoire
- Réutilisation code : 90 % (seul le contenu change)

**À éviter :**
- Ne pas promettre l'expansion en an 1 — c'est prématuré.
- Ne pas dire « tous les programmes sont identiques » — ils sont proches mais pas identiques, il y a un travail d'adaptation.

---

### Q42. Quelle est la taille de votre marché adressable ?

**Réponse courte (30-60 sec) :**
Trois niveaux. TAM (Total Addressable Market) : 800 000 élèves du secondaire au Togo (3ème à Terminale). SAM (Serviceable Addressable Market) : 150 000 candidats BEPC + BAC par an — c'est le cœur de notre cible. SOM (Serviceable Obtainable Market) an 2 : 50 000 utilisateurs actifs ciblés (objectif KPI M18). Au-delà du Togo, le marché CEDEAO francophone représente ~3 millions d'élèves du secondaire — c'est notre potentiel d'expansion à 5 ans. Le boom démographique scolaire (hausse de 20-30 % par an des candidats aux examens) fait que le marché grandit naturellement.

**Chiffres clés à citer :**
- TAM Togo : 800 000 élèves du secondaire
- SAM Togo : 150 000 candidats BEPC + BAC/an
- SOM an 2 : 50 000 utilisateurs actifs (KPI M18)
- CEDEAO francophone : ~3 millions d'élèves
- Hausse démographique : +20-30 % candidats/an

**À éviter :**
- Ne pas gonfler artificiellement le TAM (« 100 millions en Afrique ») — le jury voit ça venir.
- Ne pas confondre TAM (marché total) et SOM (ce qu'on peut réellement obtenir).

---

### Q43. Les programmes Bénin/CI/Burkina sont-ils vraiment identiques ?

**Réponse courte (30-60 sec) :**
Pas identiques, mais très proches. Les pays francophones d'Afrique de l'Ouest partagent un héritage éducatif commun (réforme APC dans la majorité, programmes construits sur la même ossature), mais chaque pays a ses spécificités. Par exemple, le Bénin a un BEPC quasi identique au Togo (même structure, mêmes matières principales), mais le BAC ivoirien diffère sur certaines séries (le BAC D ivoirien n'est pas exactement le BAC D togolais). Notre stratégie d'expansion est pragmatique : nous adaptons le taguage des compétences et les annales à chaque pays, mais les algorithmes (IRT, SM-2, BKT, XGBoost) et l'app Flutter sont réutilisables à 90 %. Le coût d'adaptation par pays est estimé à 3-6 mois de travail.

**Chiffres clés à citer :**
- Bénin : BEPC quasi identique au Togo (adaptation minimale)
- Côte d'Ivoire : BAC séries D différentes (adaptation moyenne)
- Burkina : APC commune mais annales différentes
- Coût adaptation par pays : 3-6 mois

**À éviter :**
- Ne pas dire « c'est exactement le même programme » — c'est faux, le jury le sait.
- Ne pas sous-estimer le travail d'adaptation — il est réel mais gérable.

---

## Thème 8 — Risques & Limites (5 questions)

### Q44. Que faites-vous si les élèves trichent (regardent la réponse avant de répondre) ?

**Réponse courte (30-60 sec) :**
C'est un risque réel, mais ses conséquences sont auto-limitantes. Si un élève triche (regarde la réponse avant de se noter q=5), il fausse son propre calibrage — l'algorithme SM-2 va espacer ses révisions à tort, et il oubliera réellement le contenu. À l'examen blanc, il échouera. Trois mécanismes de mitigation. (1) Le mode « examen authentique » (simulation chronométrée) ne montre pas la réponse avant la fin — c'est la mesure réelle. (2) Nous collectons le temps de réponse par question : un temps < 3 secondes avec réponse « parfaite » est un signal de tricherie, et l'algorithme peut le détecter. (3) À terme, la prédiction XGBoost compare les scores SRS (auto-évalués) aux scores simulation (objectifs) — un écart systématique de +2 points est un signal d'alerte envoyé à l'enseignant.

**Chiffres clés à citer :**
- Détection temps < 3 sec avec q = 5 = signal de tricherie
- Écart SRS vs simulation > 2 pts = alerte enseignant
- Mode examen authentique = mesure objective non truquable

**À éviter :**
- Ne pas dire « on ne peut pas tricher » — c'est faux.
- Ne pas être moralisateur (« les élèves ne doivent pas tricher ») — pragmatique : la triche se auto-punit.

---

### Q45. Comment gérez-vous l'addiction au smartphone ?

**Réponse courte (30-60 sec) :**
C'est une préoccupation légitime. ExamBoost est conçu pour un usage ciblé : 30 minutes par jour suffisent grâce à la répétition espacée (SM-2 planifie exactement ce qu'il faut réviser). Nous intégrons trois mécanismes anti-addiction. (1) Notifications limitées : 1 rappel quotidien maximum, configurable. (2) Mode « focus » : pas de notifications push pendant les sessions, pas de scroll infini, pas de récompenses addictives type TikTok. (3) Tableau de bord de temps d'usage : l'élève voit combien de temps il a passé, et nous recommandons un plafond de 30 minutes par jour. Notre objectif n'est pas le temps d'écran maximal — c'est l'efficacité pédagogique. 30 minutes d'ExamBoost valent mieux que 3 heures de scrolling WhatsApp.

**Chiffres clés à citer :**
- Cible : 30 min/jour (vs 3h scrolling WhatsApp)
- 1 notification quotidienne max, configurable
- SM-2 = efficacité maximale par minute révisée

**À éviter :**
- Ne pas dire « l'addiction n'est pas un problème » — c'est un sujet sensible pour les parents.
- Ne pas promettre un mode « sans notifications » par défaut — il en faut au moins une pour le rappel.

---

### Q46. Que se passe-t-il si le gouvernement interdit les phones en classe ?

**Réponse courte (30-60 sec) :**
ExamBoost n'a pas vocation à être utilisé pendant les cours — c'est un outil de préparation hors classe. L'élève l'utilise chez lui, dans le bus, à la bibliothèque. Une interdiction des phones en classe ne nous impacte donc pas directement. De plus, même si une telle interdiction était promulguée, elle ne s'appliquerait qu'aux heures de cours — pas aux révisions personnelles. Et le boom de la pénétration mobile (> 100 % au Togo selon ARCEP) montre que le téléphone est devenu l'outil principal d'accès à l'information pour les jeunes. Un retour en arrière est peu probable. Enfin, nous proposons aussi une version web pour les enseignants et directeurs (phase 2), qui peut être utilisée sur ordinateur en classe.

**Chiffres clés à citer :**
- Pénétration mobile > 100 % au Togo (ARCEP T3-2025)
- Usage ExamBoost = hors classe (chez soi, transport, bibliothèque)
- Version web enseignants prévue en phase 2

**À éviter :**
- Ne pas paraître antagoniste au gouvernement — respecter la politique éducative.
- Ne pas dire « le gouvernement ne fera jamais ça » — c'est présomptueux.

---

### Q47. Comment garantissez-vous la protection des données des élèves (loi 2019-014) ?

**Réponse courte (30-60 sec) :**
Conformité stricte avec la loi n° 2019-014 du 29 octobre 2019 relative à la protection des données personnelles au Togo. Trois piliers. (1) Minimisation : nous collectons uniquement ce qui est strictement nécessaire — pas de nom complet si un pseudonyme suffit, pas de géolocalisation, pas de données biométriques. (2) Consentement explicite à l'inscription, avec information claire sur les données collectées et leur usage. (3) Anonymisation systématique pour l'entraînement des modèles ML — les réponses (0/1) sont découplées de l'identité de l'élève dans les datasets d'entraînement. De plus, nous suivons les guidelines DJANTA Tech Hub sur la sécurité by design (OWASP, JWT, HTTPS/TLS, journalisation des actions sensibles). Audit de conformité prévu en M6.

**Chiffres clés à citer :**
- Loi 2019-014 du 29 octobre 2019 (protection données Togo)
- Guidelines DJANTA : OWASP, JWT, HTTPS/TLS 1.2+
- Anonymisation systématique pour ML
- Audit conformité prévu en M6

**À éviter :**
- Ne pas dire « on ne collecte rien » — on collecte des réponses, c'est nécessaire pour l'IRT/BKT.
- Ne pas oublier la loi togolaise spécifique — la mentionner explicitement rassure le jury.

---

### Q48. Que faites-vous si votre app n'améliore pas réellement les notes ?

**Réponse courte (30-60 sec) :**
C'est le risque le plus sérieux, et nous le prenons en charge scientifiquement. D'abord, les précédents sont encourageants : Khan Academy a amélioré les notes de 16 % en Inde (étude CEPR/J-PAL), et les plateformes adaptatives augmentent les taux de réussite de 10 à 20 points en 12-18 mois chez les utilisateurs réguliers. Ensuite, nous mesurons l'impact dès le pilote : comparaison des notes de contrôle trimestriel entre élèves utilisateurs et non-utilisateurs dans 5 lycées de Lomé (M5-M6). Si l'impact est insuffisant, nous pivottons : analyse des features qui marchent (révision SRS, simulation, explications) et de celles qui ne marchent pas, itération sur le produit, re-test. Si après 2 itérations l'impact reste nul, nous serons transparents avec nos bailleurs et lycées partenaires — c'est une question d'intégrité scientifique.

**Chiffres clés à citer :**
- Précédent Khan Academy Inde : +16 % notes (CEPR/J-PAL)
- Plateformes adaptatives : +10 à +20 pts en 12-18 mois
- KPI M6 pilote : +8 pts aux contrôles trimestriels (utilisateurs vs non-utilisateurs)

**À éviter :**
- Ne pas dire « on améliorera forcément les notes » — c'est présomptueux sans preuves pilotes.
- Ne pas promettre +20 points au lancement — viser +8 pts (KPI M6) est plus crédible.

---

## Thème 9 — Impact social & Mesure (4 questions)

### Q49. Comment allez-vous mesurer l'impact réel sur les notes ?

**Réponse courte (30-60 sec) :**
Méthodologie scientifique en trois temps. (1) Pilote M5-M6 : 5 lycées de Lomé, 300 élèves volontaires randomisés en 2 groupes (utilisateurs ExamBoost vs groupe contrôle non-utilisateurs). Comparaison des notes de contrôle trimestriel en Maths et Français. (2) Suivi longitudinal M6-M18 : suivi des mêmes élèves jusqu'au BEPC 2026 pour comparer le taux de réussite vs cohorte non-utilisatrice. (3) Publication transparente : un rapport d'impact annuel public, méthodologie incluse, y compris les résultats négatifs. Nous collaborons avec AIMS Ghana pour la validation statistique (test t, taille d'effet Cohen's d). Sans cette rigueur, l'impact n'est qu'un slogan marketing.

**Chiffres clés à citer :**
- Pilote : 5 lycées, 300 élèves, randomisation utilisateurs vs contrôle
- KPI M6 : +8 pts ; M12 : +12 pts ; M18 : +15 pts
- Validation statistique : test t, Cohen's d (AIMS Ghana)

**À éviter :**
- Ne pas dire « on sera l'app qui change tout » — c'est un slogan vide.
- Ne pas promettre des résultats sans groupe contrôle — c'est non scientifique.

---

### Q50. Quelle est votre cible d'ici 18 mois en termes d'utilisateurs ?

**Réponse courte (30-60 sec) :**
Trajectoire en trois paliers. M6 (pilote) : 300 utilisateurs actifs/mois, 5 établissements partenaires, rétention 30 jours > 40 %. M12 (croissance) : 5 000 utilisateurs actifs/mois, 50 établissements partenaires, rétention > 50 %, +12 pts d'amélioration aux contrôles. M18 (consolidation) : 50 000 utilisateurs actifs/mois, 200 établissements partenaires, rétention > 60 %, +15 pts d'amélioration. À 50 000 utilisateurs actifs, nous représentons environ 33 % du SAM togolais (150 000 candidats BEPC+BAC par an) — c'est ambitieux mais atteignable si nous signons avec le MEPSK pour un déploiement national.

**Chiffres clés à citer :**
- M6 : 300 users, 5 écoles, +8 pts
- M12 : 5 000 users, 50 écoles, +12 pts
- M18 : 50 000 users, 200 écoles, +15 pts
- 50 000 = 33 % du SAM togolais

**À éviter :**
- Ne pas promettre 100 000 utilisateurs en M12 — c'est irréaliste.
- Ne pas oublier la rétention — un utilisateur inscrit n'est pas un utilisateur actif.

---

### Q51. Comment garantissez-vous l'équité filles/garçons, urbain/rural ?

**Réponse courte (30-60 sec) :**
L'équité est un principe de conception. Trois mesures concrètes. (1) Mode offline : indispensable pour l'élève de Dapaong ou Sokodé qui n'a pas de 4G. Sans offline, ExamBoost serait un outil de Loméens — pas acceptable. (2) Gratuité pour l'élève : supprime la barrière financière qui exclurait les filles (souvent désavantagées dans l'allocation du budget familial à l'éducation) et les ruraux. (3) Mesure systématique : nous suivons le genre, la région et le type d'établissement (public/privé, urbain/rural) dans nos KPIs. Si nous détectons un déséquilibre (par exemple, < 40 % de filles), nous lançons une action corrective (campagne ciblée, partenariat avec une ONG genre). L'équité n'est pas un slogan, c'est une métrique suivie.

**Chiffres clés à citer :**
- Mode offline = équité rurale (vs 46-57 % non-conformité réseau rural, ARCEP)
- Gratuité = équité financière (revenu/habitant Togo : 2 390 USD PPP)
- Suivi genre + région + type d'établissement dans KPIs

**À éviter :**
- Ne pas dire « on traite tout le monde pareil » — c'est naïf, les inégalités existent.
- Ne pas promettre 50 % de filles dès M6 — c'est difficile, il faut l'objectiver.

---

### Q52. Allez-vous publier vos résultats d'impact ?

**Réponse courte (30-60 sec) :**
Oui, intégralement et publiquement. Un rapport d'impact annuel sera publié sur notre site et sur le repo GitHub public, incluant : méthodologie, taille d'échantillon, groupe contrôle, résultats statistiques (test t, taille d'effet), et — c'est important — les résultats négatifs ou non concluants. Cette transparence est non négociable pour trois raisons. (1) Intégrité scientifique : sans publication transparente, l'impact n'est qu'un slogan. (2) Confiance des bailleurs : GPE, UNICEF, AFD exigent une mesure rigoureuse. (3) Amélioration continue : publier ses échecs permet d'apprendre. Nous collaborons avec AIMS Ghana pour la validation statistique indépendante. Si les résultats sont décevants, nous le dirons — et nous pivoterons.

**Chiffres clés à citer :**
- Rapport d'impact annuel public (site + GitHub)
- Validation statistique indépendante AIMS Ghana
- Inclusion des résultats négatifs

**À éviter :**
- Ne pas dire « nos résultats seront toujours positifs » — c'est présomptueux.
- Ne pas rechigner à publier — la transparence est un avantage concurrentiel pour la confiance.

---

## Thème 10 — Questions "pièges" difficiles (5 questions)

### Q53. Pourquoi vous et pas une autre équipe ?

**Réponse courte (30-60 sec) :**
Quatre raisons concrètes, pas des slogans. (1) Connexion personnelle : nous sommes togolais, nous avons nous-mêmes subi les failles du système (BEPC, BAC), nous connaissons le programme MEPST de l'intérieur. Une équipe étrangère mettrait 12 mois juste pour comprendre le contexte. (2) Expertise technique réelle : nous avons déjà codé 3 algorithmes ML (SM-2, BKT, IRT 3PL) dans le repo GitHub public — ce n'est pas une promesse, c'est un fait. (3) Réseau AIMS Ghana : accès à des chercheurs en IA appliquée à l'éducation, validation scientifique de nos modèles. (4) Engagement : nous avons démarré le développement avant même de postuler à DJANTA — nous ne sommes pas là pour attendre, nous sommes là pour construire. Le jury DJANTA cherche exactement ce profil.

**Chiffres clés à citer :**
- 3 algorithmes ML déjà implémentés (SM-2, BKT, IRT 3PL) dans repo GitHub public
- Équipe togolaise (connait MEPST de l'intérieur)
- Réseau AIMS Ghana (validation scientifique)
- Développement démarré avant candidature DJANTA

**À éviter :**
- Ne pas dire « on est les meilleurs » — c'est arrogant.
- Ne pas être modeste à l'excès (« on ne sait pas si on est les bons ») — ça manque de confiance.

---

### Q54. Si vous aviez 1 million USD demain, que feriez-vous ?

**Réponse courte (30-60 sec) :**
Déploiement en trois temps sur 24 mois, en restant discipliné. (1) 40 % pour l'équipe (400 000 USD) : recrutement immédiat de l'équipe complète de 10-13 personnes (2 développeurs Flutter, 1 backend, 1 data scientist, 2 enseignants experts, 3-5 opérateurs saisie, 1 designer, 1 community manager) sur 24 mois. (2) 30 % pour le contenu et les données (300 000 USD) : OCR et annotation de 6 000 questions BEPC/BAC, validation pédagogique systématique, calibrage IRT avec 1 000+ élèves pilotes. (3) 30 % pour l'expansion terrain (300 000 USD) : enquêtes 5 villes, pilote 50 lycées, lancement public national, campagne marketing lycées, début expansion Bénin en an 2. Pas d'achats inutiles, pas de bureaux luxueux — l'argent va dans l'équipe et le contenu.

**Chiffres clés à citer :**
- 40 % équipe (400k USD) : 10-13 personnes sur 24 mois
- 30 % contenu/données (300k USD) : 6 000 questions + calibrage IRT
- 30 % expansion (300k USD) : 50 lycées pilotes + lancement national

**À éviter :**
- Ne pas dire « on lèverait plus » — c'est présomptueux.
- Ne pas promettre l'expansion 5 pays immédiate — rester discipliné.

---

### Q55. Quelle est la pire chose qui pourrait arriver à ExamBoost ?

**Réponse courte (30-60 sec) :**
Trois scénarios noirs, dans l'ordre de gravité. (1) Une erreur pédagogique majeure non détectée : une question avec une mauvaise réponse publiée à 10 000 élèves, qui perdent confiance en l'app et discréditent le produit auprès des enseignants. Mitigation : double validation pédagogique systématique + mécanisme de signalement in-app. (2) Un échec d'adoption : les élèves téléchargent l'app mais ne l'utilisent pas régulièrement — c'est le risque numéro 1 dans l'EdTech africaine. Mitigation : gamification, engagement des établissements, sessions supervisées. (3) Une concurrence subventionnée par le gouvernement : si l'État lance une app gratuite et nous coupe l'accès au MEPST. Mitigation : nous positionner en complément, pas en concurrent. Aucun de ces scénarios n'est fatal — tous sont gérables avec la bonne exécution.

**Chiffres clés à citer :**
- Risque #1 : contenu erroné (mitigation = double validation)
- Risque #2 : adoption faible (mitigation = gamification + écoles)
- Risque #3 : concurrence gouvernementale (mitigation = complémentarité)

**À éviter :**
- Ne pas dire « rien de grave ne peut arriver » — c'est naïf.
- Ne pas paraître anxieux — rester serein face aux risques.

---

### Q56. Êtes-vous sûrs que les élèves togolais utiliseront vraiment une app pour réviser ?

**Réponse courte (30-60 sec) :**
Honnêtement, ce n'est pas garanti — c'est notre risque numéro 1. Mais trois éléments nous donnent confiance. (1) L'enquête terrain : 94 % des 30 élèves sondés à Lomé ont exprimé un intérêt. C'est un signal fort, à confirmer à plus large échelle. (2) Les précédents : Afrilearn au Nigeria, EDVES au Nigeria (2 300+ écoles), Génie OCP au Maroc — l'adoption d'apps éducatives en Afrique est prouvée. (3) Le design d'engagement : nous ne comptons pas sur la motivation intrinsèque seule — gamification (points, badges, classements inter-établissements), coaching par les pairs, notifications SMS, mode examen authentique. Si malgré cela l'adoption reste faible après le pilote M5-M6, nous pivoterons le design d'engagement. Mais nous ne mentons pas : c'est un risque réel que nous prenons au sérieux.

**Chiffres clés à citer :**
- 94 % des 30 élèves sondés à Lomé intéressés
- Précédents : Afrilearn, EDVES (2 300+ écoles), Génie OCP
- Engagement : gamification + classements + coaching pairs + SMS

**À éviter :**
- Ne pas dire « oui, certainement » — c'est faux, c'est un risque.
- Ne pas paraître défaitiste — montrer qu'on a un plan d'engagement sérieux.

---

### Q57. Ne pensez-vous pas que l'IA va remplacer les enseignants, pas les aider ?

**Réponse courte (30-60 sec) :**
Au contraire. ExamBoost est conçu comme un outil qui augmente l'enseignant, pas qui le remplace. Trois arguments concrets. (1) L'app gère la pratique individuelle (répétition, exercices, simulations) — ce qui libère l'enseignant pour ce que lui seul peut faire : expliquer des concepts complexes, animer des débats, donner un feedback humain, gérer la dynamique de classe. (2) Le tableau de bord enseignant (B2B) lui donne une vue agrégée de sa classe : quels élèves sont en retard sur quelle compétence, qui est à risque de décrochage (modèle RF + SHAP). C'est un assistant pédagogique, pas un concurrent. (3) Nous recrutons des enseignants pour valider le contenu — ils sont partie prenante du produit. L'IA remplace les tâches répétitives, jamais l'humain pédagogique. C'est l'IA qui outille l'enseignant, pas l'IA qui remplace l'enseignant.

**Chiffres clés à citer :**
- Tableau de bord enseignant : vue agrégée classe, alertes élèves à risque
- Modèle décrochage : Random Forest + SHAP (rappel ≥ 80 %)
- Enseignants recrutés pour validation pédagogique (partie prenante)

**À éviter :**
- Ne pas paraître défensif — répondre sereinement.
- Ne pas dire « l'IA ne remplacera jamais rien » — c'est faux, l'IA remplace déjà certaines tâches. Préciser : elle remplace les tâches répétitives, pas l'humain pédagogique.

---

## Thème 11 — Modules Session 3-4 : tuteur IA, gamification, sync, ML avancé, parent, devoirs, sécurité (20 questions)

### Q58. Comment fonctionne le tuteur IA ? Quel modèle utilisez-vous ?

**Réponse courte (30-60 sec) :**
Le tuteur IA est un chat conversationnel intégré à l'app, accessible depuis l'écran home. Côté backend, nous utilisons l'API Claude d'Anthropic (modèle claude-sonnet-4-6 par défaut, configurable via variable d'environnement). Le système prompt est calibré pour le contexte togolais : méthode socratique (le tuteur pose des questions avant de donner la solution), exemples en FCFA, références aux villes de Lomé et Kara, vocabulaire BEPC/BAC. Rate limiting à 30 questions/heure/élève pour éviter l'abus. Fallback mock si la clé API est absente (mode démo). Voice input est préparé via speech_to_text, masqué sur desktop/web.

**Chiffres clés à citer :**
- Modèle : Claude (claude-sonnet-4-6), Anthropic
- Rate limit : 30 req/h/user, max 2 000 tokens/réponse, historique 10 derniers tours
- Méthode socratique — pas de réponse directe

**À éviter :**
- Ne pas dire « notre IA » — préciser Claude API d'Anthropic (transparence).
- Ne pas promettre la voix en production v1 — c'est un stub UI en attente d'activation.

---

### Q59. Le tuteur donne-t-il les réponses aux exercices ?

**Réponse courte (30-60 sec) :**
Non — c'est central dans notre design. Le system prompt impose la méthode socratique : le tuteur guide l'élève par des questions (« Qu'as-tu essayé ? », « Quelle formule pourrais-tu appliquer ? ») au lieu de cracher la solution. Si l'élève insiste après trois échanges, le tuteur peut donner un indice, puis la solution accompagnée de l'explication. L'objectif est l'apprentissage, pas la réponse. C'est aussi pour cela que le tuteur est séparé de l'écran de révision (où la réponse n'apparaît qu'après que l'élève a validé sa propre réponse via SM-2).

**Chiffres clés à citer :**
- System prompt socratique (pas de réponse directe)
- Tuteur = écran séparé (différent de révision SM-2)
- Historique limité à 10 tours (évite dépendance)

**À éviter :**
- Ne pas dire « jamais » — il y a des cas où le tuteur donne la solution (élève bloqué après 3 échanges). Dire « en dernier recours, avec explication ».

---

### Q60. Que se passe-t-il si le tuteur IA donne une mauvaise réponse ?

**Réponse courte (30-60 sec) :**
Trois garde-fous. (1) L'élève peut signaler une mauvaise réponse — un bouton dédié est prévu dans la bulle de message, qui logge l'échange pour revue pédagogique. (2) Le tuteur ne remplace jamais l'enseignant ni le contenu officiel — les annales MEPST restent la source de vérité. (3) En cas d'erreur factuelle grave, l'élève peut effacer la conversation et recommencer. Nous mesurons le taux de signalement comme KPI produit : cible < 5 % des conversations. Au-delà, on ajuste le system prompt ou on bascule sur un modèle plus récent.

**Chiffres clés à citer :**
- Bouton « signaler » sur chaque bulle IA
- KPI : < 5 % conversations signalées
- Annales MEPST = source de vérité (le tuteur est secondaire)

**À éviter :**
- Ne pas promettre « 0 % d'erreur » — c'est impossible avec un LLM. Mieux : « taux d'erreur mesuré, gardé sous 5 % ».

---

### Q61. Les badges ne risquent-ils pas de détourner l'élève de l'apprentissage ?

**Réponse courte (30-60 sec) :**
C'est une préoccupation légitime — c'est pourquoi nous avons conçu 39 badges alignés sur des comportements d'apprentissage, pas sur le temps passé. Les catégories : Streak (régularité), Révision (volume de questions), Maîtrise (P(L)≥0,85 sur une matière), Simulation (examens blancs), Spécial (signalisation de bug, beta testeur). Aucun badge ne récompense « 3 heures d'app » — tous sont liés à des actions pédagogiques mesurables. Les badges sont aussi bornés : 3 niveaux (Bronze, Argent, Or), XP 100/250/500, total max ~12 875 XP. Une fois le catalogue complet, l'élève n'a plus d'incitation à farmer.

**Chiffres clés à citer :**
- 39 badges en 5 catégories (Streak 9, Révision 9, Maîtrise 9, Simulation 9, Spécial 3)
- 3 niveaux par badge (Bronze/Argent/Or) — XP 100/250/500
- Aucun badge sur « temps passé » — tous sur actions pédagogiques

**À éviter :**
- Ne pas dire « la gamification ne pose jamais de problème » — reconnaître le risque et expliquer comment le design le mitigate.

---

### Q62. Comment évitez-vous la gamification toxique (addiction) ?

**Réponse courte (30-60 sec) :**
Quatre dispositifs. (1) Pas de notifications push agressives — une seule notification quotidienne à l'heure choisie par l'élève (réglable, désactivable). (2) Pas de mécanique de FOMO : pas de récompenses limitées dans le temps, pas de streaks qui se brisent avec des popups alarmistes. (3) Le streak tolérant accepte « hier OU aujourd'hui » — pas de punition à minuit. (4) Tableau de bord parent (module premium) qui alerte si l'usage dépasse un seuil (par défaut 2 h/jour) — la gamification est contre-balancée par une vigilance parentale. L'objectif est 30 min/jour en moyenne, pas 3 h en soirée.

**Chiffres clés à citer :**
- 1 notification/jour max (réglable + désactivable)
- Streak tolérant (hier OU aujourd'hui)
- Alerte parent seuil 2 h/jour (module premium)
- Cible usage : 30 min/jour moyen

**À éviter :**
- Ne pas évoquer les mécaniques addictives type « loot boxes » ou « daily rewards » — nous n'en avons pas, et les mentionner sèmerait le doute.

---

### Q63. Comment gérez-vous les conflits si l'élève révisait offline et online simultanément ?

**Réponse courte (30-60 sec) :**
Architecture offline-first avec CRDT (Conflict-free Replicated Data Types). Chaque action utilisateur est horodatée localement et mise dans une file d'attente Hive persistante. Au retour réseau, le backend applique les actions avec une stratégie de résolution par type : LWW (Last-Write-Wins) pour les ReviewCard (la plus récente l'emporte sur lastReviewDate), conservateur (min) pour les P(L) BKT en cas d'égalité, union pour les badges (aucun badge ne se « perd »), max pour les compteurs. Le tout est idempotent grâce à une table `sync_applied_actions` indexée par action_id (UUID client). Backoff exponentiel 1/2/4/8/16/32s en cas d'échec.

**Chiffres clés à citer :**
- CRDT : LWW pour ReviewCard, conservateur min pour BKT, union pour badges, max pour compteurs
- Idempotence backend via table sync_applied_actions (clé UUID client)
- 5 endpoints FastAPI (/sync/action, /sync/batch max 50, /sync/status, /sync/pull, /sync/health)
- Backoff exponentiel 1→32s, stop après 5 échecs consécutifs

**À éviter :**
- Ne pas dire « il n'y a jamais de conflit » — c'est faux. Dire : « conflits gérés par CRDT, stratégie par type de donnée ».

---

### Q64. Que se passe-t-il si l'élève perd son téléphone ? Perd-il sa progression ?

**Réponse courte (30-60 sec) :**
Non, à condition qu'il ait synchronisé au moins une fois. La sync cloud est activée par défaut sur WiFi (configurable sur mobile data). Chaque réponse SM-2, mise à jour BKT, résultat de simulation, badge débloqué est poussé vers le backend. Au reinstall sur un nouveau téléphone, l'élève se reconnecte avec son compte, l'app tire l'état complet via /sync/pull?since=0. Cas limite : un élève qui n'a jamais sync (par exemple 100 % offline en zone rurale sans aucun retour WiFi) perd sa progression locale — c'est pourquoi nous poussons une notification de sync toutes les 24 h si données en attente. Le compte lui-même (email + mot de passe + niveau scolaire) est toujours récupérable côté backend.

**Chiffres clés à citer :**
- Sync cloud activée par défaut sur WiFi (mobile data configurable)
- Pull complet via /sync/pull?since=0 au reinstall
- Notification rappel sync toutes les 24 h si file non vide

**À éviter :**
- Ne pas dire « 0 perte possible » — reconnaître le cas « 100 % offline sans jamais sync » et expliquer la mitigation (notification + auto-sync).

---

### Q65. Vous dites que l'IA est calibrée — sur quelles données ?

**Réponse courte (30-60 sec) :**
Pour la calibration IRT, nous utilisons actuellement un dataset synthétique de 500 élèves × 64 questions = 32 000 réponses générées avec theta ~ N(0,1) tronqué [-3,+3] et 5 % de bruit (inattentions), avec temps de réponse corrélé à |theta - b|. Le pipeline py-irt est en place mais py-irt 0.1.1 (version PyPI) ne supporte que 1PL/2PL — nous avons donc un fallback numpy MLE (EM-like alterné) pour la calibration 3PL complète (avec estimation du paramètre c pour les QCM). C'est transparent : dès le pilote M5-M6 avec 300-500 vrais élèves, on remplace le CSV synthétique par les vraies données PostgreSQL via le script `train_score_model.py`. La calibration est ensuite relancée mensuellement.

**Chiffres clés à citer :**
- Pipeline actuel : 500 élèves synthétiques × 64 questions = 32 000 réponses
- py-irt 0.1.1 (1PL/2PL) + fallback numpy MLE pour 3PL
- Calibration relancée mensuellement dès pilote M5-M6 (300-500 vrais élèves)
- Script reproductible : random_state=42

**À éviter :**
- Ne pas cacher le caractère synthétique — dire clairement « phase de bootstrap sur données synthétiques, remplacement par vraies données dès le pilote ».

---

### Q66. Pourquoi XGBoost plutôt qu'un réseau de neurones ?

**Réponse courte (30-60 sec) :**
Trois raisons. (1) Interprétabilité : XGBoost est compatible SHAP (TreeExplainer polynomial de Lundberg 2020), ce qui permet d'expliquer chaque prédiction au jury, à l'enseignant, à l'élève (« ton score prédit est bas parce que ta P(L) en maths est faible et que l'examen est dans 30 jours »). Un réseau de neurones est une boîte noire. (2) Performance sur petit dataset : avec 5 000 élèves, XGBoost régularisé (max_depth=3, lr=0,01, n_estimators=500) généralise mieux qu'un NN qui overfit. Nos métriques : RMSE 1,466/20, MAE 1,183/20, R² 0,663. (3) Coût de déploiement : XGBoost se sérialise en 589 Ko joblib, inférence en millisecondes, pas de GPU. Un NN nécessiterait PyTorch/TensorFlow + serveur GPU — inenvisageable pour un projet à 246 400 USD.

**Chiffres clés à citer :**
- XGBoost : RMSE 1,466/20, MAE 1,183/20, R² 0,663
- SHAP TreeExplainer — interprétabilité native
- Modèle sérialisé 589 Ko joblib (vs NN + PyTorch/TensorFlow + GPU)
- Grid search 54 combinaisons 5-fold CV — best params max_depth=3, lr=0,01, n_estimators=500

**À éviter :**
- Ne pas dire « XGBoost est meilleur que les réseaux de neurones partout » — c'est faux. Dire : « meilleur pour notre contexte : petit dataset, besoin d'interprétabilité, contrainte coût ».

---

### Q67. Le DKT (Deep Knowledge Tracing) est mentionné — l'utilisez-vous en production ?

**Réponse courte (30-60 sec) :**
Non, pas en production. DKT (Piech et al. 2015) est mentionné dans notre cours théorique comme référence scientifique de l'état de l'art en knowledge tracing. En production, nous utilisons BKT (Bayesian Knowledge Tracing) classique — implémenté côté Dart (user.dart) et côté Python (bkt_service.py) — parce qu'il est interprétable (P(L) par compétence), léger (formules bayésiennes, pas de NN), et bien adapté à un dataset petit. DKT nécessite un réseau de neurones récurrent (LSTM/GRU) entraîné sur des dizaines de milliers d'élèves — incompatible avec notre phase pilote. C'est une piste d'évolution M18+ si nous atteignons 50 000+ utilisateurs avec données suffisantes.

**Chiffres clés à citer :**
- BKT en production (P(L) par compétence, formules bayésiennes)
- DKT = piste M18+ (nécessite 50 000+ utilisateurs)
- Référence : Piech et al. 2015 (Deep Knowledge Tracing, Stanford)
- Paramètres BKT actuels : pLearn=0,20, pSlip=0,10, pGuess=0,20

**À éviter :**
- Ne pas dire « nous utilisons DKT » — c'est faux. Honnêteté radicale : BKT aujourd'hui, DKT en étude future.

---

### Q68. Le module parent est-il payant ?

**Réponse courte (30-60 sec) :**
Le module parent de base (login + 4 onglets : enfants, progression, alertes, messages enseignant) est gratuit pour les parents d'élèves inscrits. Le module parent premium est payant, avec 3 plans : Essentiel à 2 000 FCFA/mois (1 enfant), Famille à 5 000 FCFA/mois (jusqu'à 3 enfants, le plus populaire), Trimestre à 4 800 FCFA pour 3 mois (économie 20 %). Paiement via Flooz, TMoney ou carte bancaire. Essai gratuit 14 jours. Le premium débloque les alertes avancées (décrochage, chute de notes), le chat direct avec l'enseignant, et l'export PDF du bulletin de progression.

**Chiffres clés à citer :**
- Base gratuit (login + 4 onglets) ; premium à 2 000 FCFA/mois (Essentiel) ou 5 000 FCFA/mois (Famille, 3 enfants)
- 3 méthodes de paiement : Flooz, TMoney, carte bancaire
- Essai gratuit 14 jours

**À éviter :**
- Ne pas dire « le module parent est gratuit » sans nuance — préciser base gratuite, premium payant.

---

### Q69. Comment protégez-vous la vie privée des élèves vis-à-vis des parents ?

**Réponse courte (30-60 sec) :**
Le parent ne voit que ce que l'élève (ou l'école) autorise. Concrètement : (1) le parent doit avoir le code à 6 chiffres de son enfant pour lier son compte — l'élève a le contrôle ; (2) le parent voit la progression académique (P(L), scores simulation, badges), pas le contenu des conversations avec le tuteur IA ni les messages aux enseignants ; (3) aucune donnée de localisation, aucun historique de navigation hors app ; (4) le parent premium peut activer le seuil d'alerte « usage > 2 h/jour » mais ne voit pas le détail minute par minute. Conformément à la loi 2019-014 du Togo, l'élève mineur (avec l'école) reste titulaire des données — le parent est « tuteur légal autorisé » sur les données académiques uniquement.

**Chiffres clés à citer :**
- Code 6 chiffres pour lier parent (élève = Contrôleur)
- Parent voit académique uniquement (pas tuteur IA, pas messages enseignants)
- Loi 2019-014 Togo : élève mineur = titulaire, parent = tuteur autorisé

**À éviter :**
- Ne pas dire « le parent voit tout » — c'est faux et contraire à la loi 2019-014. Préciser le périmètre académique uniquement.

---

### Q70. Les enseignants doivent-ils créer leurs propres questions ?

**Réponse courte (30-60 sec) :**
Non, ce n'est pas obligatoire — mais c'est possible. Le module devoirs permet à l'enseignant de soit piocher dans la banque ExamBoost (114 questions BEPC/BAC couvrant 6 matières, 2019-2024), soit créer ses propres QCM via un formulaire (énoncé + 4 choix + indice du bon choix + explication). Pour les questions ouvertes (rédaction, dissertation), l'enseignant saisit le sujet et l'élève s'auto-évalue après coup. Le mode hybride est le plus courant : 80 % banque ExamBoost + 20 % questions personnalisées. L'objectif n'est pas de transformer l'enseignant en créateur de contenu — c'est de lui donner le choix pédagogique.

**Chiffres clés à citer :**
- 114 questions dans la banque ExamBoost (6 matières, BEPC 84 + BAC1 30)
- Mode hybride recommandé : 80 % banque + 20 % perso
- Auto-correction QCM immédiate, auto-évaluation pour questions ouvertes

**À éviter :**
- Ne pas dire « les enseignants doivent créer leurs questions » — c'est un repoussoir. Dire : « ils peuvent, mais la banque couvre déjà le besoin principal ».

---

### Q71. Comment gérez-vous la triche si l'élève fait le devoir à la maison ?

**Réponse courte (30-60 sec) :**
Honnêtement, on ne l'élimine pas — on la minimise et on la détecte. (1) Le devoir n'est qu'un signal parmi d'autres : si l'élève a 18/20 au devoir maison mais 8/20 à la simulation surveillée, l'enseignant le voit dans le tableau de bord (écart devoir vs simulation). (2) Auto-correction QCM immédiate mais score final calculé à la soumission (pas de triche en arrière-plan). (3) Mode examen authentique disponible (calculatrice + brouillon + accessibilité, sans Internet) pour les évaluations surveillées en classe. (4) Limitation par temps (timer par question configurable par l'enseignant). La triche existe aussi en classe — notre objectif est de fournir plus de signaux à l'enseignant, pas de la résoudre seule.

**Chiffres clés à citer :**
- Tableau de bord enseignant : écart devoir vs simulation visible
- Mode examen authentique (calculatrice + brouillon, offline)
- Timer par question configurable
- Auto-correction QCM immédiate, score à la soumission

**À éviter :**
- Ne pas dire « 0 % triche possible » — personne n'y croit. Mieux : « triche minimisée + détectée par signaux croisés ».

---

### Q72. Le système de niveaux ne crée-t-il pas des inégalités entre élèves ?

**Réponse courte (30-60 sec) :**
C'est une vraie question — nous y avons réfléchi. Trois mitigations. (1) Le système est individuel, pas comparatif : il n'y a pas de classement public, pas de leaderboard social. L'élève voit SA progression, pas celle des autres. (2) 50 niveaux avec formule XP progressive (100×N×(N+1)/2) : chaque niveau demande plus d'effort, ce qui ralentit naturellement les élèves avancés et laisse les élèves en difficulté progresser à leur rythme. (3) 8 récompenses débloquables (niveaux 5, 10, 15, 20, 25, 30, 40, 50) — toutes des fonctionnalités cosmétiques (dark theme, custom badge, custom colors) ou non-essentielles (early access, ambassador status). Aucune récompense ne donne d'avantage académique — pas de « pay-to-win » déguisé.

**Chiffres clés à citer :**
- 50 niveaux, formule 100×N×(N+1)/2 (effort croissant)
- 8 récompenses cosmétiques/non-essentielles (dark theme, custom badge, etc.)
- Aucun classement public, aucune récompense académique
- 9 sources d'XP (question correcte, simulation, badges, streak, devoir, tuteur)

**À éviter :**
- Ne pas dire « ça ne crée aucune inégalité » — reconnaître le risque, expliquer les mitigations (individuel, cosmétique, sans avantage académique).

---

### Q73. Sur quoi repose l'algorithme d'orientation ? Est-il validé scientifiquement ?

**Réponse courte (30-60 sec) :**
L'algorithme d'orientation combine deux signaux : 70 % similarité cosinus entre le profil de l'élève (6 axes : Scientifique, Littéraire, Créatif, Social, Business, Leadership) et les poids de chaque filière togolaise ; 30 % score matières (moyenne des P(L) BKT sur les matières pivots de la filière). Pénalité -10 points si la filière est sélective (Médecine, Pharmacie, Ingénierie, Architecture, Soins infirmiers, ENS) et que les axes forts de la filière sont < 0,55 chez l'élève — empêche de recommander Médecine à un élève sans profil scientifique. La base de données couvre 15 filières togolaises (UN Lomé, EUT, EPB, ESAE, ESA, IFG, ENI, ENAM, ENS, ISMP) et 35 career paths. Validité scientifique : la similarité cosinus est standard en systèmes de recommandation (Netflix Prize 2009), les 6 axes sont inspirés du RIASEC de Holland. Ce n'est pas validé cliniquement — c'est un outil d'aide, pas de décision.

**Chiffres clés à citer :**
- 70 % similarité cosinus + 30 % score matières
- 6 axes (inspirés du RIASEC de Holland)
- 15 filières togolaises + 35 career paths + 7 universités
- Pénalité -10 pts filières sélectives si axes faibles

**À éviter :**
- Ne pas sur-vendre : dire « outil d'aide à la décision », pas « orientation scientifique ». Préciser que l'élève doit consulter un conseiller humain pour valider.

---

### Q74. Le mode multijoueur nécessite-t-il Internet ? Comment ça marche en zone rurale ?

**Réponse courte (30-60 sec) :**
Le mode multijoueur actuel est en mode simulation locale (simulateMode=true) — il fonctionne 100 % offline avec 5 joueurs togolais mockés (Kossi, Aya, Komlan, Délali, Mawuko) qui répondent avec des compétences variables (35-75 %) pour simuler une partie réelle. C'est idéal pour la démo et pour les élèves ruraux sans Internet : ils peuvent créer une room, jouer contre les bots, voir le podium. La version réseau (WebSocket) est préparée côté code (`web_socket_channel` déjà en pubspec, parsing TODO) — elle nécessitera Internet pour affronter de vrais élèves. En zone rurale, le fallback est : mode solo (révision SM-2), mode simulation contre bots, ou mode coopératif en classe (un seul téléphone partagé, le prof anime).

**Chiffres clés à citer :**
- simulateMode=true par défaut (offline-ready, 5 joueurs togolais mockés)
- Max 6 joueurs par room, code 6 chiffres
- WebSocketChannel préparé (web_socket_channel ^3.0.0)
- Bonus vitesse : 50 pts ≤5s, 30 pts ≤10s, 10 pts ≤20s

**À éviter :**
- Ne pas dire « multijoueur marche en zone rurale » sans nuance — préciser : mode simulation offline oui, multijoueur réel nécessite Internet.

---

### Q75. Avez-vous fait un audit de sécurité ?

**Réponse courte (30-60 sec) :**
Oui, un audit OWASP Top 10 complet du backend FastAPI a été réalisé (11 fichiers étudiés, 26 routes cartographiées). Résultat : 19 vulnérabilités identifiées — 3 critiques (toutes A01 Broken Access Control : endpoints /sessions et /predict sans auth ni ownership check), 5 hautes (rate limiting non branché, CORS allow_origins=["*"], python-jose vulnérable CVE-2024-33664, etc.), 7 moyennes, 4 basses. 21 corrections documentées dans SECURITY_FIXES.md (avant/après + justification). 2 middlewares créés : security_headers.py (HSTS, CSP restrictive, X-Frame-Options, COOP/CORP) et input_validation.py (sanitizers anti-injection, validators Pydantic). SAST (bandit) et SCA (safety) ajoutés au requirements.txt pour CI.

**Chiffres clés à citer :**
- OWASP Top 10 : 19 vulnérabilités (3 critiques, 5 hautes, 7 moyennes, 4 basses)
- 21 corrections documentées dans SECURITY_FIXES.md
- 2 middlewares prêts (security_headers + input_validation)
- SAST bandit + SCA safety intégrés au requirements.txt

**À éviter :**
- Ne pas cacher les 3 vulnérabilités critiques — au contraire, montrer qu'elles sont identifiées et corrigées. Le jury valorise la transparence sur la sécurité.

---

### Q76. Comment protégez-vous les données des élèves mineurs ?

**Réponse courte (30-60 sec) :**
Sept dispositifs. (1) Mots de passe hachés via bcrypt (jamais en clair). (2) JWT avec algorithms explicite (anti-confusion clé) — pas de session serveur. (3) Pydantic validators côté backend : email normalisé, contrôle de longueur, IDs au format strict (TG-...-Q..). (4) UserOut schema exclut password_hash des réponses API. (5) Limitation taille body 1 Mo + query string 2 048 chars (anti-DoS). (6) Logs admin persistés (table admin_action_logs) — toute action sensible est tracée. (7) Avant prod réelle : endpoints conformité loi 2019-014 (/users/me/export, /users/me PUT, /users/me DELETE) à implémenter, chiffrement volume DB, déclaration ARP. Le pitch DJANTA utilisera un compte de démo dédié — aucune donnée réelle d'élève ne transitera pendant la présentation.

**Chiffres clés à citer :**
- bcrypt pour password hashing
- JWT algorithms explicite + UserOut exclut password_hash
- Table admin_action_logs (audit trail)
- Loi 2019-014 : 13 principes évalués, 9 non conformes, plan 3 phases

**À éviter :**
- Ne pas dire « conformes à 100 % à la loi 2019-014 » — c'est faux. Dire : « audit réalisé, 9 principes non conformes, plan d'action en 3 phases ».

---

### Q77. Êtes-vous conformes à la loi 2019-014 du Togo ?

**Réponse courte (30-60 sec) :**
Partiellement — c'est honnête. Sur les 13 principes de la loi 2019-014, 4 sont déjà conformes (sécurité technique, journalisation admin, minimisation via ORM, durée de conservation paramétrable) et 9 restent à implémenter avant la production réelle : consentement explicite, notification de violation sous 72 h, droits accès/rectification/effacement (endpoints à coder), transparence (politique de confidentialité à publier), déclaration auprès de l'ARP (Autorité de Protection des Données), transferts hors Togo (hébergement à définir). Le plan d'action est en 3 phases : P0 avant pitch DJANTA (statut démo explicite, aucune donnée réelle), P1 avant prod réelle (endpoints + déclaration ARP + chiffrement volume DB), P2 continu (audit annuel, rotation clés, revue RGPD). Le pitch DJANTA ne manipulera que des données mockées.

**Chiffres clés à citer :**
- Loi 2019-014 : 13 principes, 4 conformes, 9 à implémenter
- Plan 3 phases : P0 avant pitch, P1 avant prod, P2 continu
- Déclaration ARP obligatoire avant production réelle
- Pitch DJANTA : 100 % données mockées

**À éviter :**
- Ne jamais dire « conformes » sans nuance — c'est faux et dangereux juridiquement. Le jury DJANTA connaît la loi 2019-014 et valorise l'honnêteté sur le statut de conformité.

---

## Annexe A — Chiffres clés à mémoriser

Tableau récapitulatif des chiffres essentiels à avoir en tête pour répondre au jury. Ces 50 chiffres suffisent à répondre à 90 % des questions.

| # | Catégorie | Chiffre | Source | Quand citer |
|---|---|---|---|---|
| 1 | Crise éducation | BEPC 2023 : 81 % | MEPST Togo 2024 | Q1, Q2, Q7 |
| 2 | Crise éducation | BEPC 2024 : 44,09 % (−37 pts) | MEPST Togo 2024 | Q1, Q7 |
| 3 | Crise éducation | BAC 2 2024 : 46,71 % | MEPST Togo 2024 | Q1, Q2 |
| 4 | Crise éducation | BAC 1 2024 : 71,73 % (−6,8 pts) | MEPST Togo 2024 | Q1 |
| 5 | Crise éducation | 100 000+ candidats BAC 2 en 2025 (+30 %) | Togo First 2025 | Q6, Q42 |
| 6 | Crise éducation | 86 % learning poverty à 10 ans | Banque Mondiale 2021 | Q2 |
| 7 | Marché | TAM Togo : 800 000 élèves secondaire | Étude faisabilité | Q42 |
| 8 | Marché | SAM Togo : 150 000 candidats BEPC+BAC/an | Étude faisabilité | Q42 |
| 9 | Marché | SOM an 2 : 50 000 utilisateurs actifs | Étude faisabilité | Q42, Q50 |
| 10 | Marché | CEDEAO francophone : ~3 millions d'élèves | Étude faisabilité | Q41 |
| 11 | Marché | 500+ lycées privés au Togo | Étude faisabilité | Q9 |
| 12 | Mobile | Pénétration mobile > 100 % (T3-2025) | ARCEP Togo | Q4, Q46 |
| 13 | Mobile | 42 % des terminaux compatibles 4G | ARCEP Togo | Q4 |
| 14 | Mobile | 41 % des terminaux encore 2G uniquement | ARCEP T1-2025 | Q4, Q5 |
| 15 | Mobile | 46-57 % non-conformité opérateurs ruraux 2023 | ARCEP | Q5, Q51 |
| 16 | Modèle éco | Revenu/habitant Togo : 2 390 USD PPP | Banque Mondiale 2021 | Q8, Q13 |
| 17 | Modèle éco | Licence établissement : 100 000 FCFA/an | Étude faisabilité | Q8, Q9 |
| 18 | Modèle éco | Premium élève : 2 000 FCFA/mois | Étude faisabilité | Q8 |
| 19 | Modèle éco | Seuil rentabilité : 300-400 établissements | Étude faisabilité | Q10 |
| 20 | Budget | Budget 18 mois : 246 400 USD (~150M FCFA) | Étude faisabilité | Q12, Q54 |
| 21 | Budget | MVP bootstrap : 40 000-70 000 USD | Étude faisabilité | Q36 |
| 22 | Données | 800-1 200 sujets BEPC/BAC PDF disponibles | Étude faisabilité | Q23, Q26 |
| 23 | Données | 3 000-6 000 questions structurées cible | Étude faisabilité | Q23, Q26 |
| 24 | Algos | SM-2 (1987, Anki 10M+ users), FSRS +20-40 % | Cours théorique | Q16 |
| 25 | Algos | IRT utilisée par GRE, GMAT, TOEFL, Duolingo | Cours théorique | Q15 |
| 26 | KPIs | M6 : 300 users / M12 : 5 000 / M18 : 50 000 | Étude faisabilité | Q50 |
| 27 | KPIs | M6 : +8 pts / M12 : +12 pts / M18 : +15 pts | Étude faisabilité | Q48, Q49 |
| 28 | Légal | Loi 2019-014 (29 oct 2019) protection données Togo | Réglement DJANTA | Q47 |
| 29 | Concurrence | Khan Academy : +16 % notes Inde (CEPR/J-PAL) | Étude faisabilité | Q3, Q48 |
| 30 | Concurrence | Afrilearn Nigeria : curriculum WAEC, anglais | Étude faisabilité | Q29 |
| 31 | Produit | 114 questions dans le dataset unifié (6 matières, 2019-2024) | assets/data/questions.json | Q26, Q70 |
| 32 | Produit | 23 routes Flutter (GoRouter), 17 Hive adapters, 10 providers | app_router.dart, main.dart | Q70, Q72 |
| 33 | QA | 91 tests critiques (27 SM-2 + 20 BKT + 23 IRT + 21 Question) | test/unit/ | Q75 |
| 34 | QA | 50+ tests widget | test/widget/ | Q75 |
| 35 | ML | XGBoost RMSE = 1,466/20, MAE = 1,183/20, R² = 0,663 | backend/scripts/ml_training/ | Q17, Q66 |
| 36 | ML | XGBoost 14 features, 5 000 élèves synthétiques, grid search 54 combinaisons 5-fold CV | backend/scripts/ml_training/ | Q65, Q66 |
| 37 | ML | SHAP TreeExplainer (Lundberg 2020) — interprétabilité native | backend/scripts/ml_training/ | Q17, Q66 |
| 38 | ML | IRT calibration : py-irt 0.1.1 (1PL/2PL) + fallback numpy MLE 3PL | backend/scripts/irt_calibration/ | Q15, Q65 |
| 39 | Gamification | 39 badges en 5 catégories × 3 niveaux — XP 100/250/500, ~12 875 XP max | lib/models/badge.dart | Q61, Q62 |
| 40 | Gamification | 50 niveaux XP, formule 100×N×(N+1)/2, 8 récompenses débloquables | lib/services/level_service.dart | Q72 |
| 41 | IA tutor | Claude API (claude-sonnet-4-6), 30 req/h/user, max 2 000 tokens | backend/routers/tutor.py | Q58 |
| 42 | Sync | CRDT (LWW + conservateur + union + max), 5 endpoints FastAPI, backoff 1→32s | backend/routers/sync.py | Q63, Q64 |
| 43 | Parent | 3 plans premium (2 000/mois, 5 000/mois 3 enfants, 4 800/3 mois) — Flooz/TMoney/CB | lib/screens/parent/ | Q68 |
| 44 | Orientation | 15 filières togolaises, 35 careers, 6 axes (RIASEC), 70 % cosinus + 30 % matières | lib/screens/orientation/ | Q73 |
| 45 | Multijoueur | 6 écrans, max 6 joueurs, code 6 chiffres, simulateMode offline-ready | lib/screens/multiplayer/ | Q74 |
| 46 | Sécurité | OWASP Top 10 : 19 vulnérabilités (3 critiques, 5 hautes, 7 moyennes, 4 basses) | docs/security/OWASP_AUDIT_REPORT.md | Q75, Q76 |
| 47 | Sécurité | 21 corrections documentées + 2 middlewares (security_headers + input_validation) | docs/security/SECURITY_FIXES.md | Q75 |
| 48 | Sécurité | Loi 2019-014 : 13 principes évalués, 4 conformes, 9 non conformes, plan 3 phases | docs/security/OWASP_AUDIT_REPORT.md | Q77 |
| 49 | i18n | 4 langues (FR, EN, Éwé, Kabyè) — 165 clés de traduction | lib/l10n/ | Q51 |
| 50 | Backend | 23 endpoints FastAPI (auth, predict, sessions, questions, sync, tutor, classroom, admin, health) | backend/main.py | Q19 |

---

## Annexe B — Sources à citer

Liste structurée des sources officielles à citer si le jury challenge un chiffre. Préparer ces sources permet de répondre avec autorité.

| Source | Donnée fournie | Quand citer |
|---|---|---|
| **MEPST Togo 2024** (Ministère des Enseignements Primaire et Secondaire) | Taux de réussite aux examens 2023-2024 : BEPC 81 % → 44 %, BAC 1 71,73 %, BAC 2 46,71 % | Q1, Q2, Q7 — à chaque mention de la crise éducative |
| **Togo First 2024-2025** (togofirst.com) | 100 000+ candidats au BAC 2 en 2025, hausse 30 % | Q6, Q42 — pour démontrer la croissance démographique |
| **ARCEP Togo T3-2025** (Observatoire des marchés des communications électroniques) | Pénétration mobile > 100 %, 4G = 75 % trafic, 42 % terminaux 4G | Q4, Q46 — pour justifier le mobile-first |
| **ARCEP Togo T1-2025** | 41 % terminaux 2G uniquement, taux non-conformité ruraux 46-57 % | Q5, Q51 — pour justifier le mode offline |
| **ARCEP / nPerf 2024** | Moov Africa Togo meilleur opérateur data UEMOA, MAT latence 28 ms (meilleure Afrique), YAS 30 Mb/s 4G | Q4 — si question qualité réseau |
| **Banque Mondiale 2021** (Learning Poverty Brief Togo, données PASEC 2014) | 86 % d'élèves incapables de lire correctement à 10 ans, revenu/habitant 2 390 USD PPP | Q2, Q8, Q13, Q51 — pour documenter l'urgence et le pouvoir d'achat |
| **UNICEF COAR Togo 2022** (Country Office Annual Report) | Données de genre, présence et abandons scolaires | Q51 — si question équité filles |
| **UNESCO Institute for Statistics** | Données sur inscriptions, enseignants, taux de réussite | Q42 — si question marché global |
| **UNESCO / COL 2023** (Commonwealth of Learning) | Rapports EdTech Afrique francophone | Q11, Q29 — pour les précédents EdTech |
| **Loi n° 2019-014 du 29 octobre 2019** (Togo) | Protection des données personnelles | Q47 — à chaque question RGPD/protection données |
| **Règlement DJANTA Tech Hub 2026** (Article 6) | Critères d'évaluation jury : pertinence, innovation, impact, équipe, faisabilité | Toutes questions — pour montrer alignement |
| **Guidelines techniques DJANTA 2026** | 7 principes : open source, portabilité, interopérabilité, sécurité, transparence, documentation, valeur mesurable | Q22, Q47 — pour montrer conformité aux attentes |
| **CEPR / J-PAL Inde 2026** (étude Khan Academy randomisée) | +0,44 à 0,47 écart-type = +16 % notes | Q3, Q48 — pour les précédents adaptatif |
| **Conference EDM Azerbaijan 2023** | Khan Academy +16 % notes sur 207 élèves primaire | Q48 — pour les précédents EdTech |
| **Étude faisabilité ExamBoost Togo (mai 2025)** | Budget 246 400 USD, KPIs M6/M12/M18, modèle B2B2C, stack technique | Q8-Q14, Q42, Q50 — chiffres internes |
| **Cours théorique ExamBoost Togo (mai 2025)** | Détails algorithmes SM-2, IRT 3PL, BKT, XGBoost, py-irt, pyBKT | Q15-Q22 — pour la crédibilité technique |
| **Plan stratégique DJANTA ExamBoost (juin 2026)** | Structure pitch deck 10 slides, plan d'entraînement Q&A | Structuration générale de la défense |
| **SmartFarm Togo / AIMS Ghana** | Équipe, connexion réseau IA panafricain | Q34, Q39 — pour la crédibilité équipe |
| **epreuvesetcorriges.com, banquedesepreuves.com, examens-concours.net, fomesoutra.com** | Annales BEPC/BAC Togo 2010-2025 | Q23 — pour la disponibilité des données |
| **py-irt, pyBKT (Berkeley), scikit-learn, XGBoost** | Bibliothèques open-source utilisées | Q19 — pour la transparence technique |
| **Anthropic Claude API (2026)** | Tuteur IA conversationnel : claude-sonnet-4-6, méthodes socratique, rate limiting 30 req/h/user | Q58, Q59, Q60 — pour toute question sur le tuteur IA |
| **OWASP Top 10 (2021)** | Cadre de référence audit sécurité : 10 catégories (A01 Broken Access Control → A10 SSRF) | Q75, Q76 — pour justifier la rigueur sécurité |
| **OWASP_AUDIT_REPORT.md / SECURITY_FIXES.md / SECURITY_CHECKLIST.md** (Session 4, Agent BY) | 19 vulnérabilités identifiées, 21 corrections documentées, 2 middlewares prêts | Q75, Q76, Q77 — pour montrer l'audit concret |
| **Loi n° 2019-014 du 29 octobre 2019 + ARP Togo** | Protection données personnelles Togo, 13 principes, autorité ARP | Q47, Q69, Q76, Q77 — pour toute question RGPD/loi togolaise |
| **Mitchell et al. 2019 (Model Cards for Model Reporting, Google)** | Standard Model Cards pour XGBoost score predictor | Q19, Q66 — pour la transparence ML |
| **Lundberg et al. 2020 (Tree SHAP, NeurIPS)** | SHAP TreeExplainer polynomial pour interprétabilité XGBoost | Q17, Q66 — pour justifier l'interprétabilité |
| **Chen & Guestrin 2016 (XGBoost, KDD)** | Algorithme XGBoost, paper originel | Q19, Q66 — pour la crédibilité technique ML |
| **Piech et al. 2015 (Deep Knowledge Tracing, Stanford)** | DKT, réseau de neurones récurrent pour knowledge tracing | Q67 — pour expliquer le choix BKT vs DKT |
| **Holland 1997 (RIASEC, Holland Codes)** | Théorie des 6 axes de personnalité professionnelle — base de l'algorithme d'orientation | Q73 — pour la crédibilité orientation |
| **Netflix Prize 2009 (Koren et al.)** | Similarité cosinus pour systèmes de recommandation — base algorithmique orientation | Q73 — pour la crédibilité orientation |
| **RFC 7804 / CRDT (Shapiro et al. 2011, INRIA)** | Conflict-free Replicated Data Types — base théorique sync cloud | Q63, Q64 — pour la crédibilité sync offline |
| **FastAPI + Starlette + Uvicorn (Pydantic 2)** | Stack backend : validation Pydantic, JWT, async, OpenAPI auto-généré | Q19, Q75 — pour la transparence stack |
| **Flutter 3.44.4 + Hive 2.2 + Provider 6.1 + GoRouter** | Stack mobile : 23 routes, 17 Hive adapters (typeIds 0-20), 10 providers | Q20, Q70 — pour la transparence stack mobile |

**Règle de citation** : toujours préciser l'année et la source. « Selon l'ARCEP Togo, T3 2025 » est plus crédible que « selon nos recherches ».

---

## Annexe C — Pitch en 30 secondes (elevator pitch)

> À mémoriser par cœur. À utiliser si le jury demande « Présentez-vous en 30 secondes », ou en ouverture/fermeture du pitch.

**Version française (30 secondes, ~95 mots) :**

« ExamBoost Togo est une application mobile gratuite qui prépare les élèves togolais aux examens nationaux — BEPC et BAC. En 2024, le BEPC est passé de 81 % à 44 % de réussite. La cause principale : l'absence d'outils alignés sur le programme officiel. Notre app utilise l'IRT — la même technologie que le GRE et Duolingo — pour adapter chaque question au niveau de l'élève, la répétition espacée pour combattre l'oubli, un tuteur IA Claude méthode socratique, 39 badges gamification, sync cloud offline-first avec CRDT. Elle fonctionne hors-ligne sur un Tecno Spark. Gratuite pour l'élève, monétisée via les écoles et le module parent premium. 114 questions, 91 tests critiques, audit OWASP Top 10. Notre cible : 50 000 utilisateurs en 18 mois. »

**Version anglaise (30 seconds, ~90 words) — pour CcHub mentors :**

« ExamBoost Togo is a free mobile app that prepares Togolese students for their national exams — BEPC and BAC. In 2024, BEPC pass rates collapsed from 81 % to 44 %. The root cause: no tool aligned with the national curriculum. Our app uses IRT — the same tech powering GRE and Duolingo — to adapt every question to each student's level, spaced repetition to fight forgetting, a Claude-powered socratic AI tutor, 39 gamification badges, and offline-first cloud sync with CRDT. It works offline on a Tecno Spark. Free for students, monetized through schools and a premium parent module. 114 questions, 91 critical tests, OWASP Top 10 security audit. Target: 50,000 users in 18 months. »

**Version ultra-courte (15 secondes, ~55 mots) — si le jury coupe court :**

« ExamBoost Togo : une app gratuite qui aide les 100 000 lycéens togolais à réussir le BEPC et le BAC, avec une IA adaptative qui marche offline sur téléphone basique, un tuteur IA Claude, et 114 questions alignées MEPST. Le BEPC est tombé à 44 % en 2024. Nous changeons ça. »

---

## Annexe D — Checklist jour du pitch (24 juillet 2026)

Pour ne rien oublier le jour J. À imprimer et à cocher.

**La veille (23 juillet) :**
- [ ] Run final du pitch en conditions réelles (vidéo)
- [ ] Téléphone chargé à 100 % avec l'APK ExamBoost installé
- [ ] Backup de la démo sur clé USB
- [ ] Cartes de visite de l'équipe (4 jeux)
- [ ] Version imprimée du pitch deck (4 copies)
- [ ] Tenue cohérente professionnelle validée (même couleur de haut)
- [ ] Ce document Q&A relu en entier
- [ ] Annexe A (chiffres clés) mémorisée

**Le jour même (24 juillet) :**
- [ ] Arriver 30 minutes avant l'heure prévue
- [ ] Tester le projecteur et la connexion avant tout
- [ ] Présence des 4 membres de l'équipe
- [ ] Laptop avec démo + téléphone avec APK prêts
- [ ] Calendrier de bootcamp CcHub (20-22 juillet) intégré
- [ ] Check final des 50 chiffres clés (Annexe A)

**Pendant le pitch :**
- [ ] La personne qui pitche regarde le jury, pas l'écran
- [ ] Respecter le timing : 7 minutes pitch + 5 minutes Q&A
- [ ] En cas de question difficile : 2 secondes de pause, reformuler, répondre honnêtement
- [ ] Ne jamais dire « je ne sais pas » seul — toujours compléter par « voici ce que nous savons et comment nous approfondirons »
- [ ] Si challenge sur un chiffre : citer la source (Annexe B)
- [ ] Conclure par une phrase mémorable, regarder le jury, silence

---

## Annexe E — Réponses aux 5 critiques les plus probables

Anticipation des 5 attaques les plus probables du jury, avec réponses prêtes.

### Critique 1 : « Votre modèle économique n'est pas réaliste — les écoles togolaises ne paieront pas »

**Réponse :** « C'est une préoccupation légitime. C'est pourquoi nous avons diversifié nos sources de revenus (B2B écoles, B2B bailleurs, premium élève, API MEPST) — pas monocanal. De plus, le précédent EDVES au Nigeria (2 300+ écoles) prouve que le modèle B2B écoles fonctionne en Afrique de l'Ouest. Et nous avons déjà un lycée de Lomé intéressé par un pilote — la demande est réelle, pas hypothétique. »

### Critique 2 : « Votre IA ne marchera pas sans données — vous n'avez pas d'utilisateurs »

**Réponse :** « Excellent point — c'est pourquoi nous avons une stratégie par paliers. Avant le pilote, nous utilisons des valeurs par défaut raisonnables (a=1, c=1/k pour QCM, b estimé par inversion du taux de réussite historique dans les annales). Dès le pilote M5-M6 avec 300-500 élèves, nous calibrons l'IRT avec py-irt. XGBoost arrive en phase 2 (1 000+ utilisateurs). L'IA s'améliore progressivement — pas de cold start. »

### Critique 3 : « Vous n'avez pas d'expérience — l'équipe est trop jeune »

**Réponse :** « Nous ne prétendons pas avoir 20 ans d'expérience. Mais nous avons trois atouts : (1) connexion directe au contexte togolais — nous avons passé le BEPC et le BAC nous-mêmes ; (2) expertise technique prouvée — 3 algorithmes ML déjà implémentés dans le repo GitHub public ; (3) réseau AIMS Ghana pour la validation scientifique. Et nous avons déjà démarré le développement — ce qui prouve notre engagement. DJANTA nous donnera le mentorat CcHub pour combler les gaps. »

### Critique 4 : « Khan Academy existe déjà et est gratuit — pourquoi réinventer la roue ? »

**Réponse :** « Khan Academy est excellente — mais elle n'est pas alignée sur le programme MEPST togolais. Les élèves togolais qui utilisent Khan apprennent les mathématiques, mais ne s'entraînent pas au format BEPC/BAC. C'est la différence entre 'apprendre' et 'réussir l'examen'. ExamBoost fait les deux : on enseigne ET on entraîne sur le format exact. Khan est complémentaire — nous sommes spécifiques. »

### Critique 5 : « Vos projections d'utilisateurs (50 000 en 18 mois) sont irréalistes »

**Réponse :** « Nous sommes alignés sur les précédents : Afrilearn Nigeria a atteint 100 000+ utilisateurs en 18 mois, EDVES a signé 2 300 écoles en quelques années. 50 000 utilisateurs représente 33 % de notre SAM (150 000 candidats BEPC+BAC/an) — c'est ambitieux mais pas extravagant. Cela suppose un partenariat MEPST pour un déploiement national, que nous visons. Sans MEPST, nous serions plus conservateurs (5 000-10 000 utilisateurs). »

---

## Conclusion — État d'esprit pour le 24 juillet

Ce document prépare l'équipe ExamBoost Togo à 77 questions probables du jury DJANTA Tech Hub. La couverture est large mais non exhaustive — le jury posera peut-être des questions imprévues. Dans ce cas, trois principes :

1. **Honnêteté radicale** : ne jamais mentir, ne jamais exagérer. Si on ne sait pas, dire « voici ce que nous savons et comment nous approfondirons ». Le jury DJANTA voit passer des dizaines de pitchs par an — il détecte immédiatement le bluff.

2. **Chiffres sourcés** : chaque affirmation chiffrée doit avoir une source (Annexe B). « Selon l'ARCEP Togo 2025, pénétration mobile > 100 % » est crédible. « Beaucoup d'élèves ont un téléphone » ne l'est pas.

3. **Profondeur de localisation** : notre avantage concurrentiel n'est pas la technologie (IRT, SM-2, XGBoost existent déjà) — c'est la localisation togolaise profonde. Chaque réponse doit rappeler cet ancrage : français togolais, annales MEPST, lycées de Lomé et Kara, programme APC, loi 2019-014.

Le 24 juillet 2026, le jury DJANTA verra une équipe qui n'attend pas — qui construit. 114 questions dans le dataset unifié, 23 routes Flutter, 17 Hive adapters, 10 providers, 91 tests critiques (50+ widget tests), tuteur IA Claude, sync cloud offline-first avec CRDT, modèle XGBoost RMSE 1,46/20, 39 badges gamification, audit sécurité OWASP Top 10, 4 langues (FR, EN, Éwé, Kabyè). Prototype Flutter fonctionnel, enquête terrain menée, plan stratégique en 19 pages, étude de faisabilité en 30 pages, cours théorique en 31 pages. Aucune autre équipe candidate n'aura cette profondeur de préparation.

Le momentum compte. Les équipes qui gagnent ne sont pas celles qui ont la meilleure idée sur le papier — ce sont celles qui montrent qu'elles avancent.

**Bon pitch. L'équipe ExamBoost Togo mérite sa place.**

---

*Document préparé par l'équipe ExamBoost Togo — juillet 2026*
*Sources : MEPST Togo 2024, ARCEP Togo 2025, Banque Mondiale 2021, UNICEF 2022, Étude de faisabilité mai 2025, Cours théorique mai 2025, Plan stratégique juin 2026, Règlement DJANTA Tech Hub 2026.*
*Confidentiel — usage interne équipe ExamBoost Togo.*
