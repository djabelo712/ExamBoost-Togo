// lib/screens/parent/parent_login_screen.dart
// Écran de connexion parent (séparé de l'élève).
//
// 3 champs :
//   1. Email parent
//   2. Mot de passe (masquable)
//   3. Code enfant à 6 chiffres (permet de lier le compte parent à un
//      enfant déjà inscrit sur ExamBoost — ce code est fourni par
//      l'établissement ou visible dans l'app élève : Profil > Code parent)
//
// Mode démo : n'importe quel email valide + mot de passe ≥ 4 caractères
// + code à 6 chiffres est accepté et redirige vers /parent/dashboard.
// Aucun appel réseau réel — voir services/parent_service.dart.
//
// Note : les routes /parent/login et /parent/dashboard doivent être
// déclarées dans lib/utils/app_router.dart (voir README.md du dossier
// parent).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  // ─── Contrôleurs de formulaire ─────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ─── État UI ───────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ─── Connexion ─────────────────────────────────────────────────
  // Appelle ParentService.login (mock 700 ms) puis redirige vers
  // /parent/dashboard. Gère les ParentAuthException en affichant un
  // message d'erreur inline sous le bouton.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ParentService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        childCode: _codeController.text.trim(),
      );

      if (!mounted) return;
      context.go('/parent/dashboard');
    } on ParentAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage =
          'Une erreur inattendue est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // ─── Titre + sous-titre ─────────────────────
                    Text('Espace Parent',
                        style: AppTextStyles.h2.copyWith(
                            color: AdaptiveColors.textPrimary(context))),
                    const SizedBox(height: 4),
                    Text(
                      'Suivez la progression de votre enfant et recevez '
                      'des alertes en temps réel.',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textSecondary(context)),
                    ),
                    const SizedBox(height: 20),

                    // ─── Email ──────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const ['email'],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email parent',
                        hintText: 'parent@example.tg',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$')
                            .hasMatch(v.trim())) {
                          return 'Format d\'email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ─── Mot de passe ───────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4)
                          ? '4 caractères minimum'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ─── Code enfant (6 chiffres) ───────────────
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _handleLogin();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Code enfant (6 chiffres)',
                        hintText: '384726',
                        prefixIcon: Icon(Icons.child_care_outlined),
                        helperText: 'Trouvable dans l\'app de votre enfant : '
                            'Profil > Code parent.',
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Code enfant requis';
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                          return 'Le code doit comporter exactement 6 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Lien mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordSheet,
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── Message d'erreur (si any) ──────────────
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.4),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Bouton connexion ───────────────────────
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── Lien créer un compte ───────────────────
                    Center(
                      child: TextButton.icon(
                        onPressed: _showCreateAccountSheet,
                        icon: const Icon(Icons.person_add_alt_1_outlined,
                            size: 18),
                        label: const Text('Créer un compte parent'),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ─── Encart d'info premium ──────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdaptiveColors.primarySurface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primaryLight, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Premium parent : 2000 FCFA/mois par enfant '
                              '(ou 5000 FCFA/mois jusqu\'à 3 enfants avec la '
                              'formule Famille). Essai gratuit de 14 jours '
                              'inclus au premier lien d\'enfant.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AdaptiveColors.primary(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header avec logo ──────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              const Icon(Icons.family_restroom, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 14),
        Text('ExamBoost Togo',
            style: AppTextStyles.h1
                .copyWith(color: AdaptiveColors.textPrimary(context))),
        const SizedBox(height: 4),
        Text(
          'Espace Parent',
          style: AppTextStyles.bodySmall.copyWith(
            color: AdaptiveColors.primary(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Bottom sheet "Mot de passe oublié" ────────────────────────
  // UI only — en production, POST /auth/parent/reset-password.
  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_reset, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Mot de passe oublié',
                          style: AppTextStyles.h2.copyWith(
                              color: AdaptiveColors.textPrimary(context))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saisissez votre email. Un lien de réinitialisation vous '
                  'sera envoyé (mode démo : action simulée).',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email parent',
                    hintText: 'parent@example.tg',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis';
                    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$')
                        .hasMatch(v.trim())) {
                      return 'Format d\'email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(sheetCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Si cet email correspond à un compte parent, '
                            'un lien de réinitialisation vient d\'être envoyé.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Envoyer le lien'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom sheet "Créer un compte parent" ─────────────────────
  // UI only — en production, POST /auth/parent/register.
  void _showCreateAccountSheet() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Créer un compte parent',
                            style: AppTextStyles.h2.copyWith(
                                color:
                                    AdaptiveColors.textPrimary(context))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renseignez vos informations. Vous pourrez lier vos '
                    'enfants après création du compte via leur code à 6 '
                    'chiffres.',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: prenomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      hintText: 'Kossi',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      hintText: 'Mensah',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'parent@example.tg',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ requis';
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$')
                          .hasMatch(v.trim())) {
                        return 'Format d\'email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (Flooz / TMoney)',
                      hintText: '+228 90 12 34 56',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.of(sheetCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Compte créé. Vous pouvez maintenant vous '
                              'connecter avec votre email et mot de passe.',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text('Créer le compte'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
