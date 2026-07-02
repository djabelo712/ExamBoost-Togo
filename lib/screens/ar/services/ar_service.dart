// lib/screens/ar/services/ar_service.dart
// Service AR pour le module de geometrie 3D.
//
// Rôle :
//   - Detecter si l'appareil supporte l'AR (ARCore sur Android 8+, ARKit sur
//     iOS 12+).
//   - Initialiser / fermer une session AR (camera + scene 3D).
//   - Demander les permissions camera.
//   - Capturer une photo (camera + overlay 3D) — screenshot.
//
// Implementation actuelle :
//   - [SimulatedArService] — vue 3D interactive SANS camera reelle. Tous les
//     manipulations (rotation, scale, translation) sont gerees par le widget
//     [ArObjectOverlay]. Ce mode fonctionne partout (mobile, desktop, web) et
//     ne necessite aucun plugin AR.
//
// Implementation future (lorsque `ar_flutter_plugin` sera ajoute au pubspec) :
//   - [NativeArService] — vraie AR via ARCore/ARKit. Voir README.md pour le
//     wiring complet (imports conditionnels, plateformes supportees, etc.).
//
// Le pattern "factory + interface abstraite" permet de permuter l'implementation
// sans modifier les ecrans/widgets qui consomment le service.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/ar_object.dart';

/// Etat courant d'une session AR.
enum ArSessionState {
  /// Session non encore demarree.
  idle,

  /// Initialisation en cours (ouverture camera, detection ARCore/ARKit).
  initializing,

  /// Session prete, l'utilisateur peut manipuler des formes 3D.
  ready,

  /// Permission camera refusee ou AR non disponible sur l'appareil.
  permissionDenied,

  /// Erreur pendant l'initialisation (ARCore non installe, etc.).
  error,
}

/// Resultat d'une capture photo AR.
class ArCaptureResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  const ArCaptureResult({
    required this.success,
    this.filePath,
    this.errorMessage,
  });
}

/// Contrat du service AR.
///
/// Les implementations concrètes :
///   - [SimulatedArService] — fallback universel (mobile/desktop/web).
///   - [NativeArService] — a brancher lorsque ar_flutter_plugin est disponible.
abstract class ArService {
  /// Vrai si l'AR native (ARCore/ARKit) est supportee sur cet appareil.
  /// En mode simule, retourne toujours false.
  bool get isNativeSupported;

  /// Vrai si on est en mode simulation (fallback).
  /// reciprocal de [isNativeSupported] (sauf si on veut differencier
  /// "non-supporte" de "mode simulation force").
  bool get isSimulated => !isNativeSupported;

  /// Etat courant de la session AR.
  ArSessionState get state;

  /// Stream des changements d'etat (pour rebuild UI reactif).
  Stream<ArSessionState> get stateStream;

  /// Initialise la session AR.
  /// - En mode natif : ouvre la camera, attend ARCore/ARKit ready.
  /// - En mode simule : no-op, passe directement a l'etat `ready`.
  Future<void> initialize();

  /// Demande les permissions necessaires (camera).
  /// Retourne true si accordees (ou deja accordees).
  Future<bool> requestPermissions();

  /// Place un objet 3D dans la scene AR.
  /// - En mode natif : ancre l'objet a une position detectee.
  /// - En mode simule : no-op, l'objet est affiche par [ArObjectOverlay].
  Future<void> placeObject(ARObject object);

  /// Retire tous les objets 3D de la scene.
  Future<void> clearScene();

  /// Capture une photo (camera + overlay 3D) et l'enregistre sur le disque.
  /// Retourne le chemin du fichier en cas de succes.
  ///
  /// En mode simule : capture uniquement le rendu 3D (RepaintBoundary -> PNG).
  /// En mode natif : capture le frame AR complet (camera + objets 3D).
  Future<ArCaptureResult> captureScreenshot({
    required GlobalKey repaintBoundaryKey,
  });

  /// Libere les ressources (camera, session AR, etc.).
  void dispose();
}

// ─── Implementation : mode simule (fallback universel) ──────────────────────

/// Service AR simule — fonctionne sans aucun plugin AR.
///
/// Toute la manipulation 3D est geree par le widget [ArObjectOverlay] via
/// Transform + Matrix4 + GestureDetector. Le service ne fait que tenir l'etat
/// (idle/ready) et exposer une API compatible avec le mode natif.
class SimulatedArService implements ArService {
  final StreamController<ArSessionState> _stateController =
      StreamController<ArSessionState>.broadcast();

  ArSessionState _state = ArSessionState.idle;

  @override
  bool get isNativeSupported => false;

  @override
  ArSessionState get state => _state;

  @override
  Stream<ArSessionState> get stateStream => _stateController.stream;

