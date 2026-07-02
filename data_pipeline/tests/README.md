# Tests du pipeline OCR ExamBoost Togo

Suite de tests unitaires et d'integration pour le pipeline OCR
(`data_pipeline/`). Ces tests couvrent toutes les phases du pipeline :

1. **OCR** (`ocr_extract.py`) : conversion PDF -> image -> texte Tesseract,
   fallback GPT-4o Vision pour les pages maths, cache OCR.
2. **Structuration** (`structure_questions.py`) : parsing du nom de fichier,
   appel GPT-4o-mini, normalisation des questions LLM, validation.
3. **Validation** (`validate_questions.py`) : schema JSON, coherence metier,
   detection doublons, questions suspectes.
4. **Deduplication** (`deduplicate.py`) : hachage SimHash, distance de
   Hamming, score de completude, clustering.
5. **Estimation IRT** (`estimate_irt.py`) : heuristique b par type,
   ajustements (points, BAC, serie, explication), inv_norm, historique CSV.

## Principe fondamental : aucun appel reseau

Tous les composants externes sont moques :

- **pytesseract** : moque via `monkeypatch.setattr(pytesseract, "image_to_string", ...)`.
- **pdf2image** : moque via `monkeypatch.setattr(pdf_utils, "convert_from_path", ...)`.
- **OpenAI SDK** : le client (`get_client()`) est remplace par un `MagicMock`
  dont la methode `chat.completions.create` retourne une reponse
  pre-construite. Le SDK OpenAI utilise httpx (pas requests), donc la
  librairie `responses` ne peut pas intercepter directement les appels ; on
  mock donc `get_client()` pour renvoyer un faux client.
- **`responses`** : utilise comme gardien (registre les URLs attendues) et
  comme mock HTTP pour tout code qui utiliserait `requests` directement
  (ex. `scrape_pdfs.py`).
- **poppler-utils** (pdfinfo) : moque via `pdfinfo_from_path`.

## Fichiers de tests

| Fichier                  | Couverture                                                 | Nb tests |
|---                       |---                                                         |---:|
| `conftest.py`            | Fixtures reutilisees (sample image, PDF, questions, mock)  | -        |
| `test_ocr.py`            | detect_math, normalize, run_tesseract, pdf_id, cache OCR   | ~31      |
| `test_structure.py`      | build_id, normalize, validate, dedup, IRT, structure_one   | ~68      |
| `test_validate.py`       | validate_schema, validate_pedagogy, validate_coherence     | ~56      |
| `test_deduplicate.py`    | completeness_score, SimHash, Hamming, dedup, clusters      | ~37      |
| `test_estimate_irt.py`   | BASE_B_BY_TYPE, heuristique, ajustements, inv_norm, history | ~57      |
| `test_pdf_utils.py`      | count_pdf_pages, convert_pdf_to_images, save_page_image    | ~28      |
| `test_tesseract_utils.py`| TESSERACT_CONFIG, run_tesseract, detect_math, fallback     | ~53      |
| `test_json_utils.py`     | Schema, build_id, normalize_enonce, load/save, merge       | ~72      |
| `test_openai_utils.py`   | get_client, encode_b64, vision_ocr, structure, prompts     | ~62      |

**Total : ~470 tests** (pytest collecte).

## Lancer les tests

```bash
cd data_pipeline
python3 -m pytest tests/ -v
```

### Options utiles

```bash
# Tests d'un module specifique
python3 -m pytest tests/test_validate.py -v

# Coverage
python3 -m pytest tests/ --cov=. --cov-report=term-missing

# Un test precis
python3 -m pytest tests/test_ocr.py::test_detect_math_content_true_with_sqrt -v

# Sortie courte
python3 -m pytest tests/ --tb=short

# Parallelisation (si pytest-xdist installe)
python3 -m pytest tests/ -n auto
```

## Fixtures disponibles (`conftest.py`)

