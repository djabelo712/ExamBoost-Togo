# Google Forms — Structure a recreer

> Ce document decrit exactement comment reproduire le questionnaire ExamBoost Togo dans Google Forms.
> Duree estimee de creation : 45-60 minutes.
> URL cible : https://forms.gle/ (a generer apres publication)

---

## 1. Configuration generale du formulaire

### 1.1 Creation
1. Aller sur https://forms.google.com
2. Cliquer sur **"Nouveau formulaire"** (+)
3. Titre : **Enquete ExamBoost Togo — Eleves BEPC / BAC**
4. Description : *Enquete anonyme de 10-15 minutes pour comprendre comment les eleves de Lome preparer leurs examens. Vos reponses aideront a construire une application gratuite de revision.*

### 1.2 Theme et couleurs
- Cliquer sur l'icone **Personnaliser le theme** (palette en haut a droite)
- **Couleur principale** : `#006837` (vert Togo)
- **Couleur de fond** : `#F5F5F5` (gris tres clair)
- **Police** : *Basic* ou *Arial* (lisibilite maximale)
- **Image d'en-tete** : logo ExamBoost Togo (si disponible, sinon laisser vide)

### 1.3 Parametres (onglet "Parametres")
- **Reponses** : *Collecter les adresses e-mail* = NON
- **Reponses** : *Limiter a 1 reponse* = NON (permet a plusieurs eleves de partager un telephone)
- **Presentation** : *Afficher la barre de progression* = OUI
- **Presentation** : *Melanger l'ordre des questions* = NON
- **Presentation** : *Afficher un lien pour soumettre une autre reponse* = NON
- **Verification** : *Captcha* = OUI (anti-spam)

### 1.4 Message d'accueil (premiere "section")
- Titre : **Bienvenue dans l'enquete ExamBoost Togo**
- Description :
  > Merci de prendre 10-15 minutes pour repondre a ce questionnaire anonyme.
  > Vos reponses aideront l'equipe ExamBoost Togo a construire une application gratuite de preparation aux examens BEPC et BAC, adaptee aux eleves togolais.
  >
  > - Anonymat total garanti
  > - Aucune donnee personnelle nominative
  > - Tu peux te retirer a tout moment
  > - A la fin, tu peux laisser ton contact pour etre beta-testeur (facultatif)
  >
  > Commence quand tu es pret(e).

---

## 2. Sections et questions detaillees

### SECTION 1 — Identification (5 questions)

> Ajouter une "Section" intitulee : **A. Identification**

| Question | Type Google Forms | Obligatoire | Options / Details |
|---|---|---|---|
| A1. Niveau scolaire actuel | Choix unique (radio) | OUI | 3e / 2nde / 1ere / Terminale |
| A2. Serie (si lycee) | Choix unique (radio) | NON | A / B / C / D / F / Non applicable |
| A3. Type d'etablissement | Choix unique (radio) | OUI | Public / Prive confessionnel / Prive laic |
| A4. Quartier de residence | Choix unique (radio) | OUI | Lome centre / Be / Adidogome / Tokoin / Aflao / Baguida / Kegue / Agoe / Nyekonakpoep / Autre |
| A5. Age | Choix unique (radio) | OUI | 14 ans ou moins / 15-16 / 17-18 / 19-20 / 21+ |

**Logique conditionnelle A2** :
- Clic sur A2 → "Activer la logique" → Afficher seulement si A1 = "2nde", "1ere" ou "Terminale"

---

### SECTION 2 — Habitudes de revision (8 questions)

> Ajouter une "Section" intitulee : **B. Habitudes de revision**

