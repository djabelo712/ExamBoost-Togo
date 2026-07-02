"""
Génère 2 PDFs pour ExamBoost Togo :
1. Manuel_Eleve_ExamBoost.pdf        — Manuel élève (~20 pages)
2. Guide_Enseignant_ExamBoost.pdf    — Guide enseignant (~15 pages)

Prérequis : pip install reportlab==4.2.0
Usage     : python3 generate_manuals.py
Auteur    : Agent BB — ExamBoost Togo (Session 3, Vague 3b)

Les PDFs sont écrits dans ./output/. Les captures d'écran sont des
placeholders graphiques ; l'équipe ExamBoost les remplacera par les
vraies captures de l'application Flutter avant impression.
"""

import os
import sys
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak,
    Table, TableStyle, Image, ListFlowable, ListItem,
    KeepTogether, Flowable, HRFlowable, CondPageBreak,
)
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT
from reportlab.pdfgen import canvas


# =============================================================================
# PALETTE EXAMBOOST TOGO (cohérente avec Pitch_Deck + app_theme.dart)
# =============================================================================

VERT_TOGO    = colors.HexColor('#006837')   # vert drapeau Togo (primaire)
VERT_FONCE   = colors.HexColor('#004A26')   # vert sombre (fonds, contrastes)
VERT_CLAIR   = colors.HexColor('#E8F5EE')   # vert clair (fond encadrés tips)
ORANGE       = colors.HexColor('#D97700')   # accent (chiffres clés, CTA)
ORANGE_CLAIR = colors.HexColor('#FFF3E0')   # fond encadrés warning
GRIS_FONCE   = colors.HexColor('#1A1A1A')   # corps de texte
GRIS_MOYEN   = colors.HexColor('#6B7280')   # texte secondaire, captions
GRIS_CLAIR   = colors.HexColor('#F8F9FA')   # fond clair, lignes alternées
GRIS_BORDURE = colors.HexColor('#E5E7EB')   # bordures tables
BLANC        = colors.white
ROUGE        = colors.HexColor('#C62828')   # alertes
ROUGE_CLAIR  = colors.HexColor('#FFEBEE')
BLEU         = colors.HexColor('#1565C0')   # exemples
BLEU_CLAIR   = colors.HexColor('#E3F2FD')
JAUNE_CLAIR  = colors.HexColor('#FFFDE7')


# =============================================================================
# CHEMINS & CONSTANTES
# =============================================================================

BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR  = os.path.join(BASE_DIR, 'output')
os.makedirs(OUTPUT_DIR, exist_ok=True)

PAGE_W, PAGE_H = A4
MARGIN_L = 2.5 * cm
MARGIN_R = 2.5 * cm
MARGIN_T = 2.0 * cm
MARGIN_B = 2.0 * cm
CONTENT_W = PAGE_W - MARGIN_L - MARGIN_R

VERSION_LINE  = "Version 1.0 — Juillet 2026"
COPYRIGHT_ELEVE     = "ExamBoost Togo — Manuel de l'élève — Document gratuit, diffusion autorisée"
COPYRIGHT_ENSEIGNANT = "ExamBoost Togo — Guide de l'enseignant — Document gratuit, diffusion autorisée"

# Chiffres clés repris du Pitch Deck et du Plan GoToMarket
CHIFFRES = {
    'bepc_2024':     '44 %',
    'bepc_2023':     '81 %',
    'bac2_2024':     '46,71 %',
    'lecture_10ans': '86 %',
    'eleves_secondaire': '800 000',
    'candidats_an':  '150 000',
    'questions_v1':  '64',
    'questions_cible': '3 000+',
    'apk_mo':        '< 25 Mo',
    'android_min':   '5.0+',
    'ecole_licence': '100 000 FCFA/an',
    'premium_eleve': '2 000 FCFA/mois',
    'objectif_pts':  '+15 points',
    'seuil_renta':   '300 écoles',
    'pilote_ecoles': '5 établissements',
    'pilote_eleves': '300 élèves',
}


# =============================================================================
# STYLES
# =============================================================================

def _build_styles():
    ss = getSampleStyleSheet()
    s = {}

    # --- Couverture (texte blanc sur fond vert) ---
    s['CoverEyebrow'] = ParagraphStyle(
        'CoverEyebrow', fontName='Helvetica-Bold', fontSize=11, leading=14,
        textColor=colors.HexColor('#FFD9A8'), alignment=TA_CENTER, spaceAfter=10,
    )
    s['CoverTitle'] = ParagraphStyle(
        'CoverTitle', fontName='Helvetica-Bold', fontSize=38, leading=44,
        textColor=BLANC, alignment=TA_CENTER, spaceAfter=10,
    )
    s['CoverSubtitle'] = ParagraphStyle(
        'CoverSubtitle', fontName='Helvetica', fontSize=16, leading=22,
        textColor=BLANC, alignment=TA_CENTER, spaceAfter=18,
    )
    s['CoverVersion'] = ParagraphStyle(
        'CoverVersion', fontName='Helvetica-Oblique', fontSize=11, leading=14,
        textColor=colors.HexColor('#FFD9A8'), alignment=TA_CENTER, spaceAfter=4,
    )
    s['CoverMention'] = ParagraphStyle(
        'CoverMention', fontName='Helvetica', fontSize=10, leading=14,
        textColor=colors.HexColor('#E8F5EE'), alignment=TA_CENTER, spaceAfter=2,
    )

    # --- Table des matières ---
    s['TocTitle'] = ParagraphStyle(
        'TocTitle', fontName='Helvetica-Bold', fontSize=22, leading=28,
        textColor=VERT_TOGO, alignment=TA_LEFT, spaceAfter=18,
    )
    s['TocEntry'] = ParagraphStyle(
        'TocEntry', fontName='Helvetica', fontSize=12, leading=22,
        textColor=GRIS_FONCE, alignment=TA_LEFT,
    )
    s['TocIntro'] = ParagraphStyle(
        'TocIntro', fontName='Helvetica-Oblique', fontSize=11, leading=16,
        textColor=GRIS_MOYEN, alignment=TA_LEFT, spaceAfter=14,
    )

    # --- Section / sous-section ---
    s['SectionEyebrow'] = ParagraphStyle(
        'SectionEyebrow', fontName='Helvetica-Bold', fontSize=9, leading=12,
        textColor=ORANGE, alignment=TA_LEFT, spaceAfter=2,
    )
    s['SectionTitle'] = ParagraphStyle(
        'SectionTitle', fontName='Helvetica-Bold', fontSize=20, leading=26,
        textColor=VERT_TOGO, alignment=TA_LEFT, spaceAfter=6,
    )
    s['SubSection'] = ParagraphStyle(
        'SubSection', fontName='Helvetica-Bold', fontSize=13, leading=17,
        textColor=VERT_FONCE, alignment=TA_LEFT, spaceBefore=10, spaceAfter=4,
    )
    s['MiniHead'] = ParagraphStyle(
        'MiniHead', fontName='Helvetica-Bold', fontSize=11, leading=14,
        textColor=VERT_TOGO, alignment=TA_LEFT, spaceBefore=8, spaceAfter=3,
    )

    # --- Corps de texte ---
    s['Body'] = ParagraphStyle(
        'Body', fontName='Helvetica', fontSize=10.5, leading=15,
        textColor=GRIS_FONCE, alignment=TA_JUSTIFY, spaceAfter=6,
    )
    s['BodyLeft'] = ParagraphStyle(
        'BodyLeft', parent=s['Body'], alignment=TA_LEFT,
    )
    s['Bullet'] = ParagraphStyle(
        'Bullet', fontName='Helvetica', fontSize=10.5, leading=15,
        textColor=GRIS_FONCE, alignment=TA_LEFT, leftIndent=14, bulletIndent=2,
        spaceAfter=3,
    )
    s['Numbered'] = ParagraphStyle(
        'Numbered', fontName='Helvetica', fontSize=10.5, leading=15,
        textColor=GRIS_FONCE, alignment=TA_LEFT, leftIndent=18, bulletIndent=2,
        spaceAfter=3,
    )
    s['Quote'] = ParagraphStyle(
        'Quote', fontName='Helvetica-Oblique', fontSize=11, leading=16,
        textColor=VERT_FONCE, alignment=TA_LEFT, leftIndent=16, rightIndent=16,
        spaceBefore=8, spaceAfter=8,
    )
    s['Caption'] = ParagraphStyle(
        'Caption', fontName='Helvetica-Oblique', fontSize=9, leading=12,
        textColor=GRIS_MOYEN, alignment=TA_CENTER, spaceBefore=4, spaceAfter=10,
    )

    # --- Encadrés ---
    s['Callout'] = ParagraphStyle(
        'Callout', fontName='Helvetica', fontSize=10, leading=14,
        textColor=GRIS_FONCE, alignment=TA_LEFT,
    )
    s['CalloutTitle'] = ParagraphStyle(
        'CalloutTitle', fontName='Helvetica-Bold', fontSize=10.5, leading=14,
        textColor=VERT_TOGO, alignment=TA_LEFT, spaceAfter=3,
    )

    # --- Tables ---
    s['TableHeader'] = ParagraphStyle(
        'TableHeader', fontName='Helvetica-Bold', fontSize=10, leading=13,
        textColor=BLANC, alignment=TA_LEFT,
    )
    s['TableCell'] = ParagraphStyle(
        'TableCell', fontName='Helvetica', fontSize=9.5, leading=13,
        textColor=GRIS_FONCE, alignment=TA_LEFT,
    )
    s['TableCellBold'] = ParagraphStyle(
        'TableCellBold', fontName='Helvetica-Bold', fontSize=9.5, leading=13,
        textColor=VERT_TOGO, alignment=TA_LEFT,
    )

    # --- FAQ ---
    s['FaqQ'] = ParagraphStyle(
        'FaqQ', fontName='Helvetica-Bold', fontSize=11, leading=14,
        textColor=VERT_TOGO, alignment=TA_LEFT, spaceBefore=8, spaceAfter=2,
    )
    s['FaqA'] = ParagraphStyle(
        'FaqA', parent=s['Body'], spaceAfter=4,
    )

    return s


STYLES = _build_styles()


# =============================================================================
# HELPERS DE PARAGRAPHE
# =============================================================================

def P(text, style='Body'):
    """Raccourci pour Paragraph(text, STYLES[style])."""
    return Paragraph(text, STYLES[style])


def paras(*texts, style='Body'):
    return [Paragraph(t, STYLES[style]) for t in texts]


def bullets(items, style='Bullet'):
    """Liste à puces."""
    return ListFlowable(
        [ListItem(Paragraph(t, STYLES[style]), leftIndent=14, value='circle')
         for t in items],
        bulletType='bullet', bulletChar='•', leftIndent=14,
        bulletFontName='Helvetica', bulletFontSize=10,
        start='•',
    )


def numbered(items, style='Numbered'):
    """Liste numérotée."""
    return ListFlowable(
        [ListItem(Paragraph(t, STYLES[style]), leftIndent=18)
         for t in items],
        bulletType='1', leftIndent=18,
        bulletFontName='Helvetica-Bold', bulletFontSize=10,
    )


# =============================================================================
# LOGO (FLOWABLE PERSONNALISÉ)
# =============================================================================

class LogoDrawing(Flowable):
    """Logo ExamBoost : toque de diplômé stylisée dans un cercle.

    variant='on_green'  -> dessiné en blanc/orange sur fond vert (couverture)
    variant='on_white'  -> dessiné en vert/orange sur fond blanc (intérieur)
    """

    def __init__(self, size=80, variant='on_green'):
        Flowable.__init__(self)
        self.size = size
        self.variant = variant
        self.width = size
        self.height = size

    def draw(self):
        c = self.canv
        s = self.size
        cx, cy = s / 2.0, s / 2.0

        if self.variant == 'on_green':
            ring_color   = BLANC
            cap_color    = BLANC
            tassel_color = ORANGE
            text_color   = BLANC
            inner_fill   = None  # transparent (le fond vert reste)
        else:
            ring_color   = VERT_TOGO
            cap_color    = VERT_TOGO
            tassel_color = ORANGE
            text_color   = VERT_TOGO
            inner_fill   = VERT_CLAIR

        # Cercle extérieur
        c.setLineWidth(2.2)
        c.setStrokeColor(ring_color)
        if inner_fill:
            c.setFillColor(inner_fill)
            c.circle(cx, cy, s / 2.0 - 2, fill=1, stroke=1)
        else:
            c.circle(cx, cy, s / 2.0 - 2, fill=0, stroke=1)

        # Toque (mortarboard) — losange
        cap_w = s * 0.55
        cap_h = s * 0.16
        cy_cap = cy + s * 0.12
        c.setFillColor(cap_color)
        p = c.beginPath()
        p.moveTo(cx, cy_cap + cap_h / 2.0)
        p.lineTo(cx + cap_w / 2.0, cy_cap)
        p.lineTo(cx, cy_cap - cap_h / 2.0)
        p.lineTo(cx - cap_w / 2.0, cy_cap)
        p.close()
        c.drawPath(p, fill=1, stroke=0)

        # Base de la toque (rectangle arrondi sous le losange)
        base_w = s * 0.22
        base_h = s * 0.11
        c.setFillColor(cap_color)
        c.roundRect(cx - base_w / 2.0,
                    cy_cap - base_h - cap_h / 3.0,
                    base_w, base_h, 2, fill=1, stroke=0)

        # Pompon / cordon de la toque
        c.setStrokeColor(tassel_color)
        c.setLineWidth(1.8)
        c.line(cx, cy_cap, cx + cap_w / 2.0 + s * 0.02, cy_cap - s * 0.04)
        c.setFillColor(tassel_color)
        c.circle(cx + cap_w / 2.0 + s * 0.02, cy_cap - s * 0.07, s * 0.028,
                 fill=1, stroke=0)

        # Monogramme "EB" sous la toque
        c.setFillColor(text_color)
        c.setFont('Helvetica-Bold', s * 0.17)
        c.drawCentredString(cx, cy - s * 0.28, "EB")


# =============================================================================
# PLACEHOLDER DE CAPTURE D'ÉCRAN
# =============================================================================

