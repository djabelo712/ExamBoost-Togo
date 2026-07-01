# Palette de couleurs — ExamBoost Togo

> Référence unique pour toutes les interfaces, supports de communication et assets graphiques.
> Alignée sur `lib/theme/app_theme.dart` (AppColors) pour cohérence Flutter/web/print.

---

## 1. Couleurs primaires — Vert Togo

Le vert est la couleur nationale togolaise et le pilier de la marque. Il évoque la croissance, l'espoir et l'apprentissage durable.

| Nom              | Hex       | RGB              | Usage recommandé                                                     |
|------------------|-----------|------------------|----------------------------------------------------------------------|
| `primary`        | `#006837` | `rgb(0,104,55)`  | Boutons primaires,AppBar si full-color, accents principaux, logo    |
| `primaryLight`   | `#4CAF7A` | `rgb(76,175,122)`| États hover, badges "facile", illustrations secondaires             |
| `primaryDark`    | `#004A26` | `rgb(0,74,38)`   | Dégradés vers le bas, fond sombre, pressed states                   |
| `primarySurface` | `#E8F5ED` | `rgb(232,245,237)`| Surfaces claires teintées vert, fonds de cartes "réussite"         |

**Contraste WCAG** :
- `#006837` sur blanc = ratio 6.3:1 (AA Large + AA Normal pour texte ≥14px bold).
- `#004A26` sur blanc = ratio 11.5:1 (AAA).
- Texte blanc sur `#006837` = ratio 6.3:1 (AA Large, AA Normal).

---

## 2. Couleur accent — Orange chaleureux

L'orange incarne l'énergie, la progression (le "boost") et la réussite. Il complète le vert sans le dominer.

| Nom              | Hex       | RGB              | Usage recommandé                                                     |
|------------------|-----------|------------------|----------------------------------------------------------------------|
| `accent`         | `#D97700` | `rgb(217,119,0)` | Mortarboard (cap), étoile, CTA secondaires, indicateurs "difficile" |
| `accentLight`    | `#FFB74D` | `rgb(255,183,77)`| Hover, dégradés cap, badges highlight, pompon, favicon EB           |
| `accentSurface`  | `#FFF3E0` | `rgb(255,243,224)`| Surfaces claires teintées orange, tooltips, info-bulles            |

**Contraste WCAG** :
- `#D97700` sur blanc = ratio 3.4:1 (AA Large uniquement — à éviter pour texte <14px bold).
- Texte blanc sur `#D97700` = ratio 3.4:1 (usage décoratif ou texte ≥18px).

---

## 3. Couleurs sémantiques

| Sémantique | Nom       | Hex       | RGB              | Usage                                                  |
|------------|-----------|-----------|------------------|--------------------------------------------------------|
| Success    | `success` | `#2E7D32` | `rgb(46,125,50)` | Validation, "Correct", BKT ≥ 0.85, niveau "facile"    |
| Warning    | `warning` | `#F57C00` | `rgb(245,124,0)` | Alerte modérée, "À réviser", révision due             |
| Error      | `error`   | `#C62828` | `rgb(198,40,40)` | Erreur, "Oublié", BKT < 0.3, niveau "échec"           |
| Info       | `info`    | `#1565C0` | `rgb(21,101,192)`| Information neutre, niveau "moyen", lien aide         |

---

## 4. Couleurs neutres

| Nom               | Hex       | RGB                | Usage                                              |
|-------------------|-----------|--------------------|----------------------------------------------------|
| `background`      | `#F8F9FA` | `rgb(248,249,250)` | Fond global de l'app, fond clair par défaut       |
| `surface`         | `#FFFFFF` | `rgb(255,255,255)` | Cartes, dialogues, AppBar en mode clair           |
| `surfaceVariant`  | `#F1F3F4` | `rgb(241,243,244)` | Champs input, fonds secondaires                  |
| `divider`         | `#E0E0E0` | `rgb(224,224,224)` | Séparateurs, bordures fines                      |
| `textPrimary`     | `#1A1A1A` | `rgb(26,26,26)`    | Texte principal, titres                           |
| `textSecondary`   | `#757575` | `rgb(117,117,117)` | Texte secondaire, captions, métadonnées          |
| `textDisabled`    | `#BDBDBD` | `rgb(189,189,189)` | Texte désactivé, placeholders                    |

---

## 5. Niveaux de difficulté SRS (spécifique métier)

| Niveau      | Couleur    | Hex       | Contexte                                       |
|-------------|------------|-----------|------------------------------------------------|
| Facile      | Vert       | `#2E7D32` | Carte "Facile" (SM-2 q=5), maîtrise élevée     |
| Moyen       | Bleu       | `#1565C0` | Carte "Correct" (SM-2 q=4), niveau intermédiaire|
| Difficile   | Orange     | `#D97700` | Carte "Difficile" (SM-2 q=3), à renforcer      |
| Échec       | Rouge      | `#C62828` | Carte "Oublié" (SM-2 q≤2), réinitialiser        |

---

## 6. Combinaisons valides recommandées

### Bouton primaire
- Fond : `#006837` (primary)
- Texte : `#FFFFFF` (blanc)
- Padding : 24×14 — Rayon : 12px

### Bouton secondaire (outlined)
- Fond : transparent
- Bordure : `#006837` 1.5px
- Texte : `#006837`

### Carte d'action (Home)
- Fond : `#FFFFFF` (surface)
- Ombre : `rgba(0,0,0,0.08)` 2dp
- Titre : `#1A1A1A` H3 18px/600
- Sous-titre : `#757575` bodySmall 13px/400
- Accent : `#D97700` (icône ou badge)

### Bandeau succès (Dashboard)
- Fond : `#E8F5ED` (primarySurface)
- Bordure gauche : `#2E7D32` 4px
- Texte : `#1A1A1A` + icône `#2E7D32`

### En-tête sombre (Mode sombre futur)
- Fond : `#004A26` (primaryDark)
- Texte : `#FFFFFF`
- Accent : `#FFB74D` (accentLight pour visibilité accrue)

### Fonds décoratifs (bannières, slides pitch)
- Dégradé linéaire : `#004A26` → `#006837` → `#D97700` (horizontal, ratio 45/45/10)
- Texte blanc par-dessus, ratio WCAG AA respecté sur 90% de la surface

---

## 7. Interdictions

- **Ne pas** mélanger plus de 3 couleurs sémantiques sur un même écran (surcharge cognitive).
- **Ne pas** utiliser `#D97700` (accent) pour du texte courant sur fond blanc (contraste insuffisant).
- **Ne pas** appliquer un opacity < 0.4 sur `#006837` (perte d'identité de marque).
- **Ne pas** remplacer le vert Togo par un autre vert (Chartreuse, Emerald, etc.) — c'est l'identité nationale.
- **Ne pas** utiliser de couleurs néon ou saturées à 100% (préserver le côté "sérieux éducatif").

---

## 8. Récapitulatif hex (copier-coller)

```
Primary         #006837   (vert Togo)
Primary Light   #4CAF7A
Primary Dark    #004A26
Primary Surface #E8F5ED

Accent          #D97700   (orange)
Accent Light    #FFB74D
Accent Surface  #FFF3E0

Success         #2E7D32
Warning         #F57C00
Error           #C62828
Info            #1565C0

Background      #F8F9FA
Surface         #FFFFFF
Surface Variant #F1F3F4
Divider         #E0E0E0
Text Primary    #1A1A1A
Text Secondary  #757575
Text Disabled   #BDBDBD
```

---

*Dernière mise à jour : 30 juin 2026 — Agent J (Task 12-logo).*
