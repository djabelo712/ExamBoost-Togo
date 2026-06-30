"""
Téléchargement des PDFs d'annales depuis les sources configurées.

Usage:
    python scrape_pdfs.py --source epreuvesetcorriges --year 2022
    python scrape_pdfs.py --source epreuvesetcorriges --dry-run
    python scrape_pdfs.py --source epreuvesetcorriges --limit 5
    python scrape_pdfs.py --all-sources

Le scraper respecte robots.txt et insere un delai entre chaque requete
(config: SCRAPER_DELAY_SECONDS). Un manifeste JSON est maintenu a jour dans
`data/raw_pdfs/manifest.json` pour permettre la reprise apres interruption.
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import time
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set
from urllib.parse import urljoin, urlparse
from urllib.robotparser import RobotFileParser

import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

from config import PATHS, SOURCES, SourceConfig

logger = logging.getLogger("scrape_pdfs")


# ─── Modele manifeste ─────────────────────────────────────────────────────


@dataclass
class PdfEntry:
    """Metadata d'un PDF telecharge (ou detecte en dry-run)."""

    source: str
    examen: str
    matiere: str
    serie: Optional[str]
    annee: int
    url: str
    local_path: Optional[str] = None
    size_bytes: Optional[int] = None
    downloaded_at: Optional[str] = None
    status: str = "pending"  # pending | downloaded | failed | skipped


@dataclass
class Manifest:
    """Manifeste global des PDFs connus du pipeline."""

    version: int = 1
    updated_at: str = ""
    entries: List[PdfEntry] = field(default_factory=list)

    def to_dict(self) -> Dict:
        return {
            "version": self.version,
            "updated_at": self.updated_at,
            "entries": [asdict(e) for e in self.entries],
        }


# ─── I/O manifeste ────────────────────────────────────────────────────────


def load_manifest() -> Manifest:
    """Load the manifest from disk (or return an empty one)."""
    if not PATHS.manifest.exists():
        return Manifest()
    try:
        with PATHS.manifest.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        entries = [PdfEntry(**e) for e in data.get("entries", [])]
        return Manifest(
            version=data.get("version", 1),
            updated_at=data.get("updated_at", ""),
            entries=entries,
        )
    except (json.JSONDecodeError, TypeError, OSError) as exc:
        logger.warning("Manifest illisible, demarrage a vide: %s", exc)
        return Manifest()


def save_manifest(manifest: Manifest) -> None:
    """Persist the manifest to disk."""
    manifest.updated_at = datetime.now(timezone.utc).isoformat()
    PATHS.manifest.parent.mkdir(parents=True, exist_ok=True)
    with PATHS.manifest.open("w", encoding="utf-8") as fh:
        json.dump(manifest.to_dict(), fh, ensure_ascii=False, indent=2)
    logger.info("Manifest sauvegarde (%d entrees)", len(manifest.entries))


# ─── robots.txt ───────────────────────────────────────────────────────────


def can_fetch(url: str, user_agent: str = "*") -> bool:
    """Check robots.txt for a given URL.

    Args:
        url: full URL to test.
        user_agent: UA string to test against.

    Returns:
        True if fetching is allowed, False otherwise.
    """
    parsed = urlparse(url)
    robots_url = f"{parsed.scheme}://{parsed.netloc}/robots.txt"
    rp = RobotFileParser()
    rp.set_url(robots_url)
    try:
        rp.read()
        return rp.can_fetch(user_agent, url)
    except Exception as exc:  # noqa: BLE001
        logger.warning("robots.txt illisible pour %s: %s", robots_url, exc)
        return True  # permissive si indisponible


# ─── Scraper ──────────────────────────────────────────────────────────────


# Mapping matiere -> mots-cles reconnus dans les titres de liens.
MATIERE_KEYWORDS: Dict[str, List[str]] = {
    "Mathématiques": ["math", "maths", "mathematiques"],
    "Français": ["francais", "franc", "langue"],
    "Sciences Physiques": ["physique", "phys", "pc"],
    "Sciences de la Vie et de la Terre": ["svt", "biologie", "science vie"],
    "Histoire-Géographie": ["histoire", "geographie", "hg"],
    "Anglais": ["anglais", "english"],
    "Philosophie": ["philo", "philosophie"],
    "EPS": ["eps", "sport"],
}

# Mapping examen -> mots-cles.
EXAMEN_KEYWORDS: Dict[str, List[str]] = {
    "BEPC": ["bepc"],
    "BAC1": ["bac", "bac1", "premiere", "probatoire"],
    "BAC2": ["bac2", "terminale", "bac ii", "bac-2"],
}