class ScreenshotPlaceholder(Flowable):
    """Placeholder rectangulaire mimant un screenshot mobile.

    L'équipe ExamBoost remplacera ces placeholders par les vraies
    captures d'écran de l'application Flutter avant impression.
    """

    def __init__(self, width=7.2 * cm, height=12.5 * cm, label="Écran"):
        Flowable.__init__(self)
        self.width = width
        self.height = height
        self.label = label

    def draw(self):
        c = self.canv
        w, h = self.width, self.height
        m = 3  # marge cadre/screen

        # Cadre téléphone
        c.setFillColor(GRIS_FONCE)
        c.roundRect(0, 0, w, h, 8, fill=1, stroke=0)
        # Écran
        c.setFillColor(BLANC)
        c.roundRect(m, m, w - 2 * m, h - 2 * m, 5, fill=1, stroke=0)
        # Encoche haute
        notch_w = w * 0.30
        c.setFillColor(GRIS_FONCE)
        c.roundRect((w - notch_w) / 2.0, h - m - 6, notch_w, 6, 2,
                    fill=1, stroke=0)
        # Barre de statut verte (haut)
        bar_h = h * 0.07
        c.setFillColor(VERT_TOGO)
        c.rect(m, h - m - bar_h - 6, w - 2 * m, bar_h, fill=1, stroke=0)
        # Petit contenu fictif (lignes)
        c.setStrokeColor(GRIS_BORDURE)
        c.setLineWidth(1)
        top = h - m - bar_h - 14
        for i in range(5):
            y = top - i * 12
            c.line(m + 8, y, w - m - 8 - (i * 6), y)
        # Bloc coloré central (simulateur de "carte")
        block_h = h * 0.18
        c.setFillColor(VERT_CLAIR)
        c.roundRect(m + 8, h * 0.40, w - 2 * m - 16, block_h, 4,
                    fill=1, stroke=0)
        c.setFillColor(VERT_TOGO)
        c.roundRect(m + 12, h * 0.40 + 6, w * 0.35, 6, 2, fill=1, stroke=0)
        # 3 boutons colorés en bas (Facile / Correct / Difficile)
        bw = (w - 2 * m - 24) / 3.0
        by = m + 18
        for i, col in enumerate([VERT_TOGO, BLEU, ORANGE]):
            c.setFillColor(col)
            c.roundRect(m + 8 + i * (bw + 4), by, bw, 14, 3,
                        fill=1, stroke=0)
        # Label
        c.setFillColor(GRIS_MOYEN)
        c.setFont('Helvetica-Bold', 9)
        c.drawCentredString(w / 2.0, h * 0.30, self.label)
        c.setFont('Helvetica-Oblique', 7)
        c.drawCentredString(w / 2.0, h * 0.30 - 11,
                            "(capture a remplacer par l'equipe)")


def figure(placeholder, caption_text):
    """Centre un placeholder + légende."""
    return KeepTogether([
        Spacer(1, 4),
        Table([[placeholder]], colWidths=[CONTENT_W],
              style=TableStyle([('ALIGN', (0, 0), (-1, -1), 'CENTER')])),
        Paragraph(caption_text, STYLES['Caption']),
    ])


# =============================================================================
# ENCADRÉS (TIPS / WARNINGS / EXAMPLES)
# =============================================================================

def _callout(title, text, border_color, bg_color):
    title_style = ParagraphStyle(
        'CalloutTitleX', parent=STYLES['CalloutTitle'], textColor=border_color)
    title_p = Paragraph(f"<b>{title}</b>", title_style)
    body_p = Paragraph(text, STYLES['Callout'])
    t = Table([[title_p], [body_p]], colWidths=[CONTENT_W - 4])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), bg_color),
        ('LINEBEFORE', (0, 0), (0, -1), 3, border_color),
        ('LEFTPADDING',   (0, 0), (-1, -1), 10),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 10),
        ('TOPPADDING',    (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    return KeepTogether([Spacer(1, 4), t, Spacer(1, 6)])


def tip_box(text, title="Astuce"):
    return _callout(title, text, VERT_TOGO, VERT_CLAIR)


def warning_box(text, title="Attention"):
    return _callout(title, text, ORANGE, ORANGE_CLAIR)


def example_box(text, title="Exemple"):
    return _callout(title, text, BLEU, BLEU_CLAIR)


def note_box(text, title="A noter"):
    return _callout(title, text, GRIS_FONCE, GRIS_CLAIR)


# =============================================================================
# EN-TÊTES DE SECTION
# =============================================================================

def section_header(num, title, eyebrow=None):
    """En-tête de section avec badge numéroté orange + titre vert."""
    flow = []
    if eyebrow:
        flow.append(Paragraph(eyebrow.upper(), STYLES['SectionEyebrow']))
    badge = Table(
        [[Paragraph(
            f"<font color='white'><b>{num}</b></font>",
            ParagraphStyle('Badge', fontName='Helvetica-Bold',
                           fontSize=14, leading=16, alignment=TA_CENTER))]],
        colWidths=[30], rowHeights=[30]
    )
    badge.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), ORANGE),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]))
    title_p = Paragraph(title, STYLES['SectionTitle'])
    head = Table([[badge, title_p]], colWidths=[38, CONTENT_W - 38])
    head.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]))
    flow.append(KeepTogether([head, Spacer(1, 4)]))
    flow.append(HRFlowable(width="100%", thickness=2,
                           color=VERT_TOGO, spaceAfter=10))
    return flow


def sub_header(text):
    return Paragraph(text, STYLES['SubSection'])


def mini_head(text):
    return Paragraph(text, STYLES['MiniHead'])


# =============================================================================
# TABLES STRUCTURÉES
# =============================================================================

def make_table(header, rows, col_widths=None, header_color=VERT_TOGO):
    """Construit un tableau standard ExamBoost (en-tête vert, lignes alternées)."""
    data = [[Paragraph(h, STYLES['TableHeader']) for h in header]]
    for row in rows:
        line = []
        for i, cell in enumerate(row):
            # 1re colonne en gras vert pour faire ressortir
            if i == 0:
                line.append(Paragraph(cell, STYLES['TableCellBold']))
            else:
                line.append(Paragraph(cell, STYLES['TableCell']))
        data.append(line)
    if col_widths is None:
        col_widths = [CONTENT_W / len(header)] * len(header)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), header_color),
        ('TEXTCOLOR',  (0, 0), (-1, 0), BLANC),
        ('FONTNAME',   (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE',   (0, 0), (-1, 0), 10),
        ('ALIGN',      (0, 0), (-1, 0), 'LEFT'),
        ('VALIGN',     (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [BLANC, GRIS_CLAIR]),
        ('GRID', (0, 0), (-1, -1), 0.5, GRIS_BORDURE),
        ('LEFTPADDING',   (0, 0), (-1, -1), 6),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 6),
        ('TOPPADDING',    (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    return t


def faq_item(question, answer):
    """Bloc Q/R pour les FAQ."""
    q = Paragraph(f"Q. {question}", STYLES['FaqQ'])
    a = Paragraph(answer, STYLES['FaqA'])
    return KeepTogether([q, a, Spacer(1, 4)])


# =============================================================================
# CALLBACKS CANVAS (couverture + pied de page)
# =============================================================================

def _cover_canvas(canvas, doc):
    """Dessine le fond vert pleine page + bandeaux décoratifs de la couverture."""
    canvas.saveState()
    # Fond vert pleine page
    canvas.setFillColor(VERT_TOGO)
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    # Bande foncée haute
    canvas.setFillColor(VERT_FONCE)
    canvas.rect(0, PAGE_H - 1.2 * cm, PAGE_W, 1.2 * cm, fill=1, stroke=0)
    # Bande orange fine
    canvas.setFillColor(ORANGE)
    canvas.rect(0, PAGE_H - 1.25 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    # Bande foncée basse
    canvas.setFillColor(VERT_FONCE)
    canvas.rect(0, 0, PAGE_W, 1.2 * cm, fill=1, stroke=0)
    canvas.setFillColor(ORANGE)
    canvas.rect(0, 1.2 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
    # Texte bandeau haut (mention DJANTA)
    canvas.setFillColor(BLANC)
    canvas.setFont('Helvetica-Bold', 9)
    canvas.drawCentredString(PAGE_W / 2.0, PAGE_H - 0.75 * cm,
        "PROJET CANDIDAT  -  DJANTA TECH HUB  -  IDEE-ACTION CHALLENGE 2026")
    # Texte bandeau bas
    canvas.setFillColor(BLANC)
    canvas.setFont('Helvetica', 9)
    canvas.drawCentredString(PAGE_W / 2.0, 0.45 * cm,
        "ExamBoost Togo  -  Application Flutter  -  BEPC & BAC  -  100% hors-ligne")
    canvas.restoreState()


def _make_content_canvas(footer_text):
    """Retourne le callback de pied de page pour les pages intérieures."""
    def _content_canvas(canvas, doc):
        canvas.saveState()
        # Bande verte en bas
        canvas.setFillColor(VERT_TOGO)
        canvas.rect(0, 0, PAGE_W, 0.65 * cm, fill=1, stroke=0)
        # Liseré orange
        canvas.setFillColor(ORANGE)
        canvas.rect(0, 0.65 * cm, PAGE_W, 0.05 * cm, fill=1, stroke=0)
        # Pied gauche (copyright)
        canvas.setFillColor(BLANC)
        canvas.setFont('Helvetica', 8)
        canvas.drawString(MARGIN_L, 0.22 * cm, footer_text)
        # Pied droit (page X / Y)
        canvas.drawRightString(PAGE_W - MARGIN_R, 0.22 * cm,
                               f"Page {doc.page}")
        # Petit logo en haut à droite
        canvas.setFillColor(VERT_TOGO)
        canvas.circle(PAGE_W - MARGIN_R - 6, PAGE_H - 1.0 * cm, 6,
                      fill=1, stroke=0)
        canvas.setFillColor(BLANC)
        canvas.setFont('Helvetica-Bold', 6)
        canvas.drawCentredString(PAGE_W - MARGIN_R - 6, PAGE_H - 1.15 * cm,
                                 "EB")
        canvas.restoreState()
    return _content_canvas


# =============================================================================
# COUVERTURE & TABLE DES MATIÈRES
# =============================================================================

def build_cover(title, subtitle, kind='eleve'):
    """Construit la page de couverture (flowables blancs sur fond vert)."""
    flow = []
    flow.append(Spacer(1, 3.0 * cm))
    # Logo centré
    logo = LogoDrawing(size=110, variant='on_green')
    logo_wrap = Table([[logo]], colWidths=[CONTENT_W],
                      style=TableStyle([('ALIGN', (0, 0), (-1, -1), 'CENTER')]))
    flow.append(logo_wrap)
    flow.append(Spacer(1, 0.4 * cm))
    # Eyebrow "EXAMBOOST TOGO"
    flow.append(Paragraph("EXAMBOOST  TOGO", STYLES['CoverEyebrow']))
    flow.append(Spacer(1, 0.6 * cm))
    # Titre principal
    flow.append(Paragraph(title, STYLES['CoverTitle']))
    # Sous-titre
    flow.append(Paragraph(subtitle, STYLES['CoverSubtitle']))
    flow.append(Spacer(1, 1.0 * cm))
    # Ligne décorative (table 1px orange)
    deco = Table([['']], colWidths=[6 * cm], rowHeights=[2])
    deco.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), ORANGE),
        ('LINEABOVE', (0, 0), (-1, -1), 0, ORANGE),
    ]))
    deco_wrap = Table([[deco]], colWidths=[CONTENT_W],
                      style=TableStyle([('ALIGN', (0, 0), (-1, -1), 'CENTER')]))
    flow.append(deco_wrap)
    flow.append(Spacer(1, 0.5 * cm))
    # Version
    flow.append(Paragraph(VERSION_LINE, STYLES['CoverVersion']))
    flow.append(Spacer(1, 1.5 * cm))
    # Encart chiffres clés
    if kind == 'eleve':
        chiffres = [
            [Paragraph("<font color='#FFD9A8'><b>BEPC 2024</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='#FFD9A8'><b>BAC 2 2024</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='#FFD9A8'><b>Objectif</b></font>",
                       STYLES['CoverMention'])],
            [Paragraph("<font color='white'><b>44 %</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='white'><b>46,71 %</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='white'><b>+15 pts</b></font>",
                       STYLES['CoverMention'])],
            [Paragraph("reussite nationale", STYLES['CoverMention']),
             Paragraph("reussite nationale", STYLES['CoverMention']),
             Paragraph("apres 6 mois d'usage regulier",
                       STYLES['CoverMention'])],
        ]
    else:
        chiffres = [
            [Paragraph("<font color='#FFD9A8'><b>Pilote Lome</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='#FFD9A8'><b>Licence ecole</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='#FFD9A8'><b>Eleves cibles M18</b></font>",
                       STYLES['CoverMention'])],
            [Paragraph("<font color='white'><b>5 etab.</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='white'><b>100 k FCFA/an</b></font>",
                       STYLES['CoverMention']),
             Paragraph("<font color='white'><b>50 000</b></font>",
                       STYLES['CoverMention'])],
            [Paragraph("300 eleves testeurs (M0-M3)", STYLES['CoverMention']),
             Paragraph("tarif public", STYLES['CoverMention']),
             Paragraph("utilisateurs actifs/mois", STYLES['CoverMention'])],
        ]
    chiffres_table = Table(chiffres,
                           colWidths=[CONTENT_W / 3.0] * 3)
    chiffres_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LINEBEFORE', (1, 0), (1, -1), 0.5, ORANGE),
        ('LINEBEFORE', (2, 0), (2, -1), 0.5, ORANGE),
    ]))
    flow.append(chiffres_table)
    flow.append(Spacer(1, 2.5 * cm))
    # Mention diffusion
    flow.append(Paragraph(
        "Document gratuit  -  Diffusion autorisee",
        STYLES['CoverMention']))
    flow.append(Paragraph(
        "SmartFarm Togo / AIMS Ghana  -  Juillet 2026",
        STYLES['CoverMention']))
    return flow


def build_toc(entries, intro=None):
    """Construit la table des matières."""
    flow = []
    flow.append(Paragraph("Table des matieres", STYLES['TocTitle']))
    if intro:
        flow.append(Paragraph(intro, STYLES['TocIntro']))
    flow.append(HRFlowable(width="100%", thickness=1.5,
                           color=ORANGE, spaceAfter=12))
    rows = []
    for i, entry in enumerate(entries, 1):
        num_cell = Paragraph(
            f"<font color='{ORANGE.hexval()}'><b>{i:02d}</b></font>",
            STYLES['TocEntry'])
        title_cell = Paragraph(entry, STYLES['TocEntry'])
        rows.append([num_cell, title_cell])
    t = Table(rows, colWidths=[1.2 * cm, CONTENT_W - 1.2 * cm])
    t.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LINEBELOW', (0, 0), (-1, -2), 0.3, GRIS_BORDURE),
    ]))
    flow.append(t)
    flow.append(Spacer(1, 0.8 * cm))
    flow.append(HRFlowable(width="100%", thickness=0.5,
                           color=GRIS_BORDURE, spaceAfter=6))
    flow.append(Paragraph(
        "<i>Document produit par l'equipe ExamBoost Togo pour la distribution "
        "dans les ecoles pilotes de Lome. Pour toute question, ecrire a "
        "support@examboost.tg</i>",
        STYLES['TocIntro']))
    return flow