| Fixture             | Description                                                  |
|---                  |---                                                           |
| `tmp_cache_dir`     | Redirige `PATHS.cache` vers un dossier temporaire isole      |
| `sample_image`      | `PIL.Image` RGB 100x100 blanche                              |
| `sample_pdf_bytes`  | Bytes d'un PDF factice (header `%PDF-1.4`)                   |
| `sample_pdf_path`   | `Path` vers un PDF factice sur disque                         |
| `valid_bepc_q`      | Question BEPC canonique valide (calcul, serie=None)           |
| `valid_bac_q`       | Question BAC1 serie C canonique valide                       |
| `valid_qcm_q`       | Question QCM BEPC canonique valide (4 choix)                  |
| `sample_questions`  | Liste des 3 questions ci-dessus                              |
| `openai_client_mock`| `MagicMock` simulant le client OpenAI                        |

## Convention d'ecriture

- Pas d'emojis dans le code source ni les commentaires.
- Commentaires en anglais (pour faciliter la revue par des developpeurs
  internationaux) sauf ou la spec est en francais (BEPC, BAC, serie, etc.).
- Docstrings en anglais sur les classes de test, en francais sur les
  fonctions helper locales.
- Chaque classe de test porte un nom explicite (`TestValidateSchemaRequired`,
  `TestEstimateBHeuristicAdjustments`, etc.).
- Les `pytest.mark.parametrize` sont utilises pour les tests parametriques.
- Aucun test ne doit acceder au filesystem reel (toujours `tmp_path`).
- Aucun test ne doit faire d'appel reseau (mocks systematiques).

## Architecture des mocks

```
                  +-----------------------+
                  |  Tesseract (pytess)   | <-- monkeypatch
                  +-----------------------+
                            |
                            v
+-------+    +----------------+    +-----------------------+
| PDF   | -> | pdf2image      | -> | detect_math_content   |
+-------+    | (poppler-utils)|    | (heuristic)           |
             +----------------+    +-----------------------+
                                            |
                              +-------------+-------------+
                              |                           |
                              v                           v
                    +-----------------+        +--------------------+
                    | Tesseract (txt) |        | GPT-4o Vision OCR  |
                    +-----------------+        | (mock client)      |
                               |               +--------------------+
                               v                           |
                    +-----------------+                   |
                    | normalize_tess  |                   |
                    +-----------------+                   |
                               |                           |
                               +-------------+-------------+
                                             |
                                             v
                                  +---------------------+
                                  | data/extracted_text |
                                  +---------------------+
                                             |
                                             v
                                  +---------------------+
                                  | structure_questions |
                                  | (GPT-4o-mini mock)  |
                                  +---------------------+
                                             |
                                             v
                                  +---------------------+
                                  | validate_questions  |
                                  +---------------------+
                                             |
                                             v
                                  +---------------------+
                                  | deduplicate (SimHash)|
                                  +---------------------+
                                             |
                                             v
                                  +---------------------+
                                  | estimate_irt (b)    |
                                  +---------------------+
                                             |
                                             v
                                  +---------------------+
                                  | data/final/         |
                                  | questions.json      |
                                  +---------------------+
```

## Decisions cles

1. **Mock `get_client()` plutot que `OpenAI`** : la fonction `get_client()` etant
   un singleton, mocker son retour est plus simple et plus stable que de
   patcher la classe `OpenAI` (qui peut varier entre versions du SDK).

2. **`responses` comme gardien** : meme si le SDK OpenAI utilise httpx (et
   donc `responses` ne peut pas l'intercepter), on enregistre les URL
   attendues via `responses.add(...)` pour documenter l'endpoint et
   intercepter tout appel `requests` accidentel.

3. **`Paths` est un dataclass `frozen=True`** : on ne peut pas monkeypatcher
   un attribut individuel. La fixture `tmp_cache_dir` remplace l'instance
   `PATHS` entiere sur le module `config` ET sur chaque module utils qui a
   fait `from config import PATHS` au top du fichier.

4. **Tests in-memory par defaut** : les tests de deduplication, validation,
   IRT et JSON utils ne touchent jamais le disque (tout est in-memory). Les
   tests OCR et structure utilisent `tmp_path` (pytest) pour isoler les I/O.

5. **Pas de calibration IRT reelle** : les tests verifient que
   `irt.calibre = False` apres estimation (la vraie calibration se fait
   cote backend via py-irt, pas dans le pipeline).

## Liens utiles

- Spec pipeline : `data_pipeline/README.md`
- Configuration : `data_pipeline/config.py`
- Schema JSON : `data_pipeline/utils/json_utils.py` (constante
  `QUESTION_JSON_SCHEMA`)
- Modele Flutter cible : `lib/models/question.dart`
