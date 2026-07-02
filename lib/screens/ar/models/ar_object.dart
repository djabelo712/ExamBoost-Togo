// lib/screens/ar/models/ar_object.dart
// Modele des formes 3D visualisables en AR pour le module de geometrie.
//
// Une ARObject decrit une forme 3D (cylindre, pyramide, cone, sphere, cube,
// prisme) avec ses dimensions parametrables, ses formules de volume et de
// surface laterale/totale, et une couleur d'affichage.
//
// Les calculs (volume, surface) sont des formules mathematiques pures : ils
// servent a afficher en temps reel les proprietes de la formee manipulee par
// l'eleve. Les unites sont en cm (longueurs) et cm^2 / cm^3 (surfaces/volumes).
//
// Palette respectee : vert Togo #006837 + orange #D97700.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Types de formes 3D supportees par le module AR.
enum ARShapeType {
  cylindre,
  pyramide,
  cone,
  sphere,
  cube,
  prisme,
}

/// Extension utilitaire : libelle humain lisible pour chaque forme.
extension ARShapeTypeLabel on ARShapeType {
  String get label {
    switch (this) {
      case ARShapeType.cylindre:
        return 'Cylindre';
      case ARShapeType.pyramide:
        return 'Pyramide';
      case ARShapeType.cone:
        return 'Cône';
      case ARShapeType.sphere:
        return 'Sphère';
      case ARShapeType.cube:
        return 'Cube';
      case ARShapeType.prisme:
        return 'Prisme';
    }
  }

  /// Description courte pedagogique (rappel du cours).
  String get description {
    switch (this) {
      case ARShapeType.cylindre:
        return 'Solide à base circulaire, parois droites. '
            'Le volume dépend du rayon et de la hauteur.';
      case ARShapeType.pyramide:
        return 'Base carrée et 4 faces triangulaires se rejoignant au sommet. '
            'Volume = tiers du produit base × hauteur.';
      case ARShapeType.cone:
        return 'Base circulaire et une seule face latérale convergeant vers le sommet.';
      case ARShapeType.sphere:
        return 'Solide parfaitement rond, tous les points sont à égale distance du centre.';
      case ARShapeType.cube:
        return 'Solide à 6 faces carrées égales. Cas particulier du pavé droit.';
      case ARShapeType.prisme:
        return 'Prisme droit à base triangulaire (triangle équilatéral). '
            'Volume = aire de la base × longueur.';
    }
  }
}

/// Represente une forme 3D manipulable en AR.
///
/// Les [dimensions] sont une map parametree par le nom de la dimension
/// (ex: 'r' pour rayon, 'h' pour hauteur, 'cote' pour cube, etc.).
/// Les valeurs sont en centimetres.
class ARObject {
  final ARShapeType type;
  final String label;
  final Map<String, double> dimensions;
  final Color color;

  const ARObject({
    required this.type,
    required this.label,
    required this.dimensions,
    required this.color,
  });

