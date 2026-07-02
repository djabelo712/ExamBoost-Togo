# Prompts specialises par matiere / examen

Ce dossier contient les **templates de prompts** utilises pour generer des
questions via les 3 LLM (Claude, GPT-4o, Mistral). Chaque prompt est un
fichier `.txt` avec des **placeholders** au format `{nom}`.

## Fichiers existants

| Fichier                    | Examen | Matiere              | Serie | Niveau    |
| -------------------------- | ------ | -------------------- | ----- | --------- |
| `bepc_maths_prompt.txt`    | BEPC   | Mathematiques        | -     | 3e        |
| `bepc_francais_prompt.txt` | BEPC   | Francais             | -     | 3e        |
| `bepc_sciences_prompt.txt` | BEPC   | SVT + Sciences Phys. | -     | 3e        |
| `bac_c_maths_prompt.txt`   | BAC    | Mathematiques        | C     | Terminale |
| `bac_c_physique_prompt.txt`| BAC    | Sciences Physiques   | C     | Terminale |
| `bac_d_svt_prompt.txt`     | BAC    | SVT                  | D     | Terminale |

## Placeholders supportes

Tous les prompts peuvent contenir ces placeholders (remplaces au runtime) :

| Placeholder        | Description                                       | Exemple              |
| ------------------ | ------------------------------------------------- | -------------------- |
| `{examen}`         | Type d'examen                                     | `BEPC`, `BAC1`       |
| `{matiere}`        | Matiere (libelle complet)                         | `Mathematiques`      |
| `{serie}`          | Serie BAC ou null                                 | `C`, `D`, ou `null`  |
| `{annee}`          | Annee de l'examen                                 | `2024`               |
| `{niveau}`         | Niveau scolaire                                   | `3e`, `Terminale`    |
| `{count}`          | Nombre de questions a generer                     | `30`                 |
| `{liste_chapitres}`| Liste des chapitres a couvrir (optionnel)         | -                    |

## Comment creer un nouveau prompt

1. **Duplique** un prompt existant proche du besoin (ex : `bepc_maths_prompt.txt`
   pour un nouveau prompt BEPC scientifique).
2. **Adapte** :
   - Le contexte (examen, matiere, niveau, serie).
   - Les instructions specifiques (contexte togolais pertinent).
   - La liste des chapitres du programme MEPST Togo a couvrir.
   - Le format JSON de sortie (toujours un objet avec une cle `"questions"`).
3. **Respecte** les conventions :
   - ID canonique : `TG-{EXAMEN}-{CODE}-{ANNEE}-Q{NN}`.
   - Matieres exactement comme dans `config.py` (avec accents).
   - 4 choix pour QCM, 2 pour vraiFaux, null pour calcul/ouvert/redaction.
4. **Teste** avec un seul LLM d'abord :
   ```bash
   python generate_questions_3llm.py --prompt bac_d_svt --count 5
   ```

## Conventions de format JSON

Le LLM doit renvoyer un **objet** JSON (pas un tableau direct) pour
compatibilite avec `response_format={"type": "json_object"}` d'OpenAI et
Mistral :

```json
{
  "questions": [
    {
      "id": "TG-BEPC-MATHS-2024-Q01",
      "enonce": "...",
      "reponse": "...",
      "explication": "...",
      "matiere": "Mathematiques",
      "chapitre": "...",
      "competence_id": "TG-MATHS-EQ1D-001",
      "examen": "BEPC",
      "serie": null,
      "annee": 2024,
      "type": "calcul",
      "choix": null,
      "points": 4,
      "irt": {"a": null, "b": 0.3, "c": null, "calibre": false}
    }
  ]
}
```

Les 3 wrappers LLM savent extraire les questions meme si le LLM renvoie un
tableau direct (fallback regex), mais preferent toujours l'objet avec cle
`"questions"`.

## Bonnes pratiques redactionnelles

- **Toujours** preciser "Tu es un professeur togolais" dans l'en-tete.
- **Toujours** rappeler "NE recopie PAS d'annales existantes".
- **Toujours** lister les chapitres du programme MEPST Togo a couvrir.
- **Toujours** fournir le format JSON exact attendu (l'LLM copie le format).
- **Inclure** du contexte togolais (villes, FCFA, vie quotidienne, economie).
- **Varier** les types de questions (calcul, ouvert, qcm, vraiFaux).
- **Varier** les difficultes (irt.b de -1.0 a +1.5 environ).
- **Points** coherents avec la difficulte (2-5).

## Versioning

Quand un prompt est modifie, son nom de fichier peut etre suffixe par la date
(ex : `bepc_maths_prompt_2026-07.txt`) pour garder une trace des versions
precedentes. Le script principal `generate_questions_3llm.py` reference les
noms canoniques sans suffixe.
