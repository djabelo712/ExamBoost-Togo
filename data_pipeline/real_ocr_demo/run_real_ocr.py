"""Lance Tesseract OCR sur les 5 PDFs d'annales BEPC.

Étapes pour chaque PDF :
  1. Conversion PDF -> images (pdf2image, 300 dpi).
  2. Pour chaque image : OCR Tesseract (langue fra).
  3. Concaténation dans un fichier texte brut (un séparateur === PAGE N ===
     entre les pages pour faciliter le débogage visuel).
  4. Affichage des statistiques (nb pages, nb caractères, nb mots, durée).

Prérequis système :
  - Tesseract >= 5.0 avec le pack de langue fra installé.
  - poppler-utils (pdftoppm) pour pdf2image.

En sandbox sans root, le pack fra peut être absent du dossier système
/usr/share/tesseract-ocr/5/tessdata/. On gère ce cas en :
  1. Cherchant un dossier local .tessdata/ contenant fra.traineddata.
  2. Positionnant TESSDATA_PREFIX vers ce dossier pour la session Python.
Voir README.md section "Sandbox sans root" pour la procédure manuelle.

Usage :
    python run_real_ocr.py
"""

from __future__ import annotations

import json
import os
import sys
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import pytesseract
from pdf2image import convert_from_path

BASE_DIR = Path(__file__).resolve().parent
SAMPLE_PDFS_DIR = BASE_DIR / "sample_pdfs"
EXTRACTED_TEXT_DIR = BASE_DIR / "extracted_text"
FINAL_DIR = BASE_DIR / "final"

# Dossier local de données Tesseract (sandbox sans root).
LOCAL_TESSDATA = Path("/home/z/my-project/.tessdata")


@dataclass
class OcrStats:
    """Statistiques d'extraction pour un PDF."""

    pdf_name: str
    num_pages: int = 0
    num_chars: int = 0
    num_words: int = 0
    duration_sec: float = 0.0
    output_txt: str = ""
    errors: List[str] = field(default_factory=list)


def _ensure_french_language() -> None:
    """Vérifie que la langue fra est disponible pour Tesseract.

    Si la variable TESSDATA_PREFIX est déjà positionnée par l'utilisateur,
    on la respecte. Sinon, on cherche fra.traineddata dans le dossier local
    .tessdata/ (sandbox sans root) et on positionne la variable d'environnement
    pour le processus Python courant.
    """
    if "TESSDATA_PREFIX" in os.environ:
        # L'utilisateur a explicitement configuré le dossier Tesseract.
        return

    if (LOCAL_TESSDATA / "fra.traineddata").exists():
        os.environ["TESSDATA_PREFIX"] = str(LOCAL_TESSDATA)
        print(f"  TESSDATA_PREFIX positionné vers {LOCAL_TESSDATA}")
        return

    # Vérifie le dossier système standard.
    system_tessdata = Path("/usr/share/tesseract-ocr/5/tessdata")
    if not (system_tessdata / "fra.traineddata").exists():
        print("  AVERTISSEMENT : langue fra introuvable. Tesseract utilisera"
              " eng par défaut, la qualité OCR sera dégradée sur les accents.")
        print(f"  Télécharger fra.traineddata dans {LOCAL_TESSDATA}/ "
              "ou installer le paquet tesseract-ocr-fra.")


