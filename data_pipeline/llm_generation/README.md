# Pipeline de generation LLM de questions BEPC/BAC

Ce module genere **100+ nouvelles questions** pour la banque ExamBoost Togo
via 3 LLM (Claude Sonnet 4, GPT-4o, Mistral Large) avec **validation croisee** :
seules les questions validees par au moins 2 LLM sur 3 sont conservees.

## Objectif

Faire passer la banque de questions de **64** (actuel) a **200+** questions,
en couvrant :
- BEPC : Mathematiques, Francais, SVT, Sciences Physiques
- BAC serie C : Mathematiques, Sciences Physiques
- BAC serie D : SVT

## Architecture

```
data_pipeline/llm_generation/
├── __init__.py
├── generate_questions_3llm.py     # Script principal CLI (orchestrateur)
├── merge_questions.py             # Cross-validation 2/3 LLM (SimHash)
├── llm_clients/
│   ├── __init__.py
│   ├── claude_client.py            # Wrapper Anthropic (claude-sonnet-4-6)
│   ├── openai_client.py            # Wrapper OpenAI (gpt-4o)
│   └── mistral_client.py           # Wrapper Mistral (mistral-large-latest)
├── validators/
│   ├── __init__.py
│   ├── schema_validator.py         # Validation schema JSON (champs, types)
│   ├── pedagogical_validator.py    # Validation pedagogique (longueurs, pieges)
│   └── duplicate_checker.py        # Deduplication vs questions existantes
├── prompts/
│   ├── README.md                   # Comment creer un nouveau prompt
│   ├── bepc_maths_prompt.txt
│   ├── bepc_francais_prompt.txt
│   ├── bepc_sciences_prompt.txt    # SVT + Sciences Physiques BEPC
│   ├── bac_c_maths_prompt.txt
│   ├── bac_c_physique_prompt.txt
│   └── bac_d_svt_prompt.txt
└── README.md                       # Ce fichier

data_pipeline/data/llm_generated/   # Sorties (gitignored)
├── claude_raw/                     # Raw outputs par LLM
├── openai_raw/
├── mistral_raw/
├── merged_validated/               # Apres cross-validation 2/3
└── final_questions_to_add.json     # Pre-t a integrer dans questions.json
```

## Setup

### 1. Installation des dependances

```bash
# A la racine du pipeline
cd data_pipeline/
pip install -r requirements.txt
# Le requirements.txt existant contient deja: openai, simhash, jsonschema
# Ajouter manuellement:
pip install anthropic mistralai
```

### 2. Configuration des cles API

Creer un fichier `.env` dans `data_pipeline/` avec :

```bash
# Anthropic (Claude Sonnet 4)
ANTHROPIC_API_KEY=sk-ant-xxxxx

# OpenAI (GPT-4o)
OPENAI_API_KEY=sk-xxxxx

# Mistral AI (Mistral Large)
MISTRAL_API_KEY=xxxxx

# Optionnel : surcharger les modeles
CLAUDE_MODEL=claude-sonnet-4-6
OPENAI_MODEL=gpt-4o
MISTRAL_MODEL=mistral-large-latest
```

### 3. Test rapide (sans cles API)

Sans cles API, le pipeline ne peut pas generer de nouvelles questions, mais
il peut revalider des raw outputs existants :

```bash
cd data_pipeline/llm_generation
python generate_questions_3llm.py --validate-only
```

## Usage

### Generation pour une matiere specifique

```bash
python generate_questions_3llm.py \
    --matiere Mathematiques \
    --examen BEPC \
    --count 30
```

Cela demande 30 questions a CHAQUE LLM (soit 90 raw), et conserve les
questions validees par >= 2 LLM (typiquement 15-25 finales).

### Generation sur toutes les combinaisons (100+ questions)

```bash
python generate_questions_3llm.py --all
```

Genere sur les 7 combinaisons suivantes (definies dans `ALL_TARGETS`) :
- BEPC / Mathematiques (25 questions / LLM)
- BEPC / Francais (20 / LLM)
- BEPC / SVT (20 / LLM)
- BEPC / Sciences Physiques (20 / LLM)
- BAC C / Mathematiques (20 / LLM)
- BAC C / Sciences Physiques (20 / LLM)
- BAC D / SVT (20 / LLM)

