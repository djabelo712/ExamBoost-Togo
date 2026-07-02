"""Génère 5 PDFs d'annales BEPC simulés pour démontrer le pipeline OCR.

Pour chaque PDF :
  - En-tête officielle République Togolaise (Devise + Ministère + examen).
  - 5 à 8 questions BEPC authentiques (alignées sur le programme MEPST).
  - Mise en page A4 sobre : police serif (Times), marges 2,5 cm.

Les questions sont écrites en texte vectoriel (et non en image scannée) pour
garantir un rendu net. Tesseract pourra ainsi atteindre une précision > 95 %,
ce qui démontre le pipeline dans des conditions idéales. Sur de vrais PDFs
scannés (qualité variable), la précision tombe à 80-90 % — d'où l'intérêt du
fallback GPT-4o Vision dans le pipeline principal `ocr_extract.py`.

Sortie : 5 fichiers PDF dans `sample_pdfs/`.
"""

from __future__ import annotations

from pathlib import Path
from typing import List

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
)

# ─── Constantes de mise en page ───────────────────────────────────────────

BASE_DIR = Path(__file__).resolve().parent
SAMPLE_PDFS_DIR = BASE_DIR / "sample_pdfs"


def _make_styles() -> dict:
    """Construit les styles ReportLab cohérents pour tous les PDFs."""
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "BepcTitle",
            parent=base["Title"],
            fontName="Times-Bold",
            fontSize=14,
            alignment=TA_CENTER,
            spaceAfter=10,
            textColor=colors.black,
        ),
        "subtitle": ParagraphStyle(
            "BepcSubtitle",
            parent=base["Normal"],
            fontName="Times-Bold",
            fontSize=11,
            alignment=TA_CENTER,
            spaceAfter=4,
        ),
        "header": ParagraphStyle(
            "BepcHeader",
            parent=base["Normal"],
            fontName="Times-Roman",
            fontSize=10,
            alignment=TA_CENTER,
            spaceAfter=3,
        ),
        "devise": ParagraphStyle(
            "BepcDevise",
            parent=base["Normal"],
            fontName="Times-Italic",
            fontSize=10,
            alignment=TA_CENTER,
            spaceAfter=4,
        ),
        "meta": ParagraphStyle(
            "BepcMeta",
            parent=base["Normal"],
            fontName="Times-Italic",
            fontSize=10,
            alignment=TA_CENTER,
            spaceAfter=2,
        ),
        "exercise_title": ParagraphStyle(
            "ExerciseTitle",
            parent=base["Normal"],
            fontName="Times-Bold",
            fontSize=11,
            alignment=TA_LEFT,
            spaceBefore=10,
            spaceAfter=6,
        ),
        "question": ParagraphStyle(
            "Question",
            parent=base["Normal"],
            fontName="Times-Roman",
            fontSize=11,
            alignment=TA_LEFT,
            spaceAfter=8,
            leftIndent=15,
            leading=14,
        ),
        "intro": ParagraphStyle(
            "Intro",
            parent=base["Normal"],
            fontName="Times-Roman",
            fontSize=11,
            alignment=TA_LEFT,
            spaceAfter=6,
            leading=14,
        ),
    }


