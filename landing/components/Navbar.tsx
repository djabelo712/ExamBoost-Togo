// components/Navbar.tsx
// Sticky navbar with blur + logo EB inline + nav links + beta CTA.
"use client";

import * as React from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const NAV_LINKS = [
  { href: "#probleme", label: "Problème" },
  { href: "#solution", label: "Solution" },
  { href: "#features", label: "Features" },
  { href: "#tarifs", label: "Tarifs" },
  { href: "#faq", label: "FAQ" },
] as const;

export function Navbar() {
  const [scrolled, setScrolled] = React.useState(false);
  const [open, setOpen] = React.useState(false);

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-50 w-full transition-all duration-300",
        scrolled
          ? "border-b border-gray-100 bg-white/80 backdrop-blur-lg"
          : "bg-transparent"
      )}
    >
      <nav
        className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6 lg:px-8"
        aria-label="Navigation principale"
      >
        <Link
          href="#top"
          className="flex items-center gap-2 rounded-md px-1 py-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green"
        >
          <LogoMark className="h-9 w-9" />
          <span className="font-outfit text-lg font-extrabold tracking-tight text-togo-ink">
            Exam<span className="text-togo-green">Boost</span>
          </span>
        </Link>

        {/* Desktop nav */}
        <ul className="hidden items-center gap-1 md:flex">
          {NAV_LINKS.map((l) => (
            <li key={l.href}>
              <a
                href={l.href}
                className="rounded-lg px-3 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-togo-green-surface hover:text-togo-green focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green"
              >
                {l.label}
              </a>
            </li>
          ))}
        </ul>

        <div className="hidden md:block">
          <a
            href="#beta"
            className={buttonVariants({ variant: "primary", size: "sm" })}
          >
            S'inscrire en bêta
          </a>
        </div>

        {/* Mobile toggle */}
        <button
          type="button"
          className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-togo-ink hover:bg-togo-green-surface focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green md:hidden"
          aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
          aria-expanded={open}
          aria-controls="mobile-menu"
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </nav>

      {/* Mobile menu */}
      {open && (
        <div
          id="mobile-menu"
          className="border-t border-gray-100 bg-white px-4 py-4 md:hidden"
        >
          <ul className="flex flex-col gap-1">
            {NAV_LINKS.map((l) => (
              <li key={l.href}>
                <a
                  href={l.href}
                  onClick={() => setOpen(false)}
                  className="block rounded-lg px-3 py-2 text-base font-medium text-gray-800 hover:bg-togo-green-surface hover:text-togo-green"
                >
                  {l.label}
                </a>
              </li>
            ))}
            <li className="mt-2">
              <a
                href="#beta"
                onClick={() => setOpen(false)}
                className={cn(
                  buttonVariants({ variant: "primary", size: "md" }),
                  "w-full"
                )}
              >
                S'inscrire en bêta
              </a>
            </li>
          </ul>
        </div>
      )}
    </header>
  );
}

// Local logo mark: green rounded square with white "EB" monogram.
function LogoMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 40 40"
      className={className}
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
      <text
        x="20"
        y="34"
        textAnchor="middle"
        fontFamily="Outfit, system-ui, sans-serif"
        fontSize="9"
        fontWeight="800"
        fill="#FFFFFF"
      >
        EB
      </text>
    </svg>
  );
}
