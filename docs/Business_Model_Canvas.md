# ExamBoost Togo — Business Model Canvas

*Modèle économique B2B2C — Juillet 2026 — v1.0*
*Référence : Plan_GoToMarket.md v1.0 + Investor_Deck_15_slides.md + Étude de Faisabilité 2025*

---

## Vue d'ensemble — 9 blocs

Le Business Model Canvas ci-dessous résume l'architecture complète du modèle ExamBoost Togo. Il s'inscrit dans une stratégie B2B2C inspirée d'EDVES Nigeria (2 300+ écoles) et Kahoot!, et adaptée au contexte togolais (pouvoir d'achat élève faible, infra data limitée, curriculum MEPST spécifique).

### Tableau visuel 3 × 3

| Partenaires clés | Activités clés | Proposition de valeur | Relations clients | Segments clients |
|---|---|---|---|---|
| MEPST Togo (annales officielles, pilotes publics)<br>FEDER (recommandation 400 lycées privés)<br>CcHub Lomé (mentorat, networking investisseurs)<br>AIMS Ghana (validation scientifique IRT/BKT)<br>SmartFarm Togo (ancrage local, back-office)<br>FEDER / ANFEJ (distribution écoles)<br>Moov Africa / Togo Telecom YAS (bundle data + mobile money)<br>Google for Education (licences Workspace)<br>OpenAI / Anthropic (crédits API OCR + tuteur IA)<br>Railway (hébergement backend)<br>Université de Lomé (évaluation pédagogique) | Développement Flutter (5 écrans + tuteur IA)<br>Pipeline OCR (Tesseract + GPT-4o Vision, 5 sources)<br>Calibration IRT 3PL + BKT + SM-2<br>Recalibration mensuelle sur 500+ réponses<br>Démarchage B2B direct (200 écoles cibles)<br>Support B2B dédié + dashboard directeurs<br>Marketing WhatsApp + TikTok + ambassadeurs<br>Programme ambassadeurs (100 lycées)<br>Enquête terrain + mesure d'impact | Préparation BEPC/BAC adaptative et personnalisée<br>Annales officielles Togo 100 % alignées MEPST<br>Mode hors-ligne complet (offline-first, Hive + SQLite)<br>Prédiction score BEPC/BAC ± 5 % (XGBoost)<br>Dashboard directeurs (vue agrégée par classe)<br>Gratuité absolue pour l'élève — pour toujours<br>APK < 25 Mo compatible Tecno Spark 2 Go RAM<br>15 min/jour suffisent (SM-2 optimal)<br>Storytelling Amina (ancrage culturel togolais) | Auto-service (app Play Store)<br>Communauté (forum, classements inter-classes, défis hebdo)<br>Support B2B dédié (réponse < 24h premium)<br>Newsletter mensuelle élèves + directeurs<br>Onboarding école (formation 2h + kit commercial)<br>Webinaires enseignants trimestriels<br>Programme ambassadeurs (récompenses + goodies)<br>Support élève niveau 1 via WhatsApp Business | Élèves 3e / Terminale Togo (B2C, 150 k/an)<br>Lycées privés Togo (B2B, 400 recensés)<br>Lycées publics Togo (B2G, 1 100 recensés)<br>Élèves CEDEAO an 2+ (Bénin M15-M18)<br>MEPST / DREN / IEP (B2G institutionnel)<br>Bailleurs GPE / UNICEF / AFD / Banque Mondiale<br>Enseignants référents (relais pédagogique)<br>Parents d'élèves (décisionnaires premium) |

|  | Ressources clés | Canaux |  |  |
|---|---|---|---|---|
|  | Équipe tech 6 pers. au pic (4 fondateurs + 2 commerciaux régionaux M9)<br>Code Flutter + Python (GitHub public, 111 tests)<br>Banque questions 64 → 5 000+ (objectif M9)<br>Algorithmes ML propriétaires (IRT 3PL, BKT, SM-2, XGBoost)<br>Marque ExamBoost + storytelling Amina<br>Réseau FEDER + AIMS Ghana + CcHub<br>Backend FastAPI déployé Railway<br>Données togolaises propriétaires (barrière data croissante) | Play Store Android (national M4)<br>App Store iOS (M6)<br>Site web examboost-togo.vercel.app<br>WhatsApp groups scolaires (200+ groupes)<br>TikTok + Instagram (3 vidéos/semaine)<br>Démarchage direct physique (200 écoles)<br>Salons éducation (Lomé, 4 événements/an)<br>Cybercafés affiches QR code (80 lieux)<br>Radio Lomé FM + TVT (notoriété nationale)<br>Ambassadeurs ExamBoost (1 par lycée pilote) |  |  |

