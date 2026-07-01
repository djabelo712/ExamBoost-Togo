// lib/widgets/animations/typewriter_text.dart
// Texte qui se tape caractere par caractere, avec curseur clignotant.
//
// Utile pour :
//   - Messages du tuteur IA (effet " bot qui tape ")
//   - Ecrans de succes (citation motivante qui s'affiche lentement)
//   - Onboarding (presentation progressive)
//
// Utilisation :
//   TypewriterText(
//     text: 'Bonjour ! Je suis ton tuteur IA. Pose-moi ta question.',
//     speed: const Duration(milliseconds: 40),
//     style: AppTextStyles.body,
//   )
//
// Sans curseur :
//   TypewriterText(text: '...', showCursor: false)

import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  /// Texte complet a afficher progressivement.
  final String text;

  /// Vitesse de frappe (duree par caractere). Defaut 50ms.
  final Duration speed;

  /// Style du texte.
  final TextStyle? style;

  /// Afficher un curseur clignotant a la fin (defaut true).
  final bool showCursor;

  /// Caractere du curseur (defaut "|").
  final String cursorChar;

  /// Callback appele quand tout le texte a ete tape.
  final VoidCallback? onComplete;

  /// Duree d'un cycle de clignotement du curseur (defaut 500ms).
  final Duration cursorBlinkPeriod;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 50),
    this.style,
    this.showCursor = true,
    this.cursorChar = '|',
    this.onComplete,
    this.cursorBlinkPeriod = const Duration(milliseconds: 500),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late final ValueNotifier<int> _charCount;
  late final ValueNotifier<bool> _cursorVisible;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _charCount = ValueNotifier<int>(0);
    _cursorVisible = ValueNotifier<bool>(true);
    _startTyping();
    _startBlinking();
  }

  void _startTyping() async {
    for (int i = 1; i <= widget.text.length; i++) {
      await Future.delayed(widget.speed);
      if (!mounted) return;
      _currentLength = i;
      _charCount.value = i;
    }
    if (mounted) widget.onComplete?.call();
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(widget.cursorBlinkPeriod);
      if (!mounted) return;
      _cursorVisible.value = !_cursorVisible.value;
    }
  }

  @override
  void dispose() {
    _charCount.dispose();
    _cursorVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On utilise ValueListenableBuilder pour eviter un setState a chaque caractere.
    return ValueListenableBuilder<int>(
      valueListenable: _charCount,
      builder: (context, count, _) {
        final visibleText = widget.text.substring(0, count);
        if (!widget.showCursor) {
          return Text(visibleText, style: widget.style);
        }
        return ValueListenableBuilder<bool>(
          valueListenable: _cursorVisible,
          builder: (context, cursorVisible, _) {
            return RichText(
              text: TextSpan(
                text: visibleText,
                style: widget.style ?? DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: cursorVisible ? widget.cursorChar : ' ',
                    style: (widget.style ??
                            DefaultTextStyle.of(context).style)
                        .copyWith(
                      fontWeight: FontWeight.w300,
                      color: widget.style?.color ??
                          DefaultTextStyle.of(context).style.color,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
