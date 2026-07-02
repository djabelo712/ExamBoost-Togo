// lib/screens/ar/ar_viewer_screen.dart
// Ecran principal du module AR Geometrie.
//
// Combine :
//   - [ArObjectSelector] (en haut) pour choisir la forme.
//   - [ArCameraView] (au centre, expansé) avec la forme 3D manipulable.
//   - [ArInfoPanel] (en bas) avec volume, surface et dimensions editables.
//   - Boutons d'action (réinitialiser, capturer photo, auto-rotation).
//
// L'ecran initialise le [ArService] via [ArServiceFactory.create()] et
// s'abonne a son etat. En mode simule (par defaut), la session passe
// directement a `ready`. En mode AR natif (futur), elle attendrait la camera.
//
// La capture photo utilise [RepaintBoundary.toImage] puis sauvegarde un PNG
// dans le dossier documents de l'app (via path_provider).

import 'dart:io' show File;
import 'dart:ui' as ui show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart';

import 'models/ar_object.dart';
import 'services/ar_service.dart';
import 'widgets/ar_camera_view.dart';
import 'widgets/ar_info_panel.dart';
import 'ar_object_selector.dart';
import 'ar_instructions_sheet.dart';

/// Ecran principal du module AR Geometrie.
///
/// Pour le brancher dans le router, ajouter (cote agent wiring) :
/// ```dart
/// import '../screens/ar/ar_viewer_screen.dart';
/// // ...
/// GoRoute(
///   path: '/ar-geometrie',
///   builder: (context, state) => const ArViewerScreen(),
/// ),
/// ```
class ArViewerScreen extends StatefulWidget {
  /// Forme initialement selectionnee (par defaut : cylindre).
  final ARShapeType initialShape;

  const ArViewerScreen({super.key, this.initialShape = ARShapeType.cylindre});

  @override
  State<ArViewerScreen> createState() => _ArViewerScreenState();
}

class _ArViewerScreenState extends State<ArViewerScreen> {
  late final ArService _arService;
  late ARObject _currentObject;
  bool _autoRotate = true;
  bool _panelExpanded = true;
  bool _isCapturing = false;
  ArSessionState _sessionState = ArSessionState.idle;
  int _resetSignal = 0; // incremente a chaque appui sur "Reset"

  // Cle du RepaintBoundary pour la capture photo.
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentObject = ARObject.defaultFor(widget.initialShape);
    _arService = ArServiceFactory.create();
    _arService.stateStream.listen(_onSessionStateChanged);
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await _arService.requestPermissions();
    await _arService.initialize();
  }

  void _onSessionStateChanged(ArSessionState state) {
    if (!mounted) return;
    setState(() => _sessionState = state);
  }

  @override
  void dispose() {
    _arService.dispose();
    super.dispose();
  }

  void _selectShape(ARShapeType type) {
    setState(() {
      _currentObject = ARObject.defaultFor(type);
    });
  }

  void _updateDimensions(Map<String, double> newDims) {
    setState(() {
      _currentObject = _currentObject.copyWith(dimensions: newDims);
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFC62828) : null,
        duration: isError ? const Duration(seconds: 4) : const Duration(seconds: 2),
      ),
    );
  }

  /// Capture la vue courante (camera + overlay 3D) en PNG et sauvegarde
  /// dans le dossier documents de l'app.
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showMessage('Capture impossible : vue non disponible', isError: true);
        return;
      }
      // pixelRatio 2.0 : bon compromis qualité / taille.
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showMessage('Conversion PNG impossible', isError: true);
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ar_geometrie_${_currentObject.type.label}_$timestamp.png';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      _showMessage('Photo sauvegardée : ${file.path}');
    } catch (e) {
      _showMessage('Erreur capture : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  /// Bascule l'expand/reduction du panneau d'infos.
  void _togglePanel() {
    setState(() => _panelExpanded = !_panelExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('AR Géométrie'),
        backgroundColor: const Color(0xFF006837),
        foregroundColor: Colors.white,
        actions: [
          // Indicateur d'etat de session (mode simule / AR native).
          _SessionStateIndicator(
            state: _sessionState,
            isSimulated: _arService.isSimulated,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Mode d\'emploi',
            onPressed: () => ArInstructionsSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Selecteur de forme (en haut, scroll horizontal).
          Container(
            color: colorScheme.surface,
            child: ArObjectSelector(
              selected: _currentObject.type,
              onSelected: _selectShape,
            ),
          ),

          // 2. Vue camera + overlay 3D (zone principale).
          Expanded(
            child: Stack(
              children: [
                // La vue elle-meme (avec RepaintBoundary pour capture).
                ArCameraView(
                  object: _currentObject,
                  repaintBoundaryKey: _repaintBoundaryKey,
                  autoRotate: _autoRotate,
                  resetSignal: _resetSignal,
                  onInteractionStart: () {
                    // Optionnel : masquer les instructions si affichees.
                  },
                ),

                // Boutons d'action flottants (a droite).
                Positioned(
                  right: 12,
                  top: 12,
                  child: _ActionButtonsColumn(
                    autoRotate: _autoRotate,
                    onToggleAutoRotate: () =>
                        setState(() => _autoRotate = !_autoRotate),
                    onReset: () {
                      setState(() {
                        _resetSignal++;
                      });
                      _showMessage('Vue réinitialisée');
                    },
                    onCapture: _capturePhoto,
                    isCapturing: _isCapturing,
                  ),
                ),

                // Badge "forme courante" (en haut a gauche).
                Positioned(
                  left: 12,
                  top: 12,
                  child: _CurrentShapeBadge(object: _currentObject),
                ),
              ],
            ),
          ),

          // 3. Panneau d'infos (en bas, collapsible).
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: _panelExpanded
                ? ArInfoPanel(
                    object: _currentObject,
                    onDimensionsChanged: _updateDimensions,
                  )
                : _CollapsedPanelBar(
                    object: _currentObject,
                    onExpand: _togglePanel,
                  ),
          ),
        ],
      ),
      // FAB secondaire pour toggle du panneau (en bas a droite).
      floatingActionButton: _panelExpanded
          ? FloatingActionButton.small(
              heroTag: 'ar-toggle-panel',
              onPressed: _togglePanel,
              tooltip: 'Réduire le panneau',
              backgroundColor: Colors.white,
              child: const Icon(Icons.keyboard_arrow_down),
            )
          : null,
    );
  }
}