  void _setState(ArSessionState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> initialize() async {
    _setState(ArSessionState.initializing);
    // En mode simule, rien a initialiser. On simule un petit delai pour
    // que l'UI affiche l'etat "initializing" de maniere visible (UX).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _setState(ArSessionState.ready);
  }

  @override
  Future<bool> requestPermissions() async {
    // Mode simule : aucune permission requise.
    return true;
  }

  @override
  Future<void> placeObject(ARObject object) async {
    // No-op : l'overlay widget gere l'affichage 3D.
  }

  @override
  Future<void> clearScene() async {
    // No-op.
  }

  @override
  Future<ArCaptureResult> captureScreenshot({
    required GlobalKey repaintBoundaryKey,
  }) async {
    // En mode simule, la capture effective (RepaintBoundary.toImage ->
    // PNG -> fichier) est realisee par l'ecran parent, qui dispose du
    // contexte necessaire (import dart:ui, path_provider).
    // Ce service signale juste que la capture est "supportee" ; l'ecran
    // fait le vrai travail.
    //
    // En mode AR natif (futur NativeArService), cette methode utiliserait
    // le plugin AR pour capturer le frame camera + overlay 3D natif.
    if (repaintBoundaryKey.currentContext == null) {
      return const ArCaptureResult(
        success: false,
        errorMessage: 'Boundary de capture introuvable (widget non monte).',
      );
    }
    return const ArCaptureResult(success: true, filePath: null);
  }

  @override
  void dispose() {
    _stateController.close();
  }
}

// ─── Factory : choisit l'implementation selon la plateforme ─────────────────

/// Factory centralise : retourne l'implementation ArService adaptee.
///
/// Logique :
///   - Web / desktop -> [SimulatedArService] (AR non supportee).
///   - Android < 8.0 / iOS < 12.0 -> [SimulatedArService] (ARCore/ARKit absent).
///   - Android >= 8.0 / iOS >= 12.0 -> [SimulatedArService] tant que
///     `ar_flutter_plugin` n'est pas ajoute au pubspec.yaml.
///     Une fois ajoute, remplacer le return par [NativeArService].
///
/// Voir README.md pour le branchement de [NativeArService].
class ArServiceFactory {
  ArServiceFactory._(); // constructeur prive — usage statique uniquement.

  /// Cree l'instance ArService pour le runtime courant.
  static ArService create() {
    // Le mode natif n'est pas encore branche (ar_flutter_plugin absent du
    // pubspec.yaml). On retourne donc toujours le service simule, qui
    // fonctionne sur toutes les plateformes.
    //
    // Quand ar_flutter_plugin sera ajoute, decommenter le bloc conditionnel
    // ci-dessous et implementer NativeArService.
    //
    // if (_isArNativeSupported) {
    //   return NativeArService();
    // }
    return SimulatedArService();
  }

  /// Vrai si l'AR native est theoriquement supportee sur le runtime courant.
  /// Detection basee sur plateforme + version OS.
  static bool get _isArNativeSupported {
    if (kIsWeb) return false;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // ARCore requiert Android 7.0 (API 24) minimum, mais en pratique
        // Android 8.0 (API 26) pour une experience stable.
        final sdk = Platform.operatingSystemVersion;
        return _androidSdkInt(sdk) >= 26;
      }
      if (!kIsWeb && Platform.isIOS) {
        // ARKit requiert iOS 11.0 minimum, mais iOS 12.0+ recommande.
        final version = Platform.operatingSystemVersion;
        return _iosMajorVersion(version) >= 12;
      }
    } catch (_) {
      // En cas d'echec de detection (desktop, etc.), on consider que non.
      return false;
    }
    return false;
  }

  /// Extrait le SDK int d'une chaine comme "Android 13 (API 33, ...)".
  /// Retourne 0 si l'extraction echoue (fallback conservateur).
  static int _androidSdkInt(String versionString) {
    final match = RegExp(r'API (\d+)').firstMatch(versionString);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    // Fallback : extraire le numero de version majeur (ex: "Android 8.0.0").
    final majorMatch = RegExp(r'Android (\d+)').firstMatch(versionString);
    if (majorMatch != null) {
      final major = int.tryParse(majorMatch.group(1) ?? '0') ?? 0;
      // Approximation : Android 8 ~ API 26.
      if (major >= 8) return 26;
      return 0;
    }
    return 0;
  }

  /// Extrait la version majeure d'une chaine comme "Version 14.5 (Build...)".
  static int _iosMajorVersion(String versionString) {
    final match = RegExp(r'Version (\d+)').firstMatch(versionString);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }
}

// =============================================================================
// NOTE POUR L'AGENT WIRING — branchement de NativeArService (futur)
// =============================================================================
//
// 1. Ajouter au pubspec.yaml :
//
//    dependencies:
//      # AR native (Android 8+ / iOS 12+) — optionnel, fallback simulé sinon.
//      ar_flutter_plugin: ^0.7.3
//      # ou, alternative iOS-only :
//      # arkit_plugin: ^1.1.0
//
// 2. Creer lib/screens/ar/services/ar_native_service.dart implementant
//    [ArService] avec ar_flutter_plugin (ARSessionManager, ARObjectManager,
//    ARAnchorManager). Voir README.md pour le squelette.
//
// 3. Dans [ArServiceFactory.create], decommenter le bloc :
//        if (_isArNativeSupported) {
//          return NativeArService();
//        }
//        return SimulatedArService();
//
// 4. Ajouter les permissions :
//    - Android (AndroidManifest.xml) :
//        <uses-permission android:name="android.permission.CAMERA" />
//        <uses-feature android:name="android.hardware.camera.ar" />
//        <meta-data android:name="com.google.ar.core" android:value="optional" />
//    - iOS (Info.plist) :
//        <key>NSCameraUsageDescription</key>
//        <string>Camera requise pour visualiser les formes 3D en AR.</string>
//
// 5. Aucun changement dans les widgets : ils consomment l'interface [ArService]
//    et restent compatibles avec les deux implementations.
// =============================================================================
