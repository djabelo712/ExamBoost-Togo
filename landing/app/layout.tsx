// app/layout.tsx
// Root layout: fonts (Outfit + Inter via next/font) + SEO metadata.
import type { Metadata, Viewport } from "next";
import { Outfit, Inter } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
  variable: "--font-outfit-variable",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-inter-variable",
  display: "swap",
});

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://examboost-landing.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "ExamBoost Togo — Réussis ton BEPC et ton BAC avec l'IA",
    template: "%s · ExamBoost Togo",
  },
  description:
    "Application mobile gratuite, alignée sur le programme togolais, qui s'adapte à ton niveau. Hors-ligne, sur Android 5+, pour préparer BEPC et BAC avec l'IA adaptative.",
  keywords: [
    "BEPC Togo",
    "BAC Togo",
    "préparation examen",
    "révision adaptative",
    "IA éducation Afrique",
    "annales BEPC",
    "annales BAC Togo",
    "ExamBoost",
  ],
  authors: [{ name: "SmartFarm Togo / AIMS Ghana" }],
  creator: "ExamBoost Togo",
  publisher: "ExamBoost Togo",
  alternates: {
    canonical: "/",
    languages: { fr: "/" },
  },
  openGraph: {
    type: "website",
    locale: "fr_TG",
    url: siteUrl,
    siteName: "ExamBoost Togo",
    title: "ExamBoost Togo — Réussis ton BEPC et ton BAC avec l'IA",
    description:
      "Application mobile gratuite, alignée sur le programme togolais, qui s'adapte à ton niveau. Hors-ligne, sur Android 5+.",
    images: [
      {
        url: "/og-image.svg",
        width: 1200,
        height: 630,
        alt: "ExamBoost Togo — Préparation intelligente aux examens nationaux",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "ExamBoost Togo — Réussis ton BEPC et ton BAC avec l'IA",
    description:
      "Application mobile gratuite, alignée sur le programme togolais, hors-ligne, Android 5+.",
    images: ["/og-image.svg"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
    },
  },
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
    shortcut: ["/favicon.svg"],
  },
  category: "education",
};

export const viewport: Viewport = {
  themeColor: "#006837",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="fr"
      className={`${outfit.variable} ${inter.variable}`}
      suppressHydrationWarning
    >
      <body className="font-inter antialiased">
        <a href="#main" className="skip-link">
          Aller au contenu
        </a>
        {children}
      </body>
    </html>
  );
}
