// lib/screens/parent/parent_payment_screen.dart
// Écran de paiement premium du module parent.
//
// Structure :
//   1. Header (titre + sous-titre + bouton retour dashboard)
//   2. Section offres (3 plans : Essentiel 2000/mois, Famille 5000/mois,
//      Trimestre 4800/3 mois) — cartes sélectionnables
//   3. Section méthode de paiement (Flooz / TMoney / Carte bancaire)
//   4. Champ dynamique selon méthode (téléphone pour Flooz/TMoney,
//      numéro carte + expiration + CVC pour CB)
//   5. Récapitulatif (plan + montant + méthode)
//   6. Bouton "Payer 2000 FCFA" — déclenche processPayment (mock 1.5s,
//      90% de réussite)
//   7. Historique des paiements (liste des transactions passées)
//
// Mode démo : 90% de réussite, 10% d'échec simulé. Pas de paiement
// réel. En production : POST /payment/initiate -> push USSD opérateur
// -> webhook backend -> confirmation (voir README.md).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';

class ParentPaymentScreen extends StatefulWidget {
  const ParentPaymentScreen({super.key});

  @override
  State<ParentPaymentScreen> createState() => _ParentPaymentScreenState();
}

class _ParentPaymentScreenState extends State<ParentPaymentScreen> {
  // ─── État ──────────────────────────────────────────────────────
  PremiumPlan? _selectedPlan;
  PaymentMethod _method = PaymentMethod.flooz;
  final _phoneCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _processing = false;
  List<PaymentHistory> _payments = ParentMockData.payments;