def _build_header(story: List, styles: dict, matiere: str, session: int,
                  duree: str, coefficient: int) -> None:
    """Ajoute l'en-tête officielle commune à tous les PDFs d'annales."""
    story.append(Paragraph("RÉPUBLIQUE TOGOLAISE", styles["header"]))
    story.append(Paragraph("Travail - Liberté - Patrie", styles["devise"]))
    story.append(Spacer(1, 8))
    story.append(Paragraph("MINISTÈRE DE L'ENSEIGNEMENT SECONDAIRE", styles["header"]))
    story.append(Paragraph("Direction des Examens et Concours", styles["header"]))
    story.append(Spacer(1, 15))
    story.append(Paragraph("BREVET D'ÉTUDES DU PREMIER CYCLE (BEPC)", styles["title"]))
    story.append(Spacer(1, 6))
    story.append(Paragraph(f"Épreuve : {matiere}", styles["subtitle"]))
    story.append(Paragraph(f"Session : {session}", styles["subtitle"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph(
        f"Durée : {duree} — Coefficient : {coefficient}",
        styles["meta"],
    ))
    story.append(Spacer(1, 18))
    story.append(Paragraph("L'usage de la calculatrice non programmable est autorisé.",
                           styles["meta"]))
    story.append(Spacer(1, 14))


def _build_pdf(output_path: Path, story: List) -> None:
    """Construit physiquement le PDF à partir d'une story ReportLab."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=A4,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        leftMargin=2.5 * cm,
        rightMargin=2.5 * cm,
        title=f"BEPC {output_path.stem}",
        author="ExamBoost Togo — démo OCR",
    )
    doc.build(story)


# ─── 1. Maths 2022 ────────────────────────────────────────────────────────


def generate_bepc_maths_2022() -> Path:
    """Génère le PDF BEPC Mathématiques session 2022 (6 questions)."""
    styles = _make_styles()
    story: List = []
    _build_header(story, styles, "Mathématiques", 2022, "2 heures", 4)

    story.append(Paragraph("Exercice 1 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Résoudre dans ℝ l'équation suivante : 3x + 7 = 22.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Résoudre le système suivant : { 2x + y = 7 ; x - y = 2 }.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 2 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Calculer l'aire d'un triangle rectangle dont les côtés de l'angle "
        "droit mesurent 6 cm et 8 cm.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Un commerçant achète un article 15 000 FCFA et le revend avec un "
        "bénéfice de 20 %. Quel est son prix de vente ?",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 3 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Dans un repère orthonormé, soient les points A(1 ; 2) et B(5 ; 6). "
        "Calculer la distance AB.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Factoriser l'expression suivante : x² - 9.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 4 (8 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "Le volume V d'un cylindre de révolution est donné par la formule "
        "V = π × r² × h, où r est le rayon de la base et h la hauteur.",
        styles["intro"],
    ))
    story.append(Paragraph(
        "1. Calculer le volume d'un cylindre de rayon 3 cm et de hauteur "
        "10 cm. On prendra π = 3,14.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. On double le rayon en gardant la même hauteur. Par combien le "
        "volume est-il multiplié ?",
        styles["question"],
    ))

    out = SAMPLE_PDFS_DIR / "bepc_maths_2022_sample.pdf"
    _build_pdf(out, story)
    print(f"PDF généré : {out}")
    return out


# ─── 2. Français 2021 ─────────────────────────────────────────────────────


def generate_bepc_francais_2021() -> Path:
    """Génère le PDF BEPC Français session 2021 (5 questions)."""
    styles = _make_styles()
    story: List = []
    _build_header(story, styles, "Français", 2021, "2 heures", 4)

    story.append(Paragraph("Exercice 1 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "Texte : « Le soleil se levait à peine sur Lomé lorsque Kossi prit "
        "le chemin de l'école, son cartable trop lourd sur le dos. »",
        styles["intro"],
    ))
    story.append(Paragraph(
        "1. Identifier le temps du verbe « prit » dans la phrase ci-dessus.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Réécrire la phrase en remplaçant « Kossi » par « les enfants » "
        "(attention à l'accord).",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 2 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Donner la nature et la fonction du mot « lourd » dans la phrase : "
        "« son cartable trop lourd sur le dos ».",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Transformer la phrase suivante en voix passive : « Le maître "
        "corrige les copies des élèves. »",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 3 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Dans la phrase « Kossi court vite comme un guépard », identifier "
        "la figure de style employée.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 4 (8 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Rédiger un paragraphe de 8 à 10 lignes dans lequel vous décrivez "
        "le matin dans votre quartier avant le lever du soleil.",
        styles["question"],
    ))

    out = SAMPLE_PDFS_DIR / "bepc_francais_2021_sample.pdf"
    _build_pdf(out, story)
    print(f"PDF généré : {out}")
    return out


# ─── 3. Sciences Physiques 2023 ───────────────────────────────────────────


def generate_bepc_sciences_2023() -> Path:
    """Génère le PDF BEPC Sciences Physiques session 2023 (6 questions)."""
    styles = _make_styles()
    story: List = []
    _build_header(story, styles, "Sciences Physiques", 2023, "2 heures", 3)

    story.append(Paragraph("Exercice 1 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Énoncer la loi d'Ohm aux bornes d'un conducteur ohmique.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Un conducteur ohmique de résistance R = 20 Ω est traversé par un "
        "courant d'intensité I = 0,5 A. Calculer la tension U à ses bornes.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 2 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Donner l'expression du poids P d'un corps de masse m. On prendra "
        "g = 10 N/kg.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Calculer le poids d'un sac de riz de masse 50 kg.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 3 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Définir la pression p exercée par une force F sur une surface S, "
        "et donner son unité légale.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Une force de 200 N s'exerce sur une surface de 0,5 m². Calculer "
        "la pression exercée.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 4 (8 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Citer les trois modes de transfert de la chaleur.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Expliquer pourquoi une cuillère métallique plongée dans une "
        "soupe chaude devient chaude à l'une de ses extrémités.",
        styles["question"],
    ))

    out = SAMPLE_PDFS_DIR / "bepc_sciences_2023_sample.pdf"
    _build_pdf(out, story)
    print(f"PDF généré : {out}")
    return out


# ─── 4. SVT 2020 ──────────────────────────────────────────────────────────


def generate_bepc_svt_2020() -> Path:
    """Génère le PDF BEPC SVT session 2020 (5 questions)."""
    styles = _make_styles()
    story: List = []
    _build_header(story, styles, "Sciences de la Vie et de la Terre",
                  2020, "1 heure 30", 2)

    story.append(Paragraph("Exercice 1 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Donner les trois grandes étapes de la digestion chez l'Homme.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Indiquer le rôle de la bile dans la digestion des graisses.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 2 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Définir les termes suivants : écosystème, population, biocénose.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Citer deux facteurs de dégradation d'un écosystème forestier au "
        "Togo.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 3 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Nommer l'agent responsable du paludisme et le mode de "
        "transmission de cette maladie.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 4 (8 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Définir la photosynthèse et donner l'équation bilan simplifiée.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Indiquer deux facteurs qui influencent l'intensité de la "
        "photosynthèse chez une plante verte.",
        styles["question"],
    ))

    out = SAMPLE_PDFS_DIR / "bepc_svt_2020_sample.pdf"
    _build_pdf(out, story)
    print(f"PDF généré : {out}")
    return out


# ─── 5. Histoire-Géographie 2022 ──────────────────────────────────────────


def generate_bepc_histoire_2022() -> Path:
    """Génère le PDF BEPC Histoire-Géographie session 2022 (5 questions)."""
    styles = _make_styles()
    story: List = []
    _build_header(story, styles, "Histoire-Géographie", 2022, "2 heures", 3)

    story.append(Paragraph("Exercice 1 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Donner la date de l'indépendance du Togo et citer le premier "
        "président de la République togolaise.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Citer deux anciennes colonies françaises d'Afrique de l'Ouest "
        "devenues indépendantes en 1960.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 2 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Définir les termes suivants : colonisation, décolonisation.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Citer deux causes de la traite négrière sur la côte des Esclaves "
        "au Golfe de Guinée.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 3 (4 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Nommer les cinq régions administratives du Togo actuel.",
        styles["question"],
    ))

    story.append(Paragraph("Exercice 4 (8 points)", styles["exercise_title"]))
    story.append(Paragraph(
        "1. Définir la notion de climat et citer les deux grands types de "
        "climats rencontrés au Togo.",
        styles["question"],
    ))
    story.append(Paragraph(
        "2. Donner deux caractéristiques du climat tropical soudanien au "
        "nord du Togo.",
        styles["question"],
    ))

    out = SAMPLE_PDFS_DIR / "bepc_histoire_2022_sample.pdf"
    _build_pdf(out, story)
    print(f"PDF généré : {out}")
    return out


# ─── Driver ────────────────────────────────────────────────────────────────


def main() -> None:
    """Génère les 5 PDFs d'annales BEPC simulés."""
    print("=== Génération des 5 PDFs d'annales BEPC simulés ===")
    print()
    generate_bepc_maths_2022()
    generate_bepc_francais_2021()
    generate_bepc_sciences_2023()
    generate_bepc_svt_2020()
    generate_bepc_histoire_2022()
    print()
    print("5 PDFs d'annales BEPC générés dans : "
          f"{SAMPLE_PDFS_DIR.relative_to(BASE_DIR)}/")


if __name__ == "__main__":
    main()