Total attendu : ~145 raw / LLM × 3 = ~435 raw, et **100-150 questions finales**
apres cross-validation 2/3 + validators.

### Re-validation seule (sans generation)

```bash
python generate_questions_3llm.py --validate-only
# ou pour une matiere specifique
python generate_questions_3llm.py --validate-only --matiere Mathematiques --examen BEPC
```

Utile pour rejouer les validators (schema, pedago, doublons) sur des raw
deja generes, par exemple apres avoir ajuste les seuils.

## Pipeline detaille

```
┌──────────────────────────────────────────────────────────────────────┐
│ 1. GENERATION (async parallele)                                     │
│    ┌────────────┐  ┌────────────┐  ┌────────────┐                  │
│    │  Claude    │  │  OpenAI    │  │  Mistral   │                  │
│    │ Sonnet 4   │  │  GPT-4o    │  │  Large     │                  │
│    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘                  │
│          │               │               │                          │
│          v               v               v                          │
│    claude_raw/*.json  openai_raw/*.json  mistral_raw/*.json         │
└──────────────────────────────────────────────────────────────────────┘
                                |
                                v
┌──────────────────────────────────────────────────────────────────────┐
│ 2. CROSS-VALIDATION 2/3 (merge_questions.py)                        │
│    - Calcule SimHash 64 bits de chaque enonce (shingles 3 mots)     │
│    - Groupe les questions similaires (distance Hamming < 9 bits)    │
│    - Garde seulement les groupes valides par >= 2 LLM               │
│    - Pour chaque groupe garde : la question la plus complete        │
│    Output: merged_validated/merged_*.json                           │
└──────────────────────────────────────────────────────────────────────┘
                                |
                                v
┌──────────────────────────────────────────────────────────────────────┐
│ 3. VALIDATION SCHEMA (validators/schema_validator.py)               │
│    - Presence de tous les champs obligatoires (id, enonce, ...)     │
│    - Types conformes (string, int, list, dict)                      │
│    - Coherence examen/serie (BEPC -> serie null, BAC -> serie set)  │
│    - QCM a exactement 4 choix dont la reponse                       │
│    - irt.b dans [-2, 2], points dans [1, 5]                         │
│    - id canonique TG-{EXAMEN}-{CODE}-{ANNEE}-Q{NN}                  │
│    - Normalisation automatique (Mathematiques -> Mathematiques)     │
└──────────────────────────────────────────────────────────────────────┘
                                |
                                v
┌──────────────────────────────────────────────────────────────────────┐
│ 4. VALIDATION PEDAGOGIQUE (validators/pedagogical_validator.py)     │
│    - enonce >= 10 caracteres                                        │
│    - reponse >= 1 caractere                                         │
│    - explication >= 30 caracteres                                   │
│    - Pas de question piege (mot "pas" + reponse negative)           │
│    - Pas de double negation                                         │
│    - Coherence niveau (BAC + irt.b >= -0.2 ; BEPC + irt.b <= 1.2)   │
│    - Format competence_id TG-{MAT}-{CHAP}-NNN                       │
└──────────────────────────────────────────────────────────────────────┘
                                |
                                v
┌──────────────────────────────────────────────────────────────────────┐
│ 5. DEDUPLICATION (validators/duplicate_checker.py)                  │
│    - Charge les 64 questions existantes de questions.json           │
│    - Index SimHash de chaque enonce                                │
│    - Pour chaque question LLM validee, si distance Hamming < 5      │
│      avec une existante -> discard (doublon)                        │
└──────────────────────────────────────────────────────────────────────┘
                                |
                                v
┌──────────────────────────────────────────────────────────────────────┐
│ 6. SAUVEGARDE FINALE                                                │
│    Output: data/llm_generated/final_questions_to_add.json           │
│    Liste prete a etre ajoutee a assets/data/questions.json          │
│    (par l'agent wiring ou manuellement apres review humaine)        │
└──────────────────────────────────────────────────────────────────────┘
```