def detect_matiere(text: str) -> Optional[str]:
    """Detect the matiere of a PDF from its link text/filename."""
    text_lower = text.lower()
    for matiere, keywords in MATIERE_KEYWORDS.items():
        if any(kw in text_lower for kw in keywords):
            return matiere
    return None


def detect_examen(text: str) -> Optional[str]:
    """Detect the exam type from a link text/filename."""
    text_lower = text.lower()
    # Ordre important: BAC2 avant BAC1 avant BAC.
    for exam in ("BAC2", "BAC1", "BEPC"):
        for kw in EXAMEN_KEYWORDS[exam]:
            if kw in text_lower:
                return exam
    return None


def detect_year(text: str) -> Optional[int]:
    """Extract a 4-digit year (2010-2025) from a string."""
    match = re.search(r"\b(20[12]\d)\b", text)
    if match:
        y = int(match.group(1))
        if 2010 <= y <= 2025:
            return y
    return None


def detect_serie(text: str, examen: Optional[str]) -> Optional[str]:
    """Detect the series letter (A/B/C/D/F) for BAC exams."""
    if not examen or not examen.startswith("BAC"):
        return None
    text_lower = text.lower()
    for serie in ("C", "D", "B", "A", "F"):
        # On cherche "serie C", "serie C/D", "bac C", etc.
        if re.search(rf"\b(?:s[ée]rie|bac)\s*[/-]?\s*{serie}\b", text_lower):
            return serie
    return None


def list_pdfs_for_source(
    source: SourceConfig,
    year_filter: Optional[int] = None,
    examen_filter: Optional[str] = None,
    matiere_filter: Optional[str] = None,
    limit: Optional[int] = None,
) -> List[PdfEntry]:
    """Crawl the source listing page and return matching PDF entries.

    Does NOT download anything. Only enumerates candidates.

    Args:
        source: source config to crawl.
        year_filter: if set, only keep entries matching this year.
        examen_filter: if set, only keep entries matching this exam.
        matiere_filter: if set, only keep entries matching this matiere.
        limit: max number of entries to return (None = unlimited).

    Returns:
        List of PdfEntry with status="pending".
    """
    if not can_fetch(source.listing_url):
        logger.warning("robots.txt interdit le crawl de %s", source.listing_url)
        return []

    try:
        resp = requests.get(
            source.listing_url,
            headers={"User-Agent": _user_agent()},
            timeout=30,
        )
        resp.raise_for_status()
    except requests.RequestException as exc:
        logger.error("Requete listing echouee pour %s: %s", source.name, exc)
        return []

    soup = BeautifulSoup(resp.text, "html.parser")
    pdf_re = re.compile(source.pdf_url_pattern, flags=re.IGNORECASE)
    seen_urls: Set[str] = set()
    entries: List[PdfEntry] = []

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if not pdf_re.search(href):
            continue
        full_url = urljoin(source.base_url, href)
        if full_url in seen_urls:
            continue
        seen_urls.add(full_url)

        link_text = a.get_text(strip=True) or Path(urlparse(full_url).path).name
        examen = detect_examen(link_text) or detect_examen(full_url)
        matiere = detect_matiere(link_text) or detect_matiere(full_url)
        annee = detect_year(link_text) or detect_year(full_url)
        serie = detect_serie(link_text, examen) or detect_serie(full_url, examen)

        if examen_filter and examen != examen_filter:
            continue
        if matiere_filter and matiere != matiere_filter:
            continue
        if year_filter and annee != year_filter:
            continue
        if annee is None or examen is None or matiere is None:
            logger.debug("Ignore (metadata incomplete): %s", full_url)
            continue

        entries.append(
            PdfEntry(
                source=source.name,
                examen=examen,
                matiere=matiere,
                serie=serie,
                annee=annee,
                url=full_url,
                status="pending",
            )
        )
        if limit and len(entries) >= limit:
            break

    return entries


# ─── Telechargement ───────────────────────────────────────────────────────


def _user_agent() -> str:
    import os
    return os.getenv("SCRAPER_USER_AGENT", "ExamBoostBot/1.0 (+contact@examboost.tg)")


def _delay(source: SourceConfig) -> float:
    import os
    return float(os.getenv("SCRAPER_DELAY_SECONDS", str(source.rate_limit)))