  /// Cree une ARObject avec les dimensions par defaut pour le type donne.
  /// Les dimensions par defaut sont pedagogiquement choisies (entiers simples).
  factory ARObject.defaultFor(ARShapeType type) {
    switch (type) {
      case ARShapeType.cylindre:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'r': 3.0, 'h': 10.0},
          color: const Color(0xFF006837), // vert Togo
        );
      case ARShapeType.pyramide:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'cote': 6.0, 'h': 8.0},
          color: const Color(0xFFD97700), // orange Togo
        );
      case ARShapeType.cone:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'r': 4.0, 'h': 9.0},
          color: const Color(0xFF1565C0), // bleu info
        );
      case ARShapeType.sphere:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'r': 5.0},
          color: const Color(0xFF2E7D32), // vert success
        );
      case ARShapeType.cube:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'cote': 5.0},
          color: const Color(0xFFD97700), // orange Togo
        );
      case ARShapeType.prisme:
        return ARObject(
          type: type,
          label: type.label,
          dimensions: const {'cote': 4.0, 'longueur': 10.0},
          color: const Color(0xFF006837), // vert Togo
        );
    }
  }

  /// Cree une copie avec certaines dimensions modifiees.
  ARObject copyWith({Map<String, double>? dimensions, Color? color}) {
    return ARObject(
      type: type,
      label: label,
      dimensions: dimensions ?? this.dimensions,
      color: color ?? this.color,
    );
  }

  /// Volume en cm^3.
  double get volume {
    switch (type) {
      case ARShapeType.cylindre:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        return math.pi * r * r * h;
      case ARShapeType.pyramide:
        final a = dimensions['cote'] ?? 0;
        final h = dimensions['h'] ?? 0;
        return (a * a * h) / 3.0;
      case ARShapeType.cone:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        return (math.pi * r * r * h) / 3.0;
      case ARShapeType.sphere:
        final r = dimensions['r'] ?? 0;
        return (4.0 / 3.0) * math.pi * r * r * r;
      case ARShapeType.cube:
        final a = dimensions['cote'] ?? 0;
        return a * a * a;
      case ARShapeType.prisme:
        // Base triangle equilateral de cote 'cote', longueur 'longueur'.
        final a = dimensions['cote'] ?? 0;
        final l = dimensions['longueur'] ?? 0;
        final aireBase = (math.sqrt(3) / 4.0) * a * a;
        return aireBase * l;
    }
  }

  /// Surface totale (en cm^2) — somme de toutes les faces.
  double get surfaceTotale {
    switch (type) {
      case ARShapeType.cylindre:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        // 2 disques + surface laterale (2*pi*r*h)
        return 2 * math.pi * r * r + 2 * math.pi * r * h;
      case ARShapeType.pyramide:
        final a = dimensions['cote'] ?? 0;
        final h = dimensions['h'] ?? 0;
        // Base + 4 triangles isoceles (apotheme = sqrt(h^2 + (a/2)^2))
        final apotheme = math.sqrt(h * h + (a / 2) * (a / 2));
        return a * a + 4 * (a * apotheme / 2);
      case ARShapeType.cone:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        // Base + surface laterale (pi*r*generatrice)
        final generatrice = math.sqrt(r * r + h * h);
        return math.pi * r * r + math.pi * r * generatrice;
      case ARShapeType.sphere:
        final r = dimensions['r'] ?? 0;
        return 4 * math.pi * r * r;
      case ARShapeType.cube:
        final a = dimensions['cote'] ?? 0;
        return 6 * a * a;
      case ARShapeType.prisme:
        final a = dimensions['cote'] ?? 0;
        final l = dimensions['longueur'] ?? 0;
        // 2 bases (triangles equilateraux) + 3 rectangles (longueur × cote)
        final aireBase = (math.sqrt(3) / 4.0) * a * a;
        return 2 * aireBase + 3 * a * l;
    }
  }

  /// Surface laterale seule (sans les bases) — utile pour le cours.
  double get surfaceLaterale {
    switch (type) {
      case ARShapeType.cylindre:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        return 2 * math.pi * r * h;
      case ARShapeType.pyramide:
        final a = dimensions['cote'] ?? 0;
        final h = dimensions['h'] ?? 0;
        final apotheme = math.sqrt(h * h + (a / 2) * (a / 2));
        return 4 * (a * apotheme / 2);
      case ARShapeType.cone:
        final r = dimensions['r'] ?? 0;
        final h = dimensions['h'] ?? 0;
        final generatrice = math.sqrt(r * r + h * h);
        return math.pi * r * generatrice;
      case ARShapeType.sphere:
        // La sphere n'a pas de base ; surface laterale = surface totale.
        return surfaceTotale;
      case ARShapeType.cube:
        // Le cube n'a pas de distinction base/laterale ; on retourne la totale.
        return surfaceTotale;
      case ARShapeType.prisme:
        final a = dimensions['cote'] ?? 0;
        final l = dimensions['longueur'] ?? 0;
        return 3 * a * l;
    }
  }

  /// Formule du volume sous forme de string (pour affichage pedagogique).
  String get formuleVolume {
    switch (type) {
      case ARShapeType.cylindre:
        return 'V = π × r² × h';
      case ARShapeType.pyramide:
        return 'V = (a² × h) / 3';
      case ARShapeType.cone:
        return 'V = (π × r² × h) / 3';
      case ARShapeType.sphere:
        return 'V = (4/3) × π × r³';
      case ARShapeType.cube:
        return 'V = a³';
      case ARShapeType.prisme:
        return 'V = (√3/4 × a²) × L';
    }
  }

  /// Formule de la surface totale sous forme de string.
  String get formuleSurface {
    switch (type) {
      case ARShapeType.cylindre:
        return 'S = 2πr² + 2πrh';
      case ARShapeType.pyramide:
        return 'S = a² + 4 × (a × apothème / 2)';
      case ARShapeType.cone:
        return 'S = πr² + πr × g   (g = √(r²+h²))';
      case ARShapeType.sphere:
        return 'S = 4πr²';
      case ARShapeType.cube:
        return 'S = 6a²';
      case ARShapeType.prisme:
        return 'S = 2 × (√3/4 × a²) + 3 × a × L';
    }
  }

  /// Liste des dimensions avec leur symbole, valeur et unite.
  /// Sert a construire un panneau d'infos "temps reel".
  List<ARDimension> get dimensionsListees {
    switch (type) {
      case ARShapeType.cylindre:
        return [
          ARDimension('r', 'Rayon', dimensions['r'] ?? 0, 'cm'),
          ARDimension('h', 'Hauteur', dimensions['h'] ?? 0, 'cm'),
        ];
      case ARShapeType.pyramide:
        return [
          ARDimension('a', 'Côté base', dimensions['cote'] ?? 0, 'cm'),
          ARDimension('h', 'Hauteur', dimensions['h'] ?? 0, 'cm'),
        ];
      case ARShapeType.cone:
        return [
          ARDimension('r', 'Rayon', dimensions['r'] ?? 0, 'cm'),
          ARDimension('h', 'Hauteur', dimensions['h'] ?? 0, 'cm'),
        ];
      case ARShapeType.sphere:
        return [
          ARDimension('r', 'Rayon', dimensions['r'] ?? 0, 'cm'),
        ];
      case ARShapeType.cube:
        return [
          ARDimension('a', 'Côté', dimensions['cote'] ?? 0, 'cm'),
        ];
      case ARShapeType.prisme:
        return [
          ARDimension('a', 'Côté triangle', dimensions['cote'] ?? 0, 'cm'),
          ARDimension('L', 'Longueur', dimensions['longueur'] ?? 0, 'cm'),
        ];
    }
  }
}

/// Decrit une dimension nommee d'une forme (symbole, libelle, valeur, unite).
class ARDimension {
  final String symbole;
  final String libelle;
  final double valeur;
  final String unite;

  const ARDimension(this.symbole, this.libelle, this.valeur, this.unite);

  /// Valeur arrondie a 1 decimale, affichable directement.
  String get valeurFormatee {
    if (valeur == valeur.roundToDouble()) {
      return valeur.toInt().toString();
    }
    return valeur.toStringAsFixed(1);
  }
}
