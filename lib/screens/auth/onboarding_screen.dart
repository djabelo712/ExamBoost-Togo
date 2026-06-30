// lib/screens/auth/onboarding_screen.dart
// Onboarding multi-étapes : bienvenue, identité, niveau scolaire, série, matières préférées.
// Sauvegarde du profil via UserProvider (Hive + SharedPreferences + notify du router).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // ─── Contrôleurs ───────────────────────────────────────────────
  final PageController _pageController = PageController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _etablissementCtrl = TextEditingController();
  final TextEditingController _villeCtrl = TextEditingController();
  final FocusNode _villeFocusNode = FocusNode();

  // ─── État du formulaire ────────────────────────────────────────
  int _currentStep = 0;
  static const int _welcomeStep = 0;
  static const int _identityStep = 1;
  static const int _niveauStep = 2;
  static const int _serieStep = 3;
  static const int _matieresStep = 4;
  static const int _totalSteps = 5;

  String? _niveauScolaire; // "3eme" | "2nde" | "1ere" | "Terminale"
  String? _serie; // "A" | "B" | "C" | "D" | "F"
  final Set<String> _matieresChoisies = <String>{};

  bool _isSaving = false;

  // ─── Données de référence ──────────────────────────────────────
  static const List<String> _villesTogo = <String>[
    'Lomé',
    'Kpalimé',
    'Atakpamé',
    'Sokodé',
    'Kara',
    'Dapaong',
  ];

  static const List<String> _matieresDisponibles = <String>[
    'Mathématiques',
    'Français',
    'Sciences Physiques',
    'SVT',
    'Histoire-Géographie',
    'Anglais',
    'Philosophie',
    'Économie',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _etablissementCtrl.dispose();
    _villeCtrl.dispose();
    _villeFocusNode.dispose();
    super.dispose();
  }

  // ─── L'étape série n'est requise qu'en 1ère et Terminale ───────
  bool get _serieRequired =>
      _niveauScolaire == '1ere' || _niveauScolaire == 'Terminale';

  // ─── Validation par étape ──────────────────────────────────────
  bool get _canProceedFromIdentity =>
      _prenomCtrl.text.trim().isNotEmpty &&
      _nomCtrl.text.trim().isNotEmpty;

  bool get _canProceedFromNiveau => _niveauScolaire != null;

  bool get _canProceedFromSerie => _serie != null;

  bool get _canProceedFromMatieres =>
      _matieresChoisies.length >= 1 && _matieresChoisies.length <= 3;

  // ─── Navigation entre étapes ───────────────────────────────────
  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    int next = _currentStep + 1;
    // Skip l'étape série si elle n'est pas requise
    if (next == _serieStep && !_serieRequired) {
      next = _matieresStep;
    }
    if (next >= _totalSteps) return;
    _goToStep(next);
  }

  void _previousStep() {
    int prev = _currentStep - 1;
    // Skip l'étape série si elle n'est pas requise
    if (prev == _serieStep && !_serieRequired) {
      prev = _niveauStep;
    }
    if (prev < 0) return;
    _goToStep(prev);
  }

  // ─── Création du profil en base ────────────────────────────────
  Future<void> _createProfile() async {
    setState(() => _isSaving = true);

    try {
      final String userId = const Uuid().v4();
      final AppUser user = AppUser(
        id: userId,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        etablissement: _etablissementCtrl.text.trim().isEmpty
            ? null
            : _etablissementCtrl.text.trim(),
        ville: _villeCtrl.text.trim().isEmpty
            ? null
            : _villeCtrl.text.trim(),
        niveauScolaire: _niveauScolaire!,
        serie: _serie,
        dateInscription: DateTime.now(),
      );

      // Sauvegarde via le UserProvider global (gère Hive + SharedPreferences + notify)
      // → déclenche le redirect du router automatiquement
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setCurrentUser(user);

      // Pause visuelle sur l'écran de succès (1,5 s)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // Le router va auto-redirect de /onboarding → / car l'user est maintenant authentifié
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du profil : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: _isSaving
          ? _buildSuccessView()
          : SafeArea(
              child: Column(
                children: <Widget>[
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      // On désactive le swipe pour forcer l'utilisation des boutons (validation par étape)
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int i) =>
                          setState(() => _currentStep = i),
                      children: <Widget>[
                        _buildWelcomeStep(),
                        _buildIdentityStep(),
                        _buildNiveauStep(),
                        _buildSerieStep(),
                        _buildMatieresStep(),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
    );
  }

  // ─── Indicateur de progression (points) ────────────────────────
  Widget _buildProgressIndicator() {
    // On masque le point de l'étape série si elle est skippée
    final List<int> visibleSteps = _serieRequired
        ? const <int>[
            _welcomeStep,
            _identityStep,
            _niveauStep,
            _serieStep,
            _matieresStep,
          ]
        : const <int>[
            _welcomeStep,
            _identityStep,
            _niveauStep,
            _matieresStep,
          ];

    final int currentVisibleIndex = visibleSteps.indexOf(_currentStep);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(visibleSteps.length, (int i) {
          final bool active = i == currentVisibleIndex;
          final bool passed = i < currentVisibleIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active || passed ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  // ─── Étape 1 : Bienvenue ───────────────────────────────────────
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 32),
          Text('ExamBoost Togo', style: AppTextStyles.h1),
          const SizedBox(height: 12),
          Text(
            'Prépare tes examens nationaux avec intelligence.',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'BEPC · BAC · Adapté au programme togolais · 100% hors-ligne',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Étape 2 : Identité ────────────────────────────────────────
  Widget _buildIdentityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          Text('Identité', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Dis-nous en plus sur toi pour personnaliser ton parcours.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _prenomCtrl,
            decoration: const InputDecoration(
              labelText: 'Prénom *',
              hintText: 'Ex : Kofi',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              hintText: 'Ex : Komla',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _etablissementCtrl,
            decoration: const InputDecoration(
              labelText: 'Établissement (optionnel)',
              hintText: 'Ex : Lycée de Tokoin',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          RawAutocomplete<String>(
            textEditingController: _villeCtrl,
            focusNode: _villeFocusNode,
            optionsBuilder: (TextEditingValue v) {
              if (v.text.isEmpty) return const Iterable<String>.empty();
              return _villesTogo.where((String ville) =>
                  ville.toLowerCase().contains(v.text.toLowerCase()));
            },
            onSelected: (String selection) {
              _villeCtrl.text = selection;
              _villeCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: selection.length),
              );
              _villeFocusNode.unfocus();
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController controller,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
                decoration: const InputDecoration(
                  labelText: 'Ville (optionnel)',
                  hintText: 'Ex : Lomé',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              );
            },
            optionsViewBuilder: (
              BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options,
            ) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth:
                            MediaQuery.sizeOf(context).width - 48,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: options
                            .map((String option) => ListTile(
                                  dense: true,
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Étape 3 : Niveau scolaire ─────────────────────────────────
  Widget _buildNiveauStep() {
    final List<_NiveauOption> niveaux = <_NiveauOption>[
      _NiveauOption(
        value: '3eme',
        label: '3ème',
        description: 'Préparation BEPC',
        icon: Icons.menu_book_outlined,
      ),
      _NiveauOption(
        value: '2nde',
        label: '2nde',
        description: 'Préparation BAC (commun)',
        icon: Icons.book_outlined,
      ),
      _NiveauOption(
        value: '1ere',
        label: '1ère',
        description: 'Préparation BAC (Probatoire)',
        icon: Icons.school_outlined,
      ),
      _NiveauOption(
        value: 'Terminale',
        label: 'Terminale',
        description: 'Préparation BAC (BAC final)',
        icon: Icons.emoji_events_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          Text('Ton niveau scolaire', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Sélectionne la classe qui correspond à ta situation actuelle.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: niveaux
                  .map((_NiveauOption n) => _buildNiveauCard(n))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauCard(_NiveauOption n) {
    final bool selected = _niveauScolaire == n.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _niveauScolaire = n.value;
          // Réinitialise la série si le niveau ne la requiert plus
          if (n.value != '1ere' && n.value != 'Terminale') {
            _serie = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              n.icon,
              size: 36,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              n.label,
              style: AppTextStyles.h3.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              n.description,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Étape 4 : Série ───────────────────────────────────────────
  Widget _buildSerieStep() {
    final List<_SerieOption> series = <_SerieOption>[
      _SerieOption(
        value: 'A',
        label: 'Série A',
        description: 'Littéraire',
        icon: Icons.menu_book_outlined,
      ),
      _SerieOption(
        value: 'B',
        label: 'Série B',
        description: 'Sciences Économiques',
        icon: Icons.trending_up,
      ),
      _SerieOption(
        value: 'C',
        label: 'Série C',
        description: 'Maths & Sciences Physiques',
        icon: Icons.calculate_outlined,
      ),
      _SerieOption(
        value: 'D',
        label: 'Série D',
        description: 'Sciences Naturelles',
        icon: Icons.science_outlined,
      ),
      _SerieOption(
        value: 'F',
        label: 'Série F',
        description: 'Technique',
        icon: Icons.engineering_outlined,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          Text('Quelle est ta série ?', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Indispensable pour cibler les épreuves du BAC adaptées à ta filière.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...series.map((_SerieOption s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSerieCard(s),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSerieCard(_SerieOption s) {
    final bool selected = _serie == s.value;
    return GestureDetector(
      onTap: () => setState(() => _serie = s.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                s.icon,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(s.label, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(s.description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  // ─── Étape 5 : Matières préférées ──────────────────────────────
  Widget _buildMatieresStep() {
    final bool canSelectMore = _matieresChoisies.length < 3;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          Text('Tes matières préférées', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Choisis 1 à 3 matières pour commencer. Tu pourras en ajouter '
            'd\'autres plus tard depuis ton espace.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                _matieresChoisies.length >= 1
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 16,
                color: _matieresChoisies.length >= 1
                    ? AppColors.success
                    : AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                '${_matieresChoisies.length}/3 sélectionnées',
                style: AppTextStyles.label.copyWith(
                  color: _matieresChoisies.length >= 1
                      ? AppColors.success
                      : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _matieresDisponibles.map((String m) {
              final bool selected = _matieresChoisies.contains(m);
              return FilterChip(
                label: Text(m),
                selected: selected,
                onSelected: (bool val) {
                  setState(() {
                    if (val && canSelectMore) {
                      _matieresChoisies.add(m);
                    } else if (!val) {
                      _matieresChoisies.remove(m);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Boutons de navigation ─────────────────────────────────────
  Widget _buildNavigationButtons() {
    final bool isFirst = _currentStep == _welcomeStep;

    bool canProceed = false;
    String nextLabel = 'Suivant';
    VoidCallback? onNext;

    switch (_currentStep) {
      case _welcomeStep:
        canProceed = true;
        nextLabel = 'Commencer';
        onNext = _nextStep;
        break;
      case _identityStep:
        canProceed = _canProceedFromIdentity;
        nextLabel = 'Suivant';
        onNext = _nextStep;
        break;
      case _niveauStep:
        canProceed = _canProceedFromNiveau;
        nextLabel = 'Suivant';
        onNext = _nextStep;
        break;
      case _serieStep:
        canProceed = _canProceedFromSerie;
        nextLabel = 'Suivant';
        onNext = _nextStep;
        break;
      case _matieresStep:
        canProceed = _canProceedFromMatieres;
        nextLabel = 'Créer mon profil';
        onNext = _createProfile;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: <Widget>[
          if (!isFirst) ...<Widget>[
            OutlinedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: canProceed ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Écran de succès ───────────────────────────────────────────
  Widget _buildSuccessView() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text('Profil créé !', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(
              'Bienvenue ${_prenomCtrl.text.trim()} !',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Redirection vers l\'accueil...',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèles de données internes (UI seulement) ─────────────────
class _NiveauOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  const _NiveauOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class _SerieOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  const _SerieOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}
