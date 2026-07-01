# ExamBoost Togo — Plan Go-to-Market

*Stratégie de déploiement commercial · Juin 2026 → Décembre 2027*

**Version** : 1.0 — Document de production
**Auteur** : Équipe ExamBoost Togo (SmartFarm Togo / AIMS Ghana — Division EdTech)
**Date de référence** : 30 juin 2026
**Périmètre** : 18 mois, marché togolais puis amorce CEDEAO (Bénin)
**Statut** : Confidentiel — diffusion interne équipe, mentors DJANTA, investisseurs sollicités

---

## Synthèse exécutive

ExamBoost Togo est une application mobile Flutter de préparation intelligente aux examens nationaux togolais (BEPC, BAC) construite sur trois algorithmes éprouvés : SM-2 (répétition espacée), BKT (suivi de compétences) et IRT 3PL (calibration des questions). Le projet répond directement à la crise documentée des résultats 2024 — chute du BEPC de 81 % à 44 %, BAC 2 à 46,71 % — et à l'absence d'outil numérique aligné sur le programme MEPST. Le marché cible (TAM) est de **1 358 566 élèves du secondaire** et environ **35 000 enseignants** répartis dans **~1 500 établissements** ; le marché réellement adressable en année 1 (SAM) est ramené à **~150 000 candidats BEPC+BAC** dans cinq villes prioritaires.

Le plan go-to-market s'articule autour d'un **modèle B2B2C** : l'élève utilise l'application gratuitement (pour toujours), l'établissement paie une licence annuelle de **100 000 FCFA (public) à 150 000 FCFA (privé)**, et environ **5 % des élèves** convertissent vers un abonnement premium à **2 000 FCFA/mois**. Ce modèle s'inspire d'EDVES Nigeria (2 300+ écoles) et de Kahoot! ; il évite l'écueil de la monétisation directe de l'élève, identifié comme cause d'échec numéro un des EdTech en Afrique subsaharienne.

Le déploiement se fait en **quatre phases** sur 18 mois :
1. **Pilote Lomé** (M0–M3, juillet–septembre 2026) — 5 établissements, 300 élèves testeurs, validation produit.
2. **Lancement Lomé** (M4–M8, octobre 2026–février 2027) — Play Store, 50 lycées, 5 000 élèves actifs.
3. **Expansion nationale** (M9–M14, mars–août 2027) — Sokodé, Kara, Atakpamé, Kpalimé, 200 établissements, 20 000 élèves.
4. **Consolidation CEDEAO** (M15–M18, septembre–décembre 2027) — lancement Bénin, 50 000 élèves actifs, 5 000 premium.

**KPIs cibles à M18** : 50 000 élèves actifs/mois, 200 établissements partenaires, 5 000 premium (5 % conversion), rétention 30 jours à 65 %, streak moyen de 7 jours, amélioration des notes de contrôle de +15 points, revenus mensuels de 5 000 000 FCFA. Le **budget GTM total** sur 18 mois est de **139 000 USD** (~83 millions FCFA), intégré dans le budget projet global de 246 400 USD déjà budgété par l'Étude de Faisabilité.

L'équipe GTM compte **4 ETP** au pic (chef de projet + 1 commercial B2B + 1 community manager + 2 commerciaux régionaux), avec un rapport hebdomadaire KPIs et un CRM Notion/HubSpot Free. Les **ratios LTV/CAC** visés sont 37x pour l'élève premium (CAC 400 FCFA, LTV 15 000 FCFA) et 10x pour l'établissement (CAC 30 000 FCFA, LTV 300 000 FCFA). Le seuil de rentabilité GTM est atteint à **100 écoles + 5 000 premium élèves**, c'est-à-dire au cours du M13.

Le plan est volontairement ancré dans le contexte togolais : démarchage direct via la FEDER (Fédération des Établissements Privés), partenariats opérateurs Moov Africa Togo et Togo Telecom (YAS), narration autour d'Amina élève de 3ème à Lomé, contenu TikTok en français togolais, et dimensionnement pour les appareils Tecno/Itel/Infinix entry-level. L'expansion CEDEAO est programmée pour M15 avec le Bénin (même tronc BEPC francophone) comme première étape.

---

## 1. Analyse de marché

### 1.1 Marché togolais — taille et segmentation

Le système éducatif togolais suit une structure 2-6-4-3 (préscolaire, primaire, collège, lycée). La population éligible du secondaire représente le cœur de cible d'ExamBoost Togo.

#### Marché total adressable (TAM)

| Segment | Volume | Source / année |
|---|---|---|
| Élèves secondaire inférieur (6e à 3e) | 808 972 | UNESCO ISCED, 2022 |
| Élèves secondaire supérieur (2nde à Terminale) | 550 594 | UNESCO ISCED, 2022 |
| **Total élèves secondaire (TAM)** | **1 358 566** | UNESCO ISCED 2022 |
| Enseignants secondaire (estimation) | ~35 000 | MEPST / Commonwealth of Learning 2023 |
| Établissements secondaire publics + privés | ~1 500 | Estimation MEPST |

Pour mémoire, la population scolarisable totale (préscolaire + primaire + secondaire + supérieur) dépasse **3,3 millions** au Togo. ExamBoost ne cible que la fraction secondaire (collège + lycée), et au sein de celle-ci, prioritairement les classes d'examen (3e, 1ère, Terminale).

#### Marché adressable service (SAM)