def ocr_pdf(pdf_path: Path, output_txt_path: Path,
            lang: str = "fra", dpi: int = 300) -> OcrStats:
    """Lance Tesseract sur un PDF complet.

    Args:
        pdf_path: chemin du PDF à OCR-iser.
        output_txt_path: chemin du fichier texte de sortie.
        lang: langue Tesseract (fra par défaut).
        dpi: résolution de conversion PDF -> image (300 dpi recommandé).

    Returns:
        Statistiques d'extraction (pages, caractères, mots, durée).
    """
    stats = OcrStats(pdf_name=pdf_path.name, output_txt=str(output_txt_path))
    print(f"  OCR sur {pdf_path.name}...")
    start = time.time()

    if not pdf_path.exists():
        msg = f"PDF introuvable : {pdf_path}"
        print(f"    ERREUR : {msg}")
        stats.errors.append(msg)
        return stats

    try:
        images = convert_from_path(str(pdf_path), dpi=dpi)
    except Exception as exc:  # noqa: BLE001
        msg = f"Conversion PDF -> images échouée : {exc}"
        print(f"    ERREUR : {msg}")
        stats.errors.append(msg)
        return stats

    stats.num_pages = len(images)
    print(f"    {stats.num_pages} page(s) à OCR-iser")

    full_text_parts: List[str] = []
    for idx, image in enumerate(images, start=1):
        try:
            text = pytesseract.image_to_string(image, lang=lang)
        except Exception as exc:  # noqa: BLE001
            msg = f"Page {idx} : OCR échoué ({exc})"
            print(f"    {msg}")
            stats.errors.append(msg)
            text = ""

        full_text_parts.append(f"\n\n=== PAGE {idx} ===\n\n{text}")
        print(f"    Page {idx}/{stats.num_pages} OCR-isée "
              f"({len(text)} caractères)")

    full_text = "".join(full_text_parts).strip()

    # Sauvegarde du texte.
    output_txt_path.parent.mkdir(parents=True, exist_ok=True)
    output_txt_path.write_text(full_text, encoding="utf-8")

    stats.num_chars = len(full_text)
    stats.num_words = len(full_text.split())
    stats.duration_sec = round(time.time() - start, 2)

    print(f"  OK : {stats.num_chars} caractères, {stats.num_words} mots "
          f"extraits en {stats.duration_sec}s -> {output_txt_path.name}")
    return stats


def main() -> int:
    """Lance l'OCR sur les 5 PDFs et sauve un rapport JSON global."""
    print("=== OCR Tesseract sur les 5 PDFs d'annales BEPC ===")
    print()
    _ensure_french_language()
    print()

    pdfs: List[tuple[Path, Path]] = [
        (
            SAMPLE_PDFS_DIR / "bepc_maths_2022_sample.pdf",
            EXTRACTED_TEXT_DIR / "bepc_maths_2022.txt",
        ),
        (
            SAMPLE_PDFS_DIR / "bepc_francais_2021_sample.pdf",
            EXTRACTED_TEXT_DIR / "bepc_francais_2021.txt",
        ),
        (
            SAMPLE_PDFS_DIR / "bepc_sciences_2023_sample.pdf",
            EXTRACTED_TEXT_DIR / "bepc_sciences_2023.txt",
        ),
        (
            SAMPLE_PDFS_DIR / "bepc_svt_2020_sample.pdf",
            EXTRACTED_TEXT_DIR / "bepc_svt_2020.txt",
        ),
        (
            SAMPLE_PDFS_DIR / "bepc_histoire_2022_sample.pdf",
            EXTRACTED_TEXT_DIR / "bepc_histoire_2022.txt",
        ),
    ]

    all_stats: List[OcrStats] = []
    for pdf, txt in pdfs:
        stats = ocr_pdf(pdf, txt)
        all_stats.append(stats)
        print()

    # Rapport global dans final/ocr_stats.json
    FINAL_DIR.mkdir(parents=True, exist_ok=True)
    report_path = FINAL_DIR / "ocr_stats.json"
    report = {
        "total_pdfs": len(all_stats),
        "total_pages": sum(s.num_pages for s in all_stats),
        "total_chars": sum(s.num_chars for s in all_stats),
        "total_words": sum(s.num_words for s in all_stats),
        "total_duration_sec": round(sum(s.duration_sec for s in all_stats), 2),
        "pdfs": [asdict(s) for s in all_stats],
    }
    report_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    print("=== Synthèse OCR ===")
    print(f"  PDFs traités : {report['total_pdfs']}")
    print(f"  Pages OCR-isées : {report['total_pages']}")
    print(f"  Caractères extraits : {report['total_chars']}")
    print(f"  Mots extraits : {report['total_words']}")
    print(f"  Durée totale : {report['total_duration_sec']}s")
    print(f"  Rapport JSON : {report_path.relative_to(BASE_DIR)}")
    print()
    print("OCR terminé sur les 5 PDFs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