| Structure des coûts |  |  |  | Sources de revenus |
|---|---|---|---|---|
| Salaires équipe (tech + GTM) : 130 k USD / 18 mois<br>Infrastructure cloud + backend : 12 k USD<br>APIs IA (OpenAI, Anthropic, OCR) : 8 k USD<br>Marketing & sales (salons, TikTok ads, ambassadeurs) : 20 k USD<br>Pipeline data & OCR (saisie, validation) : 15 k USD<br>Légal, comptable, propriété intellectuelle : 10 k USD<br>Sous-total opérations : 195 k USD<br>Buffer & imprévus (20 %) : 51 k USD<br>**Total budget 18 mois : 246 k USD** |  |  |  | Licences établissements : 50 M FCFA/an (200 écoles)<br>Premium élèves : 10–20 M FCFA/an (5 000 premium)<br>Subventions GPE / UNICEF / AFD : 30–50 M FCFA/an<br>API de données pour MEPST : 10–20 M FCFA/an<br>**Total année 2 : 100–140 M FCFA (~150–210 k USD)**<br>Run-rate mensuel M18 : 5 M FCFA/mois<br>Break-even GTM : M13 (100 écoles + 5 000 premium) |  |

---

## Détails par bloc

### 1. Partenaires clés

Les partenaires clés sont répartis en quatre familles : institutionnels (légitimité B2G), technologiques (infrastructure à coût réduit), distribution (accès écoles), académiques (validation scientifique).

| Partenaire | Famille | Rôle concret | Statut (juillet 2026) |
|---|---|---|---|
| MEPST Togo | Institutionnel | Accord-cadre pour utilisation annales officielles BEPC/BAC + 10 écoles publiques pilotes + intégration future SIGE | Approche Q3 2026, signature espérée Q1 2027 |
| FEDER (Fédération Établissements Privés) | Distribution | Recommandation officielle ExamBoost aux 400 lycées privés membres | Approche Q3 2026, objectif 50 écoles signées via FEDER en 18 mois |
| ANFEJ (Femmes Éducateurs) | Distribution | Co-déploiement dans écoles membres + dimension genre | Approche Q4 2026, objectif 20 établissements |
| CcHub Lomé | Écosystème | Mentorat post-DJANTA, networking investisseurs Accra/Dakar | Programme DJANTA Idée-Action en cours |
| AIMS Ghana | Académique | Validation scientifique IRT 3PL + BKT, accès chercheurs ML, calibration algorithme | Convention existante |
| SmartFarm Togo | Écosystème | Back-office administratif, ancrage tech local | Partenaire opérationnel |
| Moov Africa Togo | Distribution + paiement | Bundle data + premium (100 Mo offerts pour activation) + Flooz mobile money | Négociation Q3 2026, signature Q4 2026 |
| Togo Telecom (YAS) | Distribution + paiement | Bundle data + TMoney integration | Négociation Q3 2026 |
| Google for Education | Technologique | Google Workspace for Education gratuit (50 licences équipe + écoles pilotes) | Approche Q3 2026 |
| OpenAI / Anthropic | Technologique | Crédits API GPT-4o Vision (OCR) + LLM tuteur IA | Demande researcher program Q3 2026 |
| Railway.app | Technologique | Hébergement backend FastAPI (crédits startup 5 k USD) | Demande Q3 2026 |
| Université de Lomé (Sciences Éducation) | Académique | Stage élèves chercheurs, évaluation pédagogique indépendante | Convention Q1 2027 |
| Africa's Talking | Technologique | API SMS notifications élèves sans data permanente | Intégration Q4 2026 |