| Question | Type Google Forms | Obligatoire | Options / Details |
|---|---|---|---|
| B1. Heures de revision/semaine | Choix unique (radio) | OUI | 0-5h / 6-10h / 11-15h / 16h+ |
| B2. Outils de revision utilises | Cases a cocher (checkbox) | OUI | Cahiers / Manuels / PDF WhatsApp / YouTube / App mobile / Sites web / Cours particuliers / Aucun |
| B3. Smartphone personnel | Choix unique (radio) | OUI | Oui / Non, partage famille / Non, aucun |
| B4. Marque smartphone | Choix unique (radio) | NON | Tecno / Itel / Infinix / Samsung / Huawei / iPhone / Autre |
| B5. Acces Internet quotidien | Choix unique (radio) | OUI | Wifi maison / Forfait data / Cybercafe / Ecole / Pas d'acces |
| B6. Frequence revision numerique | Choix unique (radio) | OUI | Jamais / 1-2x / 3-4x / 5x+ |
| B7. Matieres les plus difficiles | Cases a cocher (checkbox) | NON | Maths / Francais / Sciences Phy / SVT / H-G / Anglais / Philo / Economie |
| B8. Organisation revisions avant examen | Paragraphe (texte long) | NON | Zone libre |

**Logique conditionnelle B4** :
- Afficher seulement si B3 = "Oui" ou "Non, partage famille"

---

### SECTION 3 — Douleurs et besoins (7 questions)

> Ajouter une "Section" intitulee : **C. Douleurs et besoins**

| Question | Type Google Forms | Obligatoire | Options / Details |
|---|---|---|---|
| C1. Satisfaction methodes actuelles | Echelle lineaire (1-5) | OUI | 1 = Pas du tout satisfait → 5 = Tres satisfait. Etiquettes aux deux extremites |
| C2. Ce qui te manque le plus | Paragraphe (texte long) | NON | Zone libre |
| C3. Deja utilise une app de revision | Choix unique (radio) | OUI | Oui / Non |
| C4. Laquelle | Choix unique (radio) | NON | Khan Academy / Duolingo / App locale / Autre / Aucune connue |
| C5. Pourquoi pas de simulations | Cases a cocher (checkbox) | NON | Pas de sujets / Pas le temps / Pas motive / Sais pas comment / Je fais deja |
| C6. Connais-tu ton niveau exact | Choix unique (radio) | OUI | Oui / Non / Approximativement |
| C7. Recommandations personnalisees | Choix unique (radio) | OUI | Oui / Non / Peut-etre |

**Logique conditionnelle C4** :
- Afficher seulement si C3 = "Oui"

---

### SECTION 4 — Reaction au concept ExamBoost (7 questions)

> Ajouter une "Section" intitulee : **D. Reaction au concept ExamBoost**

> **AVANT les questions D1-D7**, ajouter un bloc "Titre et description" avec le texte suivant :
>
> *ExamBoost Togo est une application mobile gratuite qui aide les eleves togolais a preparer le BEPC et le BAC. Elle propose :*
> - *Cartes memoire intelligentes (algorithme SM-2)*
> - *Simulations chronometrees d'examens avec sujets precedents*
> - *Prediction du score probable (IA)*
> - *Classement par rapport aux autres eleves de l'ecole*
> - *Mode hors-ligne (offline)*
> - *Notifications de rappel de revision*

| Question | Type Google Forms | Obligatoire | Options / Details |
|---|---|---|---|
| D1. Concept utile ? | Echelle lineaire (1-5) | OUI | 1 = Pas du tout utile → 5 = Tres utile |
| D2. Fonctionnalites interessees | Cases a cocher (checkbox) | OUI | Flashcards / Simulations / Prediction score / Classement ecole / Mode offline / Notifications / Aucune |
| D3. Telechargerais si gratuit | Choix unique (radio) | OUI | Oui / Non / Peut-etre |
| D4. Valeur estimee par mois (FCFA) | Choix unique (radio) | OUI | 0 / 500 / 1000 / 2000 / 5000+ |
| D5. Interet acces premium ecole | Choix unique (radio) | OUI | Oui / Non |
| D6. Freins a l'utilisation | Cases a cocher (checkbox) | NON | Stockage / Forfait data / Pas le temps / Pas de smartphone / Pas confiance / Autre |
| D7. Recommanderais a un ami (NPS) | Echelle lineaire (1-10) | OUI | 1 = Absolument pas → 10 = Tout a fait |

---

### SECTION 5 — Feedback ouvert (3 questions)

> Ajouter une "Section" intitulee : **E. Feedback ouvert**

