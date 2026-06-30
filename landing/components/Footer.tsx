// components/Footer.tsx
// Footer: logo + columns Produit / Entreprise / Contact / Suivez-nous + GitHub + © 2026.
import Link from "next/link";
import { Github, Mail, MapPin } from "lucide-react";

interface FooterCol {
  title: string;
  links: { label: string; href: string; external?: boolean }[];
}

const COLUMNS: FooterCol[] = [
  {
    title: "Produit",
    links: [
      { label: "Problème", href: "#probleme" },
      { label: "Solution", href: "#solution" },
      { label: "Fonctionnalités", href: "#features" },
      { label: "Tarifs", href: "#tarifs" },
      { label: "FAQ", href: "#faq" },
    ],
  },
  {
    title: "Entreprise",
    links: [
      { label: "À propos", href: "#" },
      { label: "Équipe", href: "#" },
      { label: "Pitch DJANTA 2026", href: "#" },
      { label: "Carrières", href: "#" },
    ],
  },
  {
    title: "Contact",
    links: [
      { label: "hello@examboost.tg", href: "mailto:hello@examboost.tg" },
      { label: "+228 90 00 00 00", href: "tel:+22890000000" },
      { label: "Lomé, Togo", href: "#" },
    ],
  },
];

export function Footer() {
  return (
    <footer
      className="bg-togo-ink text-white"
      aria-labelledby="footer-heading"
    >
      <h2 id="footer-heading" className="sr-only">
        Pied de page
      </h2>

      <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-10 md:grid-cols-2 lg:grid-cols-5">
          {/* Brand */}
          <div className="lg:col-span-2">
            <div className="flex items-center gap-2">
              <svg
                viewBox="0 0 40 40"
                className="h-9 w-9"
                role="img"
                aria-label="Logo ExamBoost Togo"
              >
                <rect width="40" height="40" rx="10" fill="#006837" />
                <path
                  d="M11 12h10M11 20h9M11 28h10"
                  stroke="#FFFFFF"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                />
                <circle cx="28" cy="12" r="3" fill="#D97700" />
              </svg>
              <span className="font-outfit text-lg font-extrabold tracking-tight">
                Exam<span className="text-togo-green-light">Boost</span> Togo
              </span>
            </div>
            <p className="mt-4 max-w-sm font-inter text-sm text-white/70">
              La préparation intelligente aux examens nationaux pour chaque
              élève togolais. Hors-ligne, gratuit, aligné sur le programme MEPST.
            </p>

            <div className="mt-6 flex flex-col gap-2 font-inter text-sm text-white/80">
              <a
                href="mailto:hello@examboost.tg"
                className="inline-flex items-center gap-2 hover:text-togo-orange-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green rounded"
              >
                <Mail className="h-4 w-4" aria-hidden="true" />
                hello@examboost.tg
              </a>
              <span className="inline-flex items-center gap-2">
                <MapPin className="h-4 w-4" aria-hidden="true" />
                Lomé, Togo
              </span>
            </div>
          </div>

          {/* Link columns */}
          {COLUMNS.map((col) => (
            <nav key={col.title} aria-label={col.title}>
              <h3 className="font-outfit text-sm font-bold uppercase tracking-wider text-white/90">
                {col.title}
              </h3>
              <ul className="mt-4 space-y-2">
                {col.links.map((link) => (
                  <li key={link.label}>
                    {link.external ? (
                      <a
                        href={link.href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-inter text-sm text-white/70 transition-colors hover:text-togo-orange-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green rounded"
                      >
                        {link.label}
                      </a>
                    ) : (
                      <Link
                        href={link.href}
                        className="font-inter text-sm text-white/70 transition-colors hover:text-togo-orange-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green rounded"
                      >
                        {link.label}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        {/* Bottom bar */}
        <div className="mt-12 flex flex-col items-start justify-between gap-4 border-t border-white/10 pt-6 sm:flex-row sm:items-center">
          <p className="font-inter text-xs text-white/60">
            © 2026 ExamBoost Togo — SmartFarm Togo / AIMS Ghana. Tous droits
            réservés.
          </p>
          <div className="flex items-center gap-4">
            <a
              href="https://github.com/djabelo712/ExamBoost-Togo"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-lg px-3 py-1.5 font-inter text-xs text-white/80 transition-colors hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green"
              aria-label="Voir le code source sur GitHub"
            >
              <Github className="h-4 w-4" aria-hidden="true" />
              <span>GitHub</span>
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
