// lib/widgets/exam/exam_timer_official.dart
// Minuterie officielle avec alarmes pour le mode examen authentique.
//
// - Affichage grand format HH:MM:SS en monospace.
// - Couleur changeante :
//     * blanc   (> 30 min)
//     * jaune   (10 a 30 min)
//     * orange  (5 a 10 min)
//     * rouge clignotant (< 5 min)
// - Alarmes sonores (SystemSound.alert) aux seuils : 30 min, 10 min, 5 min,
//   1 min, et sonnerie prolongee a 0:00.
// - Vibration (HapticFeedback.heavyImpact) sur mobile aux memes seuils.
// - Auto-submit a 0:00 via callback [onTimeout].
// - Pause possible seulement en mode "Mode rapide" (canPause = true).
// - Indicateur "Temps additionnel" si AccessibilityService extraTime25 = true.
//
// NB : Pour des sons plus riches (bip personnalise, sonnerie finale), il est
// possible d'ajouter le package `audioplayers` et de brancher la callback
// [onAlert]. Voir lib/screens/simulation/README.md.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import '../../theme/app_theme.dart';

/// Niveaux d'alerte emis par la minuterie officielle.
enum TimerAlertLevel {
  /// 30 minutes restantes - premier rappel discret.
  info30,
  /// 10 minutes restantes - attention montante.
  warning10,
  /// 5 minutes restantes - urgence.
  warning5,
  /// 1 minute restante - derniere minute.
  critical1,
  /// Temps ecoule - sonnerie finale + auto-submit.
  final_,
}

/// Minuterie officielle d'examen avec affichage grand format et alarmes.
class ExamTimerOfficial extends StatefulWidget {
  const ExamTimerOfficial({
    super.key,
    required this.duration,
    required this.onTimeout,
    this.onAlert,
    this.canPause = false,
    this.compact = false,
  });

  /// Duree totale de l'examen (AVANT ajustement +25%). Le widget applique
  /// lui-meme l'ajustement via AccessibilityService.adjustDuration.
  final Duration duration;

  /// Callback appele quand le temps est ecoule (0:00).
  final VoidCallback onTimeout;

  /// Callback optionnel pour brancher un systeme de son externe
  /// (ex: audioplayers). Par defaut, le widget emet SystemSound.alert +
  /// HapticFeedback.heavyImpact().
  final void Function(TimerAlertLevel level)? onAlert;

  /// Autoriser la pause. devrait etre true seulement en mode "rapide"
  /// (pas en mode standard).
  final bool canPause;

  /// Affichage compact (AppBar) vs grand format (en-tete).
  final bool compact;

  @override
  State<ExamTimerOfficial> createState() => ExamTimerOfficialState();
}