| Question | Type Google Forms | Obligatoire | Options / Details |
|---|---|---|---|
| E1. Qu'est-ce qui rendrait ExamBoost indispensable | Paragraphe (texte long) | NON | Zone libre |
| E2. Anecdote difficulte preparation examen | Paragraphe (texte long) | NON | Zone libre. Préciser que citation anonymisée peut etre utilisee dans le pitch |
| E3. Beta-testeur ? | Choix unique (radio) | OUI | Oui (email/WhatsApp) / Non. Si Oui, ajouter un champ "Paragraphe" pour saisir email/WhatsApp |

**Logique conditionnelle email beta-testeur** :
- Ajouter une question E3b "Laisser ton email ou WhatsApp" de type "Reponse courte"
- Afficher seulement si E3 = "Oui"

---

### SECTION 6 — Message de fin (confirmation)

> Ajouter une "Section" finale :
> - Titre : **Merci pour ta participation !**
> - Description :
  > Tes reponses vont directement nourrir le projet ExamBoost Togo et seront presentees au jury du programme DJANTA Tech Hub le 24 juillet 2026.
  >
  > Si tu as laisse ton contact, tu seras recontacte pour le programme beta-testeur (lancement prevu septembre 2026).
  >
  > Pour suivre le projet : https://github.com/djabelo712/ExamBoost-Togo
  > Contact equipe : examboost.togo@gmail.com

Dans les parametres : **"Message de confirmation"** = cocher "Afficher un message personnalisé" et coller le texte ci-dessus.

---

## 3. Lien avec Google Sheets (collecte automatique)

1. Onglet **Reponses** → cliquer sur l'icone **Google Sheets** (vert)
2. Choisir "Creer une feuille de calcul"
3. La feuille s'ouvre avec une ligne d'en-tete pre-remplie (noms de questions)
4. **URL de la feuille** : a conserver pour l'analyse (cf. `analyse_enquete.py`)
5. Pour exporter en CSV : Fichier → Telecharger → Valeurs separees par des virgules (.csv)

---

## 4. Partage du formulaire

### 4.1 Lien public
- Bouton **Envoyer** (en haut a droite)
- Onglet **Lien** (icône chaîne)
- Cocher **Raccourcir l'URL**
- URL cible : à conserver dans ce fichier une fois générée : `https://forms.gle/_________________`

### 4.2 QR Code (pour affichage papier)
- Onglet **QR code** dans la fenêtre Envoyer
- Télécharger l'image PNG
- Imprimer en grand format pour les enquêteurs

### 4.3 Code d'intégration (si landing page)
- Onglet **Intégrer** dans la fenêtre Envoyer
- Copier le code iframe
- À coller dans `/home/z/my-project/ExamBoost-Togo/landing/` (cf. task 18-landing)

---

## 5. Vérification finale (checklist)

Avant de publier le formulaire, vérifier :

- [ ] 30 questions au total (5 + 8 + 7 + 7 + 3)
- [ ] Toutes les questions obligatoires marquées "*"
- [ ] Logique conditionnelle A2, B4, C4, E3b testée
- [ ] Couleur verte Togo #006837 appliquée
- [ ] Message d'accueil et message de fin présents
- [ ] Collecte d'email désactivée (anonymat)
- [ ] Lien Google Sheets connecté
- [ ] QR code téléchargé
- [ ] Pré-test : remplir le formulaire 1 fois pour vérifier le flux
- [ ] URL publique partagée avec les enquêteurs

---

## 6. Sauvegarde et archivage

Une fois l'enquête terminée (30 réponses collectées) :
1. Exporter Google Sheets en CSV
2. Renommer `enquete_examboost_lome_2026-06.csv`
3. Placer dans `/home/z/my-project/ExamBoost-Togo/docs/Enquete_Terrain/analyse/`
4. Lancer : `python analyse_enquete.py enquete_examboost_lome_2026-06.csv`
5. Le script génère :
   - `figures/` (6 graphiques PNG)
   - `rapport_auto.md` (rapport markdown automatique)
   - `kpis.json` (3 KPIs au format JSON)

---

## 7. Contact technique

- Créateur du formulaire : **Agent N (ExamBoost Togo)**
- Email équipe : examboost.togo@gmail.com
- Slack/Discord équipe : canal #enquete-terrain
