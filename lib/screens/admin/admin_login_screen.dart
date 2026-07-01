// lib/screens/admin/admin_login_screen.dart
// Espace directeurs / chefs d'établissement (B2B)
//
// Ecran de login séparé de l'app élève (route /admin/login).
// - Champs email + mot de passe
// - Lien "Demander une démo" (formulaire de contact minimal)
// - Bouton "Se connecter"
//
// Mode démo : n'importe quel email + mot de passe non vide est accepté
// et redirige vers /admin/dashboard. Aucun appel réseau réel.
//
// Note : les routes /admin/login et /admin/dashboard doivent être déclarées
// dans lib/utils/app_router.dart (voir README.md du dossier admin).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // ─── Contrôleurs de formulaire ─────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ─── Etat UI ───────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Connexion (mode démo) ─────────────────────────────────────
  // Accepte n'importe quel email valide + mot de passe non vide.
  // A brancher plus tard sur POST /auth/admin/login (voir README).
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Simulation d'un appel réseau
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _loading = false);

    // Redirection vers le dashboard directeur
    context.go('/admin/dashboard');
  }

  // ─── Formulaire "Demander une démo" ────────────────────────────
  // Ouvre un bottom sheet avec 3 champs (établissement, ville, contact).
  // En production : POST /admin/demo-request
  void _openDemoRequest() {
    final etabCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
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
                    const Icon(Icons.school, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demander une démo',
                        style: AppTextStyles.h2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Notre équipe vous recontactera sous 48h pour une '
                  'démonstration personnalisée.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: etabCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'établissement',
                    hintText: 'Lycée de Tokoin',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: villeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    hintText: 'Lomé',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email ou téléphone',
                    hintText: 'direction@lycee-tokoin.tg',
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                            'Demande envoyée. Notre équipe vous recontactera '
                            'sous 48h.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Envoyer la demande'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Logo / Branding ──────────────────────────
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // ─── Champs de connexion ─────────────────────
                    Text('Connexion', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Réservé aux directeurs et chefs d\'établissement.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const ['email'],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email professionnel',
                        hintText: 'direction@etablissement.tg',
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

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                    ),
                    const SizedBox(height: 8),

                    // Lien mot de passe oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Un lien de réinitialisation vous sera envoyé '
                                'par email (mode démo : action simulée).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bouton connexion
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

                    // Demander une démo
                    Center(
                      child: TextButton.icon(
                        onPressed: _openDemoRequest,
                        icon: const Icon(Icons.calendar_today_outlined,
                            size: 18),
                        label: const Text('Demander une démo'),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Note d'info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
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
                              'Licence ExamBoost : 100 000 FCFA/an par '
                              'établissement. Démo gratuite de 30 jours '
                              'disponible sur demande.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryDark),
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
          child: const Icon(Icons.school, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 14),
        Text('ExamBoost Togo', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          'Espace Directeurs',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