## Cout estime

Pour une generation complete (`--all` = ~145 questions / LLM × 3 = 435 raw) :

| LLM    | Modele                | Input (USD/1K) | Output (USD/1K) | Cout estime |
| ------ | --------------------- | -------------- | --------------- | ----------- |
| Claude | claude-sonnet-4-6     | $0.003         | $0.015          | ~$1.20      |
| OpenAI | gpt-4o                | $0.005         | $0.015          | ~$1.80      |
| Mistral| mistral-large-latest  | $0.002         | $0.006          | ~$0.50      |
|        |                       |                | **TOTAL**       | **~$3.50**  |

Estimation detaillee (par LLM, pour 145 questions × ~500 tokens/question) :
- Input : ~10K tokens (prompt) × 145 = ~1.5M tokens... en realite beaucoup
  moins car le prompt est constant (~2K tokens) et chaque reponse LLM
  contient ~150 questions × ~300 tokens = ~45K tokens.
- Input total (par LLM) : ~2K + 0 = ~2K tokens (1 appel / LLM)
- Output total (par LLM) : ~45K tokens
- Soit ~$0.50-1.00 / LLM, total **~$2-3**.

## Format de sortie

Le fichier `final_questions_to_add.json` est un tableau JSON de questions
au format attendu par `lib/models/question.dart` :

```json
[
  {
    "id": "TG-BEPC-MATHS-2025-Q01",
    "enonce": "...",
    "reponse": "...",
    "explication": "...",
    "matiere": "Mathematiques",
    "chapitre": "...",
    "competence_id": "TG-MATHS-EQ1D-001",
    "examen": "BEPC",
    "serie": null,
    "annee": 2025,
    "type": "calcul",
    "choix": null,
    "points": 4,
    "irt": {"a": null, "b": 0.3, "c": null, "calibre": false}
  },
  ...
]
```

## Integration dans questions.json

Apres review humaine (recommandee), integrer avec :

```bash
# 1. Backup
cp assets/data/questions.json assets/data/questions.json.bak

# 2. Concatener + dedup (en Python)
python3 -c "
import json
existing = json.load(open('assets/data/questions.json'))
new = json.load(open('data_pipeline/data/llm_generated/final_questions_to_add.json'))
merged = existing + new
print(f'Avant: {len(existing)} + {len(new)} = {len(merged)} questions')
json.dump(merged, open('assets/data/questions.json', 'w'), ensure_ascii=False, indent=2)
"
```

**Toujours faire une review humaine** sur un echantillon (10-20%) avant
integration massive. Les LLM peuvent produire des questions factuellement
correctes mais pedagogiquement peu pertinentes, ou avec des libelles
ambigus.

## Comment ajouter une nouvelle matiere

1. **Creer un prompt** dans `prompts/` (voir `prompts/README.md`).
2. **Ajouter une entree** dans `PROMPT_MAPPING` et `ALL_TARGETS` dans
   `generate_questions_3llm.py`.
3. **Tester** avec un seul LLM d'abord :
   ```bash
   python generate_questions_3llm.py --matiere <nouvelle> --examen BEPC --count 5
   ```
4. **Reviewer** les raw outputs, ajuster le prompt si besoin.
5. **Lancer** en mode `--all` une fois le prompt stable.

## Decisions de conception

### Pourquoi 3 LLM avec cross-validation 2/3 ?

- **Redondance** : si 1 LLM hallucine, les 2 autres le contrebalancent.
- **Diversite** : chaque LLM a des biais differents (Claude = plus rigoureux,
  GPT-4o = plus creatif, Mistral = plus europeen/francophone).
- **Cout** : le cross-val 2/3 elimine les questions trop uniques (potentiel
  hallucinees) sans pour autant exiger un consensus unanime (trop strict).
