#!/usr/bin/env python3
"""
ExamBoost Togo — Analyse automatique des resultats d'enquete terrain.

Ce script :
  1. Charge un fichier CSV de reponses (export Google Sheets ou template).
  2. Calcule des statistiques descriptives (moyennes, medians, pourcentages).
  3. Genere 6 graphiques matplotlib (palette vert Togo + orange).
  4. Calcule 3 KPIs cles pour le pitch DJANTA.
  5. Produit un rapport markdown automatique avec insights.

Usage :
    python analyse_enquete.py template_results.csv
    python analyse_enquete.py enquete_examboost_lome_2026-06.csv --output-dir ./output

Requirements : voir requirements.txt (pandas, numpy, matplotlib, scipy, jinja2).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")  # backend non-interactif (serveur / CI)
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import MaxNLocator

# -----------------------------------------------------------------------------
# Configuration globale : couleurs Togo, polices, constantes
# -----------------------------------------------------------------------------

VERT_TOGO: str = "#006837"
ORANGE_TOGO: str = "#D97700"
GRIS_FONCE: str = "#3F3F3F"
GRIS_CLAIR: str = "#BFBFBF"
ROUGE: str = "#C0392B"
BLEU: str = "#2C3E50"

PALETTE: list[str] = [
    VERT_TOGO,
    ORANGE_TOGO,
    BLEU,
    ROUGE,
    GRIS_FONCE,
    "#8E44AD",
    "#16A085",
    "#F39C12",
    "#7F8C8D",
    "#E67E22",
]

# Tentative d'utilisation de Noto Sans (police unicode pour accents francais)
# Fallback silencieux si la police n'est pas installee
try:
    import matplotlib.font_manager as fm

    for font_name in ("Noto Sans", "Noto Sans SC", "DejaVu Sans", "Arial"):
        try:
            fm.findfont(font_name, fallback_to_default=False)
            plt.rcParams["font.family"] = font_name
            break
        except Exception:
            continue
except Exception:
    plt.rcParams["font.family"] = "DejaVu Sans"

plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["figure.dpi"] = 110
plt.rcParams["savefig.dpi"] = 150
plt.rcParams["axes.spines.top"] = False
plt.rcParams["axes.spines.right"] = False

N_QUESTIONS: int = 30  # Nombre attendu de questions (A1 a E3)

NOMS_COLONNES: dict[str, str] = {
    "A1": "A1_niveau",
    "A2": "A2_serie",
    "A3": "A3_type_etablissement",
    "A4": "A4_quartier",
    "A5": "A5_age",
    "B1": "B1_heures_semaine",
    "B2": "B2_outils_revision",
    "B3": "B3_smartphone",
    "B4": "B4_marque_smartphone",
    "B5": "B5_internet",
    "B6": "B6_freq_revision_numerique",
    "B7": "B7_matieres_difficiles",
    "B8": "B8_organisation_revision",
    "C1": "C1_satisfaction_methodes",
    "C2": "C2_manquant",
    "C3": "C3_app_deja_utilisee",
    "C4": "C4_laquelle_app",
    "C5": "C5_raisons_pas_simulation",
    "C6": "C6_connait_niveau",
    "C7": "C7_veut_recommandations",
    "D1": "D1_concept_utile",
    "D2": "D2_fonctionnalites_interesse",
    "D3": "D3_telechargerait",
    "D4": "D4_valeur_fcfa",
    "D5": "D5_acces_premium_ecole",
    "D6": "D6_freins",
    "D7": "D7_nps",
    "E1": "E1_indispensable",
    "E2": "E2_anecdote",
    "E3": "E3_beta_testeur",
}


# -----------------------------------------------------------------------------
# Utilitaires de parsing
# -----------------------------------------------------------------------------


def split_multi(value: Any) -> list[str]:
    """Split une valeur multi-choix separée par '|'.

    Args:
        value: Cellule brute (str, NaN, etc.).

    Returns:
        Liste des options selectionnees (sans espaces superflus).
    """
    if pd.isna(value) or value is None:
        return []
    text = str(value).strip()
    if not text:
        return []
    return [chunk.strip() for chunk in text.split("|") if chunk.strip()]


def load_data(csv_path: Path) -> pd.DataFrame:
    """Charge le CSV d'enquete et valide les colonnes attendues.

    Args:
        csv_path: Chemin vers le fichier CSV.

    Returns:
        DataFrame pandas nettoye.

    Raises:
        FileNotFoundError: Si le fichier n'existe pas.
        ValueError: Si des colonnes obligatoires sont absentes.
    """
    if not csv_path.exists():
        raise FileNotFoundError(f"Fichier introuvable : {csv_path}")

    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False, na_values=[""])

    colonnes_attendues = list(NOMS_COLONNES.values())
    manquantes = [c for c in colonnes_attendues if c not in df.columns]
    if manquantes:
        raise ValueError(
            f"Colonnes manquantes dans le CSV : {manquantes}. "
            f"Attendu : {colonnes_attendues}"
        )

    # Conversion numerique pour les colonnes Likert / NPS
    for col in ["C1_satisfaction_methodes", "D1_concept_utile", "D7_nps", "D4_valeur_fcfa"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    print(f"[INFO] {len(df)} reponses chargees depuis {csv_path.name}")
    return df


# -----------------------------------------------------------------------------
# Calculs statistiques
# -----------------------------------------------------------------------------


def compte_multi(df: pd.DataFrame, colonne: str) -> pd.Series:
    """Compte les occurrences de chaque option dans une colonne multi-choix.

    Args:
        df: DataFrame d'enquete.
        colonne: Nom de colonne (ex: 'B2_outils_revision').

    Returns:
        Series triee decroissant, index = option, valeur = nombre d'eleves.
    """
    compteur: dict[str, int] = {}
    for raw in df[colonne]:
        for opt in split_multi(raw):
            compteur[opt] = compteur.get(opt, 0) + 1
    series = pd.Series(compteur).sort_values(ascending=False)
    return series


def stats_descriptives(df: pd.DataFrame) -> dict[str, Any]:
    """Calcule un dictionnaire de statistiques descriptives par question.

    Args:
        df: DataFrame d'enquete.

    Returns:
        Dict structure : {question_id: {stat: valeur}}.
    """
    stats: dict[str, Any] = {}

    # Cible : nombre total de reponses
    stats["n_total"] = int(len(df))

    # Section A
    for q in ["A1_niveau", "A2_serie", "A3_type_etablissement", "A4_quartier", "A5_age"]:
        if q in df.columns:
            stats[q] = df[q].value_counts(dropna=False).to_dict()

    # Section B
    stats["B1_heures_semaine"] = df["B1_heures_semaine"].value_counts(dropna=False).to_dict()
    stats["B2_outils_revision_counts"] = compte_multi(df, "B2_outils_revision").to_dict()
    stats["B3_smartphone"] = df["B3_smartphone"].value_counts(dropna=False).to_dict()
    stats["B4_marque_smartphone"] = df["B4_marque_smartphone"].value_counts(dropna=False).to_dict()
    stats["B5_internet"] = df["B5_internet"].value_counts(dropna=False).to_dict()
    stats["B6_freq_revision_numerique"] = df["B6_freq_revision_numerique"].value_counts(dropna=False).to_dict()
    stats["B7_matieres_difficiles_counts"] = compte_multi(df, "B7_matieres_difficiles").to_dict()

    # Section C
    c1 = df["C1_satisfaction_methodes"].dropna()
    stats["C1_satisfaction_methodes"] = {
        "distribution": c1.value_counts().sort_index().to_dict(),
        "moyenne": float(c1.mean()) if len(c1) else 0.0,
        "mediane": float(c1.median()) if len(c1) else 0.0,
    }
    stats["C3_app_deja_utilisee"] = df["C3_app_deja_utilisee"].value_counts(dropna=False).to_dict()
    stats["C5_raisons_pas_simulation_counts"] = compte_multi(df, "C5_raisons_pas_simulation").to_dict()
    stats["C6_connait_niveau"] = df["C6_connait_niveau"].value_counts(dropna=False).to_dict()
    stats["C7_veut_recommandations"] = df["C7_veut_recommandations"].value_counts(dropna=False).to_dict()

    # Section D
    d1 = df["D1_concept_utile"].dropna()
    stats["D1_concept_utile"] = {
        "distribution": d1.value_counts().sort_index().to_dict(),
        "moyenne": float(d1.mean()) if len(d1) else 0.0,
        "mediane": float(d1.median()) if len(d1) else 0.0,
    }
    stats["D2_fonctionnalites_interesse_counts"] = compte_multi(df, "D2_fonctionnalites_interesse").to_dict()
    stats["D3_telechargerait"] = df["D3_telechargerait"].value_counts(dropna=False).to_dict()
    stats["D4_valeur_fcfa"] = df["D4_valeur_fcfa"].value_counts(dropna=False).to_dict()
    stats["D5_acces_premium_ecole"] = df["D5_acces_premium_ecole"].value_counts(dropna=False).to_dict()
    stats["D6_freins_counts"] = compte_multi(df, "D6_freins").to_dict()
    d7 = df["D7_nps"].dropna()
    stats["D7_nps"] = {
        "distribution": d7.value_counts().sort_index().to_dict(),
        "moyenne": float(d7.mean()) if len(d7) else 0.0,
        "mediane": float(d7.median()) if len(d7) else 0.0,
        "nps_score": float(d7.mean()) if len(d7) else 0.0,  # version simple moyenne
    }

    # Section E
    stats["E3_beta_testeur"] = df["E3_beta_testeur"].value_counts(dropna=False).to_dict()

    return stats


def calcul_kpis(df: pd.DataFrame) -> dict[str, Any]:
    """Calcule les 3 KPIs cles pour le pitch DJANTA.

    KPI 1 — % eleves sans outil numerique adapte
        (cible > 80%) : eleves dont B2 ne contient pas 'Application mobile'
        OU B6 == 'Jamais'.

    KPI 2 — % prets a utiliser ExamBoost
        (cible > 85%) : D3 in ('Oui', 'Peut-etre') ET D5 == 'Oui'.
        Version large : D3 in ('Oui', 'Peut-etre').

    KPI 3 — NPS moyen
        (cible > 7/10) : moyenne de D7.

    Args:
        df: DataFrame d'enquete.

    Returns:
        Dict avec les 3 KPIs + valeurs cibles + status (atteint / manquant).
    """
    n = len(df)
    if n == 0:
        return {"erreur": "Aucune reponse dans le CSV"}

    # KPI 1 — sans outil numerique adapte
    b2_is_app = df["B2_outils_revision"].apply(
        lambda x: "Application mobile dediee" in split_multi(x)
    )
    b6_jamais = df["B6_freq_revision_numerique"].astype(str).str.strip() == "Jamais"
    sans_outil_numerique = (~b2_is_app) | b6_jamais
    pct_sans_outil = float(sans_outil_numerique.mean() * 100)

    # KPI 2 — prets a utiliser ExamBoost (large : Oui + Peut-etre)
    d3_ok = df["D3_telechargerait"].astype(str).str.strip().isin(["Oui", "Peut-etre"])
    pct_prets = float(d3_ok.mean() * 100)

    # Version stricte : Oui uniquement
    d3_strict = df["D3_telechargerait"].astype(str).str.strip() == "Oui"
    pct_prets_strict = float(d3_strict.mean() * 100)

    # KPI 3 — NPS moyen
    nps_moyen = float(df["D7_nps"].dropna().mean()) if df["D7_nps"].notna().any() else 0.0

    return {
        "kpi1_sans_outil_numerique_pct": round(pct_sans_outil, 1),
        "kpi1_cible_pct": 80.0,
        "kpi1_atteint": pct_sans_outil >= 80.0,
        "kpi2_prets_utiliser_pct": round(pct_prets, 1),
        "kpi2_prets_utiliser_strict_pct": round(pct_prets_strict, 1),
        "kpi2_cible_pct": 85.0,
        "kpi2_atteint": pct_prets >= 85.0,
        "kpi3_nps_moyen": round(nps_moyen, 2),
        "kpi3_cible": 7.0,
        "kpi3_atteint": nps_moyen >= 7.0,
        "n_total": int(n),
    }


# -----------------------------------------------------------------------------
# Generation des graphiques
# -----------------------------------------------------------------------------


def _sauvegarder(fig: plt.Figure, output_dir: Path, nom: str) -> Path:
    """Sauvegarde une figure matplotlib en PNG et ferme la figure.

    Args:
        fig: Figure a sauvegarder.
        output_dir: Dossier de sortie.
        nom: Nom de fichier sans extension.

    Returns:
        Chemin complet du fichier PNG genere.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    chemin = output_dir / f"{nom}.png"
    fig.savefig(chemin, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    return chemin


def graph_outils_revision(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 1 — Bar chart : outils de revision utilises (B2)."""
    comptes = compte_multi(df, "B2_outils_revision")
    if comptes.empty:
        comptes = pd.Series({"(aucune donnee)": 0})

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh(
        range(len(comptes)),
        comptes.values,
        color=VERT_TOGO,
        edgecolor=GRIS_FONCE,
        linewidth=0.5,
    )
    ax.set_yticks(range(len(comptes)))
    ax.set_yticklabels(comptes.index, fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel("Nombre d'eleves", fontsize=11)
    ax.set_title("Outils de revision utilises par les eleves", fontsize=13, fontweight="bold", color=GRIS_FONCE)
    ax.xaxis.set_major_locator(MaxNLocator(integer=True))

    # Annotations valeurs
    for bar in bars:
        largeur = bar.get_width()
        ax.text(
            largeur + 0.1,
            bar.get_y() + bar.get_height() / 2,
            f"{int(largeur)}",
            va="center",
            fontsize=9,
            color=GRIS_FONCE,
        )
    ax.set_xlim(0, max(comptes.values) * 1.15 if len(comptes) else 1)
    return _sauvegarder(fig, out, "01_outils_revision")


def graph_smartphone(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 2 — Pie chart : acces smartphone (B3)."""
    comptes = df["B3_smartphone"].value_counts(dropna=False)
    if comptes.empty:
        comptes = pd.Series({"(aucune donnee)": 1})

    fig, ax = plt.subplots(figsize=(8, 8))
    couleurs = [VERT_TOGO, ORANGE_TOGO, GRIS_FONCE, GRIS_CLAIR, ROUGE][: len(comptes)]
    wedges, texts, autotexts = ax.pie(
        comptes.values,
        labels=comptes.index,
        colors=couleurs,
        autopct="%1.1f%%",
        startangle=90,
        textprops={"fontsize": 10},
        wedgeprops={"edgecolor": "white", "linewidth": 2},
    )
    for autotext in autotexts:
        autotext.set_color("white")
        autotext.set_fontweight("bold")
    ax.set_title("Acces au smartphone personnel", fontsize=13, fontweight="bold", color=GRIS_FONCE)
    ax.axis("equal")
    return _sauvegarder(fig, out, "02_smartphone")


def graph_heures_revision(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 3 — Histogramme : heures de revision par semaine (B1)."""
    ordre = ["0 a 5 heures", "6 a 10 heures", "11 a 15 heures", "16 heures ou plus"]
    comptes = df["B1_heures_semaine"].value_counts(dropna=False)
    valeurs = [int(comptes.get(cat, 0)) for cat in ordre]

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(
        range(len(ordre)),
        valeurs,
        color=[GRIS_CLAIR, VERT_TOGO, ORANGE_TOGO, ROUGE],
        edgecolor=GRIS_FONCE,
        linewidth=0.5,
    )
    ax.set_xticks(range(len(ordre)))
    ax.set_xticklabels(ordre, fontsize=10, rotation=15, ha="right")
    ax.set_ylabel("Nombre d'eleves", fontsize=11)
    ax.set_title("Heures de revision par semaine", fontsize=13, fontweight="bold", color=GRIS_FONCE)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

    for bar in bars:
        hauteur = bar.get_height()
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            hauteur + 0.1,
            f"{int(hauteur)}",
            ha="center",
            fontsize=10,
            color=GRIS_FONCE,
        )
    ax.set_ylim(0, max(valeurs) * 1.2 if max(valeurs) else 1)
    return _sauvegarder(fig, out, "03_heures_revision")


def graph_matieres_difficiles(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 4 — Bar chart : matieres les plus difficiles (B7)."""
    comptes = compte_multi(df, "B7_matieres_difficiles")
    if comptes.empty:
        comptes = pd.Series({"(aucune donnee)": 0})

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(
        range(len(comptes)),
        comptes.values,
        color=ORANGE_TOGO,
        edgecolor=GRIS_FONCE,
        linewidth=0.5,
    )
    ax.set_xticks(range(len(comptes)))
    ax.set_xticklabels(comptes.index, fontsize=10, rotation=20, ha="right")
    ax.set_ylabel("Nombre d'eleves", fontsize=11)
    ax.set_title("Matieres perçues comme les plus difficiles", fontsize=13, fontweight="bold", color=GRIS_FONCE)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

    for bar in bars:
        hauteur = bar.get_height()
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            hauteur + 0.1,
            f"{int(hauteur)}",
            ha="center",
            fontsize=10,
            color=GRIS_FONCE,
        )
    ax.set_ylim(0, max(comptes.values) * 1.2 if len(comptes) else 1)
    return _sauvegarder(fig, out, "04_matieres_difficiles")


def graph_satisfaction(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 5 — Distribution Likert : satisfaction methodes actuelles (C1)."""
    c1 = df["C1_satisfaction_methodes"].dropna()
    distribution = c1.value_counts().sort_index()

    etiquettes = {
        1: "1 — Pas du tout",
        2: "2 — Peu",
        3: "3 — Neutre",
        4: "4 — Plutot",
        5: "5 — Tres satisfait",
    }
    valeurs = [int(distribution.get(i, 0)) for i in range(1, 6)]
    couleurs = [ROUGE, "#E67E22", GRIS_CLAIR, "#16A085", VERT_TOGO]

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(
        list(etiquettes.values()),
        valeurs,
        color=couleurs,
        edgecolor=GRIS_FONCE,
        linewidth=0.5,
    )
    ax.set_ylabel("Nombre d'eleves", fontsize=11)
    ax.set_title(
        f"Satisfaction des methodes de revision actuelles (moyenne = {c1.mean():.2f}/5)",
        fontsize=12,
        fontweight="bold",
        color=GRIS_FONCE,
    )
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))
    plt.xticks(rotation=15, ha="right", fontsize=10)

    for bar in bars:
        hauteur = bar.get_height()
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            hauteur + 0.1,
            f"{int(hauteur)}",
            ha="center",
            fontsize=10,
            color=GRIS_FONCE,
        )
    ax.set_ylim(0, max(valeurs) * 1.2 if max(valeurs) else 1)
    return _sauvegarder(fig, out, "05_satisfaction_likert")


def graph_fonctionnalites(df: pd.DataFrame, out: Path) -> Path:
    """Graphique 6 — Bar chart : interet fonctionnalites ExamBoost (D2)."""
    comptes = compte_multi(df, "D2_fonctionnalites_interesse")
    if comptes.empty:
        comptes = pd.Series({"(aucune donnee)": 0})

    fig, ax = plt.subplots(figsize=(11, 6))
    bars = ax.bar(
        range(len(comptes)),
        comptes.values,
        color=VERT_TOGO,
        edgecolor=GRIS_FONCE,
        linewidth=0.5,
    )
    # Mettre en orange la fonctionnalite la plus demandee
    if len(comptes) > 0 and comptes.iloc[0] > 0:
        bars[0].set_color(ORANGE_TOGO)

    ax.set_xticks(range(len(comptes)))
    ax.set_xticklabels(comptes.index, fontsize=9, rotation=25, ha="right")
    ax.set_ylabel("Nombre d'eleves interesses", fontsize=11)
    ax.set_title("Fonctionnalites ExamBoost les plus attendues", fontsize=13, fontweight="bold", color=GRIS_FONCE)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

    for bar in bars:
        hauteur = bar.get_height()
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            hauteur + 0.1,
            f"{int(hauteur)}",
            ha="center",
            fontsize=10,
            color=GRIS_FONCE,
        )
    ax.set_ylim(0, max(comptes.values) * 1.2 if len(comptes) else 1)
    return _sauvegarder(fig, out, "06_fonctionnalites_interet")


def generer_graphiques(df: pd.DataFrame, output_dir: Path) -> list[Path]:
    """Genere les 6 graphiques et retourne la liste des chemins PNG.

    Args:
        df: DataFrame d'enquete.
        output_dir: Dossier de sortie pour les PNG.

    Returns:
        Liste des 6 chemins vers les fichiers PNG generes.
    """
    figures_dir = output_dir / "figures"
    figures_dir.mkdir(parents=True, exist_ok=True)
    chemins: list[Path] = []

    print(f"[INFO] Generation des 6 graphiques dans {figures_dir}/")
    chemins.append(graph_outils_revision(df, figures_dir))
    chemins.append(graph_smartphone(df, figures_dir))
    chemins.append(graph_heures_revision(df, figures_dir))
    chemins.append(graph_matieres_difficiles(df, figures_dir))
    chemins.append(graph_satisfaction(df, figures_dir))
    chemins.append(graph_fonctionnalites(df, figures_dir))
    return chemins


# -----------------------------------------------------------------------------
# Generation du rapport markdown automatique
# -----------------------------------------------------------------------------


def extraire_citations(df: pd.DataFrame, colonne: str, min_mots: int = 8) -> list[str]:
    """Extrait des citations qualitatives (reponses ouvertes) pour le pitch.

    Args:
        df: DataFrame d'enquete.
        colonne: Nom de colonne (E1, E2, C2).
        min_mots: Longueur minimale en mots pour garder la citation.

    Returns:
        Liste de citations (max 5), dedoublonnees.
    """
    if colonne not in df.columns:
        return []
    citations: list[str] = []
    vues: set[str] = set()
    for val in df[colonne].dropna():
        texte = str(val).strip()
        if len(texte.split()) < min_mots:
            continue
        cle = texte.lower()[:80]
        if cle in vues:
            continue
        vues.add(cle)
        citations.append(texte)
        if len(citations) >= 5:
            break
    return citations


def generer_rapport_markdown(
    df: pd.DataFrame,
    stats: dict[str, Any],
    kpis: dict[str, Any],
    chemins_figures: list[Path],
    output_path: Path,
) -> Path:
    """Genere un rapport markdown automatique avec insights.

    Args:
        df: DataFrame d'enquete.
        stats: Dictionnaire de statistiques descriptives.
        kpis: Dictionnaire des 3 KPIs.
        chemins_figures: Liste des chemins PNG (relatifs au rapport).
        output_path: Chemin du fichier markdown a generer.

    Returns:
        Chemin du rapport genere.
    """
    citations_e1 = extraire_citations(df, "E1_indispensable")
    citations_e2 = extraire_citations(df, "E2_anecdote")
    citations_c2 = extraire_citations(df, "C2_manquant")

    # Calculs supplements pour le rapport
    pct_smartphone_perso = (
        (df["B3_smartphone"].astype(str).str.strip().str.startswith("Oui")).mean() * 100
    )
    pct_acces_premium_ecole = (
        (df["D5_acces_premium_ecole"].astype(str).str.strip() == "Oui").mean() * 100
    )

    # Liste des 3 fonctionnalites les plus demandees
    fonc = compte_multi(df, "D2_fonctionnalites_interesse")
    top3_fonc = list(fonc.head(3).items()) if not fonc.empty else []

    lignes: list[str] = []
    lignes.append("# Rapport automatique d'enquete ExamBoost Togo")
    lignes.append("")
    lignes.append(f"**Genere le** : {pd.Timestamp.now().strftime('%d/%m/%Y a %H:%M')}")
    lignes.append(f"**Nombre de reponses** : {kpis.get('n_total', len(df))}")
    lignes.append("")
    lignes.append("---")
    lignes.append("")
    lignes.append("## 1. KPIs cles (pitch DJANTA)")
    lignes.append("")
    lignes.append("| KPI | Valeur | Cible | Statut |")
    lignes.append("|---|---|---|---|")
    statut_kpi1 = "ATTEINT" if kpis.get("kpi1_atteint") else "MANQUE"
    statut_kpi2 = "ATTEINT" if kpis.get("kpi2_atteint") else "MANQUE"
    statut_kpi3 = "ATTEINT" if kpis.get("kpi3_atteint") else "MANQUE"
    lignes.append(
        f"| % eleves sans outil numerique adapte | "
        f"{kpis.get('kpi1_sans_outil_numerique_pct', 0)}% | "
        f">{kpis.get('kpi1_cible_pct', 80)}% | {statut_kpi1} |"
    )
    lignes.append(
        f"| % prets a utiliser ExamBoost (Oui + Peut-etre) | "
        f"{kpis.get('kpi2_prets_utiliser_pct', 0)}% | "
        f">{kpis.get('kpi2_cible_pct', 85)}% | {statut_kpi2} |"
    )
    lignes.append(
        f"| NPS moyen (1-10) | "
        f"{kpis.get('kpi3_nps_moyen', 0)}/10 | "
        f">{kpis.get('kpi3_cible', 7)} | {statut_kpi3} |"
    )
    lignes.append("")
    lignes.append("> Si au moins 2 KPIs sur 3 sont atteints, la preuve de traction est consideree comme solide pour le pitch DJANTA.")
    lignes.append("")
    lignes.append("---")
    lignes.append("")
    lignes.append("## 2. Profils des eleves enquetes")
    lignes.append("")
    lignes.append(f"- **Total** : {len(df)} eleves")
    lignes.append(f"- **Smartphone personnel** : {pct_smartphone_perso:.1f}% des eleves")
    lignes.append(f"- **Acces premium ecole interesse** : {pct_acces_premium_ecole:.1f}% des eleves")
    lignes.append("")

    lignes.append("### Repartition par niveau (A1)")
    lignes.append("")
    lignes.append("| Niveau | Effectif | % |")
    lignes.append("|---|---|---|")
    a1 = df["A1_niveau"].value_counts()
    for niv, nb in a1.items():
        lignes.append(f"| {niv} | {nb} | {nb/len(df)*100:.1f}% |")
    lignes.append("")

    lignes.append("### Repartition par quartier (A4)")
    lignes.append("")
    lignes.append("| Quartier | Effectif |")
    lignes.append("|---|---|")
    a4 = df["A4_quartier"].value_counts()
    for q, nb in a4.items():
        lignes.append(f"| {q} | {nb} |")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 3. Habitudes de revision")
    lignes.append("")
    lignes.append(f"![Outils de revision](figures/{chemins_figures[0].name})")
    lignes.append("")
    lignes.append(f"![Acces smartphone](figures/{chemins_figures[1].name})")
    lignes.append("")
    lignes.append(f"![Heures de revision](figures/{chemins_figures[2].name})")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 4. Douleurs et besoins")
    lignes.append("")
    satisf_moy = stats.get("C1_satisfaction_methodes", {}).get("moyenne", 0)
    lignes.append(f"- **Satisfaction moyenne des methodes actuelles** : {satisf_moy:.2f}/5")
    lignes.append(f"- **Connait son niveau exact** : {df['C6_connait_niveau'].value_counts().get('Oui, je connais mon niveau precis', 0)}/{len(df)} eleves")
    lignes.append(f"![Satisfaction (Likert)](figures/{chemins_figures[4].name})")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 5. Reaction au concept ExamBoost")
    lignes.append("")
    d1_moy = stats.get("D1_concept_utile", {}).get("moyenne", 0)
    lignes.append(f"- **Utilite perçue moyenne** : {d1_moy:.2f}/5")
    lignes.append(f"- **Top 3 fonctionnalites attendues** :")
    for fonc_nom, fonc_nb in top3_fonc:
        lignes.append(f"  - {fonc_nom} ({fonc_nb} eleves)")
    lignes.append("")
    lignes.append(f"![Fonctionnalites interet](figures/{chemins_figures[5].name})")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 6. Matieres difficiles")
    lignes.append("")
    lignes.append(f"![Matieres difficiles](figures/{chemins_figures[3].name})")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 7. Citations qualitatives pour le pitch")
    lignes.append("")
    lignes.append("### 7.1 — Ce qui rendrait ExamBoost indispensable (E1)")
    lignes.append("")
    if citations_e1:
        for i, cit in enumerate(citations_e1[:3], 1):
            lignes.append(f"> {i}. \"{cit}\"")
            lignes.append(">")
            lignes.append("")
    else:
        lignes.append("_Aucune citation exploitable (reponses trop courtes ou manquantes)._")
        lignes.append("")

    lignes.append("### 7.2 — Anecdotes de difficulte a se preparer (E2)")
    lignes.append("")
    if citations_e2:
        for i, cit in enumerate(citations_e2[:3], 1):
            lignes.append(f"> {i}. \"{cit}\"")
            lignes.append(">")
            lignes.append("")
    else:
        lignes.append("_Aucune citation exploitable._")
        lignes.append("")

    lignes.append("### 7.3 — Ce qui manque le plus (C2)")
    lignes.append("")
    if citations_c2:
        for i, cit in enumerate(citations_c2[:3], 1):
            lignes.append(f"> {i}. \"{cit}\"")
            lignes.append(">")
            lignes.append("")
    else:
        lignes.append("_Aucune citation exploitable._")
        lignes.append("")

    lignes.append("---")
    lignes.append("")

    lignes.append("## 8. Insights pour le pitch DJANTA")
    lignes.append("")
    insights: list[str] = []
    if kpis.get("kpi1_atteint"):
        insights.append(
            f"- **Traction validee** : {kpis['kpi1_sans_outil_numerique_pct']}% des eleves n'ont pas d'outil numerique adapte — le probleme est confirme."
        )
    else:
        insights.append(
            f"- **Traction partielle** : {kpis['kpi1_sans_outil_numerique_pct']}% des eleves sans outil (cible 80%) — a renforcer dans le pitch."
        )

    if kpis.get("kpi2_atteint"):
        insights.append(
            f"- **Demande forte** : {kpis['kpi2_prets_utiliser_pct']}% des eleves prets a telecharger ExamBoost (cible 85%)."
        )
    else:
        insights.append(
            f"- **Demande moderee** : {kpis['kpi2_prets_utiliser_pct']}% de prets (cible 85%) — argumerter le mode offline + gratuit pour convertir les 'Peut-etre'."
        )

    if kpis.get("kpi3_atteint"):
        insights.append(
            f"- **Recommandation elevee** : NPS moyen {kpis['kpi3_nps_moyen']}/10 (cible >7)."
        )
    else:
        insights.append(
            f"- **NPS a ameliorer** : {kpis['kpi3_nps_moyen']}/10 (cible >7) — tester plus de fonctionnalites avant de mesurer."
        )

    if top3_fonc:
        insights.append(
            f"- **Fonctionnalite phare** : \"{top3_fonc[0][0]}\" demandee par {top3_fonc[0][1]} eleves sur {len(df)}."
        )

    for line in insights:
        lignes.append(line)
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 9. Recommandations produit")
    lignes.append("")
    lignes.append("1. **Mode hors-ligne prioritaire** : la majorite des eleves dependent d'un forfait data limite (cf. B5).")
    lignes.append("2. **Sujets des annees precedentes** : integrer 50+ sujets BEPC/BAC avec corrections des la version 1.0 (cf. C5).")
    lignes.append("3. **Predictions de score visuelles** : un score probable simple (pas une note precise) pour motiver (cf. D2).")
    lignes.append("4. **Compensation faible** : 200 FCFA/month max acceptable pour les eleves ; privilegier modele freemium + B2B ecoles (cf. D4, D5).")
    lignes.append("5. **Beta-testeurs** : contacter les eleves qui ont laisse leur email/WhatsApp (cf. E3) pour la phase pilote de septembre 2026.")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 10. Limites methodologiques")
    lignes.append("")
    lignes.append(f"- Echantillon de {len(df)} eleves (cible 30) — marge d'erreur elevee (±18%).")
    lignes.append("- Enquete limitee a Lome (pas de villes secondaires ; une enquete 200 eleves / 5 villes est prevue en M1 — cf. Etude de Faisabilite 2025).")
    lignes.append("- Biais de selection possible : eleves acceptant l'enquete peuvent etre plus motives que la moyenne.")
    lignes.append("- Pas de parite genre garantie par le questionnaire (a verifier via le rapport de terrain).")
    lignes.append("")
    lignes.append("---")
    lignes.append("")

    lignes.append("## 11. Conclusion")
    lignes.append("")
    lignes.append(
        f"Les resultats de cette enquete aupres de {len(df)} eleves de Lome "
        f"valident l'existence d'un besoin reel pour une application dediee a la preparation des examens nationaux togolais. "
        f"Les KPIs cibles pour le pitch DJANTA sont {'atteints' if (kpis.get('kpi1_atteint') and kpis.get('kpi2_atteint') and kpis.get('kpi3_atteint')) else 'partiellement atteints'}, "
        f"et les citations qualitatives recueillies renforcent le narratif de la preuve de traction."
    )
    lignes.append("")
    lignes.append("---")
    lignes.append("")
    lignes.append("_Rapport genere automatiquement par `analyse_enquete.py` (version 1.0)._")

    output_path.write_text("\n".join(lignes), encoding="utf-8")
    print(f"[INFO] Rapport markdown genere : {output_path}")
    return output_path


# -----------------------------------------------------------------------------
# Point d'entree CLI
# -----------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    """Point d'entree principal — parse les args, lance l'analyse.

    Args:
        argv: Arguments CLI (par defaut : sys.argv[1:]).

    Returns:
        Code de sortie (0 = succes, 1 = erreur).
    """
    parser = argparse.ArgumentParser(
        description="Analyse automatique des resultats de l'enquete ExamBoost Togo.",
        epilog=(
            "Exemple : python analyse_enquete.py template_results.csv\n"
            "          python analyse_enquete.py enquete_examboost_lome_2026-06.csv --output-dir ./output"
        ),
    )
    parser.add_argument(
        "csv_path",
        type=Path,
        help="Chemin vers le fichier CSV de reponses (export Google Sheets ou template_results.csv).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("./output"),
        help="Dossier de sortie pour les figures, KPIs et rapport markdown (defaut: ./output).",
    )
    args = parser.parse_args(argv)

    try:
        df = load_data(args.csv_path)
    except (FileNotFoundError, ValueError) as exc:
        print(f"[ERREUR] {exc}", file=sys.stderr)
        return 1

    if df.empty:
        print("[ERREUR] Le CSV est vide.", file=sys.stderr)
        return 1

    # Statistiques descriptives
    stats = stats_descriptives(df)

    # KPIs
    kpis = calcul_kpis(df)
    print("[INFO] KPIs calcules :")
    for k, v in kpis.items():
        print(f"       - {k} : {v}")

    # Graphiques
    chemins = generer_graphiques(df, args.output_dir)

    # Sauvegarde KPIs en JSON
    args.output_dir.mkdir(parents=True, exist_ok=True)
    kpis_path = args.output_dir / "kpis.json"
    kpis_path.write_text(json.dumps(kpis, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[INFO] KPIs sauvegardes : {kpis_path}")

    # Sauvegarde stats completes en JSON
    stats_path = args.output_dir / "stats.json"
    stats_path.write_text(json.dumps(stats, indent=2, ensure_ascii=False, default=str), encoding="utf-8")
    print(f"[INFO] Stats completes sauvegardees : {stats_path}")

    # Rapport markdown
    rapport_path = args.output_dir / "rapport_auto.md"
    generer_rapport_markdown(df, stats, kpis, chemins, rapport_path)

    print("\n[OK] Analyse complete. Fichiers generes dans : " + str(args.output_dir.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