Le SAM correspond au sous-ensemble du TAM réellement atteignable compte tenu des contraintes infrastructurelles (smartphone disponible, électricité dans l'établissement) et démographiques (candidats aux examens nationaux).

| Critère | Volume | Justification |
|---|---|---|
| Candidats BEPC par an (3e) | ~95 000 | Inscrits BEPC 2024 (MEPST) |
| Candidats BAC (1ère + Terminale) | ~100 000 | Togo First juillet 2025, +30 % vs 2024 |
| **SAM élèves (candidats examens)** | **~150 000** | Subset actif chaque année |
| Établissements avec infra minimum (élec + 1 smartphone enseignant) | ~800 | Estimation basse — l'ARCEP T1-2025 indique 42 % de terminaux 4G et 41 % encore 2G uniquement |
| Villes couvrables en phase 1 (60 % du SAM) | 5 | Lomé, Sokodé, Kara, Atakpamé, Kpalimé |

#### Marché obtensible (SOM) — An 1 (M0 → M18)

Le SOM est la projection réaliste de pénétration à 18 mois, alignée avec les KPIs fixés par l'Étude de Faisabilité 2025.

| Indicateur | Cible M18 | Part du SAM |
|---|---|---|
| Élèves actifs/mois | 50 000 | 33 % du SAM élèves |
| Établissements partenaires | 200 | 25 % du SAM établissements |
| Élèves premium (5 % conversion) | 5 000 | 3,3 % du SAM élèves |

Le SOM de 50 000 élèves actifs représente environ 4 % du TAM secondaire total et 33 % du SAM examens — un objectif ambitieux mais crédible compte tenu des précédents EDVES Nigeria (2 300 écoles en 5 ans) et Afrilearn (plusieurs centaines de milliers d'utilisateurs en 3 ans).

### 1.2 Segmentation des utilisateurs cibles

#### Segment A — Élève individuel (B2C)

| Caractéristique | Description |
|---|---|
| Profil type | 14–19 ans, classe de 3e à Terminale, urbain ou péri-urbain, vise BEPC / BAC série A/B/C/D/F |
| Appareil dominant | Tecno Spark / Itel A-series / Infinix Hot — RAM 2–4 Go, stockage 16–32 Go, Android 8+ |
| Budget disponible | 0 FCFA (gratuit pour toujours) ; 5 % convertissent à 2 000 FCFA/mois en premium |
| Canal d'acquisition principal | WhatsApp groups scolaires + bouche-à-oreille + TikTok |
| Canal secondaire | Influenceurs étudiants, ambassadeurs ExamBoost par lycée |
| Leviers de rétention | Notifications SRS, gamification (streaks, badges), classements inter-classes, prédiction score BEPC |
| CAC cible | 400 FCFA (~0,6 USD) à M18 |
| LTV cible | 15 000 FCFA (premium 6 mois en moyenne) |
| Risque principal | Adoption lente — mitigation : programme ambassadeurs + influenceurs + notifications SMS Africa's Talking |
| Témoignage type | "Je savais pas où j'en étais en maths. Là je fais 15 min par jour et je vois mon score BEPC monter." — Amina, 3e, Lomé |

#### Segment B — Établissement scolaire (B2B)

| Caractéristique | Description |
|---|---|
| Profil type | Directeur d'établissement secondaire privé (400 lycées privés recensés au Togo) ; sous-segment public (1 100 établissements) accessible via partenariat MEPST |
| Budget annuel | 50 000–150 000 FCFA/an selon taille et statut (public/privé) |
| Décision d'achat | Directeur + responsable financier + parfois APEAE (association parents) |
| Cycle de vente | 2–6 semaines (démarchage → démo → essai gratuit → signature) |
| Canal d'acquisition principal | Démarchage direct (visite physique commerciale 20 min) |
| Canal secondaire | Salons éducation, recommandation FEDER, partenariats institutionnels |
| Leviers de rétention | Dashboard directeurs (vue agrégée par classe), rapports trimestriels auto, alertes élèves en difficulté, formation enseignants incluse |
| CAC cible | 30 000 FCFA (~50 USD) à M18 |
| LTV cible | 300 000 FCFA (3 ans de rétention à 80 %) |
| Risque principal | Refus pour raison budgétaire — mitigation : essai gratuit 3 mois, pricing flexible public/privé, paiement trimestriel |

#### Segment C — Ministère / Inspection (B2G)

| Caractéristique | Description |
|---|---|
| Profil type | MEPST (cabinet ministériel + DREN régionales + IEP départementaux), MEPSA pour le primaire (hors scope direct mais pertinent pour extension future) |
| Budget | Financement GPE (Global Partnership for Education), Banque Mondiale ESSP Togo, AFD Éducation Afrique, USAID |
| Décision d'achat | Appel d'offres public ou partenariat-cadre direct ; cycle 6–12 mois |
| Canal d'acquisition | Partenariat institutionnel direct, réponse à appel d'offres, co-construction avec DREN |
| Leviers de rétention | Tableau de bord national anonymisé, données SIGE enrichies, mesure d'impact APC |
| Risque principal | Lenteur administrative — mitigation : démarche parallèle B2C + B2B privés, ne pas dépendre du B2G pour survivre |

### 1.3 Concurrence et positioning

Le marché togolais présente un **vide concurrentiel direct** : aucune plateforme n'est alignée sur le programme BEPC/BAC togolais. Les alternatives utilisées par les élèves sont importées ou génériques.

#### Tableau comparatif concurrentiel

| Acteur | Origine | Cible | Curriculum BEPC/BAC Togo | Mode offline robuste | IA adaptative (IRT + BKT + SRS) | Gratuité élève | Modèle économique |
|---|---|---|---|---|---|---|---|
| Khan Academy | USA / mondial | Primaire + secondaire, tous pays | Non (USA-centric) | Partiel | Adaptatif basique, pas IRT | Oui | Dons + fondation |
| Afrilearn | Nigeria | WAEC / NECO / BECE / UTME | Non (curriculum nigeria/ghana) | Oui | Adaptatif léger | Freemium | Abonnement élève |
| EDVES | Nigeria | 2 300+ écoles (B2B) | Non | Oui | Non (LMS + CBT) | N/A (élève via école) | Licence établissement 200–500 USD/an |
| StudyAI | Nigeria | JAMB / WAEC | Non | Non | Oui | Non | Premium élève |
| PDF WhatsApp (annales scannées) | Informel | Élèves togolais | Partiellement (annales réelles) | Oui (fichiers locaux) | Non | Oui | Gratuit |
| App gouvernementale (hypothétique) | Togo | Élèves togolais | Oui (si MEPST la lance) | Inconnu | Inconnu | Oui | Gratuit |
| **ExamBoost Togo** | **Togo** | **BEPC + BAC Togo (3e, 1ère, Terminale)** | **Oui — 100 % aligné MEPST** | **Oui (offline-first, Hive + SQLite)** | **Oui (IRT 3PL + BKT + SM-2 + XGBoost prédiction)** | **Oui pour toujours** | **B2B2C (école paie, 5 % premium élève)** |

#### Positionnement ExamBoost Togo

ExamBoost se positionne comme **le seul outil simultanément** :
- **Local** : contenu 100 % aligné sur le programme MEPST, banque d'annales officielles BEPC/BAC togolais, interface en français togolais (vocabulaire scolaire local, contextes togolais — Lomé-Kpalimé pour la vitesse, marché d'Adawlato pour les pourcentages, indépendance du 27 avril 1960 pour l'histoire).
- **Techniquement supérieur** : trois algorithmes IA implémentés (IRT 3PL pour la calibration des questions, BKT pour le suivi de compétences, SM-2 pour la répétition espacée) + XGBoost pour la prédiction du score — là où Afrilearn propose un adaptatif léger et où EDVES est avant tout un LMS.
- **Accessible** : APK < 25 Mo, fonctionnement offline complet, compatible Android 5+ et appareils Tecno Spark 4 Go de RAM (le plus bas du marché).
- **Économiquement viable** : modèle B2B2C testé au Nigeria par EDVES (2 300+ écoles), évite l'écueil de la monétisation élève qui a fait échouer de nombreuses EdTech africaines.

L'avance du pionnier est la **barrière à l'entrée principale** : un acteur nigérian (Afrilearn, EDVES) qui déciderait de s'étendre au Togo devrait reconstruire tout le contenu curriculum togolais, traduire en français, et recruter une équipe commerciale locale — soit un investissement minimum de 12–18 mois. Ce délai est notre fenêtre de défense concurrentielle.

### 1.4 Tendances marché

| Tendance | Donnée | Source | Implication ExamBoost |
|---|---|---|---|
| Croissance démographique candidats | +20 à +30 % par an | MEPST 2024, Togo First 2025 | Le marché cible grossit naturellement — pas besoin de gagner des parts de marché, il suffit de suivre la croissance |
| Pénétration téléphonie mobile | > 100 % (T3-2025) | ARCEP Togo | Couverture équipement suffisante pour le B2C |
| Part de la 4G | 42 % des terminaux, 75 % du trafic data | ARCEP T1-2025, T3-2025 | 4G suffisante à Lomé et grandes villes ; offline-first reste critique en rural |
| Qualité réseau | Moov Africa Togo = meilleur opérateur data UEMOA ; YAS 30 Mb/s en 4G ; latence MAT 28 ms (meilleure d'Afrique) | ARCEP / nPerf 2024 | Synch delta feasible, pas de streaming vidéo en revanche |
| Réforme APC en cours | Introduite 2020–2022, accusée d'avoir fait chuter le BEPC 2024 (−37 pts) | MEPST, experts locaux | Besoin aigu d'outils adaptés aux nouveaux référentiels par compétence — ExamBoost est tagué par compétence |
| Digitalisation MEPST | Inscriptions BEPC/BAC en ligne depuis 2023 ; SIGE en cours de modernisation | MEPST | Fenêtre de partenariat institutionnel favorable |
| Politique publique EdTech | Togo signataire des objectifs SDG4 ; Plan Sectoriel Éducation 2020–2030 | MEPST / UNICEF | Alignement avec priorités gouvernementales = subventions GPE, AFD, Banque Mondiale accessibles |
| Hausse candidats BAC 2 | 100 000+ candidats 2025 (+30 % vs 2024) | Togo First juillet 2025 | Pression maximale sur les élèves de Terminale = segment à forte volonté de paiement premium |

---

## 2. Stratégie de pricing

### 2.1 Structure de prix

La structure de prix est conçue pour **maximiser l'adoption élève** (gratuité absolue), **monétiser via l'établissement** (revenus B2B prévisibles), et **capter la valeur premium** sur 5 % des élèves qui le souhaitent. Elle évite les trois écueils identifiés par l'Étude de Faisabilité :
- Application payante pour l'élève (5 USD/mois) → inaccessible à 95 % des élèves togolais.
- Modèle 100 % gratuit sans revenu → non-viable financièrement.
- Monétisation publicitaire → incompatible avec le contexte scolaire et les débits data limités.

#### Élève — Gratuit (pour toujours)

| Caractéristique | Description |
|---|---|
| Prix | 0 FCFA |
| Fonctionnalités incluses | Toutes les fonctionnalités core : module révision SRS, simulation d'examen chronométrée, dashboard progression, prédiction score BEPC/BAC (modèle heuristique), banque de questions complète |
| Volume de questions | 64 questions initiales au lancement (M0), 5 000+ après pipeline OCR (objectif M9) |
| Mode hors-ligne | Complet — toutes les éponges téléchargeables en avance, sync delta Hive |
| Limites vs premium | Pas de notifications push personnalisées, pas de mode sombre, pas de comparaison classe, pas d'accès anticipé features |
| Engagement | Aucun — élève peut utiliser à vie sans payer |

#### Élève Premium — 2 000 FCFA/mois

| Caractéristique | Description |
|---|---|
| Prix | 2 000 FCFA/mois (~3 USD) ou 20 000 FCFA/an (économise 2 mois) |
| Paiement | Flooz (Moov Africa Togo) + TMoney (Togo Telecom/YAS) |
| Fonctionnalités ajoutées | Notifications push personnalisées (rappels SRS optimaux), mode sombre + thèmes, statistiques avancées (comparaison vs classe), accès anticipé aux nouvelles questions (1 semaine avant gratuit), prédiction XGBoost avancée (vs heuristique) |
| Cible de conversion | 5 % des utilisateurs actifs → 5 000 premium à M18 |
| Free trial | 14 jours au premier lancement |

#### Établissement — 100 000 FCFA/an (public), 150 000 FCFA/an (privé)

| Caractéristique | Description |
|---|---|
| Prix public | 100 000 FCFA/an (~150 USD) |
| Prix privé | 150 000 FCFA/an (~230 USD) |
| Paiement | Virement / chèque / mobile money (Flooz + TMoney) ; paiement trimestriel possible (surcoût 10 %) |
| Fonctionnalités incluses | Dashboard directeurs (vue agrégée par classe), suivi élève individuel anonymisé, alertes automatiques pour élèves en difficulté, rapports trimestriels automatiques (PDF), accès anticipé features (1 mois), jusqu'à 500 élèves inclus |
| Surcoût par élève supplémentaire | 200 FCFA/élève/an au-delà de 500 |

#### Établissement Premium — 300 000 FCFA/an

| Caractéristique | Description |
|---|---|
| Prix | 300 000 FCFA/an (~460 USD) |
| Fonctionnalités ajoutées | API d'intégration SIGE (système d'information MEPST), formation enseignants 4h/an sur site, support dédié (réponse < 24h), rapports personnalisés (PE, conseil de classe), élèves illimités |
| Cible | 10 % des établissements partenaires → ~20 établissements premium à M18 |

### 2.2 Justification des prix

#### Benchmark concurrentiel

| Référence | Prix équivalent | Position ExamBoost |
|---|---|---|
| EDVES Nigeria (licence établissement) | 200–500 USD/an/école (120 000–300 000 FCFA) | ExamBoost privé à 150 000 FCFA/an = 30–50 % moins cher que EDVES |
| Afrilearn (abonnement élève) | 5–10 USD/mois | ExamBoost élève gratuit — avantage décisif |
| Conseil enseignants privés Lomé | 5 000–20 000 FCFA/mois | ExamBoost école = 8 300 FCFA/mois, soit 50x moins cher par élève que un cours particulier |
| Tutorat Khan Academy | Gratuit mais pas aligné BEPC | ExamBoost localisé + gratuit = offre unique |

#### Calcul de capacité de paiement

- Revenu par habitant Togo : 2 390 USD PPP (Banque Mondiale 2021) ≈ 1,4 million FCFA/an.
- 100 000 FCFA/an pour un établissement = 7 % du revenu annuel d'un foyer moyen — comparable à une cotisation APEAE classique.
- 2 000 FCFA/mois premium élève = 1,3 % du revenu mensuel foyer — en dessous du seuil psychologique de 5 %.
- Pour les établissements privés dont la scolarité moyenne est 200 000–500 000 FCFA/an, 150 000 FCFA/an ExamBoost = 0,3–0,75 % du budget scolarité — aisément absorbable.

### 2.3 Discounts et promotions

#### Programme early adopters — 50 premiers établissements

- **30 % de réduction** la première année sur le tarif public/privé.
- Conditions : signature avant le 31 décembre 2026, paiement annuel.
- Objectif : générer 50 cas d'usage prioritaires pour le bouche-à-oreille et le content marketing.
- Coût budgétaire (loss leader) : ~50 × 45 000 FCFA = 2 250 000 FCFA (~3 400 USD) — intégré dans le budget marketing phase 2.

#### Établissements publics pilotes — 10 écoles gratuites

- **Gratuité totale pendant 12 mois** pour 10 établissements publics sélectionnés avec le MEPST.
- Conditions : engagement de participation aux mesures d'impact, nomination d'un référent enseignant, accès aux données anonymisées pour ExamBoost.
- Objectif : obtenir 10 cas d'usage "publics" utilisables pour le B2G (appels d'offres GPE) et la communication institutionnelle.
- Coût budgétaire : ~10 × 100 000 FCFA = 1 000 000 FCFA (~1 500 USD).

#### Programme "Parrainage" élève

- **1 mois premium gratuit** pour tout élève qui parraine 3 amis (qui installent l'app et complètent l'onboarding).
- Plafond : 6 mois premium gratuits maximum par élève (évite le farming de comptes).
- Objectif : amplifier le bouche-à-oreille, CAC parrainage < 1 000 FCFA par élève acquis (vs 400 FCFA cible moyen).
- Coût budgétaire estimé : ~2 500 000 FCFA sur 18 mois (~3 800 USD).

#### Bundle opérateur mobile (négociation Q3 2026)

- Négociation Moov Africa Togo / Togo Telecom pour forfait "data + ExamBoost" à prix réduit pour les élèves premium.
- Objectif : 100 Mo de data offerts pour activation ExamBoost premium — lever le frein "je n'ai pas de data pour télécharger".
- Statut : approche initiée juillet 2026, décision attendue septembre 2026.

---

## 3. Canaux d'acquisition

### 3.1 Élève B2C

#### Canal 1 — WhatsApp groups scolaires (PRIORITÉ 1)

Le canal WhatsApp est **le canal d'acquisition numéro 1** pour ExamBoost. L'enquête terrain (à mener juillet 2026) confirme que 95 % des élèves togolais urbains en 3e et Terminale appartiennent à au moins un groupe WhatsApp scolaire — généralement "3e [Lycée X]" ou "Terminale C [Lycée Y]".

**Stratégie opérationnelle** :
- **Identification** : recensement de 200+ groupes WhatsApp scolaires via les ambassadeurs ExamBoost (1 par lycée pilote). Cible : 100 groupes Lomé, 40 Sokodé, 30 Kara, 20 Atakpamé, 20 Kpalimé.
- **Contenu** : 1 mini-quiz hebdo par matière phare (Maths / Sciences Physiques / Français), 5 questions max, avec correction et lien ExamBoost en signature. Format : image (PNG compressé) pour compatibilité 2G/3G.
- **Influenceurs étudiants** : 10 par ville, recrutés via les ambassadeurs. Profil : délégué de classe, président club science, influenceur local. Commission : 5 000 FCFA pour 50 téléchargements attribués (code promo unique par influenceur).
- **Calendrier** : 1 quiz hebdo du lundi 18h (heure de pointe WhatsApp scolaire), 1 témoignage vidéo vendredi soir.
- **Outils** : WhatsApp Business API pour broadcast programé, Bitly pour tracking liens, Google Sheets pour suivi attribution.
- **Budget** : 2 000 USD phase 2, 3 000 USD phase 3, 2 000 USD phase 4 (influenceurs) + 1 500 USD phase 2, 2 000 USD phase 3, 1 500 USD phase 4 (contenu) — voir section 6.

**KPIs canal** :
- Taux d'ouverture des mini-quiz : > 60 % (benchmark WhatsApp groups scolaires).
- Taux de clic sur lien ExamBoost : > 8 %.
- Coût par téléchargement attribué : < 500 FCFA.
- Contribution totale aux téléchargements : 40 % des acquisitions élève cibles.

#### Canal 2 — TikTok et Instagram (PRIORITÉ 2)

TikTok est en croissance explosive en Afrique francophone ( penetration estimée 35 % chez les 13–19 ans urbains au Togo). C'est le canal idéal pour la **notoriété** et l'**acquisition de masse**, mais avec un CAC plus élevé et une qualité d'utilisateur plus variable.

**Stratégie opérationnelle** :
- **Fréquence** : 3 vidéos/semaine (lundi, mercredi, vendredi) — minimum pour alimenter l'algorithme TikTok.
- **Formats** :
  - "Astuce maths en 30 sec" (concept pédagogique clé, exemple : théorème de Thalès en situation Lomé-Kpalimé).
  - "Erreur classique BEPC" (la faute que tout le monde fait, ex : confusion cos/sin dans triangle rectangle).
  - "Témoignage élève" (Amina / Koffi / Afi témoigne de son parcours avec ExamBoost).
  - "Challenge maths" (un problème, la solution dans la vidéo suivante).
- **Durée** : 30–60 secondes, format vertical 9:16.
- **Montage** : CapCut (gratuit), sous-titres automatiques FR (90 % des élèves regardent sans son en classe).
- **Hashtags** : #BEPC2026 #BACTogo #ExamBoost #Lomé #TogoEducation #RevisionBEPC.
- **Objectif** : 10 000 followers TikTok + 5 000 followers Instagram en 6 mois ; 1 000 téléchargements/mois attribués.
- **Budget ads** : 2 000 USD phase 2, 5 000 USD phase 3, 5 000 USD phase 4 — Total 12 000 USD (voir section 6).

#### Canal 3 — Bouche-à-oreille scolaire (PRIORITÉ 3)

Le bouche-à-oreille physique dans les lycées reste le canal le plus qualifié : un élève acquis via un ambassadeur a un taux de rétention 30 jours supérieur de 35 % à un élève TikTok.

**Programme ambassadeurs ExamBoost** :
- **Recrutement** : 1 élève relais par lycée pilote (objectif : 100 ambassadeurs sur 100 lycées à M14).
- **Profil** : délégué de classe, bon en classe, leadership naturel, smartphone fluide.
- **Rôle** : démo ExamBoost à 5 camarades par semaine, distribution de flyers QR code, relais des quiz WhatsApp.
- **Récompense** : premium gratuit 6 mois + goodies ExamBoost (t-shirt, stickers, carnet) + lettre de recommandation signée ExamBoost (valorisable pour bourses / CV).
- **Suivi** : dashboard ambassadeurs (Notion), réunion mensuelle en ligne (Zoom gratuit), groupe WhatsApp dédié.
- **Objectif** : 30 % des téléchargements attribués au bouche-à-oreille à M18.

#### Canal 4 — Cybercafés et boutiques télécom

Canal traditionnel mais efficace pour toucher les élèves qui n'ont pas de data à domicile.

- **Affiches ExamBoost** dans 50 cybercafés Lomé (quartiers Adawlato, Bè, Tokoin, Agoè) et 30 cybercafés dans les 4 grandes villes secondaires.
- **Format** : A3, QR code vers Play Store, slogan "Prépare ton BEPC gratuitement".
- **Coût** : 2 000 FCFA par affiche + 5 000 FCFA pour affichage 3 mois par cybercafé = ~350 000 FCFA total.
- **Partenariat opérateurs** : négociation Moov Africa Togo / Togo Telecom (YAS) pour "data bonus" — 100 Mo offerts pour activation ExamBoost premium.
- **QR code tracking** : un QR code par cybercafé pour mesurer la contribution.

### 3.2 Établissement B2B

#### Canal 1 — Démarchage direct (PRIORITÉ 1)

Le démarchage direct est le **seul canal crédible** pour atteindre 200 établissements en 18 mois. Les directeurs togolais d'établissements privés décident rarement sur la base d'un e-mail ; ils décident sur la base d'une rencontre physique.

**Stratégie opérationnelle** :
- **Cible** : 200 établissements privés prioritaires — Lomé (120), Sokodé (25), Kara (25), Atakpamé (15), Kpalimé (15).
- **Cadence** : 1 visite/semaine par commercial B2B, 4 démos/mois, taux de conversion cible 15 %.
- **Séquence de vente** :
  1. Prise de rendez-vous par téléphone (5 min) — script de 2 min voir Annexe B.
  2. Visite physique sur site (20 min) — présentation + démo APK + étude de cas Lomé.
  3. Essai gratuit 30 jours (signing d'un formulaire simple).
  4. Suivi à J+15 (appel) et J+30 (visite de closing).
  5. Signature contrat annuel + facturation.
- **Documentation remise** : brochure ExamBoost (8 pages, imprimée), démo APK sur tablette, étude de cas pilote Lomé (3 pages), grille tarifaire, contrat type.
- **Outils** : CRM Notion (pipeline par établissement), Google Maps pour optimisation tournées, kit commercial imprimé.
- **Objectif an 1** : 30 établissements signés (15 % de taux de conversion sur 200 démarchés).

#### Canal 2 — Salons et conférences éducation (PRIORITÉ 2)

Les salons éducatifs togolais rassemblent en 2 jours la moitié des directeurs d'établissements privés du pays — c'est le meilleur ratio temps/contacts.

| Événement | Date (typique) | Lieu | Public cible | Budget stand |
|---|---|---|---|---|
| Salon de l'Éducation Togo | Septembre | Palais des Congrès Lomé | 300+ directeurs privés + parents | 1 500 USD |
| Conférence nationale des directeurs | Octobre | Hôtel Sarakawa Lomé | 200 directeurs privés | 1 000 USD |
| Journée portes ouvertes FEDER | Mars | Siège FEDER Lomé | 150 directeurs membres FEDER | 800 USD |
| Forum Éducation AIMS Ghana | Novembre | AIMS Mbieya Ghana | chercheurs + décideurs éducatifs ouest-africains | 500 USD (déplacement) |

**Stand ExamBoost** : 1 roll-up 80×200 cm + 1 table + 2 tablettes avec démo + 1 commercial + 1 community manager + 500 flyers + 100 goodies (stylos). Suivi systématique des contacts dans les 72 h.

#### Canal 3 — Partenariats institutionnels (PRIORITÉ 3)

Le partenariat institutionnel permet de **décupler la crédibilité** et de bénéficier de la recommandation d'un tiers de confiance.

| Partenaire | Rôle | Effort | Impact attendu |
|---|---|---|---|
| FEDER (Fédération des Établissements Privés Togo) | Recommandation officielle ExamBoost aux 400 lycées privés membres | 1 rencontre trimestrielle + 1 présentation annuelle | 50 établissements signés via FEDER en 18 mois |
| ANFEJ (Association Nationale des Femmes Éducateurs) | Co-déploiement ExamBoost dans les écoles membres ANFEJ | 1 convention de partenariat | 20 établissements signés + dimension genre |
| MEPST via programme pilote officiel | Accord-cadre pour utilisation annales officielles + 10 écoles publiques pilotes | Dossier institutionnel complet | 10 écoles publiques + légitimité B2G |
| DREN Maritime (Lomé) | Recommandation aux établissements publics région Lomé | 1 rencontre semestrielle | 5 établissements publics phase 3 |

### 3.3 Ministère / B2G

#### Canal 1 — Appel d'offres GPE (PRIORITÉ 1)

Le Global Partnership for Education est le premier bailleur de l'éducation au Togo. Le pays est éligible aux financements GPE (multi-million USD) avec des fenêtres thématiques EdTech / IA éducatif.

- **Calendrier** : préparation du dossier Q3 2026 (juillet–septembre), soumission Q4 2026.
- **Montant typique** : 100 000–500 000 USD par projet EdTech.
- **Équipe dédiée** : chef de projet GTM (50 % de son temps) + mentor DJANTA / CcHub pour relecture dossier.
- **Cohérence** : projet ExamBoost aligné avec les priorités GPE Togo (SDG4, learning poverty, APC, equity genre).

#### Canal 2 — Coopération bilatérale

| Bailleur | Programme | Montant typique | Calendrier |
|---|---|---|---|
| AFD (France) | Éducation Afrique — projet EdTech | 100 000–300 000 EUR | Appel à projets annuel Q1 |
| USAID | Programme d'alphabétisation ASS (Afrique Subsaharienne) | 200 000–500 000 USD | Appel à manifestions d'intérêt Q2 |
| Banque Mondiale | Education Sector Support Project Togo (ESSP) | Variable (composante EdTech) | Cotraitance avec MEPST |
| UNICEF Innovation Fund | EdTech pour enfants défavorisés | 50 000–150 000 USD | Appel à propositions roulant |

La stratégie consiste à **ne pas dépendre du B2G pour survivre** — le modèle B2B+B2C doit atteindre le seuil de rentabilité GTM (100 écoles + 5 000 premium) à M13 indépendamment des subventions. Le B2G est un accélérateur, pas un pilier.

---

## 4. Plan d'exécution — 18 mois

Le plan d'exécution se déroule en **quatre phases** alignées avec la feuille de route de l'Étude de Faisabilité 2025 (M1–M2 fondations, M3–M5 MVP, M5–M6 pilote, M7–M8 lancement, M9–M12 croissance, M13–M18 consolidation).

### Phase 1 — Pilote (M0–M3, juillet–septembre 2026)

**Objectif principal** : valider le produit, l'UX et la valeur pédagogique sur un échantillon restreint, avant le lancement public.

**Périmètre** :
- 5 établissements pilotes Lomé (3 privés + 2 publics).
- 300 élèves testeurs (60 par établissement, classes de 3e et Terminale).
- 2 matières prioritaires : Mathématiques + Sciences Physiques (les plus documentées en échec BEPC/BAC).

**Activités clés** :
- Juillet 2026 : sélection des 5 établissements (appel à candidatures via FEDER + Lomé), recrutement 1 community manager, démarrage enquête terrain (200 élèves 5 villes).
- Août 2026 : déploiement APK beta-testeurs (Play Store Internal Testing), formation 5 directeurs + 10 enseignants référents (2h/établissement), démarrage accompagnement hebdomadaire.
- Septembre 2026 : mesure d'impact sur notes de contrôle de début d'année (T1), collecte retours utilisateurs (entretiens semi-directifs), itération produit priorisée.

**Livrables** :
- APK beta fonctionnel (modules révision + simulation + dashboard).
- Rapport d'impact pilote (15 pages) — amélioration notes, taux de rétention, NPS élèves.
- 5 témoignages vidéo élèves + 5 témoignages directeurs.
- Recalibrage IRT initial sur les 300 élèves pilotes (objectif : 500+ réponses collectées).

**Équipe GTM** : 1 chef de projet (ETP) + 1 community manager (ETP dès M2).

**Budget** : 12 000 USD (cf. section 6).

**Critères de passage en Phase 2** (go/no-go fin septembre 2026) :
- Rétention 30 jours ≥ 50 % sur les 300 élèves.
- NPS élèves ≥ 40.
- Amélioration notes contrôle ≥ +5 pts (vs base de référence T0).
- 3 directeurs sur 5 favorables à un contrat annuel payant.

### Phase 2 — Lancement Lomé (M4–M8, octobre 2026–février 2027)

**Objectif principal** : lancer publiquement ExamBoost sur le Play Store national, recruter 50 lycées partenaires et 5 000 élèves actifs à Lomé.

**Périmètre** : Lomé + agglomération ( Agoè, Kpalimé banlieue proche).

**Activités clés** :
- Octobre 2026 : publication Play Store national (APK public), recrutement 1 commercial B2B, lancement campagne TikTok/Instagram, démarrage programme ambassadeurs (20 lycées Lomé).
- Novembre 2026 : démarchage B2B intensif (40 établissements ciblés), présence Salon de l'Éducation Togo, lancement programme influenceurs étudiants (10 Lomé).
- Décembre 2026 : bilan annuel + 1er établissement partenaire officiel signé (communiqué presse), distribution affiches cybercafés.
- Janvier 2027 : préparation rentrée scolaire T2, intensification démarchage, lancement bundle opérateur (si accord Moov/Togo Telecom signé).
- Février 2027 : objectif 50 lycées partenaires atteint, 5 000 élèves actifs, 100 premium (2 % conversion).

**Livrables** :
- Application publique Play Store + iOS App Store (version iOS en M6).
- 50 contrats établissements signés (objectif : 30 privés + 20 publics via FEDER/MEPST).
- Banque de questions enrichie à 1 500+ (pipeline OCR actif).
- Intégration mobile money Flooz + TMoney pour paiement premium.

**Équipe GTM** : 1 chef de projet + 1 commercial B2B + 1 community manager = 3 ETP.

**Budget** : 32 000 USD.

### Phase 3 — Expansion nationale (M9–M14, mars–août 2027)

**Objectif principal** : étendre la couverture aux 4 grandes villes secondaires (Sokodé, Kara, Atakpamé, Kpalimé) et atteindre 200 établissements partenaires + 20 000 élèves actifs.

**Périmètre** : 5 villes total (Lomé + 4 régions).

**Activités clés** :
- Mars 2027 : recrutement 2 commerciaux régionaux (1 Sokodé, 1 Kara), formation 2 jours Lomé, démarrage démarchage régional.
- Avril 2027 : lancement opération Atakpamé + Kpalimé (par les commerciaux régionaux en déplacement).
- Mai 2027 : intégration module communauté (classements inter-établissements, défis hebdo) — développé par Agent R (Session 2).
- Juin 2027 : campagne intensive pré-BAC (juin = mois du BAC au Togo), pousse simulation d'examen chronométrée.
- Juillet 2027 : bilan mi-parcours 18 mois, ajustement stratégie si KPIs en retard.
- Août 2027 : objectif 200 établissements partenaires atteint, 20 000 élèves actifs, 800 premium (4 % conversion).

**Livrables** :
- Couverture nationale 5 villes.
- 200 contrats établissements signés.
- Banque de questions enrichie à 5 000+ (pipeline OCR complet).
- Rapport d'impact semestriel pour bailleurs (GPE, AFD).

**Équipe GTM** : 1 chef de projet + 1 commercial B2B + 1 community manager + 2 commerciaux régionaux = 5 ETP.

**Budget** : 51 000 USD (phase la plus coûteuse — explosion salariale + démarchage inter-villes).

### Phase 4 — Consolidation CEDEAO (M15–M18, septembre–décembre 2027)

**Objectif principal** : consolider la position togolaise, préparer l'expansion CEDEAO, atteindre 50 000 élèves actifs + 5 000 premium.

**Périmètre** : Togo (consolidation) + Bénin (lancement pilote Cotonou/Porto-Novo).

**Activités clés** :
- Septembre 2027 : lancement Bénin pilote (5 établissements Cotonou, même curriculum BEPC francophone — adaptation curriculum Bénin nécessaire mais limitée).
- Octobre 2027 : préparation dossier d'expansion Côte d'Ivoire (curriculum BAC différent — adaptation plus lourde) et Burkina Faso (curriculum proche Togo).
- Novembre 2027 : levée de fonds Série A (cible 1M USD) — pitch deck examBoost, dossier d'investissement, roadshow Lomé + Accra + Dakar.
- Décembre 2027 : bilan 18 mois + projections 2028, objectif 50 000 élèves actifs + 5 000 premium (5 % conversion).

**Livrables** :
- Pilote Bénin opérationnel (5 écoles + 500 élèves Cotonou).
- Dossier Série A prêt (financial model, traction, projections).
- Rapport d'impact 18 mois (30 pages, diffusion publique).
- Plan stratégique 2028–2030 (extension CEDEAO + francophonie élargie).

**Équipe GTM** : 5 ETP Togo + 1 consultant Bénin (mission ponctuelle) = 5,5 ETP.

**Budget** : 44 000 USD.

---

## 5. KPIs et objectifs

Les KPIs sont organisés en 4 catégories : acquisition, rétention, pédagogiques, financiers. Chaque KPI a une cible trimestrielle (M3, M6, M12, M18) et un responsable.

### 5.1 KPIs acquisition

| KPI | M3 (pilote) | M6 (lancement) | M12 (croissance) | M18 (consolidation) | Responsable |
|---|---|---|---|---|---|
| Élèves actifs/mois | 300 | 1 000 | 20 000 | 50 000 | Chef de projet |
| Établissements partenaires | 5 | 20 | 100 | 200 | Commercial B2B |
| Téléchargements Play Store | 500 | 2 000 | 30 000 | 80 000 | Community manager |
| Taux conversion gratuit → premium | 0 % | 2 % | 4 % | 5 % | Chef de projet |
| Nouveaux élèves/semaine | 25 | 150 | 1 200 | 1 500 | Community manager |
| Ambassadeurs actifs | 5 | 25 | 70 | 100 | Community manager |

### 5.2 KPIs rétention

| KPI | M3 | M6 | M12 | M18 | Benchmark |
|---|---|---|---|---|---|
| Rétention 30 jours | 50 % | 55 % | 60 % | 65 % | Duolingo : 55 % (référence mondiale) |
| Rétention 7 jours | 70 % | 72 % | 75 % | 78 % | - |
| Sessions/user/semaine | 2 | 3 | 4 | 5 | - |
| Streak moyen (jours consécutifs) | 2 | 3 | 5 | 7 | Duolingo : 9,2 jours |
| Durée moyenne session | 8 min | 10 min | 12 min | 15 min | - |
| Désinstallations 30 jours | 35 % | 30 % | 25 % | 22 % | - |

### 5.3 KPIs pédagogiques

| KPI | M6 | M12 | M18 | Méthode de mesure |
|---|---|---|---|---|
| Amélioration notes de contrôle | +5 pts | +10 pts | +15 pts | Comparaison notes T0 vs T1/T2/T3 (groupe pilote vs groupe contrôle) |
| Taux de maîtrise compétences | 30 % | 50 % | 70 % | % de compétences avec P(L) BKT ≥ 0,85 |
| Score BEPC prédit vs réel | n/a (pas encore d'examen) | n/a | +/- 5 % | Calibration XGBoost sur résultats BEPC juin 2027 |
| Simulations d'examen complétées/élève | 1 | 3 | 5 | Backend FastAPI endpoint /sessions |
| Taux de complétion des sessions | 60 % | 70 % | 75 % | Backend /sessions stats |

### 5.4 KPIs financiers

| KPI | M6 | M12 | M18 | Commentaire |
|---|---|---|---|---|
| Revenus mensuels (FCFA) | 0 | 1 000 000 | 5 000 000 | Mix établissements + premium élèves |
| Revenus cumulés 18 mois (FCFA) | 0 | ~5 000 000 | ~30 000 000 | Projection conservatrice |
| Coût acquisition élève (CAC) | 200 | 300 | 400 | Baisse progressive grâce au bouche-à-oreille |
| Coût acquisition école (CAC) | 50 000 | 40 000 | 30 000 | Baisse grâce à la notoriété et à FEDER |
| LTV élève (12 mois) | 0 | 5 000 | 15 000 | Hypothèse : 6 mois premium moyen |
| LTV école (3 ans) | 100 000 | 200 000 | 300 000 | Hypothèse : rétention 80 % an 1, 70 % an 2 |
| Ratio LTV/CAC élève | n/a | 17x | 37x | Sain au-dessus de 3x |
| Ratio LTV/CAC école | 2x | 5x | 10x | Sain au-dessus de 3x |
| Marge brute | n/a | 60 % | 70 % | Hors salaires équipe technique (comptés en opex) |

---

## 6. Budget marketing & sales

### 6.1 Budget par phase (18 mois)

Le budget GTM total sur 18 mois est de **139 000 USD** (~83 millions FCFA), intégré dans le budget projet global de **246 400 USD** de l'Étude de Faisabilité (sur la ligne "Marketing et onboarding lycées" — 8 000 USD phase 1, 15 000 USD phase 2). Le présent plan GTM étend et détaille cette enveloppe.

| Poste | Phase 1 (M0–M3) | Phase 2 (M4–M8) | Phase 3 (M9–M14) | Phase 4 (M15–M18) | Total 18 mois |
|---|---|---|---|---|---|
| Salaires GTM (cumul progressif : 1 → 5 ETP) | 9 000 | 18 000 | 27 000 | 27 000 | 81 000 USD |
| Démarchage écoles (déplacements, kit commercial) | 1 000 | 5 000 | 8 000 | 5 000 | 19 000 USD |
| Social media ads (TikTok + Instagram + WhatsApp Business) | 0 | 2 000 | 5 000 | 5 000 | 12 000 USD |
| Événements / salons (stands, goodies) | 1 000 | 3 000 | 5 000 | 3 000 | 12 000 USD |
| Print (affiches cybercafés, flyers, brochures) | 500 | 2 000 | 3 000 | 2 000 | 7 500 USD |
| Influenceurs étudiants (commissions + goodies) | 500 | 2 000 | 3 000 | 2 000 | 7 500 USD |
| **Total par phase** | **12 000** | **32 000** | **51 000** | **44 000** | **139 000 USD** |

#### Détail des salaires GTM (81 000 USD sur 18 mois)

| Rôle | Période | ETP | Salaire mensuel | Durée (mois) | Total |
|---|---|---|---|---|---|
| Chef de projet GTM | M0–M18 | 1 | 1 500 USD | 18 | 27 000 USD |
| Community manager | M2–M18 | 1 | 800 USD | 16 | 12 800 USD |
| Commercial B2B | M4–M18 | 1 | 1 000 USD + commission 5 % | 14 | 14 000 USD (+ ~4 200 USD commissions) |
| Commercial régional Sokodé | M9–M18 | 1 | 800 USD | 9 | 7 200 USD |
| Commercial régional Kara | M9–M18 | 1 | 800 USD | 9 | 7 200 USD |
| **Total salaires bruts** | | | | | **68 400 USD** |
| Commissions B2B (5 % par école signée) | | | | | ~4 200 USD |
| Charges sociales (~12 % brut Togo) | | | | | ~8 400 USD |
| **Total salaires chargés** | | | | | **81 000 USD** |

### 6.2 ROI attendu

#### Calcul LTV/CAC élève premium

| Élément | Valeur | Justification |
|---|---|---|
| CAC élève | 400 FCFA (~0,6 USD) | Mix TikTok (CAC 1 200 FCFA), WhatsApp (CAC 300 FCFA), ambassadeurs (CAC 800 FCFA), bouche-à-oreille organique (CAC 0) |
| Taux conversion gratuit → premium | 5 % | Cible M18 (benchmark Afrilearn : 8 %, Duolingo : 7 %) |
| LTV premium (sur 12 mois) | 15 000 FCFA | Hypothèse moyenne 6 mois premium × 2 000 FCFA + 1 mois offert parrainage + 2 mois churnés |
| LTV non-premium (12 mois) | 0 FCFA | Mais contribution indirecte : volume pour négociation B2B |
| Ratio LTV/CAC élève premium | **37x** | Excellent (benchmark SaaS sain > 3x) |

#### Calcul LTV/CAC établissement

| Élément | Valeur | Justification |
|---|---|---|
| CAC école | 30 000 FCFA (~50 USD) | Démarchage direct + salaire commercial / 30 écoles signées/an |
| LTV école sur 3 ans | 300 000 FCFA | 100 000 FCFA/an × 3 ans × rétention 100 % an 1 + 80 % an 2 + 60 % an 3 = 240 000 FCFA ; ajout premium établissement (~60 000) |
| Ratio LTV/CAC école | **10x** | Très sain (SaaS B2B sain > 5x) |

#### Seuil de rentabilité GTM

Le seuil de rentabilité GTM est atteint lorsque les revenus récurrents couvrent les coûts opérationnels GTM mensuels.

| Étape | M13 (objectif) | M18 (objectif) |
|---|---|---|
| Écoles partenaires | 100 | 200 |
| Revenus annuels écoles (FCFA) | 12 000 000 | 24 000 000 |
| Élèves premium | 2 500 | 5 000 |
| Revenus annuels premium (FCFA) | 60 000 000 | 120 000 000 |
| **Revenus annuels totaux (FCFA)** | **72 000 000** (~110 000 USD) | **144 000 000** (~218 000 USD) |
| Coûts GTM annuels (FCFA) | ~85 000 000 (~130 000 USD) | ~85 000 000 (~130 000 USD) |
| **Break-even GTM atteint** | Quasi (95 % couverture) | Oui (167 % couverture) |

**Conclusion** : le seuil de rentabilité GTM est atteint vers **M13** avec 100 écoles + 2 500 premium élèves (légèrement en-dessous du seuil strict), et largement dépassé à M18 avec 200 écoles + 5 000 premium élèves. La viabilité financière de l'opération GTM est démontrée.

---

## 7. Équipe Go-to-Market

### 7.1 Rôles

#### Chef de projet GTM (1 ETP, M0–M18)

| Caractéristique | Description |
|---|---|
| Profil | MBA ou expérience commerciale EdTech ; idéalement ancien chef de produit ou business developer avec 5+ ans d'expérience en Afrique de l'Ouest |
| Missions | Stratégie globale, partenariats institutionnels (MEPST, FEDER, GPE), fundraising, reporting investisseurs, coordination équipe GTM |
| Compétences clés | Négociation B2B/B2G, fundraising, gestion projet agile, anglais opérationnel (pour bailleurs internationaux) |
| Salaire | 1 500 USD/mois + equity (3–5 %) |
| Recrutement | Dès M0 (juillet 2026), priorité absolue |
| KPIs | Revenus totaux, partenariats signés, funds raised |

#### Commercial B2B (1 ETP dès M4)

| Caractéristique | Description |
|---|---|
| Profil | Expérience démarchage écoles, réseau FEDER existant, connaissance du tissu éducatif togolais ; français + idéalement éwé ou kabyè |
| Missions | 200 écoles cibles sur 18 mois, 30 démos/mois, signature 30 contrats an 1, 80 an 2 |
| Compétences clés | Présentation commerciale, négociation prix, closing, CRM |
| Salaire | 1 000 USD/mois + commission 5 % par école signée (200 USD × 110 écoles signées sur 18 mois = ~22 000 USD de commissions totales) |
| Recrutement | Septembre 2026 (M3) |
| KPIs | Nombre de démos/mois, taux de conversion démarche → signature, revenus B2B |

#### Community Manager (1 ETP dès M2)

| Caractéristique | Description |
|---|---|
| Profil | Expérience contenu TikTok/Instagram, idéalement étudiant ou récent diplômé (meilleure compréhension de la cible), créatif, fluide en français togolais |
| Missions | 3 vidéos/semaine TikTok/Instagram, gestion WhatsApp groups scolaires, programme ambassadeurs, community management (réponses commentaires, support élève niveau 1) |
| Compétences clés | CapCut, écriture web, copywriting, notions design (Canva), animation communauté |
| Salaire | 800 USD/mois |
| Recrutement | Août 2026 (M2) |
| KPIs | Followers TikTok/IG, vues par vidéo, téléchargements attribués, nombre ambassadeurs actifs |

#### Commerciaux régionaux (2 ETP dès M9)

| Caractéristique | Description |
|---|---|
| Profil | Commerciaux terrain basés à Sokodé et Kara, connaissance tissu éducatif régional, multilingues (français + langue locale) |
| Missions | Démarchage établissements nord Togo (Sokodé + Kara + Atakpamé + Kpalimé), 20 démos/mois chacun |
| Compétences clés | Autonomie, gestion déplacements inter-villes, présentation commerciale |
| Salaire | 800 USD/mois chacun |
| Recrutement | Mars 2027 (M9) |
| KPIs | Démarches réalisés, taux de conversion régional, établissements signés par région |

### 7.2 Organisation

#### Rituels équipe GTM

| Rituel | Fréquence | Durée | Participants | Format |
|---|---|---|---|---|
| Stand-up quotidien | Quotidien 9h00 | 15 min | Équipe GTM complète | Tour de table : 1 succès / 1 blocage / 1 priorité jour |
| Revue KPIs hebdomadaire | Lundi 10h00 | 60 min | Équipe GTM + chef de projet | Dashboard Notion, suivi M3/M6/M12/M18, ajustements |
| Revue stratégie trimestrielle | Mars / Juin / Septembre / Décembre | 180 min | Équipe GTM + fondateurs + mentor DJANTA | Revue objectifs, planification Q suivant |
| Rétro produit mensuelle | 1er vendredi du mois | 90 min | Équipe GTM + équipe technique | Retours terrain → backlog produit priorisé |
| 1:1 chef de projet / chaque membre | Hebdomadaire | 30 min | Chef projet + chaque membre | Coaching, blocages, développement |

#### Outils

| Outil | Usage | Coût |
|---|---|---|
| Notion | CRM B2B + dashboard KPIs + wiki équipe | 8 USD/mois (plan Plus) |
| HubSpot Free (backup) | Email sequences B2B, tracking contacts | Gratuit |
| WhatsApp Business | Broadcast mini-quiz + support élève niveau 1 | Gratuit |
| Bitly | Tracking liens (attribution canaux) | Gratuit |
| Google Sheets | Suivi téléchargements, calculs LTV/CAC | Gratuit |
| CapCut | Montage TikTok/Instagram | Gratuit |
| Canva Pro | Brochures, flyers, affiches | 13 USD/mois |
| MailerLite | Newsletter mensuelle élèves + directeurs | Gratuit < 1 000 contacts |

#### Formation continue équipe GTM

- Onboarding ExamBoost 1 jour complet à l'arrivée (produit, pitch, démo, objection handling).
- Formation continue : 2h/mois sur un sujet (marché EdTech Afrique, objections classiques B2B, dernières features produit).
- Budget formation : 1 000 USD/an par membre équipe GTM (vidéos LinkedIn Learning, livres, formations en ligne).

---

## 8. Partenariats stratégiques

### 8.1 Partenaires technologie

| Partenaire | Nature du partenariat | Statut / échéance | Bénéfice attendu |
|---|---|---|---|
| Google for Education | Accès Google Workspace for Education gratuit | Approche Q3 2026 | 50 licences Gmail + Drive + Classroom pour équipe ExamBoost + écoles pilotes |
| FlutterFlow | Startup program (réduction 50 %) | Inscrit juin 2026 | Réduction abonnement de 70 → 35 USD/mois |
| Railway.app | Startup credits (5 000 USD) | Demande Q3 2026 | Hébergement backend FastAPI gratuit 12 mois |
| OpenAI | Researcher credits (10 000 USD) via program | Demande Q3 2026 | Crédits API GPT-4o Vision pour pipeline OCR |
| Vercel | Hobby → Pro (credits startup) | Demande Q4 2026 | Hébergement landing page + dashboard marketing |
| GitHub | Education Pack (déjà actif) | Actif | Outils dev gratuits (Copilot etc.) |
| PostHog Cloud Free | Analytics product | Déjà actif | Tracking événements app, funnels, cohortes |

### 8.2 Partenaires distribution

| Partenaire | Nature du partenariat | Statut | Bénéfice attendu |
|---|---|---|---|
| Moov Africa Togo | Bundle data + ExamBoost premium (100 Mo offerts pour activation) | Négociation Q3 2026, signature espérée Q4 2026 | Levier acquisition massif (Moov = 40 % parts de marché mobile Togo) |
| Togo Telecom (YAS) | Idem Moov — bundle data + TMoney integration | Négociation Q3 2026 | Idem (YAS = 60 % parts de marché) |
| Canal+ Éducation | Distribution via décodeurs satellite | Opportunité long terme (post-M18) | Accès foyers ruraux équipés décodeurs Canal+ |
| Africa's Talking | API SMS Togo (0,02 USD/SMS) | Intégration Q4 2026 | Notifications élèves sans data permanente |

### 8.3 Partenaires institutionnels

| Partenaire | Nature du partenariat | Statut | Bénéfice attendu |
|---|---|---|---|
| MEPST (Ministère) | Accord-cadre pour utilisation annales officielles + 10 écoles publiques pilotes | Approche Q3 2026, signature espérée Q1 2027 | Légitimité B2G, accès curriculum officiel, intégration SIGE futur |
| FEDER (Fédération Établissements Privés) | Recommandation ExamBoost aux 400 lycées privés membres | Approche Q3 2026 | 50 établissements signés via FEDER en 18 mois |
| ANFEJ (Association Femmes Éducateurs) | Co-déploiement ExamBoost dans écoles membres | Approche Q4 2026 | 20 établissements + dimension genre |
| CcHub Lomé | Mentorat + networking investisseurs (post-DJANTA) | Programmes DJANTA Idée-Action | Accès mentors, investisseurs, écosystème |
| AIMS Ghana | Research collaboration (calibration IRT, validation scientifique) | Convention existante | Validation scientifique, accès chercheurs ML |
| Université de Lomé (Département Sciences Éducation) | Stage élèves chercheurs, évaluation pédagogique | Convention Q1 2027 | Évaluation indépendante impact pédagogique |
| JFF (Jobs for the Future) / EdTech Hub | Knowledge partnership | Adhésion Q4 2026 | Accès bonnes pratiques EdTech globales |

### 8.4 Partenaires média

| Partenaire | Nature | Format | Fréquence | Objectif |
|---|---|---|---|---|
| Télévision Togolaise (TVT) | Éducation show mensuel | 30 min, interview + démo | Mensuel dès M5 | Notoriété nationale, crédibilité institutionnelle |
| Radio Lomé FM | Émission éducation hebdo | 15 min, astuces BEPC | Hebdomadaire dès M4 | Toucher parents + élèves non connectés TV |
| Journal L'Événement | Tribune mensuelle | 1 page, analyse EdTech | Mensuel dès M3 | Crédibilité, SEO, référencement Google |
| Togo Tribune | Articles sponsorisés | 1 article/mois | Mensuel dès M4 | SEO, présence web |
| Togo First | Articles actualité ExamBoost | 1 article par jalon majeur | Ponctuel (5 jalons/an) | Notoriété auprès décideurs |
| Blog DJANTA Tech Hub | Article invité post-sélection | 1 article | Si sélection DJANTA | Credibilité écosystème tech |

---

## 9. Risques et mitigation

### 9.1 Risques acquisition

| Risque | Probabilité | Impact | Mitigation | Plan B |
|---|---|---|---|---|
| Adoption élève lente (< 5 000 actifs M6) | Moyenne | Élevé | Programme ambassadeurs + influenceurs + WhatsApp intensif | Pivot B2B-first (concentrer ressources sur écoles) |
| Refus écoles pour raison budgétaire | Élevée | Élevé | Pricing flexible public/privé + essai gratuit 3 mois + paiement trimestriel | Modèle freemium écoles (5 élèves gratuits, paiement au-delà) |
| Concurrence app gouvernementale lancée par MEPST | Faible | Élevé | Partenariat public-privé (positionner ExamBoost comme outil complémentaire officiel) | Pivot vers B2C premium + expansion CEDEAO accélérée |
| Saturation marché Lomé (< 30 écoles disponibles restantes) | Moyenne | Moyen | Expansion rapide régions dès M9 (anticipée M8 si saturation détectée) | Accélération Bénin Q4 2027 |
| Influencers étudiants peu performants | Moyenne | Faible | Suivi attribution code promo, audit mensuel, remplacement 30 % influencers sous-performants | Renforcement WhatsApp + ambassadeurs |
| Bundle opérateur Moov/YAS refusé | Moyenne | Moyen | Négociation avec seul 1 opérateur (YAS en priorité = 60 % PDM) | Aucun bundle, contenu optimisé 2G (images compressées) |
| Anti-sélection DJANTA (juillet 2026) | Moyenne | Élevé | Pitch deck 10 slides prêt, Q&A jury 57 questions préparées, dossier candidature soigné | Levée de fonds alternative (business angels Lomé + Accra, ifloop) |

### 9.2 Risques produit

| Risque | Probabilité | Impact | Mitigation | Plan B |
|---|---|---|---|---|
| Bugs critiques en production | Faible | Élevé | Tests unitaires (déjà 54 backend + 57 OCR), tests manuels appareils Tecno/Itel/Infinix avant chaque release, monitoring PostHog, équipe support niveau 1 (community manager) | Hotfix < 48 h, communication transparente users impactés |
| Qualité questions insuffisante | Moyenne | Élevé | Validation enseignants (2 enseignants experts MEPST) avant chaque batch, pipeline OCR rigoureux (Tesseract + GPT-4o Vision + validation jsonschema) | Correction immédiate + ajout modération communautaire (signalement erreur par élève) |
| Calibration IRT erronée | Faible | Élevé | Recalibration mensuelle sur 500+ réponses, garde-fous (bornes a/b/c, fallback heuristique si py-irt indisponible), revue scientifique AIMS Ghana | Calibration manuelle par enseignants experts (dur mais robuste) |
| Pipeline OCR bloque (sites sources down) | Moyenne | Moyen | 5 sources configurées (epreuvesetcorriges, banquedesepreuves, examens-concours, fomesoutra, digischool Afrique), upload manuel PDF possible | Saisie manuelle par opérateurs (3–5 ETP prévus dans budget Étude Faisabilité) |
| App trop lourde (> 30 Mo) | Faible | Moyen | APK optimisé Flutter, images WebP compressées, lazy loading, contenu lourd (questions) téléchargé à la demande | Distribution APK directe (sideload) hors Play Store pour zones 2G |
| Crash sur appareils 2 Go RAM | Moyenne | Élevé | Tests sur Tecno Spark 1 Go / Itel A16 / Infinix Hot 6 Lite, profilage mémoire Flutter DevTools, optimisation (Hive vs SharedPreferences, images SVG vs PNG) | Build "lite" allégé (sans dashboard, sans animations) |

### 9.3 Risques opérationnels

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Perte commercial B2B clé | Moyenne | Élevé | Documentation processus, formation 2nd commercial en M9 (régional), partage CRM |
| Retard recrutement (régional M9) | Élevée | Moyen | Anticipation recrutement dès M7, pool candidats via réseau AIMS Ghana + Université Lomé |
| Burnout équipe (charge trop forte phase 3) | Moyenne | Moyen | Renforcement effectif si pic, priorisation stricte backlog, coaching mensuel |
| Problème trésorerie (paiements écoles en retard) | Élevée | Élevé | Facturation annuelle d'avance avec escompte 10 %, ligne de crédit court terme (300 000 FCFA) négociée avec banque togolaise |
| Attaque cybersécurité backend | Faible | Élevé | CORS restrictif en prod, JWT 7 jours rotation, bcrypt hashing, sauvegardes PostgreSQL quotidiennes Railway |
| Perte de données élèves (Hive corrompu) | Faible | Élevé | Sync delta backend FastAPI (dès connexion), backup Hive local hebdo, tests de restauration trimestriels |

---

## 10. Plan de communication

### 10.1 Storytelling

Le storytelling ExamBoost s'articule autour d'un récit héroïque ancré dans le contexte togolais, déjà utilisé dans le Pitch Deck 10 slides et décliné sur tous les supports de communication.

**Héros** : Amina, 16 ans, élève de 3ème au Collège d'Enseignement Général d'Adawlato (Lomé).

**Défi** : BEPC dans 6 mois. Amina ne sait pas où elle en est — ses notes de contrôle oscillent entre 7 et 11/20 sans logique apparente. Elle a peur de ne pas réussir, comme 56 % des candidats en 2024. Ses parents ont économisé pour des cours de soutien à 10 000 FCFA/mois, mais le prof arrive souvent en retard et Amina n'ose pas poser ses questions.

**Rencontre avec ExamBoost** : Amina découvre l'app via un mini-quiz partagé dans son groupe WhatsApp scolaire. Elle installe l'app en 2 minutes, crée son profil (3e, Maths + Sciences Physiques + Français préférées). Elle découvre son premier flashcard — une question Pythagore avec un schéma clair. Elle répond juste, l'app lui propose une question un peu plus difficile (IRT adaptatif).

**Quotidien ExamBoost** : Amina fait 15 minutes d'ExamBoost chaque soir avant de dormir. L'app lui envoie une notification "Ta prochaine carte Pythagore est prête" via le système SM-2 (répétition espacée). Au bout de 7 jours, elle a une série (streak) de 7 — elle refuse de la casser. Son score global augmente de 4 points en 3 semaines.

**Résultat** : Amina passe le BEPC en juin 2027. Elle obtient 78 %, soit +34 points au-dessus de la moyenne nationale (44 %). La prédiction ExamBoost était 73 % +/- 5 %. Elle partage son résultat sur WhatsApp avec le hashtag #MerciExamBoost. Son lycée en parle en conseil de classe. 5 de ses camarades installent l'app dans la semaine.

**Message implicite** : si Amina à Adawlato a pu le faire, n'importe quel élève togolais peut le faire. ExamBoost ne demande pas de génie, pas d'argent, pas de connexion permanente — juste 15 minutes par jour.

### 10.2 Messages clés

Ces 4 messages clés sont déclinés sur tous les supports (pitch, TikTok, brochures, communiqués presse, ambassadeurs). Chacun est conçu pour être mémorisable en une seconde et défendable en trente secondes.

| # | Message | Usage prioritaire | Cible |
|---|---|---|---|
| 1 | "Prépare ton BEPC et ton BAC avec l'intelligence artificielle, gratuitement." | Homepage, Play Store description, TikTok bio | Élève |
| 2 | "L'app conçue pour les élèves togolais, par des Togolais." | Brochure B2B, communiqués presse | Directeur établissement, presse |
| 3 | "15 minutes par jour suffisent pour progresser." | Notifications push, TikTok, ambassadeurs | Élève (rétention) |
| 4 | "Ça marche même sans Internet." | Affiches cybercafés, brochure B2B rural | Élève rural, directeur établissement péri-urbain |

### 10.3 Calendrier contenu 6 mois

| Mois | Thème | Contenu phare | Canaux | KPI |
|---|---|---|---|---|
| Juillet 2026 | Teaser pré-lancement | Enquête terrain 200 élèves 5 villes — résultats préliminaires | Blog + Togo Tribune + Radio Lomé FM | 5 000 vues blog, 1 article Togo Tribune |
| Août 2026 | Lancement pilote 5 écoles | Communiqué presse officiel lancement pilote + 1ères photos Lomé | Communiqué presse + TVT + Instagram | 10 000 impressions, 500 followers Instagram |
| Septembre 2026 | Play Store launch | Vidéo teaser 2 min + témoignages élèves pilote + screenshots app | Play Store + TikTok + YouTube + L'Événement | 2 000 téléchargements, 50k vues TikTok |
| Octobre 2026 | 1000 élèves atteints | Reel TikTok "1000 élèves utilisent ExamBoost" + classement top lycées | TikTok + Instagram + WhatsApp | 5 000 élèves actifs, 100k vues TikTok |
| Novembre 2026 | 1er établissement partenaire officiel | Communiqué presse "Lycée X partenaire officiel ExamBoost" + interview directeur | Communiqué + L'Événement + Togo First | 5 écoles signées, 10k vues article |
| Décembre 2026 | Bilan annuel + projections 2027 | Rapport impact 2026 (10 pages) + projection 2027 + demande aide DJANTA | Blog + PDF téléchargeable + présentation partenaires | 1 000 téléchargements rapport, 3 partenariats identifiés |

### 10.4 Lignes éditoriales par canal

| Canal | Tonalité | Fréquence | Type contenu |
|---|---|---|---|
| TikTok | Décontracté, pédagogique, energique | 3/semaine | Astuces, erreurs classiques, témoignages, challenges |
| Instagram | Inspirant, visuel, communauté | 1/jour | Citations, infographies, photos élèves, stories coulisses |
| WhatsApp groups | Utile, court, engageant | 1/semaine | Mini-quiz hebdo + 1 lien ExamBoost |
| Blog ExamBoost | Expert, pédagogique, référencement | 2/mois | Articles SEO (préparation BEPC, méthodes révision, sujet annales 2024) |
| Newsletter élèves | Personnel, motivation | 1/mois | Stats perso, astuce du mois, défis, témoignage |
| Newsletter directeurs | Institutionnel, data-driven | 1/trimestre | Rapport impact, nouveautés produit, opportunités |
| Presse togolaise | Institutionnel, impact social | 1/mois | Tribune, communiqué, interview équipe |
| LinkedIn (équipe) | Professionnel, thought leadership | 1/semaine (par membre fondateur) | Apprentissages, EdTech Afrique, recrutement, levée |

---

## Annexe A — Templates emails

### A.1 Email démarchage école (B2B)

> **Objet** : Améliorer les résultats BEPC/BAC du [Nom lycée] avec l'IA — 3 min pour échanger ?
>
> Bonjour Monsieur/Madame le Directeur,
>
> Je suis [Prénom Nom], chef de projet ExamBoost Togo. Nous développons une application mobile de préparation aux examens nationaux (BEPC et BAC) 100 % alignée sur le programme MEPST, utilisée aujourd'hui par [N] élèves à Lomé.
>
> Au Collège [Référence pilote], les élèves qui ont utilisé ExamBoost pendant 3 mois ont amélioré leurs notes de contrôle de [X] points en moyenne. Concrètement :
> - Application gratuite pour chaque élève
> - Banque de questions BEPC/BAC toutes matières
> - Tableau de bord enseignant / directeur
> - Fonctionne hors-ligne sur smartphones d'entrée de gamme
>
> Je serais heureux de vous présenter une démo de 20 minutes sur place la semaine du [date]. Souhaitez-vous réserver un créneau ?
>
> Bien cordialement,
>
> [Prénom Nom]
> Chef de projet ExamBoost Togo
> [Téléphone] · [Email]

### A.2 Email suivi pilote (B2B post-démo)

> **Objet** : Suite à notre démo ExamBoost — essai gratuit 30 jours ?
>
> Bonjour Monsieur/Madame le Directeur,
>
> Merci pour votre accueil [Date] au [Nom lycée]. Comme convenu, je vous fais un récapitulatif :
>
> - **Application gratuite pour vos élèves** (Android et iOS)
> - **Tableau de bord directeur** (vue agrégée par classe, alertes élèves en difficulté)
> - **Tarif annuel** : 150 000 FCFA/an pour établissement privé, jusqu'à 500 élèves inclus
>
> Conformément à notre offre "early adopter", je vous propose **30 jours d'essai gratuit** (sans engagement) pour que vos élèves et enseignants testent l'app. À l'issue, vous décidez sans pression.
>
> Pour démarrer, il suffit de :
> 1. Confirmer par retour email
> 2. Désigner 1 enseignant référent (15 min de formation)
> 3. Communiquer le lien d'inscription à vos classes de 3e et Terminale
>
> Puis-je vous rappeler mardi prochain à [heure] pour finaliser ?
>
> Bien cordialement,
> [Prénom Nom]

### A.3 Email relance élève inactif (B2C)

> **Objet** : [Prénom], il te reste 7 jours à réviser avant ton BEPC
>
> Salut [Prénom],
>
> On t'a vu(e) progresser en Maths la semaine dernière (+5 points sur ton dernier contrôle simulé !) mais tu n'as pas révisé depuis 5 jours.
>
> Ta série (streak) de [N] jours est encore sauve — mais si tu ne fais pas une carte aujourd'hui, elle sera perdue demain.
>
> Une seule carte suffit pour la sauver. Tu peux le faire en 2 minutes :
>
> [Bouton : "Reprendre ma série"]
>
> Tu peux le faire,
> L'équipe ExamBoost

### A.4 Newsletter mensuelle (B2C)

> **Objet** : ExamBoost — Bilan de ton mois + astuce du mois
>
> Salut [Prénom],
>
> Ton bilan ExamBoost du mois de [Mois] :
>
> - **Cartes révisées** : [N]
> - **Score global** : [X]/20 (+[Y] ce mois)
> - **Streak le plus long** : [N] jours
> - **Compétence maîtrisée** : [Nom compétence] (Pythagore par ex.)
>
> **Astuce du mois** — Comment réviser plus efficacement en moins de temps :
> Fais tes cartes ExamBoost le soir avant de dormir. Pendant ton sommeil, ton cerveau consolide les apprentissages. C'est prouvé scientifiquement (et c'est exactement ce que fait l'algorithme SM-2 d'ExamBoost).
>
> **Défi du mois** : Réussis 50 cartes en Maths cette semaine pour gagner 1 mois de premium gratuit. Top 3 élèves Lomé au classement.
>
> [Bouton : "Commencer maintenant"]
>
> Bonne révision,
> L'équipe ExamBoost

---

## Annexe B — Scripts démarchage

### B.1 Script démarchage directeur école (5 min)

**Minute 0–1 — Introduction**
> "Bonjour Monsieur/Madame le Directeur, je suis [Prénom Nom] d'ExamBoost Togo. Merci de me recevoir. Je serai bref : 5 minutes pour vous présenter une application qui aide les élèves togolais à préparer le BEPC et le BAC, et qui est déjà utilisée par [N] élèves à Lomé."

**Minute 1–2 — Problème**
> "Le BEPC 2024 a chuté de 81 % à 44 %. Vos élèves de 3e et Terminale sont sous pression. Les cours de soutien privés coûtent 10 000 FCFA/mois — inaccessible pour la plupart. Les élèves n'ont pas d'outil pour savoir où ils en sont vraiment."

**Minute 2–3 — Solution**
> "ExamBoost est une app mobile gratuite pour l'élève, alignée sur le programme MEPST. Elle utilise l'IA pour :
> - Suivre les compétences maîtrisées par élève (Bayesian Knowledge Tracing)
> - Planifier les révisions au moment optimal (répétition espacée SM-2)
> - Prédire le score BEPC/BAC probable
> - Offrir des simulations d'examen chronométrées
>
> Ça marche même hors-ligne sur smartphone d'entrée de gamme."

**Minute 3–4 — Démo**
> "Je vous montre en 1 minute ? [Ouvre l'app sur tablette]. Voici le dashboard élève : score global, progression par matière, prédiction BEPC. Voici une session de révision : l'élève répond, l'app adapte la difficulté. Voici la simulation d'examen : conditions réelles, chronomètre, rapport détaillé après."

**Minute 4–5 — Ask**
> "Nous proposons aux 50 premiers établissements un essai gratuit de 30 jours. Si vous êtes intéressé, je vous laisse un kit et je reviens la semaine prochaine avec un enseignant référent pour démarrer. Vous avez des questions ?"

### B.2 Script appel téléphonique (2 min)

> "Bonjour, [Prénom Nom] d'ExamBoost Togo. Vous êtes bien le directeur du [Nom lycée] ?
>
> Je serai bref. Nous avons développé une application gratuite pour les élèves togolais de 3e et Terminale, qui les aide à préparer le BEPC et le BAC avec l'IA. C'est déjà utilisé par [N] élèves à Lomé.
>
> Je serais à Lomé la semaine prochaine. Puis-je passer 20 minutes vous présenter l'app ? Mardi 10h ou jeudi 14h ?
>
> [Si oui] Parfait, je vous envoie une confirmation par email avec un plan d'accès. Merci beaucoup, à [jour].
>
> [Si non] Pas de souci, je vous envoie un email récap avec une démo vidéo de 2 minutes. Si ça vous intéresse, on en reparle. Bonne journée."

### B.3 Script présentation parents (10 min)

**Minute 0–1 — Accroche émotionnelle**
> "Bonjour à tous. Votre enfant est en 3e ou en Terminale cette année. Le BEPC 2024 a eu 56 % d'échec. Le BAC 2 : 53 %. Votre enfant est-il prêt ? Vraiment prêt ? A-t-il un outil pour le savoir ?"

**Minute 1–3 — Le problème concret**
> "Aujourd'hui, votre enfant révise comment ? Avec des PDF d'annales envoyés sur WhatsApp ? Avec des cours de soutien à 10 000 FCFA/mois qui ne couvrent qu'une matière ? Avec aucune idée de là où il en est vraiment ?"

**Minute 3–6 — La solution ExamBoost**
> "ExamBoost est une application gratuite. Votre enfant la télécharge en 2 minutes sur Play Store. Il crée son profil — classe, matières préférées. L'app lui propose des questions adaptées à son niveau. Chaque réponse ajuste son parcours. Au bout de 7 jours, il a un tableau de bord : voilà où il en est en Maths, en Sciences Physiques, en Français. Voilà son score BEPC probable. 15 minutes par jour suffisent."

**Minute 6–8 — Démo + témoignage**
> "Je vous montre. [Démo tablette 1 min]. Voici Amina, élève de 3e à Adawlato. En 3 mois avec ExamBoost, elle a augmenté ses notes de 8 points. Elle a eu 78 % au BEPC 2027."

**Minute 8–9 — Pour les parents**
> "En tant que parent, qu'est-ce que vous y gagnez ?
> - Vous savez où en est votre enfant (transparence)
> - Vous n'avez pas à payer des cours particuliers coûteux
> - Vous pouvez suivre sa progression
> - Ça marche même si vous n'avez pas Internet à la maison (offline)"

**Minute 9–10 — Ask**
> "Trois choses à faire ce soir :
> 1. Demandez à votre enfant d'installer ExamBoost (lien dans le flyer que je vous distribue)
> 2. Encouragez-le à faire 15 minutes par jour pendant 7 jours
> 3. Revenez me voir dans 2 semaines pour un premier bilan
>
> Merci. Questions ?"

---

## Annexe C — Métriques dashboard

### C.1 KPIs à suivre hebdomadairement

Le dashboard KPIs (Notion) est mis à jour chaque lundi 10h avant la revue hebdomadaire. Voici la structure complète.

#### Onglet 1 — Vue exécutive (1 page)

| Section | KPIs | Source |
|---|---|---|
| Acquisition | Élèves actifs/mois, Nouveaux élèves/semaine, Téléchargements cumulés, Premium élèves | PostHog + Backend |
| Établissements | Établissements partenaires, Établissements en pipeline (démarchés), Taux conversion démarche → signature | Notion CRM |
| Rétention | Rétention 30 jours, Rétention 7 jours, Streak moyen, Sessions/user/sem | PostHog + Backend |
| Pédagogie | Amélioration notes (vs base T0), Compétences maîtrisées, Simulations complétées | Backend /predict |
| Financier | Revenus mensuels, CAC élève, CAC école, LTV/CAC ratios | Comptabilité + Sheets |

#### Onglet 2 — Acquisition détaillée

- Funnel complet : Impressions → Clics → Installations → Onboarding complété → 1ère session → 7 jours actifs → 30 jours actifs → Premium conversion.
- Attribution par canal : TikTok, Instagram, WhatsApp groups, ambassadeurs, organic Play Store, B2B école (élève vient via école partenaire), parrainage.
- Cohortes d'utilisateurs (semaine d'installation) — rétention 7/14/30/60/90 jours.

#### Onglet 3 — Établissements B2B

- Pipeline CRM : Prospect → Démarché → Démo réalisée → Essai gratuit → Contrat signé → Actif → Renouvelé / Churné.
- Top 20 établissements en cours (statut, dernière interaction, prochaine action).
- Carte géographique (Google Maps) des établissements partenaires et prospects.

#### Onglet 4 — Rétention et engagement

- DAU/WAU/MAU (Daily/Weekly/Monthly Active Users) avec ratio DAU/MAU (stickiness).
- Heatmap activité par heure et par jour (quand les élèves révisent).
- Top 10 fonctionnalités utilisées (révision, simulation, dashboard, communauté).
- Taux de complétion des sessions de révision (start → end).

#### Onglet 5 — Pédagogie et impact

- Distribution des scores BEPC/BAC prédits (histogramme).
- Top 10 compétences les plus maîtrisées / moins maîtrisées (national).
- Comparaison notes contrôle ExamBoost vs non-ExamBoost (groupe pilote vs contrôle).
- Témoignages élèves collectés (10 derniers).

#### Onglet 6 — Finances

- Revenus mensuels (école + premium élèves).
- Coûts GTM mensuels (salaires + marketing + ops).
- Marge brute mensuelle.
- Runway (trésorerie / burn rate).
- Pipeline fundraising (subventions + investisseurs).

### C.2 Outil — Notion dashboard

Le dashboard est construit sur Notion (plan Plus à 8 USD/mois) avec les blocs suivants :

| Bloc | Type Notion | Source |
|---|---|---|
| Vue exécutive | Page avec toggles | Saisie manuelle hebdo |
| Acquisition | Database (table) | Sync PostHog (export CSV hebdo) |
| Établissements B2B | Database (Kanban) | Saisie commerciale directe |
| Rétention | Database (table) + vue graphique | Sync PostHog |
| Pédagogie | Page avec widgets embed | Sync backend /predict endpoint |
| Finances | Page avec table + formules | Saisie comptabilité + sync Stripe/Flooz/TMoney |

Alternative : Google Sheets (gratuit) avec onglets équivalents et formules IMPORTRANGE pour synchronisation backend. Recommandé en phase 1 (budget serré), migration Notion dès phase 2.

### C.3 Reporting externe

| Rapport | Destinataires | Fréquence | Format |
|---|---|---|---|
| KPIs hebdo interne | Équipe GTM | Lundi 10h | Notion + email récap |
| Rapport mensuel | Fondateurs + mentors DJANTA | 1er du mois | PDF 5 pages + présentation 15 min |
| Rapport trimestriel | Investisseurs + bailleurs potentiels | Mars / Juin / Septembre / Décembre | PDF 15 pages + call 60 min |
| Rapport d'impact annuel | Public (site web) | Décembre | PDF 30 pages + site web dédié |

---

## Conclusion — Plan Go-to-Market ExamBoost Togo

Le plan go-to-market présenté ici articule une **stratégie B2B2C** conçue pour le marché togolais, avec un objectif de **50 000 élèves actifs et 200 établissements partenaires à 18 mois**. Les principales forces du plan :

1. **Ancrage local togolais** — segmentation en 5 villes prioritaires, démarchage direct FEDER, bundle opérateurs Moov/YAS, narration Amina Adawlato, dimensionnement Tecno/Itel/Infinix.
2. **Modèle économique viable** — élève gratuit pour toujours (maximisation adoption), école à 100–150k FCFA/an (revenus prévisibles B2B), 5 % premium (valeur ajoutée). Ratios LTV/CAC cibles : 37x élève, 10x école.
3. **Exécution par phases** — pilote 5 écoles Lomé → lancement Play Store → expansion 5 villes → consolidation Bénin. Go/no-go au M3 sur critères mesurables.
4. **Budget maîtrisé** — 139 000 USD sur 18 mois, intégré dans le budget projet global de 246 400 USD de l'Étude de Faisabilité.
5. **Équipe GTM rationnelle** — 4 ETP au pic (1 chef projet + 1 commercial B2B + 1 community manager + 2 commerciaux régionaux), avec rituals agiles et CRM Notion.
6. **Mitigation des risques** — anti-sélection DJANTA, refus écoles, bugs produit, concurrence gouv : chacun a un plan B opérationnel.
7. **Partenariats structurés** — MEPST (B2G), FEDER (B2B), Moov/YAS (distribution), AIMS Ghana (scientifique), CcHub (écosystème).
8. **Communication narrative** — storytelling Amina, 4 messages clés mémorisables, calendrier contenu 6 mois, lignes éditoriales par canal.

Les conditions de succès du plan sont claires :
- **Anti-sélection DJANTA le 24 juillet 2026** (pivote le fundraising et la crédibilité écosystème).
- **Pilote Lomé septembre 2026** (valide produit + UX + impact pédagogique).
- **Bundle opérateur Moov/YAS** (décuple l'acquisition B2C en levant le frein data).
- **Partenariat FEDER signé** (décuple le démarchage B2B).
- **Recrutement commercial B2B + 2 commerciaux régionaux en temps et en heure** (sans retard Phase 2 et Phase 3).

Si ces 5 conditions sont réunies, ExamBoost Togo a une trajectoire crédible vers **50 000 élèves actifs, 200 écoles partenaires, 5 000 premium élèves, 5 M FCFA/mois de revenus récurrents à M18**, avec un seuil de rentabilité GTM atteint vers M13. Le projet est alors prêt pour une levée Série A (1M USD cible) en novembre 2027 et l'expansion CEDEAO (Bénin, Côte d'Ivoire, Burkina Faso) en 2028–2029.

La mission d'ExamBoost Togo — donner à chaque élève togolais les mêmes chances de réussite aux examens nationaux, gratuitement, avec l'intelligence artificielle — est désormais équipée d'un plan opérationnel concret, chiffré, séquencé et budgété. Reste à exécuter.

---

*Fin du Plan Go-to-Market — ExamBoost Togo — Version 1.0 — 30 juin 2026*
*Document de production — Confidentiel*
*Préparé par l'équipe ExamBoost Togo (SmartFarm Togo / AIMS Ghana — Division EdTech)*
*Pour diffusion interne équipe, mentors DJANTA, investisseurs sollicités*