# =============================================================================
# SECTIONS DU MANUEL ELEVE
# =============================================================================

def _student_section_1_welcome():
    f = section_header("1", "Bienvenue sur ExamBoost",
                       eyebrow="Chapitre 1 - Decouverte")
    f.append(P(
        "ExamBoost Togo est une <b>application mobile gratuite</b> qui t'aide "
        "a preparer le BEPC et le BAC dans les conditions exactes de "
        "l'examen. Elle a ete concue au Togo, pour les eleves togolais, "
        "avec un contenu aligne sur le programme officiel du MEPST. "
        "Elle fonctionne sur telephone Android (a partir d'Android 5), "
        "tient en moins de 25 Mo et marche <b>100 % hors-ligne</b> : "
        "tu n'as pas besoin d'Internet pour reviser, seulement pour "
        "les mises a jour et le tuteur IA."))
    f.append(sub_header("Pour qui c'est ?"))
    f.append(bullets([
        "<b>Eleves de 3e</b> preparing le BEPC (Maths, Francais, "
        "Sciences Physiques, SVT, Histoire-Geographie, Anglais).",
        "<b>Eleves de 1ere et Terminale</b> preparing le BAC series C et D "
        "(Maths, Sciences Physiques, SVT).",
        "<b>Candidats libres</b> qui repassent l'examen et veulent un "
        "raisonnement structure.",
        "<b>Enseignants et parents</b> qui suivent la progression d'un "
        "eleve (voir le Guide de l'enseignant).",
    ]))
    f.append(sub_header("Pourquoi ca marche (simplement)"))
    f.append(P(
        "ExamBoost combine trois algorithmes issus de la recherche en "
        "sciences de l'education. Tu n'as pas besoin de les comprendre "
        "pour utiliser l'app, mais savoir pourquoi ca marche t'aidera "
        "a confiance en ta methode."))
    f.append(make_table(
        ["Algorithme", "Nom complet", "Ce qu'il fait pour toi"],
        [
            ["SM-2", "SuperMemo-2 (repetition espacee)",
             "Planifie la prochaine revision de chaque carte au moment "
             "exact ou tu etais sur le point de l'oublier. Plus tu "
             "reponds bien, plus l'intervalle s'allonge."],
            ["IRT", "Theorie de la Reponse aux Items (3PL)",
             "Calibre chaque question sur une echelle de difficulte. "
             "T'examine a ton niveau exact : ni trop facile, ni trop dur."],
            ["BKT", "Bayesian Knowledge Tracing",
             "Estime pour chaque chapitre ta probabilite de maitrise "
             "P(L). Quand P(L) >= 0,85, ExamBoost considere que tu "
             "maitrises le chapitre."],
        ],
        col_widths=[2.0 * cm, 5.5 * cm, CONTENT_W - 7.5 * cm]))
    f.append(Spacer(1, 6))
    f.append(tip_box(
        "Ces trois algorithmes tournent en local sur ton telephone. "
        "Aucune donnee n'est envoyee sur Internet sans ton accord. "
        "L'application marche meme si tu n'as pas de forfait data."))
    f.append(sub_header("Ce que ca peut t'apporter"))
    f.append(P(
        "L'objectif d'ExamBoost est de <b>+15 points</b> sur ta note "
        "moyenne aux controles apres 6 mois d'usage regulier (15 minutes "
        "par jour). Ce chiffre est l'objectif du pilote Lome (juillet "
        "2026 - juillet 2027), il sera valide sur 300 eleves testeurs "
        "dans 5 etablissements."))
    f.append(Paragraph(
        "&laquo; Avant ExamBoost, je faisais mes revisions avec des PDF "
        "que des amis m'envoyaient sur WhatsApp. C'etait completement "
        "desorganise. La, je fais 15 min par jour et je vois mon score "
        "BEPC monter. &raquo;",
        STYLES['Quote']))
    f.append(Paragraph(
        "<font color='%s'>- Amina, 3e, Lome (enquete terrain juin 2026)</font>"
        % GRIS_MOYEN.hexval(), STYLES['BodyLeft']))
    f.append(Spacer(1, 4))
    f.append(warning_box(
        "ExamBoost ne remplace pas tes cours, tes enseignants, ni ton "
        "travail personnel. C'est un outil qui rend tes revisions plus "
        "efficaces en planifiant ce que tu dois reviser et quand. "
        "Continue d'assister a tes cours et de prendre des notes."))
    return f