def pdf_local_path(entry: PdfEntry) -> Path:
    """Compute the canonical local path for a PDF entry."""
    serie_part = entry.serie or "TOUTES"
    # Sanitize matiere for filesystem (no accents/spaces).
    matiere_safe = entry.matiere.replace(" ", "_").replace("é", "e").replace("è", "e")
    filename = f"{entry.annee}_{serie_part}.pdf"
    return PATHS.raw_pdfs / entry.source / entry.examen / matiere_safe / filename


def download_pdf(entry: PdfEntry) -> PdfEntry:
    """Download a single PDF and update the entry in-place.

    Args:
        entry: PdfEntry to download.

    Returns:
        The same entry with updated status/local_path/size_bytes.
    """
    if not can_fetch(entry.url):
        logger.warning("robots.txt interdit: %s", entry.url)
        entry.status = "skipped"
        return entry

    out_path = pdf_local_path(entry)
    if out_path.exists() and out_path.stat().st_size > 1024:
        logger.info("Deja telecharge, skip: %s", out_path)
        entry.local_path = str(out_path)
        entry.size_bytes = out_path.stat().st_size
        entry.status = "downloaded"
        return entry

    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with requests.get(
            entry.url,
            headers={"User-Agent": _user_agent()},
            stream=True,
            timeout=60,
        ) as resp:
            resp.raise_for_status()
            with out_path.open("wb") as fh:
                for chunk in resp.iter_content(chunk_size=8192):
                    if chunk:
                        fh.write(chunk)
        entry.local_path = str(out_path)
        entry.size_bytes = out_path.stat().st_size
        entry.downloaded_at = datetime.now(timezone.utc).isoformat()
        entry.status = "downloaded"
        logger.info("Telecharge: %s (%d bytes)", out_path.name, entry.size_bytes)
    except requests.RequestException as exc:
        logger.error("Echec download %s: %s", entry.url, exc)
        entry.status = "failed"

    return entry


def scrape_source(
    source_name: str,
    year: Optional[int] = None,
    examen: Optional[str] = None,
    matiere: Optional[str] = None,
    limit: Optional[int] = None,
    dry_run: bool = False,
) -> List[PdfEntry]:
    """Full scrape pipeline for one source.

    Args:
        source_name: key in SOURCES.
        year/examen/matiere: optional filters.
        limit: max entries.
        dry_run: if True, list only (no download).

    Returns:
        List of entries processed (whatever their final status).
    """
    source = SOURCES.get(source_name)
    if not source:
        logger.error("Source inconnue: %s", source_name)
        return []

    logger.info(
        "Scraping source=%s filters=(year=%s examen=%s matiere=%s limit=%s dry_run=%s)",
        source_name, year, examen, matiere, limit, dry_run,
    )
    entries = list_pdfs_for_source(
        source,
        year_filter=year,
        examen_filter=examen,
        matiere_filter=matiere,
        limit=limit,
    )
    logger.info("Detectes: %d PDF(s) candidats", len(entries))

    if dry_run:
        for e in entries:
            logger.info("[dry-run] %s | %s %s %s -> %s",
                        e.source, e.examen, e.matiere, e.annee, e.url)
        return entries

    manifest = load_manifest()
    existing_urls = {e.url for e in manifest.entries}

    for entry in tqdm(entries, desc=f"DL {source_name}", unit="pdf"):
        if entry.url in existing_urls:
            logger.debug("Deja dans manifeste, skip: %s", entry.url)
            continue
        download_pdf(entry)
        manifest.entries.append(entry)
        save_manifest(manifest)
        time.sleep(_delay(source))

    return entries


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Scraper de PDFs d'annales togolaises."
    )
    parser.add_argument("--source", help="Nom de la source (cf. config.SOURCES).")
    parser.add_argument("--all-sources", action="store_true",
                        help="Scraper toutes les sources configurees.")
    parser.add_argument("--year", type=int, help="Filtre annee (2010-2025).")
    parser.add_argument("--examen", choices=["BEPC", "BAC1", "BAC2"],
                        help="Filtre examen.")
    parser.add_argument("--matiere", help="Filtre matiere (label exact).")
    parser.add_argument("--limit", type=int, help="Nombre max de PDFs.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Lister sans telecharger.")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )

    if args.all_sources:
        sources = list(SOURCES.keys())
    elif args.source:
        sources = [args.source]
    else:
        parser.error("Specifier --source ou --all-sources.")

    total = 0
    for src in sources:
        entries = scrape_source(
            src,
            year=args.year,
            examen=args.examen,
            matiere=args.matiere,
            limit=args.limit,
            dry_run=args.dry_run,
        )
        total += len(entries)

    logger.info("Total: %d entrees traitees.", total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