class ExamTimerOfficialState extends State<ExamTimerOfficial>
    with SingleTickerProviderStateMixin {
  late Duration _dureeAjustee;
  late DateTime _finPrevue;
  Duration _tempsRestant = Duration.zero;
  Timer? _timer;
  bool _enPause = false;
  DateTime? _pauseDebut;

  // Animation clignotement pour < 5 min.
  late AnimationController _clignotement;
  late Animation<double> _clignotementAnim;

  // Seuils deja declenches (pour ne pas les repeter).
  final Set<TimerAlertLevel> _seuilsDeclenches = {};

  @override
  void initState() {
    super.initState();
    _dureeAjustee = AccessibilityService.adjustDuration(widget.duration);
    _finPrevue = DateTime.now().add(_dureeAjustee);
    _tempsRestant = _dureeAjustee;
    _clignotement = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _clignotementAnim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _clignotement, curve: Curves.easeInOut),
    );
    _demarrer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clignotement.dispose();
    super.dispose();
  }

  // ─── Gestion du timer ────────────────────────────────────────

  void _demarrer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _enPause) return;
      _tick();
    });
  }

  void _tick() {
    final maintenant = DateTime.now();
    final restant = _finPrevue.difference(maintenant);
    setState(() {
      _tempsRestant = restant.isNegative ? Duration.zero : restant;
    });

    // Gestion des seuils d'alerte.
    _verifierSeuils();

    // Auto-submit a 0:00.
    if (_tempsRestant == Duration.zero) {
      _timer?.cancel();
      _clignotement.stop();
      _declencherAlerte(TimerAlertLevel.final_);
      widget.onTimeout();
    }
  }

  void _verifierSeuils() {
    final minutes = _tempsRestant.inMinutes;
    final secondes = _tempsRestant.inSeconds;

    if (minutes == 30 && secondes % 60 == 0 &&
        !_seuilsDeclenches.contains(TimerAlertLevel.info30)) {
      _seuilsDeclenches.add(TimerAlertLevel.info30);
      _declencherAlerte(TimerAlertLevel.info30);
    } else if (minutes == 10 && secondes % 60 == 0 &&
        !_seuilsDeclenches.contains(TimerAlertLevel.warning10)) {
      _seuilsDeclenches.add(TimerAlertLevel.warning10);
      _declencherAlerte(TimerAlertLevel.warning10);
    } else if (minutes == 5 && secondes % 60 == 0 &&
        !_seuilsDeclenches.contains(TimerAlertLevel.warning5)) {
      _seuilsDeclenches.add(TimerAlertLevel.warning5);
      _declencherAlerte(TimerAlertLevel.warning5);
      _clignotement.repeat(reverse: true);
    } else if (minutes == 0 && secondes == 60 &&
        !_seuilsDeclenches.contains(TimerAlertLevel.critical1)) {
      _seuilsDeclenches.add(TimerAlertLevel.critical1);
      _declencherAlerte(TimerAlertLevel.critical1);
    }
  }

  void _declencherAlerte(TimerAlertLevel level) {
    // Vibration (si activee dans les preferences).
    if (AccessibilityService.settings.vibrationAlerts) {
      switch (level) {
        case TimerAlertLevel.info30:
          HapticFeedback.lightImpact();
          break;
        case TimerAlertLevel.warning10:
          HapticFeedback.mediumImpact();
          break;
        case TimerAlertLevel.warning5:
        case TimerAlertLevel.critical1:
          HapticFeedback.heavyImpact();
          break;
        case TimerAlertLevel.final_:
          // Triple vibration pour la sonnerie finale.
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) HapticFeedback.heavyImpact();
          });
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) HapticFeedback.heavyImpact();
          });
          break;
      }
    }

    // Son systeme (toujours disponible, pas de package externe).
    // Pour un son plus riche, brancher onAlert avec audioplayers.
    switch (level) {
      case TimerAlertLevel.info30:
      case TimerAlertLevel.warning10:
      case TimerAlertLevel.warning5:
      case TimerAlertLevel.critical1:
        SystemSound.play(SystemSoundType.alert);
        break;
      case TimerAlertLevel.final_:
        // Sonnerie prolongee : 3 bips espaces de 400ms.
        SystemSound.play(SystemSoundType.alert);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) SystemSound.play(SystemSoundType.alert);
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) SystemSound.play(SystemSoundType.alert);
        });
        break;
    }

    // Callback externe (pour brancher audioplayers, etc.).
    widget.onAlert?.call(level);
  }

  // ─── API publique ────────────────────────────────────────────

  /// Met en pause si autorise. Retourne true si la pause a ete effectuee.
  bool pause() {
    if (!widget.canPause || _enPause) return false;
    setState(() {
      _enPause = true;
      _pauseDebut = DateTime.now();
      _timer?.cancel();
    });
    return true;
  }

  /// Reprend apres une pause. Recalcule la fin prevue pour ne pas perdre
  /// le temps de pause.
  void resume() {
    if (!_enPause) return;
    final dureePause = DateTime.now().difference(_pauseDebut!);
    setState(() {
      _enPause = false;
      _pauseDebut = null;
      _finPrevue = _finPrevue.add(dureePause);
    });
    _demarrer();
  }

  void basculerPause() {
    if (_enPause) {
      resume();
    } else {
      pause();
    }
  }

  /// Renvoie le temps restant actuel.
  Duration get tempsRestant => _tempsRestant;

  /// True si la minuterie est en pause.
  bool get enPause => _enPause;

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurPourTemps(_tempsRestant);
    final clignote = _tempsRestant.inMinutes < 5 && _tempsRestant != Duration.zero;

    final contenu = AnimatedBuilder(
      animation: _clignotement,
      builder: (ctx, child) {
        final opacite = clignote ? _clignotementAnim.value : 1.0;
        return Opacity(opacity: opacite, child: child);
      },
      child: widget.compact
          ? _buildCompact(couleur)
          : _buildGrandFormat(couleur),
    );

    return contenu;
  }

  Widget _buildCompact(Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _enPause ? Icons.pause_circle : Icons.timer_outlined,
            size: 16,
            color: couleur,
          ),
          const SizedBox(width: 6),
          Text(
            _formater(_tempsRestant),
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: couleur,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (AccessibilityService.settings.extraTime25) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '+25%',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrandFormat(Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _enPause ? Icons.pause_circle : Icons.timer,
                size: 22,
                color: couleur,
              ),
              const SizedBox(width: 8),
              Text(
                'Temps restant',
                style: AppTextStyles.bodySmall.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (AccessibilityService.settings.extraTime25) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Temps additionnel +25%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formater(_tempsRestant),
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: couleur,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 2,
            ),
          ),
          if (widget.canPause)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: basculerPause,
                icon: Icon(_enPause ? Icons.play_arrow : Icons.pause, size: 16),
                label: Text(_enPause ? 'Reprendre' : 'Pause'),
                style: TextButton.styleFrom(
                  foregroundColor: couleur,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Color _couleurPourTemps(Duration d) {
    if (d == Duration.zero) return AppColors.error;
    final minutes = d.inMinutes;
    if (minutes > 30) return Colors.white; //Sur fond fonce. Sinon primary.
    if (minutes > 10) return const Color(0xFFFBC02D); // jaune
    if (minutes > 5) return AppColors.accent; // orange
    return AppColors.error; // rouge
  }

  String _formater(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