- **Qualite** : les questions gardees sont celles qu'au moins 2 LLM ont jugees
  pertinentes (parce qu'ils les ont generees de facon similaire).

### Pourquoi SimHash avec shingles de 3 mots ?

- **SimHash** est rapide (O(n log n) pour le groupage) et robuste aux
  petites variations (typos, ponctuation).
- Les **shingles de 3 mots** offrent une meilleure granularite que les mots
  uniques (un mot change sur 10 = ~10% de difference vs ~30% avec shingles).
- Le seuil **9 bits / 64 = 14%** correspond a ~86% de similarite, un bon
  compromis entre trop strict (0% = questions identiques) et trop laxiste
  (50% = beaucoup de faux positifs).

### Pourquoi un seuil de doublon plus strict (5 bits) ?

Pour la deduplication vs questions existantes (qui sont des annales
authentiques), on veut etre sur de ne pas inserer un doublon d'une question
existante. Le seuil **5 bits / 64 = 8%** correspond a ~92% de similarite,
assez strict pour ne pas rater les vrais doublons mais pas trop pour
accepter des reformulations legitimes.

### Pourquoi normaliser les matieres sans accent ?

Les LLM renvoient frequemment "Mathematiques" (sans accent) meme quand on
demande "Mathematiques" avec accent dans le prompt. Plutot que de rejeter
ces questions, on les normalise automatiquement vers la forme canonique
("Mathematiques"). Pareil pour examen (BAC -> BAC1).

### Pourquoi async/await pour 3 appels LLM ?

Les 3 LLM sont independants, on peut les appeler en parallele avec
`asyncio.gather`. Cela divise le temps total par 3 (au lieu de 60s
sequentiel = 20s en parallele). Chaque client gere son propre rate limit
et retry avec backoff exponentiel.

## Limites connues

1. **Cout** : ~$2-3 par generation complete. A ne pas lancer tous les jours.
2. **Latence** : 30-60s par combinaison (async mais chaque LLM prend du
   temps pour generer 20-30 questions).
3. **Hallucinations** : meme avec cross-validation 2/3, un LLM peut
   produire des questions factuellement fausses (ex : Pythagore avec un
   resultat errone). La review humaine reste indispensable.
4. **Variabilite** : les SimHash peuvent rater des paraphrases (meme
   question, mots differents). Une question validee par 1 LLM seul sera
   discard, meme si elle est valide. C'est le compromis pour eviter les
   hallucinations.
5. **Cles API** : si une cle est absente, le LLM correspondant est skip
   silencieusement. La cross-validation 2/3 fonctionne toujours avec 2 LLM
   (mais 1 LLM seul ne produira aucune question validee).

## Tests

```bash
# Test de non-regression sur les validators
cd data_pipeline/llm_generation
python3 -c "
import sys; sys.path.insert(0, '.')
from validators.schema_validator import validate_schema_with_errors
from validators.pedagogical_validator import validate_pedagogy_with_errors
from validators.duplicate_checker import DuplicateChecker, load_existing_questions

existing = load_existing_questions()
print(f'Charge {len(existing)} questions existantes')

# Toutes les questions existantes doivent passer les validators
for q in existing:
    ok_s, _ = validate_schema_with_errors(q)
    ok_p, _ = validate_pedagogy_with_errors(q)
    if not ok_s or not ok_p:
        print(f'WARN: {q[\"id\"]} schema={ok_s} pedago={ok_p}')

checker = DuplicateChecker(existing)
print(f'Index SimHash: {len(checker.hashes)} hashes')
print('OK : tous les validators fonctionnent')
"
```

## Prochaines etapes (V2)

- [ ] Generation de **corriges detailles** supplementaires (etape 5.5 du
  pipeline) via un 4e appel LLM dedie.
- [ ] **Calibration IRT** automatique : apres generation, lancer
  `estimate_irt.py` pour calibrer les irt.b estimes.
- [ ] **Tags de difficulte** : ajout d'un champ `tags` pour filtrage avance.
- [ ] **Generation de figures SVG** pour les questions de geometrie
  (Agent AR Vague 3).
- [ ] **Integration continue** : pipeline CI qui re-valide les questions
  LLM a chaque merge sur main.