  @override
  void initState() {
    super.initState();
    // Plan "Famille" sélectionné par défaut (isPopulaire).
    _selectedPlan = ParentMockData.plans.firstWhere(
      (p) => p.isPopulaire,
      orElse: () => ParentMockData.plans.first,
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cardCtrl.dispose();
    _expCtrl.dispose();
    _cvcCtrl.dispose();
    super.dispose();
  }

  // ─── Paiement ──────────────────────────────────────────────────
  Future<void> _pay() async {
    if (_selectedPlan == null) {
      _showSnack('Veuillez sélectionner une offre.', AppColors.warning);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    try {
      final payment = await ParentService.processPayment(
        planId: _selectedPlan!.id,
        method: _method,
        telephone: _method == PaymentMethod.carteBancaire
            ? ''
            : _phoneCtrl.text.trim(),
      );
      // Activer le premium côté compte (mock).
      await ParentService.activatePremium(
        parentId: ParentMockData.defaultParent.id,
        plan: _selectedPlan!,
      );

      if (!mounted) return;
      setState(() {
        _payments = [payment, ..._payments];
      });
      _showSuccessDialog(payment);
    } on PaymentException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('Une erreur inattendue est survenue. '
          'Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium ExamBoost'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/parent/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Bandeau avantage premium ───────────────────
                _buildPremiumBanner(),
                const SizedBox(height: 20),

                // ─── Section offres ─────────────────────────────
                Text('1. Choisissez votre offre',
                    style: AppTextStyles.h3.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontSize: 16)),
                const SizedBox(height: 12),
                ...ParentMockData.plans.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _planCard(p),
                    )),
                const SizedBox(height: 20),

                // ─── Section méthode ────────────────────────────
                Text('2. Méthode de paiement',
                    style: AppTextStyles.h3.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _methodChip(
                            PaymentMethod.flooz, 'Flooz', Icons.phone_android)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _methodChip(PaymentMethod.tmoney, 'TMoney',
                            Icons.phone_iphone)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _methodChip(PaymentMethod.carteBancaire,
                            'Carte', Icons.credit_card)),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Champ dynamique ────────────────────────────
                if (_method == PaymentMethod.carteBancaire) ...[
                  TextFormField(
                    controller: _cardCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de carte',
                      hintText: '4242 4242 4242 4242',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ requis';
                      if (v.replaceAll(' ', '').length < 13) {
                        return 'Numéro de carte invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expCtrl,
                          decoration: const InputDecoration(
                            labelText: 'MM/AA',
                            hintText: '12/28',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requis';
                            }
                            if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v.trim())) {
                              return 'MM/AA';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvcCtrl,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'CVC',
                            hintText: '123',
                            prefixIcon: Icon(Icons.lock),
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requis';
                            }
                            if (v.length < 3) return 'CVC invalide';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _method == PaymentMethod.flooz
                          ? 'Numéro Flooz'
                          : 'Numéro TMoney',
                      hintText: '+228 90 12 34 56',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ requis';
                      if (v.trim().length < 8) return 'Numéro invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdaptiveColors.accentSurface(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Un code USSD sera envoyé sur votre téléphone. '
                            'Validez avec votre code PIN ${_method == PaymentMethod.flooz ? 'Flooz' : 'TMoney'} '
                            'pour confirmer le paiement.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.accent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ─── Récapitulatif ──────────────────────────────
                if (_selectedPlan != null) _buildRecap(),

                const SizedBox(height: 20),

                // ─── Bouton payer ───────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _pay,
                    icon: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.lock_outline),
                    label: Text(
                      _processing
                          ? 'Traitement en cours...'
                          : 'Payer ${_selectedPlan?.montantFcfa ?? 0} FCFA',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Paiement sécurisé · aucune donnée bancaire stockée',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textSecondary(context),
                        fontSize: 11),
                  ),
                ),

                const SizedBox(height: 32),

                // ─── Historique ─────────────────────────────────
                Text('Historique des paiements',
                    style: AppTextStyles.h3.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontSize: 16)),
                const SizedBox(height: 12),
                ..._payments.map((p) => _paymentRow(p)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bandeau premium ───────────────────────────────────────────
  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text('Premium ExamBoost',
                  style: AppTextStyles.h2.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Débloquez tout le potentiel de l\'app pour votre enfant : '
            'examens blancs illimités, tuteur IA, prédictions de score, '
            'feedback détaillé, badges exclusifs.',
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withOpacity(0.95)),
          ),
        ],
      ),
    );
  }

  // ─── Carte offre ───────────────────────────────────────────────
  Widget _planCard(PremiumPlan plan) {
    final isSelected = _selectedPlan?.id == plan.id;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AdaptiveColors.primary(context)
                : AdaptiveColors.divider(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AdaptiveColors.primary(context).withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Radio<PremiumPlan>(
              value: plan,
              groupValue: _selectedPlan,
              onChanged: (v) => setState(() => _selectedPlan = v),
              activeColor: AdaptiveColors.primary(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.titre,
                        style: AppTextStyles.h3.copyWith(
                            color: AdaptiveColors.textPrimary(context),
                            fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      if (plan.isPopulaire)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Populaire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.description,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textSecondary(context),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.montantFcfa}',
                  style: AppTextStyles.h2.copyWith(
                      color: AdaptiveColors.primary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  'FCFA / ${plan.dureeMois == 1 ? 'mois' : '${plan.dureeMois} mois'}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chip méthode de paiement ──────────────────────────────────
  Widget _methodChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AdaptiveColors.primarySurface(context)
              : AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AdaptiveColors.primary(context)
                : AdaptiveColors.divider(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AdaptiveColors.primary(context)
                  : AdaptiveColors.textSecondary(context),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected
                    ? AdaptiveColors.primary(context)
                    : AdaptiveColors.textSecondary(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Récapitulatif ─────────────────────────────────────────────
  Widget _buildRecap() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif',
              style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context), fontSize: 14)),
          const SizedBox(height: 10),
          _recapRow('Offre', _selectedPlan!.titre),
          _recapRow('Durée', '${_selectedPlan!.dureeMois} mois'),
          _recapRow(
              'Enfants inclus',
              _selectedPlan!.maxEnfants == 1
                  ? '1 enfant'
                  : 'Jusqu\'à ${_selectedPlan!.maxEnfants} enfants'),
          _recapRow('Méthode', _methodLabel(_method)),
          const Divider(height: 16),
          _recapRow(
            'Montant total',
            '${_selectedPlan!.montantFcfa} FCFA',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ligne historique ──────────────────────────────────────────
  Widget _paymentRow(PaymentHistory p) {
    final statusColor = switch (p.status) {
      PaymentStatus.reussi => AppColors.success,
      PaymentStatus.enAttente => AppColors.warning,
      PaymentStatus.echoue => AppColors.error,
      PaymentStatus.annule => AppColors.textSecondary,
    };
    final statusLabel = switch (p.status) {
      PaymentStatus.reussi => 'Réussi',
      PaymentStatus.enAttente => 'En attente',
      PaymentStatus.echoue => 'Échoué',
      PaymentStatus.annule => 'Annulé',
    };
    final methodLabel = switch (p.method) {
      PaymentMethod.flooz => 'Flooz',
      PaymentMethod.tmoney => 'TMoney',
      PaymentMethod.carteBancaire => 'Carte bancaire',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AdaptiveColors.divider(context), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              p.status == PaymentStatus.reussi
                  ? Icons.check_circle
                  : p.status == PaymentStatus.echoue
                      ? Icons.cancel
                      : Icons.access_time,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.montantFcfa} FCFA · $methodLabel',
                  style: AppTextStyles.h3.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd/MM/yyyy · HH:mm').format(p.date)}'
                  '${p.reference != null ? ' · ${p.reference}' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────
  String _methodLabel(PaymentMethod m) => switch (m) {
        PaymentMethod.flooz => 'Flooz',
        PaymentMethod.tmoney => 'TMoney',
        PaymentMethod.carteBancaire => 'Carte bancaire',
      };

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _showSuccessDialog(PaymentHistory payment) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Paiement réussi !',
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'Votre abonnement premium est activé. '
              '${payment.montantFcfa} FCFA débités via ${_methodLabel(payment.method)}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Référence : ${payment.reference ?? '-'}',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textDisabled(context), fontSize: 11),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/parent/dashboard');
              },
              child: const Text('Retour au dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Paiement échoué',
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    );
  }
}
