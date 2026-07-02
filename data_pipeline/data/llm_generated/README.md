# Outputs du pipeline LLM generation (gitignored normalement)

Ce dossier contient les sorties du pipeline `data_pipeline/llm_generation/`.

## Structure

```
data/llm_generated/
├── claude_raw/                     # Raw outputs Claude (par combinaison)
│   └── BEPC_Mathematiques_TOUTES.json
├── openai_raw/                     # Raw outputs OpenAI
│   └── BEPC_Mathematiques_TOUTES.json
├── mistral_raw/                    # Raw outputs Mistral
│   └── BEPC_Mathematiques_TOUTES.json
├── merged_validated/               # Apres cross-validation 2/3 LLM
│   └── merged_BEPC_Mathematiques_TOUTES.json
└── final_questions_to_add.json     # Pre-t a integrer dans questions.json
```

## Attention

- Ce dossier ne doit **pas** etre commit sur Git (contient des raw LLM
  volumineux et potentiellement sensibles).
- Ajouter `data_pipeline/data/llm_generated/` au `.gitignore`.
- Seul `final_questions_to_add.json` peut etre commit manuellement apres
  review humaine.

## Re-generation

Pour regenerer ce dossier :

```bash
cd data_pipeline/llm_generation
python generate_questions_3llm.py --all
```

Voir le README.md parent pour plus de details.