// ─── Sous-widgets prives ────────────────────────────────────────────────────

/// Indicateur discret de l'etat de session AR (idle / initializing / ready /
/// error) et du mode (simule ou natif).
class _SessionStateIndicator extends StatelessWidget {
  final ArSessionState state;
  final bool isSimulated;

  const _SessionStateIndicator({
    required this.state,
    required this.isSimulated,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      ArSessionState.idle => (Colors.grey, 'En attente'),
      ArSessionState.initializing => (Colors.amber, 'Init...'),
      ArSessionState.ready =>
        isSimulated
            ? (Colors.lightBlueAccent, '3D simulée')
            : (Colors.greenAccent, 'AR native'),
      ArSessionState.permissionDenied => (Colors.redAccent, 'Refusé'),
      ArSessionState.error => (Colors.redAccent, 'Erreur'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white.withAlpha(30),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Colonne de boutons d'action flottants (reset, capture, auto-rotate).
class _ActionButtonsColumn extends StatelessWidget {
  final bool autoRotate;
  final VoidCallback onToggleAutoRotate;
  final VoidCallback onReset;
  final VoidCallback onCapture;
  final bool isCapturing;

  const _ActionButtonsColumn({
    required this.autoRotate,
    required this.onToggleAutoRotate,
    required this.onReset,
    required this.onCapture,
    required this.isCapturing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: autoRotate ? Icons.sync : Icons.sync_disabled,
          label: autoRotate ? 'Auto-rotation ON' : 'Auto-rotation OFF',
          color: autoRotate
              ? const Color(0xFF006837)
              : Colors.grey,
          onPressed: onToggleAutoRotate,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.refresh,
          label: 'Réinitialiser',
          color: const Color(0xFF1565C0),
          onPressed: onReset,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: isCapturing ? Icons.hourglass_top : Icons.photo_camera_outlined,
          label: isCapturing ? 'Capture...' : 'Photo',
          color: const Color(0xFFD97700),
          onPressed: isCapturing ? null : onCapture,
        ),
      ],
    );
  }
}

/// Bouton d'action rond (style mini-FAB).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: onPressed == null ? Colors.grey.withAlpha(120) : color,
        borderRadius: BorderRadius.circular(28),
        elevation: 4,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Badge affichant le nom de la forme courante (en haut a gauche de la vue).
class _CurrentShapeBadge extends StatelessWidget {
  final ARObject object;

  const _CurrentShapeBadge({required this.object});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: object.color.withAlpha(180), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: object.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            object.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre minimale du panneau d'infos (quand replie).
class _CollapsedPanelBar extends StatelessWidget {
  final ARObject object;
  final VoidCallback onExpand;

  const _CollapsedPanelBar({
    required this.object,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onExpand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.keyboard_arrow_up,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${object.label} — V = ${_formatVolume(object.volume)}  |  '
                  'S = ${_formatSurface(object.surfaceTotale)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)} dm³';
    if (v == v.roundToDouble()) return '${v.toInt()} cm³';
    return '${v.toStringAsFixed(1)} cm³';
  }

  String _formatSurface(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(2)} dm²';
    if (v == v.roundToDouble()) return '${v.toInt()} cm²';
    return '${v.toStringAsFixed(1)} cm²';
  }
}
