// lib/screens/parent/parent_children_tab.dart
// Onglet "Enfants" du dashboard parent.
//
// Affiche :
//   - Une carte informative en haut ("X enfant(s) lié(s) à votre compte")
//   - La liste des cartes enfants (ChildCard) — tap → onChildTap
//   - Un bouton "Lier un nouvel enfant" (formulaire code 6 chiffres)
//
// En mode démo : 2 enfants mockés (Awa Mensah, 3e B — Yao Mensah,
// Terminale D). Le formulaire "Lier un enfant" est UI only (snackbar
// de confirmation).

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';
import 'widgets/child_card.dart';

class ChildrenTab extends StatelessWidget {
  final List<Child> children;
  final ParentAccount parent;
  final ValueChanged<String> onChildTap;

  const ChildrenTab({
    super.key,
    required this.children,
    required this.parent,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Bandeau info ─────────────────────────────────────
          _buildInfoBanner(context),
          const SizedBox(height: 14),

          // ─── Bouton "Lier un enfant" ──────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLinkChildSheet(context),
              icon: const Icon(Icons.add_link),
              label: const Text('Lier un nouvel enfant'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Liste des cartes enfants ─────────────────────────
          Expanded(
            child: children.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: children.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => ChildCard(
                      child: children[i],
                      onChildTap: () => onChildTap(children[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Bandeau info ──────────────────────────────────────────────
  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.primarySurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${children.length} enfant(s) lié(s) à votre compte',
                  style: AppTextStyles.h3.copyWith(
                      color: AdaptiveColors.primary(context),
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Touchez une carte pour voir la progression détaillée, '
                  'les badges et la comparaison avec la classe.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.primary(context),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AdaptiveColors.primarySurface(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.child_care,
                size: 40, color: AdaptiveColors.primary(context)),
          ),
          const SizedBox(height: 16),
          Text('Aucun enfant lié',
              style: AppTextStyles.h3
                  .copyWith(color: AdaptiveColors.textPrimary(context))),
          const SizedBox(height: 6),
          Text(
            'Liez votre premier enfant en cliquant sur le bouton ci-dessus. '
            'Vous aurez besoin de son code à 6 chiffres (disponible dans '
            'son app ExamBoost : Profil > Code parent).',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  // ─── Bottom sheet "Lier un enfant" ─────────────────────────────
  // UI only — en production, POST /parent/children/link.
  void _showLinkChildSheet(BuildContext context) {
    final codeCtrl = TextEditingController();
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
                    const Icon(Icons.add_link, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Lier un enfant',
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
                  'Saisissez le code à 6 chiffres fourni par votre enfant '
                  '(visible dans son app : Profil > Code parent).',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontSize: 24,
                      letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '______',
                    counterText: '',
                    prefixIcon: Icon(Icons.child_care_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Code requis';
                    if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                      return 'Le code doit comporter exactement 6 chiffres';
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
                        SnackBar(
                          content: Text(
                            'Enfant lié avec succès (code ${codeCtrl.text}). '
                            'Ses données apparaîtront dans votre espace sous peu.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Lier cet enfant'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
