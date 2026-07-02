# Rapport taille APK - ExamBoost Togo

> Ce fichier est **genere automatiquement** par `./scripts/analyze_apk_size.sh`.
> Il est ecrase a chaque execution du script. Ne pas editer manuellement.

## Comment regenerer ce rapport

```bash
# Analyser un APK specifique (defaut : arm64-v8a release).
./scripts/analyze_apk_size.sh

# Analyser un autre APK (par ex. armeabi-v7a pour smartphones anciens).
./scripts/analyze_apk_size.sh build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk

# Personnaliser la limite (par defaut 25 Mo - contrainte Togo).
./scripts/analyze_apk_size.sh path/to/app.apk 20
```

## Format du rapport genere

Le rapport contient 5 sections :

1. **Resume** - tailles compressee (telechargement) et decompressee (sur device),
   limite cible, statut OK/DEPASSE.
2. **Repartition par categorie** - tableau Markdown avec octets / Mo / % pour
   chaque categorie (lib/, assets/flutter_assets/, classes*.dex, res/,
   resources.arsc, META-INF/, AndroidManifest.xml, Autre).
3. **Top 10 fichiers les plus lourds** - tableau trie par taille decompressee.
4. **Suggestions** - voir la sortie console du script pour les suggestions
   contextuelles basees sur la categorie dominante.
5. **Scripts associes** - liens vers les autres scripts d'optimisation.

## Workflow complet d'optimisation

```bash
# 1. Optimiser les assets (dry-run d'abord, puis --apply).
./scripts/optimize_assets.sh
./scripts/optimize_assets.sh --apply

# 2. Build APK ultra-optimise (5 couches : split-per-abi + shrink +
#    tree-shake-icons + obfuscate + assets).
./scripts/build_apk_optimized.sh

# 3. Analyser la composition (regenere ce rapport).
./scripts/analyze_apk_size.sh

# 4. Verifier rapidement la taille < 25 Mo.
./scripts/check_apk_size.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## One-liner

```bash
./scripts/build_apk_optimized.sh --analyze
```

Cette commande :

1. Optimise les assets (`optimize_assets.sh --apply`).
2. Build les 3 APK avec `--split-per-abi --shrink --tree-shake-icons --obfuscate`.
3. Verifie chaque APK < 25 Mo (exit 2 si depassement, build reussi).
4. Genere le rapport detaille dans ce fichier.

## Voir aussi

- `docs/APK_OPTIMIZATION_GUIDE.md` - guide complet d'optimisation (15 sections).
- `scripts/build_apk_optimized.sh` - build ultra-optimise.
- `scripts/optimize_assets.sh` - compression assets (dry-run par defaut).
- `scripts/check_apk_size.sh` - verification rapide < 25 Mo.
- `scripts/optimize_apk.sh` - audit read-only (top 10 assets).