**Pourquoi ces partenaires ?** Aucun EdTech en Afrique subsaharienne n'a réussi sans ancrage institutionnel fort (EDVES au Nigeria s'est appuyé sur le Ministère fédéral). Le partenariat MEPST est la clé de voûte du développement B2G, FEDER celle du B2B, Moov/YAS celle de la distribution élève.

### 2. Activités clés

Les activités sont organisées en trois familles : production (technologie + contenu), distribution (acquisition élève + école), opérationnel (calibration + support).

| Activité | Famille | Fréquence / volume | KPI associé |
|---|---|---|---|
| Développement Flutter | Production | 1 release/mineure par mois | Tests automatisés > 100, crash-free > 99,5 % |
| Pipeline OCR (Tesseract + GPT-4o Vision) | Production | 5 sources configurées, objectif 5 000 questions M9 | Questions calibrées IRT/semaine |
| Calibration IRT 3PL | Production | Recalibration mensuelle sur 500+ réponses élèves | Erreur prédiction < 5 % |
| Suivi BKT + prédiction XGBoost | Production | Mise à jour modèle trimestrielle | MAE prédiction score < 1,5 pt |
| Démarchage B2B direct | Distribution | 200 écoles cibles / 18 mois, 30 démos/mois | Taux de conversion démarche → signature : 15 % |
| Programme ambassadeurs | Distribution | 1 ambassadeur par lycée pilote (100 au total M14) | 30 % téléchargements attribués |
| Marketing WhatsApp + TikTok | Distribution | 1 quiz WhatsApp hebdo, 3 TikTok/semaine | CAC élève < 500 FCFA |
| Enquête terrain + mesure d'impact | Opérationnel | 200 élèves 5 villes (juillet 2026), suivi trimestriel | Amélioration notes contrôle + 15 pts M18 |
| Support B2B + onboarding écoles | Opérationnel | Formation 2h/établissement + onboarding kit | NPS directeurs > 50 |
| Community management | Opérationnel | Réponses commentaires < 24h, forum modéré | Rétention 30 jours > 65 % |
| Reporting bailleurs | Opérationnel | Rapport trimestriel GPE/AFD + rapport impact 30 pages M18 | Subventions renouvelées |

### 3. Proposition de valeur

La proposition de valeur se décline en quatre axes, du plus pédagogique au plus économique. Elle est conçue pour répondre simultanément aux besoins de l'élève (progression structurée), du directeur (visibilité agrégée), du parent (gratuité) et du MEPST (impact mesurable).

#### Pour l'élève (B2C)

- **Adaptation personnalisée** : l'IRT 3PL calibre chaque question à son niveau réel, ni trop facile ni trop dur — l'élève progresse dans sa zone proximale de développement.
- **Mémoire longue** : SM-2 lui rappelle chaque carte au moment optimal (demain dans 3 jours, dans 1 semaine, dans 1 mois) — la rétention long-terme est maximisée.
- **Feedback continu** : BKT lui dit pour chaque compétence "Tu maîtrises Thalès à 78 %" — il sait où il en est, ce qui n'arrive jamais avec les PDF WhatsApp.
- **Prédiction score BEPC/BAC** : XGBoost estime son score probable ± 5 %, ce qui désamorce le stress de l'examen.
- **Storytelling local** : les contextes sont togolais (Lomé-Kpalimé pour Thalès, marché d'Adawlato pour les pourcentages, indépendance du 27 avril 1960 pour l'histoire).

#### Pour l'établissement (B2B)

- **Dashboard directeurs** : vue agrégée par classe, identification élèves en difficulté, rapports trimestriels automatiques PDF.
- **Coût imbattable** : 100–300 k FCFA/an vs cours particuliers 5 000–20 000 FCFA/mois/élève — soit 50× moins cher par élève.
- **Alignement APC** : tags par compétence MEPST — ExamBoost épouse la réforme en cours.

#### Pour le Ministère (B2G)

- **Tableau de bord national anonymisé** (établissements, régions, matières) — données SIGE enrichies.
- **Mesure d'impact APC** : contribution documentée à la remontée du taux de réussite BEPC.

### 4. Relations clients

La stratégie de relation est différenciée par segment : auto-service massif pour l'élève (B2C), accompagnement dédié pour l'établissement (B2B), partenariat institutionnel pour le Ministère (B2G).

