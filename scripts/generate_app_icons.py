"""
Génère les icônes app PNG aux tailles Android + iOS depuis le logo SVG ExamBoost Togo.

Output :
- android/ : mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
  - ic_launcher.png            (carré, 48/72/96/144/192 px)
  - ic_launcher_round.png      (rond, mêmes tailles)
  - ic_launcher_foreground.png (foreground pour adaptive icons, 108/162/216/324/432 px)
- ios/ : Assets.xcassets/AppIcon.appiconset/
  - 20pt/29pt/40pt/60pt/1024px (1x, 2x, 3x)
  - Contents.json (généré automatiquement)

Prérequis : pip install cairosvg pillow

Usage :
    python scripts/generate_app_icons.py <path_to_logo.svg> [output_dir]

Exemple :
    python scripts/generate_app_icons.py assets/branding/icon_app.svg app_icons/

Auteur : Agent BA (Task BA-illustrations-icons), Session 3 Vague 3b.
"""

import argparse
import json
import sys
from pathlib import Path

# Imports CairoSVG + Pillow (dépendances déclarées dans requirements.txt)
try:
    import cairosvg
    from PIL import Image, ImageDraw
except ImportError as exc:
    print(
        "ERREUR : dépendances manquantes. Installez-les avec :\n"
        "    pip install -r scripts/requirements.txt\n",
        file=sys.stderr,
    )
    raise

# Tailles Android (mipmap-* folders)
# Standard Android : ic_launcher.png (carré), ic_launcher_round.png (rond)
# + adaptive icon foreground (108dp = 432px en xxxhdpi)
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Facteur de base pour les adaptive icons (foreground = 108dp en xxxhdpi = 432px)
ANDROID_ADAPTIVE_FACTOR = {
    "mipmap-mdpi": 1.0,    # 108px
    "mipmap-hdpi": 1.5,    # 162px
    "mipmap-xhdpi": 2.0,   # 216px
    "mipmap-xxhdpi": 3.0,  # 324px
    "mipmap-xxxhdpi": 4.0, # 432px
}

# Tailles iOS (pt, scale). Le px = pt * scale.
# Référence : https://developer.apple.com/design/human-interface-guidelines/app-icons
IOS_SIZES = [
    # Notification (20pt)
    (20, 1), (20, 2), (20, 3),
    # Settings (29pt)
    (29, 1), (29, 2), (29, 3),
    # Spotlight (40pt)
    (40, 1), (40, 2), (40, 3),
    # App icon iPhone (60pt — pas de 1x sur iPhone moderne)
    (60, 2), (60, 3),
    # App Store (1024pt — 1x, universel)
    (1024, 1),
]


def generate_android_icons(svg_path: str, output_dir: str, verbose: bool = False) -> None:
    """Génère les icônes Android (carrées + rondes + foreground adaptive)."""
    svg_path = Path(svg_path)
    output_root = Path(output_dir)

    for folder, size in ANDROID_SIZES.items():
        out_folder = output_root / folder
        out_folder.mkdir(parents=True, exist_ok=True)

        # ─── Icône carrée ──────────────────────────────────────────
        square_path = out_folder / "ic_launcher.png"
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(square_path),
            output_width=size,
            output_height=size,
        )
        if verbose:
            print(f"  [Android] {folder}/ic_launcher.png ({size}x{size})")

        # ─── Icône ronde (masque circulaire via Pillow) ────────────
        round_path = out_folder / "ic_launcher_round.png"
        img = Image.open(square_path).convert("RGBA")
        mask = Image.new("L", img.size, 0)
        draw = ImageDraw.Draw(mask)
        # ellipse plein cadre
        draw.ellipse([0, 0, img.size[0] - 1, img.size[1] - 1], fill=255)
        round_img = Image.new("RGBA", img.size, (0, 0, 0, 0))
        round_img.paste(img, (0, 0), mask)
        round_img.save(round_path)
        if verbose:
            print(f"  [Android] {folder}/ic_launcher_round.png ({size}x{size})")

        # ─── Foreground pour adaptive icons (108dp base) ───────────
        # Material 3 : ic_launcher_foreground fait 108dp total, le contenu
        # interne (logo centré) occupe ~66dp (60%). On génère à la taille
        # dpi correspondante pour avoir une version haute résolution.
        fg_size = int(108 * ANDROID_ADAPTIVE_FACTOR[folder])
        fg_path = out_folder / "ic_launcher_foreground.png"
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(fg_path),
            output_width=fg_size,
            output_height=fg_size,
        )
        if verbose:
            print(f"  [Android] {folder}/ic_launcher_foreground.png ({fg_size}x{fg_size})")

    print(f"OK : icones Android generees dans {output_root}")


