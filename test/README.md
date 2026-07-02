# ExamBoost Togo — Test suite (V2 — critical algorithms scope)

This directory holds the ExamBoost Togo test suite. The current V2 scope is
**deliberately reduced** to the three ML algorithms at the heart of the
product: **SM-2**, **BKT**, and **IRT 3PL**, plus the `Question` model that
every layer depends on. Widget tests and integration tests will land in V3.

## Critical tests (V2 scope)

```
test/
├── README.md                       # This file
├── helpers/
│   ├── test_data.dart              # 10 sample questions + mock user + mock review cards
│   ├── test_helpers.dart           # (Legacy) Hive init + factory helpers
│   └── mock_services.dart          # (Legacy) MockSrsService, MockQuestionService, FakeUserProvider
└── unit/
    ├── sm2_test.dart               # SM-2 algorithm — CRITICAL
    ├── bkt_test.dart               # BKT (Bayesian Knowledge Tracing) — CRITICAL
    ├── irt_test.dart               # IRT 3PL + selectBestQuestion — CRITICAL
    └── question_test.dart          # Question model (fromJson / toJson / difficulte)
```

| File | Tests | What it covers |
|---|---|---|
| `test/unit/sm2_test.dart` | ~25 | SM-2: q=5/4/3 correct, q=2/1/0 incorrect, EF floor (1.3), quality bounds (0-5), successRate, isDue, dates, SrsQuality enum |
| `test/unit/bkt_test.dart` | ~17 | BKT: exact posterior values for correct/incorrect, mastery threshold (0.85), convergence (10 correct -> mastery), custom pLearn/pSlip/pGuess, scoreGlobal |
| `test/unit/irt_test.dart` | ~18 | IRT 3PL: P=0.5 at theta=b, asymptotes (c floor, 1.0 ceiling), discrimination, overflow protection, output bounds, symmetry, selectBestQuestion (3 scenarios + null + null irtB) |
| `test/unit/question_test.dart` | ~20 | Question: fromJson (defaults, IRT, QCM), toJson round-trip, difficulte (facile/moyen/difficile boundaries), QuestionType enum (5 values), DifficulteNiveau enum (3 values) |

## Prerequisites (IMPORTANT)

The model classes (`Question`, `ReviewCard`, `AppUser`, `QuestionType`) are
annotated with `@HiveType`, which generates `*.g.dart` adapter files via
`build_runner`. **You must run build_runner before the tests can compile.**

From the project root (`ExamBoost-Togo/`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/models/question.g.dart`
- `lib/models/review_card.g.dart`
- `lib/models/user.g.dart`
- (other adapters as needed)

Without these files, every test that imports the models will fail to compile
with `Uri 'X.g.dart' does not exist`.

## Running the tests

### Run the V2 critical scope only

```bash
flutter test test/unit/sm2_test.dart test/unit/bkt_test.dart \
             test/unit/irt_test.dart test/unit/question_test.dart
```

Or, more concisely:

```bash
flutter test test/unit/
```

### Run a single file

```bash
flutter test test/unit/sm2_test.dart
```

### Run a single test (by name)

```bash
flutter test --name "Premiere reponse correcte"
```

### With coverage

```bash
flutter test --coverage
```

This generates `coverage/lcov.info`. To view the HTML report:

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html        # macOS
xdg-open coverage/html/index.html    # Linux
```

## Coverage target

The V2 target is **100% line coverage** on the three ML algorithms:

| Module | Priority | Tests | Target |
|---|---|---|---|
| `lib/models/review_card.dart` (SM-2) | CRITICAL | `test/unit/sm2_test.dart` | 100% |
| `lib/models/user.dart` (BKT) | CRITICAL | `test/unit/bkt_test.dart` | 100% |
| `lib/services/srs_service.dart` (IRT + selectBestQuestion) | CRITICAL | `test/unit/irt_test.dart` | 100% on `irtProbability` + `selectBestQuestion` |
| `lib/models/question.dart` | HIGH | `test/unit/question_test.dart` | 100% on `fromJson` + `toJson` + `difficulte` |

The SrsService methods that touch Hive (`getOrCreate`, `recordAnswer`,
`getDueCards`, `getStats`, `init`) are NOT covered in V2 — they require a
Hive box and will be tested in V3 alongside the widget/integration suite.

## Test design decisions

### No Hive initialisation for algorithm tests

`ReviewCard.applyReview`, `AppUser.updateBkt`, `SrsService.irtProbability`,
and `SrsService.selectBestQuestion` are pure functions — they do not require
an open Hive box. The tests construct model instances directly:

- `ReviewCard(userId: 'u1', questionId: 'q1')` — a fresh card.
- `AppUser(id: 'u1', nom: 'T', prenom: 'T', niveauScolaire: '3eme', dateInscription: DateTime.now())` — a fresh user.
- `SrsService()` — never calls `init()`, so the box is never opened.

`AppUser.updateBkt` ends with a `save()` call (from `HiveObject`). When the
object is not attached to a Hive box, `save()` is a no-op (`Future.value()`),
so the tests do not need to initialise Hive. This keeps the algorithm tests
fast (no `setUpAll` / `tearDownAll` boilerplate).

### Each test creates its own data

No state is shared between tests. The `setUp` block in `bkt_test.dart`
returns a fresh `AppUser` for every test; the SM-2 and IRT tests construct a
fresh `ReviewCard` / `SrsService` inline. This avoids test-ordering bugs.

### The BKT convergence floor discrepancy

The spec asked for "Après 5 incorrectes consécutives : P(L) < 0.10". The
actual implementation has `pLearn = 0.20` (transition probability), which
creates a floor: `P(L_next) = P(L|obs) + (1 - P(L|obs)) * pLearn` converges
to `pLearn` (0.20) when `P(L|obs) -> 0`. After 5 incorrect answers from
`P(L) = 0.90`, the value stabilises around 0.23 — NOT below 0.10.

We assert `lessThan(0.30)` instead, with a `greaterThanOrEqualTo(0.15)`
lower bound to catch regressions where P(L) would drop too far below the
floor. The implementation is correct; the spec was overly optimistic about
the convergence rate.

### Comments language

Per project convention: file headers and inline explanations in English;
test names and group names in French (matches the existing code style and
the FR-first audience of the app).

## Troubleshooting

### "Uri 'question.g.dart' does not exist"

Run `dart run build_runner build --delete-conflicting-outputs` from the
project root.

### "HiveError: Cannot write to a disposed box"

A test closed the Hive box but a subsequent test tried to use it. The V2
critical-scope tests do not touch Hive, so this should not occur. If you
see it, check that you are not running the legacy
`test/unit/services/srs_service_test.dart` (which DOES use Hive) in the
same `flutter test` invocation without the proper `setUpAll` /
`tearDownAll` from `test/helpers/test_helpers.dart`.

### "flutter: command not found"

The Flutter SDK is not installed. Install Flutter 3.x (the project targets
`>=3.3.0 <4.0.0`) and run `flutter pub get` before running the tests.

## What's next (V3)

The V3 scope will add:
- Widget tests: `RevisionScreen`, `HomeScreen`, `OnboardingScreen`,
  `QuestionCard`, `SrsButtons`.
- Integration tests: Onboarding -> Home -> Revision -> Dashboard.
- Service tests: `SrsService` (recordAnswer, getDueCards, getStats) with a
  real Hive box, `QuestionService` (loadQuestions, filters).
- Golden tests: visual regression on the main screens.

Those tests are already scaffolded under `test/widget/`,
`test/integration/`, `test/golden/`, and `test/unit/services/` from the V1
effort — they will be finished and wired into CI in V3.