| Segment | Type de relation | Outils | Coût unitaire |
|---|---|---|---|
| Élève gratuit | Auto-service + communauté | App self-service, forum, FAQ, support niveau 1 WhatsApp | 0 FCFA |
| Élève premium | Auto-service + premium support | Notifications push personnalisées, support prioritaire < 48h | 2 000 FCFA/mois |
| Établissement | B2B dédié + onboarding | Formation 2h, kit commercial, dashboard, support < 24h, webinaires trimestriels | 100–300 k FCFA/an |
| Établissement premium | B2B dédié + consulting | Formation enseignants 4h/an sur site, rapports personnalisés, API SIGE | 300 k FCFA/an |
| Ministère / DREN | Partenariat institutionnel | Comités de pilotage trimestriels, rapports d'impact, ateliers co-construction | Sur subvention |
| Ambassadeurs élève | Programme de fidélité | Premium gratuit 6 mois + goodies + lettre recommandation | 5 000 FCFA/ambassadeur recruté |

### 5. Segments clients

| Segment | Type | Volume cible M18 | CAC cible | LTV cible | LTV/CAC |
|---|---|---|---|---|---|
| Élève gratuit B2C | Mass market | 50 000 actifs/mois | 400 FCFA | 0 FCFA direct (valeur indirecte : volume B2B) | n/a |
| Élève premium B2C | Niche payante (5 % conversion) | 5 000 premium | 400 FCFA | 15 000 FCFA (6 mois moyen) | 37× |
| Établissement public B2B | B2G-privé | 80 écoles | 30 000 FCFA | 100 k FCFA/an × 3 ans × 80 % = 240 k FCFA | 8× |
| Établissement privé B2B | B2B core | 100 écoles | 30 000 FCFA | 150 k FCFA/an × 3 ans × 80 % = 360 k FCFA | 12× |
| Établissement premium B2B | B2B upscale | 20 écoles | 30 000 FCFA | 300 k FCFA/an × 3 ans × 80 % = 720 k FCFA | 24× |
| Ministère (B2G) | Institutionnel | 1 accord-cadre MEPST | 100 k FCFA (dossier) | 30–50 M FCFA/an subvention | 300× |
| Élèves CEDEAO an 2+ | Expansion | Pilote 500 Bénin M15-M18 | n/a (pilote) | n/a | n/a |

### 6. Ressources clés

#### Ressources humaines

- 4 fondateurs (chef projet & lead tech, data scientist ML/OCR, designer UX, growth & partenariats)
- 1 community manager (dès M2)
- 1 commercial B2B (dès M4)
- 2 commerciaux régionaux (Sokodé + Kara, dès M9)
- 1 consultant Bénin (mission ponctuelle M15-M18)
- Soit 6 ETP au pic (M9-M14), 5,5 ETP en M15-M18.

#### Ressources technologiques

- Code Flutter + Python (GitHub public, 4 contributeurs actifs, 111 tests automatisés)
- Backend FastAPI déployé sur Railway (endpoints /predict, /sessions, /sync)
- Banque de questions : 64 questions structurées JSON en M0, objectif 5 000+ en M9 via pipeline OCR
- 3 algorithmes ML propriétaires implémentés et testés : SM-2 (review_card.dart), BKT (user.dart), IRT 3PL (srs_service.dart) + XGBoost pour la prédiction
- Pipeline OCR Python : Tesseract + GPT-4o Vision, 5 sources (epreuvesetcorriges, banquedesepreuves, examens-concours, fomesoutra, digischool Afrique), validation jsonschema
- Données togolaises propriétaires (barrière data croissante)

#### Ressources intellectuelles

- Marque ExamBoost + storytelling Amina (héros du pitch deck)
- Convention AIMS Ghana (validation scientifique)
- Pré-sélection DJANTA Tech Hub 2026 (signal écosystème)

### 7. Canaux

Les canaux sont différenciés par segment : acquisition mass market pour l'élève (WhatsApp + TikTok), démarchage direct pour l'établissement (B2B physique), appel d'offres pour le Ministère (B2G institutionnel).

#### Canaux acquisition élève (B2C)

