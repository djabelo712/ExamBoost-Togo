// lib/screens/multiplayer/widgets/room_code_display.dart
// Affiche le code d'une room en grand format, avec bouton copier et
// bouton partager.
//
// Le code est toujours composé de 6 chiffres. On l'affiche avec un
// espacement tous les 3 caractères (ex: "123 456") pour la lisibilité.
//
// Usage :
//   RoomCodeDisplay(code: '123456')
//   RoomCodeDisplay(code: room.code, onShare: () { ... })

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

class RoomCodeDisplay extends StatefulWidget {
  /// Code à 6 chiffres (sans espaces).
  final String code;

  /// Label affiché au-dessus du code (par défaut "Code de la room").
  final String label;

  /// Callback optionnel pour le bouton "Partager".
  final VoidCallback? onShare;

  /// Affiche ou non le bouton "Partager".
  final bool showShareButton;

  /// Taille de police du code (par défaut 48).
  final double codeFontSize;

  const RoomCodeDisplay({
    super.key,
    required this.code,
    this.label = 'Code de la room',
    this.onShare,
    this.showShareButton = true,
    this.codeFontSize = 48,
  });

  @override
  State<RoomCodeDisplay> createState() => _RoomCodeDisplayState();
}

class _RoomCodeDisplayState extends State<RoomCodeDisplay> {
  bool _copied = false;

  String get _formattedCode {
    // Formate "123456" -> "123 456"
    final raw = widget.code.replaceAll(RegExp(r'\s'), '');
    if (raw.length <= 3) return raw;
    return '${raw.substring(0, 3)} ${raw.substring(3)}';
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copié dans le presse-papier'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Le code en grand
            GestureDetector(
              onTap: _copyToClipboard,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  _formattedCode,
                  style: TextStyle(
                    fontSize: widget.codeFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 6,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Boutons copier / partager
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _copyToClipboard,
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _copied ? 'Copié' : 'Copier',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                if (widget.showShareButton) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.share_outlined,
                        size: 18, color: AppColors.accent),
                    label: const Text(
                      'Partager',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