def generate_ios_icons(svg_path: str, output_dir: str, verbose: bool = False) -> None:
    """Génère les icônes iOS + Contents.json."""
    svg_path = Path(svg_path)
    ios_dir = Path(output_dir) / "AppIcon.appiconset"
    ios_dir.mkdir(parents=True, exist_ok=True)

    contents = {"images": [], "info": {"version": 1, "author": "xcode"}}

    for size_pt, scale in IOS_SIZES:
        size_px = size_pt * scale
        # Nommage conventionnel Xcode
        if size_pt == 1024:
            filename = "icon_1024.png"  # App Store, nom simple
            idiom = "ios-marketing"
            scale_str = "1x"
        else:
            filename = f"icon_{size_pt}pt_{scale}x.png"
            idiom = "iphone"
            scale_str = f"{scale}x"

        output_path = ios_dir / filename
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(output_path),
            output_width=size_px,
            output_height=size_px,
        )

        contents["images"].append(
            {
                "filename": filename,
                "idiom": idiom,
                "size": f"{size_pt}x{size_pt}",
                "scale": scale_str,
            }
        )

        if verbose:
            print(f"  [iOS] {filename} ({size_px}x{size_px}) — {idiom} {scale_str}")

    # Écriture du Contents.json
    with open(ios_dir / "Contents.json", "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2, ensure_ascii=False)

    print(f"OK : icones iOS generees dans {ios_dir}")


def main() -> int:
    """Point d'entrée CLI."""
    parser = argparse.ArgumentParser(
        description="Genere les icones app PNG Android + iOS depuis un logo SVG.",
        usage="python generate_app_icons.py <logo.svg> [output_dir] [--verbose]",
    )
    parser.add_argument("svg_path", help="Chemin vers le logo SVG source.")
    parser.add_argument(
        "output_dir",
        nargs="?",
        default="app_icons",
        help="Dossier de sortie (defaut : app_icons/).",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Mode verbeux."
    )
    args = parser.parse_args()

    svg_path = Path(args.svg_path)
    if not svg_path.exists():
        print(f"ERREUR : fichier SVG introuvable : {svg_path}", file=sys.stderr)
        return 1
    if svg_path.suffix.lower() != ".svg":
        print(f"ERREUR : le fichier doit etre un SVG : {svg_path}", file=sys.stderr)
        return 1

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Generation des icones depuis : {svg_path}")
    print(f"Dossier de sortie             : {output_dir}\n")

    try:
        generate_android_icons(str(svg_path), str(output_dir / "android"), args.verbose)
        generate_ios_icons(str(svg_path), str(output_dir / "ios"), args.verbose)
    except Exception as exc:
        print(f"\nERREUR lors de la generation : {exc}", file=sys.stderr)
        return 2

    print(f"\nTermine ! Icones generees dans {output_dir}/")
    print(
        "Pour Android : copiez les dossiers mipmap-* dans "
        "android/app/src/main/res/"
    )
    print(
        "Pour iOS     : copiez AppIcon.appiconset dans "
        "ios/Runner/Assets.xcassets/"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