| Canal | Priorité | Contribution cible | CAC cible |
|---|---|---|---|
| WhatsApp groups scolaires | 1 | 40 % téléchargements | 300 FCFA |
| TikTok + Instagram | 2 | 25 % téléchargements | 1 200 FCFA |
| Bouche-à-oreille ambassadeurs | 3 | 30 % téléchargements | 800 FCFA |
| Cybercafés (affiches QR code) | 4 | 5 % téléchargements | 500 FCFA |
| Bundle opérateur Moov/YAS | 5 | Amplification | 0 FCFA |
| **CAC moyen pondéré cible M18** | | | **400 FCFA** |

#### Canaux acquisition établissement (B2B)

| Canal | Priorité | Volume cible | Conversion |
|---|---|---|---|
| Démarchage direct physique | 1 | 200 démarches → 30 signatures an 1 | 15 % |
| Salons éducation (4/an) | 2 | 1 000 contacts → 20 signatures | 2 % |
| Recommandation FEDER | 3 | 400 lycées membres → 50 signatures | 12,5 % |
| Partenariat ANFEJ | 4 | 20 écoles membres → 20 signatures | 100 % |
| Co-déploiement MEPST (publics) | 5 | 10 écoles pilotes gratuites | 100 % |

### 8. Structure des coûts

Le budget total sur 18 mois est de **246 k USD** (~150 millions FCFA), intégrant le budget projet global de l'Étude de Faisabilité 2025 (246 400 USD) et la ligne GTM (139 000 USD).

| Poste | Montant USD | Part % | Justification |
|---|---|---|---|
| Salaires équipe (4 fondateurs + 2 commerciaux régionaux M9) | 130 000 | 53 % | 4 fondateurs × 18 mois + 1 CM × 16 mois + 1 commercial B2B × 14 mois + 2 commerciaux régionaux × 9 mois ; charges ~12 % incluses |
| Infrastructure cloud + backend (Railway, Vercel, PostHog) | 12 000 | 5 % | Backend FastAPI + dashboard marketing + analytics |
| APIs IA (OpenAI GPT-4o Vision, Anthropic Claude, OCR) | 8 000 | 3 % | Pipeline OCR + tuteur IA conversationnel |
| Marketing & sales (salons, TikTok ads, ambassadeurs, print, influenceurs) | 20 000 | 8 % | Sous-ensemble du budget GTM 139 k USD (focus communication pure) |
| Pipeline data & OCR (saisie manuelle fallback, validation enseignants) | 15 000 | 6 % | 3–5 opérateurs ETP pour saisie manuelle + 2 enseignants experts MEPST validation |
| Légal, comptable, propriété intellectuelle | 10 000 | 4 % | Constitution société, marques, contrats type écoles, audits |
| Buffer & imprévus (20 %) | 51 000 | 21 % | Marge de sécurité sur 18 mois |
| **Total budget 18 mois** | **246 000** | **100 %** | |

#### Coûts variables unitaires

| Coût variable | Montant | À partir de |
|---|---|---|
| Coût API GPT-4o Vision par question OCR | ~0,01 USD | 5 000 questions = 50 USD (négligeable) |
| Coût SMS Africa's Talking | 0,02 USD/SMS | Notifications premium uniquement |
| Commission mobile money Flooz/TMoney | 1,5 % | Sur paiements premium élèves |
| Commission commercial B2B | 5 % par école signée | ~4 200 USD sur 18 mois |

### 9. Sources de revenus