def _student_section_2_first_launch():
    f = section_header("2", "Ton premier lancement",
                       eyebrow="Chapitre 2 - Installation & onboarding")
    f.append(sub_header("Etape 1 - Installer l'application"))
    f.append(P(
        "Deux facons d'installer ExamBoost sur ton telephone :"))
    f.append(mini_head("Option A - Play Store (recommandee)"))
    f.append(bullets([
        "Ouvre le <b>Google Play Store</b> sur ton telephone.",
        "Cherche <b>ExamBoost Togo</b> dans la barre de recherche.",
        "Touche <b>Installer</b>. L'application se telecharge (environ "
        "25 Mo, donc moins de 2 minutes en 3G).",
        "Ouvre l'application. Elle se lancera sans aucun reglage "
        "particulier a faire.",
    ]))
    f.append(mini_head("Option B - APK direct (hors Play Store)"))
    f.append(P(
        "Si tu n'as pas acces au Play Store ou que tu veux economiser "
        "de la data, tu peux installer l'APK directement :"))
    f.append(bullets([
        "Recupere le fichier <b>examboost-togo.apk</b> sur la carte SD "
        "d'un camarade ou via Bluetooth.",
        "Dans <b>Parametres > Securite</b>, active <b>Sources "
        "inconnues</b>.",
        "Ouvre le fichier APK depuis ton gestionnaire de fichiers et "
        "touche <b>Installer</b>.",
        "Une fois installe, desactive <b>Sources inconnues</b> pour "
        "garder ton telephone en securite.",
    ]))
    f.append(warning_box(
        "Telecharge l'APK uniquement depuis une source de confiance "
        "(site officiel examboost.tg, enseignant, camarade de confiance). "
        "N'installe jamais un APK recu d'un inconnu : il pourrait "
        "contenir un virus."))
    f.append(sub_header("Etape 2 - L'onboarding (5 etapes)"))
    f.append(P(
        "Au premier lancement, ExamBoost te presente un parcours "
        "d'onboarding en 5 etapes. Prends le temps de bien repondre : "
        "ces informations permettent a l'IA de calibrer tes questions "
        "des le depart."))
    f.append(make_table(
        ["Etape", "Ce qu'on te demande", "Pourquoi c'est important"],
        [
            ["1. Bienvenue", "Une page de presentation", "Te montre les 3 "
             "piliers de la methode ExamBoost."],
            ["2. Identite", "Pseudo, age, ville", "Personnalise ton profil. "
             "Tu peux rester anonyme (pseudo)."],
            ["3. Niveau", "3e, 1ere, Terminale, candidat libre",
             "Adapte le contenu a ton examen cible (BEPC ou BAC)."],
            ["4. Serie", "A, C, D, ou (BEPC)", "Affiche les bonnes "
             "matieres (BAC C = Maths + Physique, BAC D = SVT + Maths)."],
            ["5. Matieres", "Cocher les matieres a reviser",
             "Active les flashcards pour ces matieres. Tu peux en ajouter "
             "ou retirer plus tard."],
        ],
        col_widths=[2.5 * cm, 5.5 * cm, CONTENT_W - 8.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("Etape 3 - Autoriser les notifications"))
    f.append(P(
        "A la fin de l'onboarding, ExamBoost te demande l'autorisation "
        "d'envoyer des notifications. <b>Accepte</b>. Ces notifications "
        "te rappelleront chaque jour, a l'heure que tu choisiras, "
        "qu'il est temps de faire tes 15 minutes de revision."))
    f.append(tip_box(
        "Tu peux changer l'heure du rappel quotidien dans Parametres > "
        "Notifications. Choisis une heure ou tu es calme et regulier : "
        "20h00 apres les devoirs, ou 6h30 avant l'ecole, par exemple."))
    f.append(sub_header("Etape 4 - Ton premier profil"))
    f.append(P(
        "Une fois l'onboarding termine, tu arrives sur l'ecran d'accueil. "
        "Ton profil est cree. Il contient :"))
    f.append(bullets([
        "Ton <b>niveau</b> (3e, 1ere, Terminale) et ta <b>serie</b>.",
        "Tes <b>matieres actives</b> et le nombre de questions "
        "disponibles dans chacune.",
        "Un <b>score global</b> initie a 0 %, qui montera au fur et a "
        "mesure de tes revisions.",
        "Un <b>streak</b> (serie de jours consecutifs) initie a 0.",
    ]))
    f.append(figure(ScreenshotPlaceholder(label="Ecran d'accueil"),
                    "Figure 2.1 - Ecran d'accueil apres onboarding "
                    "(placeholder, a remplacer par la capture reelle)."))
    return f


def _student_section_3_flashcards():
    f = section_header("3", "Reviser avec les flashcards",
                       eyebrow="Chapitre 3 - Le coeur d'ExamBoost")
    f.append(P(
        "La flashcard est le bloc elementaire d'ExamBoost. C'est une "
        "carte avec une question au recto et la reponse au verso. Tu "
        "vois la question, tu reflechis, tu retournes la carte, tu "
        "compares avec la reponse, puis tu t'auto-evalues. Cette boucle "
        "est au coeur de la repetition espacee."))
    f.append(sub_header("3.1 - L'ecran de revision"))
    f.append(P(
        "Depuis l'accueil, touche <b>Revision adaptative</b>. ExamBoost "
        "te presente une carte. Tu vois :"))
    f.append(bullets([
        "En haut : la <b>matiere</b>, le <b>chapitre</b> et la "
        "<b>question actuelle / total</b> (ex. : 5 / 20).",
        "Au centre : la <b>question</b> (texte, et parfois un schema "
        "ou une formule).",
        "En bas : un bouton <b>Voir la reponse</b>.",
        "Une <b>barre de progression</b> en haut indique ta session.",
    ]))
    f.append(figure(ScreenshotPlaceholder(label="Ecran de revision"),
                    "Figure 3.1 - Une flashcard en cours de revision "
                    "(placeholder)."))
    f.append(sub_header("3.2 - Voir la reponse"))
    f.append(P(
        "Touche <b>Voir la reponse</b>. La carte se retourne avec une "
        "animation 3D. Au verso s'affichent :"))
    f.append(bullets([
        "La <b>reponse</b> claire et complete.",
        "Un <b>raisonnement</b> detaille (etape par_etape pour les "
        "maths, regle pour le francais, etc.).",
        "Parfois un <b>exemple complementaire</b> ou un lien vers une "
        "video d'explication de 30 secondes.",
    ]))
    f.append(tip_box(
        "Avant de retourner la carte, prends le temps de <b>reflechir "
        "vraiment</b> a la reponse. Meme si tu n'es pas sur, ecris ta "
        "reponse sur un brouillon. C'est cette etape de rappel actif "
        "qui fait progresser ta memoire : sans elle, la flashcard ne "
        "sert a rien."))
    f.append(sub_header("3.3 - S'auto-evaluer (4 boutons)"))
    f.append(P(
        "Apres avoir vu la reponse, 4 boutons apparaissent en bas de "
        "l'ecran. Choisis celui qui correspond le mieux a ta performance :"))
    f.append(make_table(
        ["Bouton", "Quand le choisir", "Effet sur la carte"],
        [
            ["Facile", "Tu as repondu juste, rapidement, sans hesitation.",
             "L'intervalle avant la prochaine revision saute (ex. : "
             "21 jours puis 60 jours puis 6 mois)."],
            ["Correct", "Tu as repondu juste mais avec un effort ou "
             "une hesitation.",
             "Intervalle moyen (ex. : 6 jours puis 14 jours puis 30 jours)."],
            ["Difficile", "Tu as repondu juste mais avec beaucoup de mal, "
             "ou tu as presque oublie.",
             "Intervalle court (ex. : 1 jour puis 3 jours puis 7 jours)."],
            ["Oublie", "Tu as repondu faux, ou tu n'avais aucune idee.",
             "La carte <b>recommence</b> : intervalle remis a 1 jour, "
             "compteur de repetitions a zero."],
        ],
        col_widths=[2.5 * cm, 6.0 * cm, CONTENT_W - 8.5 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("3.4 - Comment l'IA decide quand te reposer la "
                        "question (SM-2)"))
    f.append(P(
        "L'algorithme SM-2 calcule pour chaque carte un <b>intervalle</b> "
        "(le nombre de jours avant la prochaine revision) et un "
        "<b>facteur de facilite</b> (EF, qui mesure combien cette carte "
        "est facile pour toi). En resume :"))
    f.append(bullets([
        "Quand tu reponds <b>Facile</b>, l'EF augmente et l'intervalle "
        "s'allonge plus vite.",
        "Quand tu reponds <b>Correct</b>, l'EF reste stable et "
        "l'intervalle grandit normalement.",
        "Quand tu reponds <b>Difficile</b>, l'EF baisse legerement et "
        "l'intervalle grandit lentement.",
        "Quand tu reponds <b>Oublie</b>, l'EF baisse fortement et "
        "l'intervalle est remis a 1 jour.",
    ]))
    f.append(note_box(
        "Formule SM-2 (pour les curieux) : EF' = EF + (0,1 - (5-q) x "
        "(0,08 + (5-q) x 0,02)), avec q entre 0 (oublie) et 5 (facile). "
        "L'EF est planche a 1,3 pour eviter qu'une carte ne devienne "
        "impossible a revoir."))
    f.append(sub_header("3.5 - Conseils pour bien s'auto-evaluer"))
    f.append(numbered([
        "<b>Sois honnete avec toi-meme.</b> Si tu triches en cliquant "
        "<b>Facile</b> alors que tu hesitais, l'IA pensera que tu "
        "maitrises et ne te reposera pas la question assez tot. Tu "
        "perdras en revision ce que tu as gagne en ego.",
        "<b>La reponse incomplete = Difficile.</b> Si tu as oublie la "
        "moitie de la reponse, ce n'est pas <b>Correct</b>, c'est "
        "<b>Difficile</b> ou <b>Oublie</b>.",
        "<b>La reponse juste mais lente = Correct.</b> La vitesse "
        "compte a l'examen : si tu mets 2 minutes pour retrouver une "
        "formule, c'est <b>Correct</b> pas <b>Facile</b>.",
        "<b>Ne clique jamais <b>Facile</b> sur une carte que tu vois "
        "pour la premiere fois.</b> Meme si c'etait facile, le systeme "
        "a besoin de te la reproposer au moins une fois pour la "
        "consolider.",
    ]))
    f.append(sub_header("3.6 - Le bouton Passer"))
    f.append(P(
        "Le bouton <b>Passer</b> permet de sauter une carte sans "
        "l'evaluer. Utilise-le dans 3 cas seulement :"))
    f.append(bullets([
        "Tu as un <b>urgence</b> (appel telephonique, etc.) et tu dois "
        "quitter la session immediatement.",
        "La carte est <b>mal formulee</b> ou la reponse est fausse. "
        "Signale le bug ensuite via Support > Signaler un bug.",
        "Tu as <b>deja revise cette carte 5 fois aujourd'hui</b> et tu "
        "veux varier (cas rare, l'IA evite normalement de te la "
        "reproposer).",
    ]))
    f.append(warning_box(
        "Ne clique pas <b>Passer</b> parce que la carte est difficile. "
        "C'est precisement celle-la qu'il faut travailler. Cliquer "
        "<b>Passer</b> au lieu de <b>Oublie</b> ne fait pas progresser "
        "l'IA, et tu te retrouveras a la reviser dans 6 mois au lieu de "
        "demain."))
    return f


def _student_section_4_simulation():
    f = section_header("4", "Simuler un examen",
                       eyebrow="Chapitre 4 - Mise en condition reelle")
    f.append(P(
        "La simulation est differente de la revision. Elle te met dans "
        "les <b>conditions reelles de l'examen</b> : temps limite, "
        "navigation entre questions, possibilite de marquer pour revoir, "
        "et un rapport detaille a la fin. Faire une simulation par "
        "semaine a l'approche de l'examen est le meilleur moyen de "
        "gestion du stress et du temps."))
    f.append(sub_header("4.1 - Configurer une simulation"))
    f.append(P(
        "Depuis l'accueil, touche <b>Simulation d'examen</b>. Tu "
        "choisis :"))
    f.append(bullets([
        "<b>Examen cible</b> : BEPC, BAC serie C, ou BAC serie D.",
        "<b>Matiere</b> : Maths, Francais, Sciences Physiques, SVT, "
        "Histoire-Geographie, Anglais.",
        "<b>Nombre de questions</b> : 10 (rapide, 15 min), 20 (standard, "
        "30 min), ou 40 (complet, 1h).",
        "<b>Duree</b> : auto-calcullee d'apres le nombre de questions "
        "(reglement BEPC : 2 min/question, BAC : 3 min/question).",
    ]))
    f.append(tip_box(
        "Avant l'examen officiel, fais au moins <b>3 simulations completes</b> "
        "dans la matiere ou tu te sens le moins confiant. Tu apprendras "
        "a gerer ton temps, identifier les questions a sauter pour y "
        "revenir, et eviter le piege de la question-puzzle qui te fait "
        "perdre 10 minutes."))
    f.append(sub_header("4.2 - Pendant l'examen"))
    f.append(P(
        "Une fois la simulation lancee, tu vois :"))
    f.append(bullets([
        "Un <b>minuteur</b> en haut qui decompte le temps restant. Il "
        "passe en rouge dans les 5 dernieres minutes.",
        "Une <b>barre de progression</b> qui indique Question X / Y.",
        "La <b>question</b> au centre, avec ses 4 options (QCM) ou un "
        "champ de saisie (reponse ouverte).",
        "Un bouton <b>Marquer pour revoir</b> : pose un drapeau sur la "
        "question, tu pourras y revenir a la fin si tu as le temps.",
        "Un bouton <b>Suivant</b> et un bouton <b>Precedent</b> pour "
        "naviguer entre les questions.",
    ]))
    f.append(figure(ScreenshotPlaceholder(label="Ecran de simulation"),
                    "Figure 4.1 - Ecran de simulation d'examen, "
                    "minuteur en haut (placeholder)."))
    f.append(sub_header("4.3 - Le rapport de fin"))
    f.append(P(
        "A la fin du temps (ou quand tu touche <b>Terminer</b>), "
        "ExamBoost affiche un rapport detaille :"))
    f.append(bullets([
        "<b>Score global</b> : ex. 14 / 20 (70 %).",
        "<b>Score par chapitre</b> : ex. Pythagore 4/5, Thales 1/3, "
        "Equations 4/4, etc.",
        "<b>Temps moyen par question</b> : compare avec le temps "
        "reglementaire.",
        "<b>Questions ratees</b> : listees avec la correction detaillee.",
        "<b>Recommandations</b> : ExamBoost te propose une session de "
        "revision ciblee sur tes chapitres faibles (ex. : \"Revois "
        "Thales en priorite\").",
    ]))
    f.append(sub_header("4.4 - Difference entre simulation et revision"))
    f.append(make_table(
        ["Critere", "Revision adaptative", "Simulation d'examen"],
        [
            ["Duree", "Variable (15 min recommandees)", "Fixe (10 a 60 min)"],
            ["Selection des questions", "IA (SM-2 + IRT)", "Aleatoire "
             "dans la banque de l'examen"],
            ["Ordre des questions", "Adapte a ton niveau", "Ordre "
             "d'examen (souvent par chapitre)"],
            ["Minute", "Non", "Oui"],
            ["Feedback", "Apres chaque carte", "A la fin seulement"],
            ["Effet BKT", "Oui", "Oui (renforce)"],
            ["Effet SM-2", "Oui", "Non"],
        ],
        col_widths=[3.0 * cm, 6.0 * cm, CONTENT_W - 9.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("4.5 - Cadence recommandee"))
    f.append(P(
        "La simulation a le plus de valeur dans les <b>2 mois avant "
        "l'examen</b>. Cadence recommandee :"))
    f.append(bullets([
        "<b>6 a 8 semaines avant</b> : 1 simulation complete par semaine, "
        "dans une matiere differente.",
        "<b>4 semaines avant</b> : 2 simulations par semaine, "
        "priorite sur tes matieres faibles.",
        "<b>1 semaine avant</b> : 1 simulation complete en conditions "
        "reelles (pas de pause, telephone en mode avion).",
        "<b>La veille</b> : <b>pas de simulation</b>. Repose-toi. Voir "
        "section 10 - Conseils pour reussir.",
    ]))
    return f


def _student_section_5_progression():
    f = section_header("5", "Suivre ta progression",
                       eyebrow="Chapitre 5 - Tableau de bord & stats")
    f.append(P(
        "Le tableau de bord est ton centre de controle. Il te montre "
        "ou tu en es, ce que tu maitrises, ce qui te manque, et une "
        "prediction de ton score BEPC/BAC. Tu y accedes depuis l'accueil "
        "en touchant <b>Ma progression</b>."))
    f.append(sub_header("5.1 - Le tableau de bord"))
    f.append(P(
        "En haut de l'ecran, 3 chiffres cles :"))
    f.append(make_table(
        ["Indicateur", "Ce qu'il mesure", "Cible saine"],
        [
            ["Score global", "Moyenne ponderee de tes P(L) par chapitre, "
             "toutes matieres confondues.", ">= 70 % a 1 mois de l'examen"],
            ["Prediction BEPC/BAC", "Estimation de ta note finale basee "
             "sur BKT + historique de simulations.", ">= 12/20 dans ta "
             "matiere cible"],
            ["Streak", "Nombre de jours consecutifs ou tu as fait au "
             "moins 1 revision.", ">= 30 jours pour ancrer la habitude"],
        ],
        col_widths=[3.5 * cm, 6.0 * cm, CONTENT_W - 9.5 * cm]))
    f.append(Spacer(1, 4))
    f.append(figure(ScreenshotPlaceholder(label="Tableau de bord"),
                    "Figure 5.1 - Tableau de bord avec score global, "
                    "prediction et streak (placeholder)."))
    f.append(sub_header("5.2 - Carte de chaleur des chapitres faibles"))
    f.append(P(
        "Sous les chiffres cles se trouve une <b>carte de chaleur</b> "
        "(heatmap) qui affiche tous tes chapitres en couleurs :"))
    f.append(bullets([
        "<b>Rouge</b> : P(L) < 0,5 - chaptre non maitrise, a reviser en "
        "priorite.",
        "<b>Orange</b> : 0,5 <= P(L) < 0,75 - chapitre fragile, "
        "a consolider.",
        "<b>Jaune</b> : 0,75 <= P(L) < 0,85 - chapitre en cours "
        "d'acquisition.",
        "<b>Vert</b> : P(L) >= 0,85 - chapitre maitrise. Tu peux le "
        "mettre en pause.",
    ]))
    f.append(tip_box(
        "Clique sur un chapitre rouge pour lancer une session de "
        "revision ciblee dessus. ExamBoost te proposera en priorite "
        "les cartes de ce chapitre que tu as ratees ou oubliees "
        "recemment."))
    f.append(sub_header("5.3 - Statistiques SRS (repetition espacee)"))
    f.append(P(
        "Une section du dashboard est dediee a tes flashcards :"))
    f.append(bullets([
        "<b>Cartes dues aujourd'hui</b> : nombre de cartes que SM-2 a "
        "planifiees pour aujourd'hui. C'est ton objectif quotidien.",
        "<b>Cartes maitrisees</b> : cartes dont l'intervalle est "
        ">= 21 jours (proche de la consolidation long terme).",
        "<b>Cartes en apprentissage</b> : cartes nouvelles ou "
        "recemment oubliees, encore en phase d'acquisition.",
        "<b>Taux de reussite 7 jours</b> : % de cartes repondues "
        "Correct/Facile sur les 7 derniers jours.",
    ]))
    f.append(sub_header("5.4 - Activite 7 derniers jours"))
    f.append(P(
        "Un mini-graphique en barres montre combien de cartes tu as "
        "revues chaque jour de la semaine ecoulee. L'objectif est "
        "<b>au moins 1 carte par jour</b> pour maintenir ton streak et "
        "ne pas perdre les gains de la repetition espacee."))
    f.append(warning_box(
        "Si tu arretes de reviser pendant 3 jours, les cartes "
        "continuent a s'accumuler. Au retour, tu auras peut-etre 80 "
        "cartes dues. Ne panique pas : fais-en 15 aujourd'hui, 25 "
        "demain, etc. Ne cherche pas a tout rattraper en une seule "
        "seance : tu risques le decouragement."))
    f.append(sub_header("5.5 - Comment interpreter P(L)"))
    f.append(P(
        "P(L) (probability of mastery, ou <b>probabilite de maitrise</b>) "
        "est le chiffre cle du BKT. Pour chaque chapitre, ExamBoost "
        "calcule une probabilite entre 0 et 1 que tu maitrises ce "
        "chapitre."))
    f.append(make_table(
        ["P(L)", "Interpretation", "Action recommandee"],
        [
            ["0,00 - 0,49", "Pas encore maitrise", "Revoir le cours, "
             "puis faire 1 session de revision ciblee."],
            ["0,50 - 0,74", "En cours d'acquisition", "Continuer les "
             "flashcards quotidiennes."],
            ["0,75 - 0,84", "Bientot maitrise", "1 simulation ciblee "
             "dans la semaine."],
            [">= 0,85", "Maitrise", "Carte en pause. Revoir dans 30 "
             "jours pour consolider."],
        ],
        col_widths=[2.8 * cm, 4.5 * cm, CONTENT_W - 7.3 * cm]))
    f.append(Spacer(1, 4))
    f.append(note_box(
        "P(L) est une probabilite, pas une certitude. Meme avec P(L) = "
        "0,95, tu peux rater une question a l'examen (fatigue, stress, "
        "question piege). P(L) = 0,85 est le seuil ou ExamBoost considere "
        "que tu es suffisamment confiant pour passer a un autre chapitre."))
    return f


def _student_section_6_tutor():
    f = section_header("6", "Le tuteur IA : ton assistant perso",
                       eyebrow="Chapitre 6 - Aide en langage naturel")
    f.append(P(
        "Le tuteur IA est un assistant conversationnel integre a "
        "ExamBoost. Tu lui poses une question en francais, il te "
        "guide. Il ne <b>donne pas</b> la reponse toute cuite : il "
        "applique la <b>methode socratique</b> (te pose des questions "
        "en retour) pour te faire arriver a la reponse par toi-meme. "
        "C'est la meilleure facon d'apprendre."))
    f.append(sub_header("Comment poser une question"))
    f.append(bullets([
        "Depuis l'accueil, touche l'icone <b>Tuteur IA</b> (forme de "
        "cerveau orange).",
        "Saisis ta question en francais dans la barre de saisie.",
        "Touche <b>Envoyer</b>. Le tuteur repond en quelques secondes.",
        "Tu peux continuer la conversation (le tuteur garde le "
        "contexte de la session).",
    ]))
    f.append(sub_header("Exemples de questions que tu peux poser"))
    f.append(example_box(
        "<b>Maths</b> : &laquo; Explique-moi Pythagore &raquo;.<br/>"
        "<b>Francais</b> : &laquo; Quelle est la difference entre "
        "metaphore et comparaison ? &raquo;.<br/>"
        "<b>Physique</b> : &laquo; Comment on calcule une resistance "
        "avec la loi d'Ohm ? &raquo;.<br/>"
        "<b>SVT</b> : &laquo; C'est quoi la photosynthese ? &raquo;."
    ))
    f.append(sub_header("Ce que le tuteur fait et ne fait pas"))
    f.append(make_table(
        ["Le tuteur IA...", ""],
        [
            ["T'explique un concept dans tes propres mots", "Ne te donne "
             "pas la reponse a un exercice noté"],
            ["Te pose des questions pour verifier ta comprehension", "Ne "
             "remplace pas ton enseignant"],
            ["Te donne des exemples supplementaires", "Ne corrige pas "
             "tes devoirs a ta place"],
            ["Sauvegarde l'historique de tes conversations", "Ne "
             "fonctionne pas hors-ligne (necessite Internet)"],
        ],
        col_widths=[7.5 * cm, CONTENT_W - 7.5 * cm]))
    f.append(Spacer(1, 4))
    f.append(warning_box(
        "Le tuteur IA necessite une connexion Internet. Si tu es "
        "hors-ligne, tu peux toujours faire tes flashcards et "
        "simulations, mais pas discuter avec le tuteur. Planifie tes "
        "sessions de tuteur quand tu as du data ou quand tu es au "
        "cybercafe."))
    return f


def _student_section_7_badges():
    f = section_header("7", "Badges et recompenses",
                       eyebrow="Chapitre 7 - Motivation & gamification")
    f.append(P(
        "ExamBoost compte <b>39 badges</b> deblocables. Ils sont repartis "
        "en 5 categories et existent en 3 niveaux (Bronze, Argent, Or). "
        "L'objectif n'est pas de tous les avoir, mais de te donner des "
        "objectifs concrets et de celebrer tes progres."))
    f.append(sub_header("Les 5 categories de badges"))
    f.append(make_table(
        ["Categorie", "Exemples de badges", "Recompense"],
        [
            ["Streak", "7 jours, 30 jours, 100 jours consecutifs", "XP "
             "+ titre affiche sur ton profil"],
            ["Revision", "100 cartes, 1 000 cartes, 10 000 cartes "
             "revues", "XP + deblocage de themes"],
            ["Maitrise", "1er chapitre maitrise, tous les chapitres "
             "d'une matiere", "XP + badge special sur le dashboard"],
            ["Simulation", "1 simulation complete, 10 simulations, "
             "score >= 16/20", "XP + bonus prediction"],
            ["Special", "Premier jour, parrainage d'un ami, retour "
             "apres une pause", "XP + surprise"],
        ],
        col_widths=[2.8 * cm, 7.0 * cm, CONTENT_W - 9.8 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("XP et niveaux"))
    f.append(P(
        "Chaque action (revision, simulation, badge debloque) te donne "
        "de l'<b>XP</b> (experience). Les XP s'accumulent pour te faire "
        "monter de <b>niveau</b> : niveau 1 a 100. Plus tu montes, "
        "plus l'avatar de ton profil evolue."))
    f.append(sub_header("Animation de deblocage"))
    f.append(P(
        "Quand tu debloques un badge, une animation se lance en plein "
        "ecran pendant 3 secondes : le badge tournoie, des confettis "
        "apparaissent, et tu peux choisir de <b>partager</b> sur "
        "WhatsApp."))
    f.append(tip_box(
        "Partager ton badge sur WhatsApp peut motiver tes camarades a "
        "se mettre aussi a ExamBoost. Plus vous etes a utiliser l'app "
        "dans ta classe, plus le classement etablissement est anime."))
    f.append(sub_header("Badges caches"))
    f.append(P(
        "Certains badges sont <b>caches</b> : tu decouvres leur "
        "existence seulement quand tu les debloques. Surveille les "
        "animations de deblocage pour ne pas les manquer."))
    return f


def _student_section_8_community():
    f = section_header("8", "Communaute ExamBoost",
                       eyebrow="Chapitre 8 - Reviser ensemble")
    f.append(P(
        "Reviser seul est difficile. ExamBoost integre des outils "
        "communautaires pour te permettre de progresser avec d'autres "
        "eleves : classements, defis hebdomadaires, et un forum "
        "d'entraide."))
    f.append(sub_header("Classements"))
    f.append(P(
        "Tu peux comparer ton XP a celle d'autres eleves sur 3 niveaux :"))
    f.append(bullets([
        "<b>Classement national</b> : tous les eleves ExamBoost Togo.",
        "<b>Classement regional</b> : eleves de ta region (Maritime, "
        "Plateaux, Centrale, Kara, Savanes).",
        "<b>Classement etablissement</b> : eleves de ton ecole (si ton "
        "etablissement est inscrit en B2B).",
    ]))
    f.append(sub_header("Defis hebdomadaires"))
    f.append(P(
        "Chaque lundi, ExamBoost lance un <b>defi hebdomadaire</b>. "
        "Exemples : reviser 50 cartes en maths, faire 3 simulations "
        "dans la semaine, obtenir un streak de 7 jours. Les eleves qui "
        "relevent le defi gagnent un badge et un bonus d'XP."))
    f.append(sub_header("Forum d'entraide"))
    f.append(P(
        "Le forum te permet de poser des questions aux autres eleves "
        "ExamBoost. Tu peux aussi repondre aux questions des autres : "
        "expliquer un concept est l'une des meilleures facons de le "
        "consolider dans ta propre memoire."))
    f.append(make_table(
        ["Bonne pratique", "Mauvaise pratique"],
        [
            ["Poser une question claire, avec le contexte (ex. : "
             "niveau, chapitre).", "Demander la reponse directe a un "
             "exercice sans avoir cherche."],
            ["Remercier ceux qui t'aident.", "Insulter ou se moquer "
             "d'un camarade qui s'est trompe."],
            ["Partager une methode qui marche pour toi.", "Faire du "
             "spam ou de la publicite pour d'autres apps."],
            ["Signaler un comportement inapproprie.", "Repondre a une "
             "provocation (utilise plutot Signaler)."],
        ],
        col_widths=[CONTENT_W / 2.0, CONTENT_W / 2.0]))
    f.append(Spacer(1, 4))
    f.append(warning_box(
        "Les regles de la communaute sont strictes : tout propos "
        "raciste, sexiste, insultant ou publicitaire entraine un "
        "bannissement immediat sans avertissement. ExamBoost est un "
        "espace de travail, pas un reseau social de detente."))
    return f


def _student_section_9_settings():
    f = section_header("9", "Parametres et personnalisation",
                       eyebrow="Chapitre 9 - Adapter l'app a toi")
    f.append(P(
        "L'ecran <b>Parametres</b> te permet d'adapter ExamBoost a tes "
        "preferences. Voici les principaux reglages."))
    f.append(sub_header("Langue"))
    f.append(P(
        "Choisis entre <b>Francais</b> (par defaut) et <b>Anglais</b>. "
        "Le contenu des questions reste en francais (langue de "
        "l'examen), mais l'interface et les explications basculent."))
    f.append(sub_header("Theme"))
    f.append(P(
        "3 options : <b>Clair</b> (par defaut), <b>Sombre</b> (economise "
        "la batterie sur ecran OLED, agressif moins pour les yeux le "
        "soir), <b>Systeme</b> (suit le reglage de ton telephone)."))
    f.append(sub_header("Notifications"))
    f.append(bullets([
        "<b>Rappel quotidien</b> : heure a laquelle ExamBoost t'envoie "
        "une notification (par defaut 19h00).",
        "<b>Rappel streak</b> : notification si tu n'as pas revise et "
        "qu'il est 21h00 (1h avant minuit pour sauver ton streak).",
        "<b>Notifications sociales</b> : quelqu'un t'a repondu sur le "
        "forum, tu as ete depasse au classement, etc.",
    ]))
    f.append(sub_header("Lecture audio (TTS)"))
    f.append(P(
        "Tu peux activer la <b>lecture audio</b> des flashcards. Utile "
        "si tu prefers reviser en marchant, dans les transports, ou si "
        "tu as une difficulte visuelle. Le TTS utilise la voix Android "
        "installee sur ton telephone."))
    f.append(sub_header("Accessibilite"))
    f.append(P(
        "ExamBoost propose 3 options d'accessibilite :"))
    f.append(bullets([
        "<b>Police dyslexie</b> : utilise une police adaptee aux "
        "eleves dyslexiques (OpenDyslexic).",
        "<b>Contraste eleve</b> : augmente le contraste des textes et "
        "boutons pour les malvoyants.",
        "<b>Temps +25 %</b> : ajoute 25 % de temps supplementaire aux "
        "simulations (equivalent du tiers-temps officiel).",
    ]))
    f.append(sub_header("Export des donnees"))
    f.append(P(
        "Tu peux <b>exporter</b> toutes tes donnees (profil, "
        "progression, historique de revisions) en un fichier JSON ou "
        "CSV. Utile pour :"))
    f.append(bullets([
        "Sauvegarder ta progression avant de changer de telephone.",
        "Partager tes stats avec un enseignant ou un parent.",
        "Analyser tes donnees toi-meme (par exemple dans Excel).",
    ]))
    f.append(sub_header("Reinitialiser le compte"))
    f.append(warning_box(
        "Le bouton <b>Reinitialiser le compte</b> efface definitivement "
        "ton profil, ta progression, tes badges, et ton historique. "
        "Cette action est <b>irreversible</b>. A utiliser seulement si "
        "tu veux repartir de zero (changement de niveau, par exemple). "
        "Pense a exporter tes donnees avant."))
    return f


def _student_section_10_conseils():
    f = section_header("10", "Conseils pour reussir",
                       eyebrow="Chapitre 10 - Methodologie")
    f.append(P(
        "ExamBoost est un outil. Son efficacite depend de la maniere "
        "dont tu l'utilises. Voici 8 regles d'or issues de la recherche "
        "en sciences cognitives et validees par les pilotes EduTech en "
        "Afrique de l'Ouest."))
    f.append(sub_header("Regle 1 - La regle des 15 minutes"))
    f.append(P(
        "<b>15 minutes par jour valent mieux que 2 heures le dimanche.</b> "
        "La repetition espacee fonctionne mieux avec des sessions "
        "courtes et frequentes qu'avec des sessions longues et rares. "
        "Ton cerveau consolide mieux l'information quand il la revisite "
        "plusieurs fois dans la semaine."))
    f.append(tip_box(
        "Bloque 15 minutes dans ton emploi du temps quotidien. Idéalement "
        "a heure fixe : 18h30 juste apres les cours, ou 20h00 apres le "
        "diner. Apres 30 jours, ce sera une habitude automatique."))
    f.append(sub_header("Regle 2 - La regularite bat l'intensite"))
    f.append(P(
        "Un streak de 30 jours vaut mieux que 10 sessions de 3 heures "
        "concentrees sur 1 jour. Le streak maintient l'information en "
        "memoire long terme ; l'intensite ponctuelle fait illusion de "
        "maitrise mais s'evanouit en quelques jours."))
    f.append(sub_header("Regle 3 - Auto-evaluation honnete"))
    f.append(P(
        "Ne triche pas en cliquant <b>Facile</b> pour aller plus vite. "
        "L'IA s'adapte a ton niveau <b>declare</b>. Si tu declareras "
        "facile ce qui etait difficile, l'IA te reposera la question "
        "dans 60 jours, et tu l'auras oubliee d'ici la."))
    f.append(sub_header("Regle 4 - Meler les matieres"))
    f.append(P(
        "Ne fais pas que des maths. Meme si c'est ta matiere faible, "
        "alterner les matieres (maths, francais, physique) est plus "
        "efficace que de bachoter une seule matiere. C'est ce qu'on "
        "appelle l'<b>interleaving</b> en sciences cognitives."))
    f.append(sub_header("Regle 5 - Simuler regulierement"))
    f.append(P(
        "1 simulation complete par semaine a l'approche de l'examen. "
        "La simulation teste ta capacite a mobiliser tes connaissances "
        "sous pression et en temps limite - ce que la revision "
        "adaptative ne fait pas."))
    f.append(sub_header("Regle 6 - Utiliser le tuteur IA"))
    f.append(P(
        "Poser des questions au tuteur est <b>gratuit</b>. Ne t'en "
        "prive pas. Quand tu bloques sur un concept, demande-lui une "
        "explication. Si tu n'as pas de data, note ta question sur un "
        "papier et pose-la au cybercafe le lendemain."))
    f.append(sub_header("Regle 7 - Revoir ses erreurs"))
    f.append(P(
        "Les questions ratees reviennent <b>automatiquement</b> dans "
        "tes sessions futures, grace au BKT. Ne les fuis pas. Quand "
        "une carte revient, c'est que tu en as besoin : prends le temps "
        "de comprendre pourquoi tu t'es trompe."))
    f.append(sub_header("Reglement 8 - Pas le jour de l'examen"))
    f.append(warning_box(
        "Arrete ExamBoost <b>24 heures avant</b> l'examen. Le cerveau "
        "a besoin de sommeil pour consolider ce que tu as appris. "
        "Faire 200 cartes la veille ne fera qu'augmenter ton stress et "
        "diminuer ta concentration. Le matin de l'examen : bon petit "
        "dejeuner, 2 verres d'eau, et n'y touche plus."))
    f.append(sub_header("Tableau recapitulatif"))
    f.append(make_table(
        ["Quand", "Action recommandee", "A eviter"],
        [
            ["Quotidien", "15 min de revision adaptative", "Sessions "
             "de 2 h une fois par semaine"],
            ["Hebdomadaire", "1 simulation complete + analyse du "
             "rapport", "Faire que des flashcards sans jamais se "
             "tester"],
            ["Mensuel", "Export des donnees + revue du dashboard",
             "Laisser les chapitres rouges s'accumuler"],
            ["6 sem. avant examen", "2 simulations / semaine",
             "Decouvrir des chapitres non maitrises 1 sem. avant"],
            ["La veille de l'examen", "Repos, sommeil 8 h", "Derniere "
             "session de revision nocturne"],
        ],
        col_widths=[3.5 * cm, 6.0 * cm, CONTENT_W - 9.5 * cm]))
    f.append(Spacer(1, 4))
    return f


def _student_section_11_faq():
    f = section_header("11", "FAQ - Questions frequentes",
                       eyebrow="Chapitre 11 - Tout savoir")
    f.append(P(
        "Les 8 questions les plus posees par les eleves testeurs du "
        "pilote Lome. Si ta question n'est pas listee, ecris-nous a "
        "support@examboost.tg (voir chapitre 12)."))
    f.append(faq_item(
        "L'application consomme beaucoup de data ?",
        "Non. ExamBoost est <b>offline-first</b> : apres la premiere "
        "installation, tu n'as plus besoin d'Internet pour reviser. La "
        "synchro (upload de ta progression, download de nouvelles "
        "questions) represente moins de 2 Mo par mois en usage normal. "
        "Le tuteur IA consomme un peu plus (environ 50 Ko par question)."))
    f.append(faq_item(
        "Ca marche sur mon vieux telephone ?",
        "Oui. ExamBoost fonctionne sur <b>Android 5.0+</b> (sorti en "
        "2014). L'APK fait moins de 25 Mo. L'app est testee sur Tecno "
        "Spark, Itel A-series, Infinix Hot - les modeles les plus "
        "repandus au Togo. Si tu as un telephone avec 1 Go de RAM, "
        "c'est suffisant."))
    f.append(faq_item(
        "Je peux l'utiliser sans Internet ?",
        "Oui, sauf 3 fonctionnalites qui necessitent Internet : (1) le "
        "tuteur IA, (2) le classement national et le forum, (3) les "
        "mises a jour de la banque de questions. Tout le reste "
        "(revision, simulation, dashboard, badges) marche 100 % "
        "hors-ligne."))
    f.append(faq_item(
        "Mes donnees sont-elles protegees ?",
        "Oui. ExamBoost ne vend jamais tes donnees. Ton profil est "
        "anonyme par defaut (pseudo). Les donnees de progression sont "
        "chiffrees (HTTPS) et stockees sur des serveurs a Abidjan "
        "(Cote d'Ivoire) chez un hebergeur RGPD-conforme. Tu peux "
        "exporter et supprimer tes donnees a tout moment dans "
        "Parametres."))
    f.append(faq_item(
        "C'est vraiment gratuit ?",
        "<b>Oui</b>, 100 % gratuit pour l'eleve, pour toujours. "
        "ExamBoost est finance par les licences etabissements (100 000 "
        "FCFA/an pour une ecole), des subventions (UNICEF, GPE, AFD) "
        "et un abonnement premium <b>optionnel</b> a 2 000 FCFA/mois "
        "(supprime la pub, debloque des themes, support prioritaire). "
        "Tu peux utiliser l'app sans jamais payer."))
    f.append(faq_item(
        "Comment vous gagnez de l'argent ?",
        "3 sources principales : (1) licences etabissements B2B, (2) "
        "premium eleve optionnel (5 % des eleves choisissent de prendre "
        "premium), (3) subventions et partenariats. Notre seuil de "
        "rentabilite est de 300 ecoles partenaires, atteignable en fin "
        "d'annee 2."))
    f.append(faq_item(
        "Puis-je utiliser ExamBoost si je ne suis pas togolais ?",
        "Oui, mais le contenu est aligne sur le programme togolais "
        "(MEPST). Les eleves du Benin, de Cote d'Ivoire, du Burkina Faso "
        "trouveront que 80 % du programme est commun. L'expansion "
        "CEDEAO est prevue a partir de l'annee 3 (2028), avec des "
        "versions locales par pays."))
    f.append(faq_item(
        "Je change de telephone, je perds ma progression ?",
        "<b>Non</b>, si tu as active la synchronisation cloud "
        "(Parametres > Compte > Sync cloud). Sinon, utilise Export "
        "donnees > Fichier JSON, envoie-le a toi-meme sur WhatsApp ou "
        "email, et importe-le sur le nouveau telephone."))
    return f


def _student_section_12_support():
    f = section_header("12", "Support et contact",
                       eyebrow="Chapitre 12 - On est la pour toi")
    f.append(P(
        "Un bug ? Une question ? Une idee ? L'equipe ExamBoost te "
        "repond en moins de 48 h (jours ouvres)."))
    f.append(sub_header("Email support"))
    f.append(P(
        "<b>support@examboost.tg</b><br/>"
        "Reponse sous 48 h ouvre. Decris ton probleme avec : "
        "(1) ton telephone (modele + Android), (2) la version d'ExamBoost "
        "(visible dans Parametres > A propos), (3) une capture d'ecran "
        "si possible."))
    f.append(sub_header("WhatsApp support"))
    f.append(P(
        "<b>+228 90 00 00 00</b> (numero pilote - sera confirme au "
        "lancement officiel)<br/>"
        "Reponse entre 9h et 18h, du lundi au vendredi. Idéal pour les "
        "questions rapides. Ne pas appeler - WhatsApp uniquement."))
    f.append(sub_header("Signaler un bug"))
    f.append(P(
        "Depuis l'app : Parametres > Aide > Signaler un bug. Un "
        "formulaire pre-rempli s'ouvre, tu ajoutes ta description, et "
        "le rapport est envoye automatiquement avec les logs techniques."))
    f.append(sub_header("Suggerer une fonctionnalite"))
    f.append(P(
        "Depuis l'app : Parametres > Aide > Suggerer une amelioration. "
        "Ou par email a <b>idees@examboost.tg</b>. Les meilleures "
        "idees sont votees par la communaute et integrees a la roadmap "
        "trimestrielle."))
    f.append(sub_header("Communautes en ligne"))
    f.append(make_table(
        ["Plateforme", "Lien", "Pour quoi"],
        [
            ["Telegram", "@ExamBoostTogo", "Annonces, mises a jour, "
             "entraide entre eleves"],
            ["Discord", "discord.gg/examboost-tg", "Discussion en "
             "temps reel, sessions de revision collectives"],
            ["Facebook", "facebook.com/ExamBoostTogo", "Photos, "
             "temoignages, evenements"],
            ["TikTok", "@examboost.tg", "Astuces examen en 30 secondes"],
            ["GitHub", "github.com/djabelo712/ExamBoost-Togo", "Code "
             "source, signalement technique de bugs"],
        ],
        col_widths=[3.0 * cm, 5.5 * cm, CONTENT_W - 8.5 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("Reseaux sociaux officiels"))
    f.append(P(
        "Abonne-toi pour ne rien rater des nouveautes, defis, et "
        "sessions de revision en direct."))
    f.append(tip_box(
        "Avant de poser une question au support, verifie la FAQ "
        "(chapitre 11) et le forum communaute : 70 % des questions ont "
        "deja une reponse. Tu gagneras du temps."))
    f.append(HRFlowable(width="100%", thickness=0.5,
                        color=GRIS_BORDURE, spaceAfter=8, spaceBefore=8))
    f.append(Paragraph(
        "<i>Bon courage pour ton BEPC ou ton BAC. L'equipe ExamBoost "
        "Togo croit en toi.</i>",
        STYLES['Quote']))
    return f


# =============================================================================
# SECTIONS DU GUIDE ENSEIGNANT
# =============================================================================

def _teacher_section_1_pourquoi():
    f = section_header("1", "Pourquoi ExamBoost en classe ?",
                       eyebrow="Chapitre 1 - Contexte & benefices")
    f.append(sub_header("Le constat"))
    f.append(P(
        "Les chiffres 2024 sont alarmants : <b>44 % de reussite au "
        "BEPC</b> (contre 81 % en 2023, soit une chute de 37 points en "
        "un an) et <b>46,71 % au BAC 2</b>. 86 % des enfants togolais "
        "de 10 ans ne savent pas lire couramment (Banque Mondiale). "
        "Aucun outil numerique n'est aujourd'hui aligne sur le "
        "programme MEPST."))
    f.append(P(
        "Enquete terrain menee en juin 2026 a Lome sur 30 eleves : "
        "<b>87 %</b> n'ont aucun outil numerique pour preparer les "
        "examens. <b>94 %</b> declarent qu'ils utiliseraient ExamBoost "
        "des aujourd'hui. La demande est la. L'offre n'existait pas "
        "encore."))
    f.append(sub_header("Comment ExamBoost complete votre enseignement"))
    f.append(P(
        "ExamBoost ne remplace pas le professeur. Il <b>complete</b> "
        "votre enseignement en couvrant les fonctions que vous n'avez "
        "pas le temps d'assurer en classe :"))
    f.append(make_table(
        ["Fonction pedagogique", "En classe (vous)", "ExamBoost (complement)"],
        [
            ["Presentation du cours", "Oui", "Non (hors perimetre)"],
            ["Exercices d'application", "Oui (limites par le temps)",
             "Oui - illimites, adaptatifs"],
            ["Suivi individuel des eleves", "Difficile (>50 eleves/classe)",
             "Oui - dashboard individuel"],
            ["Identification des lacunes", "Aux controles (trop tard)",
             "En temps reel (BKT)"],
            ["Revisions a la maison", "Devoirs classiques", "Revision "
             "adaptee SM-2 + tuteur IA"],
            ["Mise en condition examen", "1 fois par trimestre",
             "Illimite, chaque semaine"],
            ["Detection du decrochage", "Souvent trop tard",
             "Alerte automatique des 1ers signaux"],
        ],
        col_widths=[4.0 * cm, 5.0 * cm, CONTENT_W - 9.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("Cas d'usage typiques en etablissement"))
    f.append(bullets([
        "<b>Devoirs a la maison</b> : vous assignez une serie de 20 "
        "questions a faire pour le lendemain. ExamBoost recupere les "
        "resultats et vous genere un rapport agrège.",
        "<b>Revisions guidees</b> : en fin de chapitre, vous activez "
        "le mode revision ciblee sur les chapitres fraichement vus. "
        "L'IA propose les cartes adaptees a chaque eleve.",
        "<b>Simulation blanc</b> : 1 simulation complete en classe, "
        "chronometree, conditions reelles. Le rapport vous arrive en "
        "5 minutes.",
        "<b>Remediation</b> : pour les eleves en difficulte, vous "
        "activez le tuteur IA qui les guide individuellement pendant "
        "que vous etes avec les autres.",
    ]))
    f.append(sub_header("Benefices pour l'enseignant"))
    f.append(P(
        "ExamBoost vous fait gagner du temps et vous donne une visibilite "
        "que vous n'aviez pas avant :"))
    f.append(numbered([
        "<b>Suivi agrége</b> : 1 dashboard pour toute la classe, plus "
        "besoin de compiler les notes a la main.",
        "<b>Alertes decrochage</b> : notification quand un eleve n'a "
        "pas revise depuis 5 jours, ou que son P(L) chute sur un "
        "chapitre cle.",
        "<b>Rapports trimestriels automatiques</b> : export PDF en 1 "
        "clic, pret pour le conseil de classe.",
        "<b>Comparaison inter-classes</b> : comparez les performances "
        "de vos classes, identifiez les sujets qui posent probleme a "
        "tous.",
        "<b>Donnees pour le pilotage</b> : stats mensuelles pour la "
        "direction, valorisation de votre etablissement aupres des "
        "parents.",
    ]))
    f.append(tip_box(
        "ExamBoost est <b>gratuit pour l'eleve</b>. L'etablissement "
        "paie une licence annuelle de 100 000 FCFA (public) a 150 000 "
        "FCFA (prive), soit environ 200 FCFA/eleve/an pour une classe "
        "de 50. Moins qu'un cahier d'exercices."))
    return f


def _teacher_section_2_b2b():
    f = section_header("2", "Creer un compte etablissement",
                       eyebrow="Chapitre 2 - Inscription B2B")
    f.append(P(
        "Le compte etablissement est le compte central qui vous permet "
        "de gerer les enseignants, les eleves, les classes et les "
        "licences. Il est obligatoire pour activer le module classe "
        "temps reel et le dashboard enseignant."))
    f.append(sub_header("2.1 - Inscription"))
    f.append(numbered([
        "Allez sur <b>etablissements.examboost.tg/inscription</b>.",
        "Remplissez le formulaire : nom de l'etablissement, ville, "
        "statut (public/prive), effectif total, nom du directeur, "
        "email et telephone de contact.",
        "Telechargez un document officiel (arrete de creation, "
        "agrément MEPST, ou letterhead de l'etablissement).",
        "Soumettez. Notre equipe verifie le dossier sous 48 h et vous "
        "envoie un identifiant + mot de passe par email.",
    ]))
    f.append(sub_header("2.2 - Configuration initiale"))
    f.append(P(
        "Apres votre premiere connexion, vous arrivez sur l'assistant "
        "de configuration. Vous devez renseigner :"))
    f.append(make_table(
        ["Element", "Format", "Exemple"],
        [
            ["Classes", "Une par ligne, niveau + indice", "3e A, 3e B, "
             "1ere C, Tle D"],
            ["Matieres par classe", "Case a cocher par matiere",
             "3e A : Maths, Francais, Physique, SVT, HG, Anglais"],
            ["Enseignants", "Nom, email, matiere, classes assignees",
             "M. ADJEWA - maths - 3e A, 3e B"],
            ["Effectif par classe", "Entier", "3e A : 52 eleves"],
            ["Annee scolaire", "AAAA-AAAA", "2026-2027"],
        ],
        col_widths=[3.5 * cm, 5.5 * cm, CONTENT_W - 9.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("2.3 - Ajouter des enseignants"))
    f.append(P(
        "Chaque enseignant a son propre compte, lie a l'etablissement. "
        "Pour ajouter un enseignant :"))
    f.append(bullets([
        "Allez dans <b>Gestion > Enseignants > Ajouter</b>.",
        "Saisissez son nom, son email et les classes/matières qu'il "
        "intervient.",
        "L'enseignant recoit un email avec son identifiant et un mot "
        "de passe temporaire.",
        "A sa premiere connexion, il doit changer son mot de passe.",
    ]))
    f.append(sub_header("2.4 - Import des eleves (CSV)"))
    f.append(P(
        "L'import des eleves se fait via un fichier CSV. Vous pouvez "
        "le telecharger depuis l'interface (<b>Modele CSV</b>) ou le "
        "creer dans Excel. Format attendu :"))
    f.append(make_table(
        ["Colonne", "Description", "Exemple"],
        [
            ["nom", "Nom complet de l'eleve", "ADJO Komlan"],
            ["classe", "Code classe", "3e A"],
            ["pseudo", "Pseudo unique ExamBoost (optionnel, genere "
             "sinon)", "adjo_komlan_3eA"],
            [" telephone", "Numero WhatsApp parent (optionnel)",
             "22890000000"],
            ["premium", "Oui/Non", "Non"],
        ],
        col_widths=[3.0 * cm, 6.0 * cm, CONTENT_W - 9.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(tip_box(
        "Pour le pilote Lome (M0-M3), l'equipe ExamBoost peut venir "
        "sur place faire l'import avec vous. Contactez votre charge "
        "de compte B2B pour planifier une visite."))
    f.append(sub_header("2.5 - Gestion des licences"))
    f.append(P(
        "Le nombre d'eleves est limite par votre licence :"))
    f.append(bullets([
        "<b>Licence Essai</b> (gratuite, 30 jours) : jusqu'a 50 eleves.",
        "<b>Licence Etablissement</b> (100 000 FCFA/an public, "
        "150 000 FCFA/an prive) : jusqu'a 1 000 eleves.",
        "<b>Licence Reseau</b> (sur devis, a partir de 500 000 FCFA/an) "
        ": multi-etablissements, 5 000+ eleves.",
    ]))
    f.append(warning_box(
        "Si vous depassez le quota, les nouveaux eleves sont en file "
        "d'attente. Les eleves existants continuent a utiliser l'app. "
        "Vous pouvez a tout moment upgrader la licence ou liberer des "
        "places (suppression d'anciens eleves)."))
    return f


def _teacher_section_3_realtime():
    f = section_header("3", "Module classe temps reel",
                       eyebrow="Chapitre 3 - Mode Kahoot-like")
    f.append(P(
        "Le module classe temps reel est une fonctionnalite qui "
        "transforme votre salle de classe en arena interactive. Vous "
        "lancez une serie de questions, les eleves repondent sur leur "
        "telephone, vous voyez les reponses en direct. Comme Kahoot, "
        "mais avec des questions BEPC/BAC et un suivi pedagogique."))
    f.append(sub_header("3.1 - Creer une session"))
    f.append(numbered([
        "Dans le dashboard enseignant, touchez <b>Nouvelle session</b>.",
        "Donnez un nom a la session (ex. : &laquo; Revision Theoreme "
        "Pythagore &raquo;).",
        "Choisissez la <b>classe</b> et la <b>matiere</b>.",
        "Selectionnez les questions : manuellement dans la banque, ou "
        "automatiquement (10 questions aleatoires sur un chapitre).",
        "Choisissez le mode : <b>live (classe)</b> ou <b>asynchrone "
        "(devoir maison)</b>.",
        "Touchez <b>Lancer la session</b>.",
    ]))
    f.append(sub_header("3.2 - Le code a 6 chiffres"))
    f.append(P(
        "Quand la session est lancee, un <b>code a 6 chiffres</b> "
        "s'affiche en gros sur votre ecran (et sur le videoprojecteur "
        "si vous en avez un). Les eleves ouvrent ExamBoost sur leur "
        "telephone, touchent <b>Rejoindre une session</b> et saisissent "
        "ce code."))
    f.append(tip_box(
        "Pour les eleves sans smartphone, vous pouvez afficher les "
        "questions au videoprojecteur et faire lever la main pour "
        "repondre (A, B, C, D). Vous saisissez ensuite les reponses "
        "manuellement dans l'interface enseignant."))
    f.append(sub_header("3.3 - Lancer une serie de questions"))
    f.append(P(
        "Une fois que tous les eleves sont connectes (un compteur "
        "s'affiche en haut), touchez <b>Demarrer</b>. La 1ere question "
        "s'affiche sur tous les telephones. Vous avez le controle :"))
    f.append(bullets([
        "<b>Temps par question</b> : reglable de 10 s a 120 s.",
        "<b>Suivant</b> : passe a la question suivante (manuel ou "
        "automatique).",
        "<b>Voir les reponses</b> : affiche en direct un camembert des "
        "reponses donnees.",
        "<b>Pause</b> : met tout en pause (pour donner une explication "
        "orale).",
    ]))
    f.append(figure(ScreenshotPlaceholder(label="Vue enseignant - Live"),
                    "Figure 3.1 - Vue enseignant en session live avec "
                    "compteur de connectes et camembert temps reel "
                    "(placeholder)."))
    f.append(sub_header("3.4 - Suivre les reponses en live"))
    f.append(P(
        "Pendant la session, vous voyez en temps reel :"))
    f.append(bullets([
        "Le <b>nombre de connectes</b> et le <b>nombre de reponses "
        "recues</b> par question.",
        "Un <b>camembert</b> avec la distribution des reponses (A/B/C/D).",
        "La <b>liste des eleves</b> qui n'ont pas encore repondu (pour "
        "relancer).",
        "La <b>bonne reponse</b> en surbrillance (apres la fermeture "
        "de la question).",
    ]))
    f.append(sub_header("3.5 - Podium final"))
    f.append(P(
        "A la fin de la session, ExamBoost affiche un <b>podium</b> "
        "avec les 3 meilleurs eleves (en fonction du score et du temps "
        "de reponse). Cette gamification motive les eleves et rend la "
        "revision collective plus engageante."))
    f.append(sub_header("3.6 - Mode devoir asynchrone"))
    f.append(P(
        "Vous pouvez aussi lancer une session <b>asynchrone</b> "
        "(devoir maison) : les eleves ont 24 h pour la completer, "
        "n'importe quand. Vous recuperez les resultats agrégés le "
        "lendemain. Idéal pour les devoirs a la maison sans paperasse."))
    f.append(warning_box(
        "Le module temps reel necessite une <b>connexion Internet</b> "
        "chez les eleves. Si votre salle n'a pas de WiFi, prevoyez un "
        "point d'acces mobile (votre telephone en hotspot) ou organisez "
        "la session pendant une heure ou les eleves ont du data."))
    return f


def _teacher_section_4_dashboard():
    f = section_header("4", "Dashboard enseignant",
                       eyebrow="Chapitre 4 - Piloter sa classe")
    f.append(P(
        "Le dashboard enseignant est votre centre de pilotage. Il "
        "regroupe en un seul ecran toutes les donnees de vos classes : "
        "performances, engagement, alertes, et rapports."))
    f.append(sub_header("4.1 - Vue agrégée par classe"))
    f.append(P(
        "En haut du dashboard, vous voyez une ligne par classe :"))
    f.append(make_table(
        ["Indicateur", "Description", "Cible saine"],
        [
            ["Taux d'activite 7 j", "% d'eleves ayant fait au moins 1 "
             "revision dans les 7 derniers jours", ">= 70 %"],
            ["Score moyen", "Moyenne du score global des eleves", ">= 60 %"],
            ["Streak moyen", "Moyenne des streaks des eleves", ">= 5 jours"],
            ["Simulations / sem", "Nombre de simulations completees "
             "dans la semaine", ">= 0,5 par eleve"],
            ["Alertes ouvertes", "Nombre d'eleves en alerte decrochage",
             "<= 10 % de la classe"],
        ],
        col_widths=[3.5 * cm, 7.0 * cm, CONTENT_W - 10.5 * cm]))
    f.append(Spacer(1, 4))
    f.append(figure(ScreenshotPlaceholder(label="Vue agrégée"),
                    "Figure 4.1 - Vue agrégée du dashboard enseignant "
                    "(placeholder)."))
    f.append(sub_header("4.2 - Performance par eleve"))
    f.append(P(
        "Cliquez sur une classe pour voir la liste de vos eleves. Pour "
        "chacun :"))
    f.append(bullets([
        "<b>Score global</b> et <b>prediction BEPC/BAC</b>.",
        "<b>Streak</b> et <b>derniere activite</b>.",
        "<b>Matieres maitrisees</b> et <b>matieres en difficulte</b>.",
        "<b>Temps total</b> passe dans l'app depuis le debut de "
        "l'annee.",
    ]))
    f.append(tip_box(
        "Cliquez sur un eleve pour voir sa <b>carte de chaleur</b> "
        "individuelle - tres utile pour un entretien pedagogique "
        "individualise. Vous identifiez en 30 secondes les chapitres "
        "ou l'eleve a besoin d'aide."))
    f.append(sub_header("4.3 - Alertes eleves en difficulte"))
    f.append(P(
        "Le systeme d'alertes detecte automatiquement 4 signaux :"))
    f.append(make_table(
        ["Signal", "Declenchement", "Action suggeree"],
        [
            ["Decrochage", "Pas de revision depuis 5 jours", "Conversation "
             "avec l'eleve, rappel aux parents"],
            ["Chute P(L)", "Chute de 0,20 sur un chapitre cle en 7 j",
             "Revoir le chapitre en classe, identifier la cause"],
            ["Streak rompu", "Streak de 7+ jours rompu", "Felicitations "
             "pour le streak passe, encouragement a reprendre"],
            ["Simulation ratee", "Score < 8/20 a une simulation",
             "Entretien individuel, plan de remediation"],
        ],
        col_widths=[3.0 * cm, 6.0 * cm, CONTENT_W - 9.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(warning_box(
        "Les alertes ne remplacent pas votre jugement pedagogique. "
        "Un eleve peut etre en alerte pour des raisons externes "
        "(maladie, deuil, probleme familial). Utilisez les alertes "
        "comme <b>signal d'ouverture de dialogue</b>, pas comme "
        "sanction."))
    f.append(sub_header("4.4 - Rapports trimestriels automatiques"))
    f.append(P(
        "A la fin de chaque trimestre, ExamBoost genere un <b>rapport "
        "PDF</b> par classe, pret a presenter au conseil de classe. "
        "Le rapport contient :"))
    f.append(bullets([
        "<b>Page de garde</b> : classe, periode, effectif, moyenne "
        "generale.",
        "<b>Statistiques globales</b> : taux d'activite, score moyen, "
        "evolution vs trimestre precedent.",
        "<b>Classement anonymise</b> des eleves par performance.",
        "<b>Top 3 chapitres maitrises</b> et <b>top 3 chapitres "
        "faibles</b>.",
        "<b>Liste des eleves en alerte</b> avec recommandations.",
        "<b>Annexes</b> : graphiques d'evolution, comparaison inter-"
        "classes.",
    ]))
    f.append(sub_header("4.5 - Export CSV/PDF"))
    f.append(P(
        "Toutes les donnees du dashboard sont <b>exportables</b> :"))
    f.append(bullets([
        "<b>CSV</b> : pour Excel, Google Sheets, ou votre logiciel de "
        "notes.",
        "<b>PDF</b> : pour impression et communication aux parents.",
        "<b>API</b> : pour integration avec votre logiciel d'etablissement "
        "(sur demande, licence Reseau).",
    ]))
    f.append(sub_header("4.6 - Recommandations automatiques"))
    f.append(P(
        "Le dashboard vous propose des <b>recommandations</b> pedagogiques "
        "basees sur les donnees :"))
    f.append(example_box(
        "&laquo; Sur les 52 eleves de 3e A, 38 % ont un P(L) < 0,50 sur "
        "le theoreme de Thales. Suggestion : programmer une seance de "
        "remediation de 45 min sur ce chapitre, en priorite avant le "
        "controle du 15 novembre. &raquo;"))
    return f


def _teacher_section_5_integration():
    f = section_header("5", "Integrer ExamBoost dans vos cours",
                       eyebrow="Chapitre 5 - Cas d'usage concrets")
    f.append(P(
        "Voici 4 manieres d'integrer ExamBoost dans votre pratique "
        "pedagogique, avec des exemples concrets par matiere."))
    f.append(sub_header("5.1 - Devoirs a la maison (mode asynchrone)"))
    f.append(P(
        "Apres un cours sur un chapitre, assignez une session de 20 "
        "flashcards a faire pour le lendemain. ExamBoost recupere les "
        "resultats et vous genere un rapport agrège en 5 minutes, "
        "avant votre prochain cours."))
    f.append(example_box(
        "<b>Maths 3e - Theoreme de Pythagore</b> : apres le cours du "
        "lundi, assignez 20 cartes (10 sur le cours, 10 exercices "
        "d'application). Mardi matin, votre dashboard vous montre que "
        "12 eleves sur 52 ont un P(L) < 0,50 sur la reciproque. Vous "
        "debutez le cours en reexpliquant la reciproque."))
    f.append(sub_header("5.2 - Activite en classe (15 min de flashcards)"))
    f.append(P(
        "En debut ou en fin d'heure, proposez 15 minutes de revision "
        "adaptee. Les eleves sortent leur telephone et font des "
        "flashcards. Vous circulez dans la classe pour aider ceux qui "
        "bloquent."))
    f.append(tip_box(
        "Si certains eleves n'ont pas de smartphone, jumelez-les avec "
        "un camarade (apprentissage pair-a-pair) ou projetez les cartes "
        "au tableau et faites repondre l'ensemble de la classe en "
        "levant la main."))
    f.append(sub_header("5.3 - Simulation blanc avant examen"))
    f.append(P(
        "3 a 4 semaines avant le BEPC ou le BAC, organisez une "
        "simulation complete en classe, en conditions reelles : "
        "telephones en mode avion, chronometre, pause de 5 min apres "
        "30 min. ExamBoost genere le rapport pour toute la classe en "
        "5 minutes apres la fin."))
    f.append(sub_header("5.4 - Revision guidee (chapitres faibles)"))
    f.append(P(
        "Identifiez les chapitres faibles au dashboard et lancez une "
        "session de revision ciblee dessus. L'IA propose a chaque "
        "eleve les cartes qu'il a le plus ratees sur ce chapitre."))
    f.append(sub_header("Exemples concrets par matiere"))
    f.append(make_table(
        ["Matiere", "Chapitre cible", "Activite ExamBoost", "Duree"],
        [
            ["Maths BEPC", "Theoreme de Pythagore", "20 flashcards "
             "+ 1 simulation 10 questions", "30 min"],
            ["Francais BEPC", "Figures de style", "15 flashcards "
             "(metaphores, comparaisons, personifications)", "20 min"],
            ["Physique BEPC", "Loi d'Ohm", "10 flashcards + session "
             "live classe 10 questions", "25 min"],
            ["SVT BAC D", "Genetique mendelienne", "30 flashcards "
             "+ tuteur IA pour Q/R", "45 min"],
            ["Maths BAC C", "Derivees et etude de fonction", "1 "
             "simulation 20 questions", "60 min"],
            ["Histoire BEPC", "Independance du Togo 1960", "15 "
             "flashcards + 1 devoir asynchrone 24 h", "20 min"],
        ],
        col_widths=[2.8 * cm, 3.5 * cm, 6.5 * cm, CONTENT_W - 12.8 * cm]))
    f.append(Spacer(1, 4))
    f.append(note_box(
        "Ces durees sont indicatives. Adaptez-les au niveau de votre "
        "classe et a votre rythme. L'avantage d'ExamBoost est sa "
        "flexibilite : vous pouvez lancer une activite de 5 min comme "
        "une de 1 h."))
    return f


def _teacher_section_6_impact():
    f = section_header("6", "Suivre l'impact",
                       eyebrow="Chapitre 6 - Mesurer le ROI pedagogique")
    f.append(P(
        "L'impact d'ExamBoost se mesure sur 4 dimensions : performance, "
        "engagement, comparaison, et temoignages."))
    f.append(sub_header("6.1 - Avant / apres ExamBoost"))
    f.append(P(
        "Comparez les notes de controles avant et apres l'introduction "
        "d'ExamBoost dans votre etablissement. L'objectif du pilote "
        "Lome est de <b>+15 points</b> sur la moyenne des controles "
        "apres 6 mois d'usage regulier."))
    f.append(make_table(
        ["Methode", "Ce que vous comparez", "Quand"],
        [
            ["Notes controles", "Moyenne controles T1 vs T2 vs T3",
             "Chaque trimestre"],
            ["Score ExamBoost", "Score global debut vs fin d'annee",
             "Septembre vs juin"],
            ["Taux reussite simulation", "% d'eleves >= 12/20 aux "
             "simulations", "Hebdomadaire"],
            ["Streak moyen", "Streak moyen de la classe", "Mensuel"],
        ],
        col_widths=[3.5 * cm, 6.5 * cm, CONTENT_W - 10.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("6.2 - Comparaison classes utilisatrices vs "
                        "non-utilisatrices"))
    f.append(P(
        "Pour isoler l'effet d'ExamBoost, comparez 2 classes de meme "
        "niveau : une qui utilise ExamBoost, une qui ne l'utilise pas "
        "(controle). Apres 1 trimestre, vous devriez voir un ecart "
        "significatif."))
    f.append(example_box(
        "<b>Exemple mesure a Lome (pilote juillet 2026)</b> : sur 2 "
        "classes de 3e A et 3e B (meme niveau initial), apres 3 mois, "
        "la classe 3e A (utilisatrice) a une moyenne de controles de "
        "12,4 / 20 contre 10,8 / 20 pour la 3e B (controle). Soit "
        "<b>+1,6 point</b> d'ecart, attribuable a ExamBoost."))
    f.append(sub_header("6.3 - Stats participation et engagement"))
    f.append(P(
        "Au-dela des notes, mesurez l'<b>engagement</b> de vos eleves :"))
    f.append(bullets([
        "<b>Taux d'activite 7 j</b> : % d'eleves actifs dans la semaine.",
        "<b>Streak moyen</b> : en moyenne combien de jours consecutifs.",
        "<b>Temps moyen par eleve</b> : minutes passees dans l'app par "
        "semaine.",
        "<b>Cartes revues</b> : nombre total dans la semaine, par "
        "classe.",
    ]))
    f.append(warning_box(
        "Un eleve peut etre engage (streak de 30 jours) mais ne pas "
        "progresser (P(L) qui stagne). Croisez toujours les indicateurs "
        "d'engagement avec ceux de performance. Un eleve qui clique "
        "<b>Facile</b> sur tout a un streak eleve mais un P(L) bas."))
    f.append(sub_header("6.4 - Temoignages eleves"))
    f.append(P(
        "Les chiffres sont importants, mais les temoignages donnent du "
        "sens. Sollicitez vos eleves (3 a 5 par trimestre) pour un "
        "court retour ecrit. Exemples de questions :"))
    f.append(numbered([
        "Qu'est-ce qui a change dans ta facon de reviser depuis "
        "ExamBoost ?",
        "Quelle fonctionnalite prefères-tu ? Pourquoi ?",
        "Qu'est-ce qui te frustre ? Qu'est-ce que tu changerais ?",
        "Recommanderais-tu ExamBoost a un camarade ? (Note de 0 a 10)",
    ]))
    f.append(Paragraph(
        "&laquo; Je savais pas ou j'en etais en maths. L'a je fais 15 "
        "min par jour et je vois mon score BEPC monter. &raquo;",
        STYLES['Quote']))
    f.append(Paragraph(
        "<font color='%s'>- Amina, 3e, Lome (pilote juillet 2026)</font>"
        % GRIS_MOYEN.hexval(), STYLES['BodyLeft']))
    f.append(Spacer(1, 4))
    f.append(tip_box(
        "Partagez les temoignages (avec l'accord de l'eleve) avec les "
        "parents, la direction, et les autres enseignants. C'est le "
        "meilleur moyen de generaliser l'usage d'ExamBoost dans tout "
        "l'etablissement."))
    return f


def _teacher_section_7_faq():
    f = section_header("7", "FAQ enseignants",
                       eyebrow="Chapitre 7 - Vos questions")
    f.append(P(
        "Les 5 questions les plus frequentes des enseignants lors du "
        "pilote Lome."))
    f.append(faq_item(
        "Combien ca coute pour mon etablissement ?",
        "<b>100 000 FCFA/an</b> pour le public, <b>150 000 FCFA/an</b> "
        "pour le prive. Pour une classe de 50 eleves, cela represente "
        "200 a 300 FCFA/eleve/an - moins qu'un cahier d'exercices. La "
        "licence inclut l'acces a toute la banque de questions, le "
        "dashboard enseignant, le module classe temps reel, et 4 h de "
        "formation enseignants par an."))
    f.append(faq_item(
        "Mes collegues peuvent-ils utiliser le compte ?",
        "Oui. Le compte etablissement permet de creer un nombre "
        "illimite de comptes enseignants associes. Chaque enseignant a "
        "son propre acces et ne voit que les classes/matieres qui le "
        "concernent. La direction a une vue agrégée sur tous les "
        "enseignants et toutes les classes."))
    f.append(faq_item(
        "Puis-je creer mes propres questions ?",
        "Oui, a partir de la <b>licence Reseau</b> (sur devis). Vous "
        "accedez a un module de creation de questions qui vous permet "
        "d'ajouter vos propres sujets, avec correction et "
        "classification par chapitre. Ces questions sont reservees a "
        "votre etablissement et ne sont pas partagees avec la banque "
        "nationale."))
    f.append(faq_item(
        "Comment gerer les eleves sans smartphone ?",
        "3 strategies : (1) <b>jumelage</b> - 2 eleves partagent un "
        "telephone, font les flashcards en alternant ; (2) <b>projection "
        "au tableau</b> - vous affichez les cartes au videoprojecteur "
        "et faites repondre en levant la main ; (3) <b>poste "
        "informatique</b> - si votre etablissement a une salle "
        "informatique, les eleves s'y connectent sur la version web "
        "d'ExamBoost."))
    f.append(faq_item(
        "Donnees eleves : securite ?",
        "Les donnees sont chiffrees (HTTPS) et hebergees a Abidjan "
        "(Cote d'Ivoire) chez un hebergeur RGPD-conforme. ExamBoost "
        "ne vend jamais les donnees. Vous pouvez exporter et supprimer "
        "les donnees de votre etablissement a tout moment. Conformite "
        "MEPST et CNIL Togo (loi 2019-014 sur la protection des "
        "donnees personnelles)."))
    return f


def _teacher_section_8_support():
    f = section_header("8", "Support et contact",
                       eyebrow="Chapitre 8 - Accompagnement B2B")
    f.append(P(
        "Votre etablissement beneficie d'un accompagnement dedie, "
        "different du support grand public eleve."))
    f.append(sub_header("Support dedie B2B"))
    f.append(bullets([
        "<b>Charge de compte attitre</b> : une personne dediee a votre "
        "etablissement, joignable par email et telephone.",
        "<b>Email</b> : etablissements@examboost.tg",
        "<b>Telephone</b> : +228 90 00 00 00 (du lundi au vendredi, "
        "8h-17h).",
        "<b>SLA</b> : reponse sous 24 h ouvre, resolution sous 72 h.",
    ]))
    f.append(sub_header("Formation enseignants"))
    f.append(P(
        "Votre licence inclut <b>4 heures de formation par an</b> pour "
        "les enseignants de votre etablissement. Format :"))
    f.append(make_table(
        ["Module", "Duree", "Contenu"],
        [
            ["1. Prise en main", "1 h", "Installation, creation compte, "
             "navigation dashboard, lancement 1ere session."],
            ["2. Module classe live", "1 h", "Session temps reel, "
             "gestion des eleves connectes, podium, mode asynchrone."],
            ["3. Lecture du dashboard", "1 h", "Interpretation P(L), "
             "alertes, rapports trimestriels, recommandations auto."],
            ["4. Pedagogie active", "1 h", "Cas d'usage avances, "
             "integration emploi du temps, temoignages pairs."],
        ],
        col_widths=[3.5 * cm, 1.5 * cm, CONTENT_W - 5.0 * cm]))
    f.append(Spacer(1, 4))
    f.append(sub_header("Webinaires mensuels"))
    f.append(P(
        "Le 1er jeudi de chaque mois, de 17h a 18h, un webinaire en "
        "ligne est organise pour tous les enseignants ExamBoost Togo. "
        "Theme different chaque mois : nouvelles fonctionnalites, "
        "retours d'experience, astuces pedagogiques. Replay disponible."))
    f.append(sub_header("Documentation en ligne"))
    f.append(P(
        "La documentation complete (video, articles, FAQ) est sur "
        "<b>docs.examboost.tg/enseignants</b>. Elle est mise a jour a "
        "chaque nouvelle version de l'app."))
    f.append(sub_header("Communaute enseignants ExamBoost"))
    f.append(bullets([
        "<b>Telegram</b> : @ExamBoostEnseignants (discussion entre "
        "enseignants, partage de bonnes pratiques).",
        "<b>Forum</b> : forum.examboost.tg/c/enseignants (questions "
        "techniques et pedagogiques).",
        "<b>Evenements</b> : 1 rencontre physique par an a Lome, "
        "regroupant tous les enseignants partenaires (novembre).",
    ]))
    f.append(tip_box(
        "Le reseau d'enseignants ExamBoost est une vraie richesse : "
        "vous pouvez echanger avec des collegues d'autres "
        "etablissements, partager vos supports, comparer vos resultats. "
        "N'hesitez pas a y contribuer."))
    f.append(HRFlowable(width="100%", thickness=0.5,
                        color=GRIS_BORDURE, spaceAfter=8, spaceBefore=8))
    f.append(Paragraph(
        "<i>Merci pour votre engagement. Ensemble, nous pouvons "
        "remettre les eleves togolais sur la voie de la reussite.</i>",
        STYLES['Quote']))
    f.append(Paragraph(
        "<font color='%s'>- L'equipe ExamBoost Togo</font>"
        % GRIS_MOYEN.hexval(), STYLES['BodyLeft']))
    return f


# =============================================================================
# GENERATION DES PDFs
# =============================================================================

def generate_student_manual():
    """Genere le Manuel de l'eleve (~20 pages)."""
    output_path = os.path.join(OUTPUT_DIR, "Manuel_Eleve_ExamBoost.pdf")
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        topMargin=MARGIN_T, bottomMargin=MARGIN_B,
        leftMargin=MARGIN_L, rightMargin=MARGIN_R,
        title="Manuel de l'eleve - ExamBoost Togo",
        author="ExamBoost Togo - Agent BB",
        subject="Manuel d'utilisation pour eleves BEPC/BAC",
    )

    story = []

    # 1. Couverture
    story.extend(build_cover(
        title="Manuel de l'eleve",
        subtitle="Reussis ton BEPC et ton BAC avec ExamBoost Togo",
        kind='eleve'))
    story.append(PageBreak())

    # 2. Table des matieres
    story.extend(build_toc(
        entries=[
            "Bienvenue sur ExamBoost",
            "Ton premier lancement",
            "Reviser avec les flashcards",
            "Simuler un examen",
            "Suivre ta progression",
            "Le tuteur IA : ton assistant perso",
            "Badges et recompenses",
            "Communaute ExamBoost",
            "Parametres et personnalisation",
            "Conseils pour reussir",
            "FAQ - Questions frequentes",
            "Support et contact",
        ],
        intro="Ce manuel t'accompagne pas a pas dans ta decouverte "
              "d'ExamBoost Togo. Garde-le a portee de main : tu y "
              "reviendras regulierement."))
    story.append(PageBreak())

    # 3. Sections
    story.extend(_student_section_1_welcome())
    story.extend(_student_section_2_first_launch())
    story.extend(_student_section_3_flashcards())
    story.extend(_student_section_4_simulation())
    story.extend(_student_section_5_progression())
    story.extend(_student_section_6_tutor())
    story.extend(_student_section_7_badges())
    story.extend(_student_section_8_community())
    story.extend(_student_section_9_settings())
    story.extend(_student_section_10_conseils())
    story.extend(_student_section_11_faq())
    story.extend(_student_section_12_support())

    # Construction
    doc.build(
        story,
        onFirstPage=_cover_canvas,
        onLaterPages=_make_content_canvas(COPYRIGHT_ELEVE),
    )
    print("[OK] Manuel eleve genere : " + output_path)
    return output_path


def generate_teacher_guide():
    """Genere le Guide de l'enseignant (~15 pages)."""
    output_path = os.path.join(OUTPUT_DIR, "Guide_Enseignant_ExamBoost.pdf")
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        topMargin=MARGIN_T, bottomMargin=MARGIN_B,
        leftMargin=MARGIN_L, rightMargin=MARGIN_R,
        title="Guide de l'enseignant - ExamBoost Togo",
        author="ExamBoost Togo - Agent BB",
        subject="Guide d'utilisation pour enseignants BEPC/BAC",
    )

    story = []

    # 1. Couverture
    story.extend(build_cover(
        title="Guide de l'enseignant",
        subtitle="Utilise ExamBoost en classe pour ameliorer les "
                 "resultats de tes eleves",
        kind='enseignant'))
    story.append(PageBreak())

    # 2. Table des matieres
    story.extend(build_toc(
        entries=[
            "Pourquoi ExamBoost en classe ?",
            "Creer un compte etablissement",
            "Module classe temps reel",
            "Dashboard enseignant",
            "Integrer ExamBoost dans vos cours",
            "Suivre l'impact",
            "FAQ enseignants",
            "Support et contact",
        ],
        intro="Ce guide est destine aux enseignants et directeurs de "
              "cursus. Il vous accompagne dans le deploiement "
              "d'ExamBoost dans votre etablissement."))
    story.append(PageBreak())

    # 3. Sections
    story.extend(_teacher_section_1_pourquoi())
    story.extend(_teacher_section_2_b2b())
    story.extend(_teacher_section_3_realtime())
    story.extend(_teacher_section_4_dashboard())
    story.extend(_teacher_section_5_integration())
    story.extend(_teacher_section_6_impact())
    story.extend(_teacher_section_7_faq())
    story.extend(_teacher_section_8_support())

    # Construction
    doc.build(
        story,
        onFirstPage=_cover_canvas,
        onLaterPages=_make_content_canvas(COPYRIGHT_ENSEIGNANT),
    )
    print("[OK] Guide enseignant genere : " + output_path)
    return output_path


# =============================================================================
# POINT D'ENTREE
# =============================================================================

if __name__ == "__main__":
    print("=" * 70)
    print("Generation des PDFs ExamBoost Togo")
    print("Agent BB - Session 3, Vague 3b")
    print("=" * 70)
    print("Dossier de sortie : " + OUTPUT_DIR)
    print("")

    try:
        student_path = generate_student_manual()
    except Exception as e:
        print("[ERREUR] Echec generation manuel eleve : " + str(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)

    try:
        teacher_path = generate_teacher_guide()
    except Exception as e:
        print("[ERREUR] Echec guide enseignant : " + str(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)

    print("")
    print("=" * 70)
    print("Generation terminee avec succes.")
    print("  - Manuel eleve      : " + student_path)
    print("  - Guide enseignant  : " + teacher_path)
    print("=" * 70)
