// lib/screens/tutor/widgets/message_bubble.dart
// Bulle de message du tuteur IA — rendu markdown léger sans dépendance externe.
//
// Gère :
//   - Gras (**texte**), italique (*texte*), code inline (`code`)
//   - Blocs de code (```...```) avec fond sombre + police monospace
//   - Listes à puces (- item) et numérotées (1. item)
//   - Titres (#, ##, ###)
//   - Paragraphes (concaténation des lignes consécutives)
//
// Pour activer la coloration syntaxique complète, voir README.md
// (intégration optionnelle de flutter_highlight).
//
// Bulles :
//   - User : à droite, fond AppColors.primary, texte blanc
//   - Assistant : à gauche, fond AppColors.surfaceVariant, texte noir
//   - Erreur : à gauche, fond rouge translucide + bordure, bouton "Réessayer"

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    final bubbleColor = isError
        ? AppColors.error.withOpacity(0.10)
        : isUser
            ? AppColors.primary
            : AppColors.surfaceVariant;
    final textColor = isError
        ? AppColors.error
        : isUser
            ? Colors.white
            : AppColors.textPrimary;
    final timeColor = isError
        ? AppColors.error.withOpacity(0.75)
        : isUser
            ? Colors.white.withOpacity(0.85)
            : AppColors.textSecondary;

    final time = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isError),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isError
                        ? Border.all(color: AppColors.error.withOpacity(0.3))
                        : null,
                  ),
                  child: _MessageContent(
                    content: message.content,
                    textColor: textColor,
                    isUser: isUser,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(fontSize: 11, color: timeColor),
                      ),
                      if (isError && onRetry != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onRetry,
                          child: Text(
                            'Réessayer',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isError),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isError) {
    if (isError) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.error.withOpacity(0.15),
        child: const Icon(Icons.error_outline, color: AppColors.error, size: 16),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          isUser ? AppColors.primaryDark : AppColors.primarySurface,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: isUser ? Colors.white : AppColors.primary,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Rendu du contenu (markdown léger)
// ════════════════════════════════════════════════════════════════════
class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.content,
    required this.textColor,
    required this.isUser,
  });

  final String content;
  final Color textColor;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final blocks = _MarkdownParser.parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => b.toWidget(textColor, isUser)).toList(),
    );
  }
}

// ─── Hiérarchie de blocs markdown ────────────────────────────────────
abstract class _Block {
  Widget toWidget(Color textColor, bool isUser);
}

class _ParagraphBlock extends _Block {
  _ParagraphBlock(this.text);
  final String text;

  @override
  Widget toWidget(Color textColor, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _InlineRichText(text: text, color: textColor),
    );
  }
}

class _CodeBlock extends _Block {
  _CodeBlock(this.code, {this.language});
  final String code;
  final String? language;

  @override
  Widget toWidget(Color textColor, bool isUser) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            isUser ? Colors.black.withOpacity(0.30) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null && language!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language!,
                style: TextStyle(
                  fontSize: 11,
                  color: (isUser ? Colors.white70 : const Color(0xFF888888)),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          SelectableText(
            code.trim(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: isUser ? Colors.white : const Color(0xFFE0E0E0),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItemBlock extends _Block {
  _ListItemBlock(this.text, {required this.ordered, required this.index});
  final String text;
  final bool ordered;
  final int index;

  @override
  Widget toWidget(Color textColor, bool isUser) {
    final bullet = ordered ? '$index. ' : '• ';
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bullet,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: _InlineRichText(text: text, color: textColor)),
        ],
      ),
    );
  }
}

class _HeadingBlock extends _Block {
  _HeadingBlock(this.text, {required this.level});
  final String text;
  final int level;

  @override
  Widget toWidget(Color textColor, bool isUser) {
    final size = level == 1 ? 19.0 : (level == 2 ? 17.0 : 15.5);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

// ─── Rendu inline (gras / italique / code) ───────────────────────────
class _InlineRichText extends StatelessWidget {
  const _InlineRichText({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: color, fontSize: 14.5, height: 1.45),
        children: _parseInline(text, color),
      ),
    );
  }

  /// Parse **bold**, *italic*, `code inline` et renvoie les TextSpan.
  List<InlineSpan> _parseInline(String src, Color base) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    var pos = 0;
    for (final match in regex.allMatches(src)) {
      if (match.start > pos) {
        spans.add(TextSpan(text: src.substring(pos, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            backgroundColor: base == Colors.white
                ? Colors.black.withOpacity(0.10)
                : Colors.white.withOpacity(0.18),
          ),
        ));
      }
      pos = match.end;
    }
    if (pos < src.length) {
      spans.add(TextSpan(text: src.substring(pos)));
    }
    return spans;
  }
}

// ─── Parser bloc (découpe le texte en blocs) ────────────────────────
class _MarkdownParser {
  static List<_Block> parse(String src) {
    final lines = src.split('\n');
    final blocks = <_Block>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.trimLeft().startsWith('```')) {
        final language = line.trimLeft().substring(3).trim();
        final buf = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          buf.add(lines[i]);
          i++;
        }
        blocks.add(_CodeBlock(
          buf.join('\n'),
          language: language.isEmpty ? null : language,
        ));
        i++; // skip closing ```
        continue;
      }

      // Heading
      final hMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line.trimLeft());
      if (hMatch != null) {
        final level = hMatch.group(1)!.length;
        blocks.add(_HeadingBlock(hMatch.group(2)!, level: level));
        i++;
        continue;
      }

      // Ordered list
      final olMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line.trimLeft());
      if (olMatch != null) {
        final idx = int.tryParse(olMatch.group(1)!) ?? 1;
        blocks.add(_ListItemBlock(olMatch.group(2)!,
            ordered: true, index: idx));
        i++;
        continue;
      }

      // Unordered list
      final ulMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line.trimLeft());
      if (ulMatch != null) {
        blocks.add(_ListItemBlock(ulMatch.group(1)!,
            ordered: false, index: 0));
        i++;
        continue;
      }

      // Ligne vide -> séparateur
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Paragraphe : on concatène les lignes consécutives non-spéciales
      final buf = <String>[line];
      i++;
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !lines[i].trimLeft().startsWith('```') &&
          !RegExp(r'^(#{1,3})\s+').hasMatch(lines[i].trimLeft()) &&
          !RegExp(r'^(\d+)\.\s+').hasMatch(lines[i].trimLeft()) &&
          !RegExp(r'^[-*]\s+').hasMatch(lines[i].trimLeft())) {
        buf.add(lines[i]);
        i++;
      }
      blocks.add(_ParagraphBlock(buf.join(' ')));
    }
    return blocks;
  }
}