Le modèle B2B2C repose sur quatre sources de revenus complémentaires. La gratuité élève est non-négociable (cause d'échec numéro 1 des EdTech africaines), la monétisation se fait donc via l'établissement, l'élève premium volontaire, les subventions et l'API de données.

| Source | Tarif | Volume an 2 | Revenu an 2 | Part revenus |
|---|---|---|---|---|
| Licence établissement public | 100 000 FCFA/an | 80 écoles | 8 M FCFA | 6–8 % |
| Licence établissement privé | 150 000 FCFA/an | 100 écoles | 15 M FCFA | 11–15 % |
| Licence établissement premium | 300 000 FCFA/an | 20 écoles | 6 M FCFA | 4–6 % |
| Sous-total licences B2B | | 200 écoles | 29 M FCFA | ~21–29 % |
| Premium élève (5 % de 50 000) | 2 000 FCFA/mois × 6 mois moyen | 5 000 premium | 60 M FCFA/an (10–20 M selon churn réel) | 7–15 % |
| Subventions GPE / UNICEF / AFD | 100–500 k USD/projet | 1–2 subventions/an | 30–50 M FCFA/an | 21–50 % |
| API de données pour MEPST | Contrat annuel | 1 contrat | 10–20 M FCFA/an | 7–20 % |
| **Total année 2** | | | **100–140 M FCFA** | 100 % |

#### Unit economics cibles M18

| Indicateur | Élève premium | Établissement |
|---|---|---|
| CAC | 400 FCFA | 30 000 FCFA |
| LTV | 15 000 FCFA (6 mois moyen) | 300 000 FCFA (3 ans × 80 % rétention) |
| Ratio LTV/CAC | 37× | 10× |
| Benchmark SaaS sain | > 3× | > 5× |
| Verdict | Excellent | Très sain |

#### Seuil de rentabilité GTM

Le break-even opérationnel est atteint à **M13** avec 100 écoles partenaires + 5 000 élèves premium — couverture à 95 % des coûts GTM mensuels. À M18 (200 écoles + 5 000 premium), la couverture atteint 167 %.

---

## Hypothèses clés du modèle

1. Taux de conversion gratuit → premium élève : 5 % (benchmark Afrilearn 8 %, Duolingo 7 %).
2. Rétention établissement an 1 : 100 %, an 2 : 80 %, an 3 : 60 %.
3. Rétention élève premium : 6 mois en moyenne (inclut 1 mois offert parrainage + 2 mois churnés).
4. Taux de conversion démarchage B2B → signature : 15 %.
5. Croissance naturelle marché BEPC : +20 à +30 %/an (démographie togolaise).
6. Aucune concurrence directe alignée MEPST pendant 12–18 mois (fenêtre de pionnier).

## Risques majeurs sur le modèle

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Adoption élève lente (< 5 000 actifs M6) | Moyenne | Élevé | Programme ambassadeurs + influenceurs + WhatsApp intensif ; pivot B2B-first si nécessaire |
| Refus écoles pour raison budgétaire | Élevée | Élevé | Pricing flexible public/privé + essai gratuit 3 mois + paiement trimestriel |
| Subventions B2G retardées | Élevée | Moyen | Modèle B2B+B2C doit atteindre break-even indépendamment — B2G = accélérateur, pas pilier |
| Concurrence app gouvernementale MEPST | Faible | Élevé | Partenariat public-privé (positionner ExamBoost comme outil complémentaire officiel) |
| Augmentation coût APIs IA | Faible | Moyen | Crédits OpenAI/Anthropic + fallback modèle open-source (Llama 3) |

---

## Conclusion

Le Business Model Canvas d'ExamBoost Togo présente un modèle **B2B2C défendable** :

- **Diversification revenus** : 4 sources complémentaires (licences écoles, premium élève, subventions, API données) — aucune source ne dépasse 50 % du total.
- **Unit economics sains** : LTV/CAC à 37× (élève premium) et 10× (école), bien au-dessus du seuil SaaS de 3×.
- **Break-even atteignable** : M13 avec 100 écoles + 5 000 premium, sans dépendre du B2G.
- **Barrières concurrentielles** : localisation MEPST profonde, données togolaises propriétaires, communauté établie — fenêtre de pionnier de 12–18 mois.
- **Alignement social** : gratuité élève = impact direct sur learning poverty (86 % à 10 ans au Togo), alignement SDG4 = subventions GPE/UNICEF/AFD accessibles.

Le modèle est conçu pour **passer à l'échelle CEDEAO dès M15** (Bénin même curriculum BEPC) tout en restant rentable unitairement.

---

*Références : Plan_GoToMarket.md v1.0 (sections 2, 5, 6, 8) — Investor_Deck_15_slides.md (slides 4, 5, 6, 8) — Étude de Faisabilité 2025 (budget 246 400 USD).*
*Juillet 2026 — v1.0*
