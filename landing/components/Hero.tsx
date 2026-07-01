// components/Hero.tsx
// Hero section: gradient green background + H1 + tagline + EmailForm + trust badges.
"use client";

import { motion } from "framer-motion";
import { WifiOff, BadgeCheck, Smartphone } from "lucide-react";
import { EmailForm } from "@/components/EmailForm";
import { Badge } from "@/components/ui/badge";

export function Hero() {
  return (
    <section
      id="top"
      className="relative overflow-hidden bg-togo-green-dark text-white"
      aria-labelledby="hero-title"
    >
      {/* Decorative gradient + grid */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-gradient-to-br from-togo-green via-togo-green to-togo-green-dark"
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 opacity-[0.07]"
        style={{
          backgroundImage:
            "radial-gradient(circle at 1px 1px, white 1px, transparent 0)",
          backgroundSize: "32px 32px",
        }}
      />
      {/* Orange glow */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -right-32 -top-32 h-96 w-96 rounded-full bg-togo-orange/30 blur-3xl"
      />

      <div className="relative mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-24 lg:px-8 lg:py-28">
        <div className="mx-auto max-w-3xl text-center">
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <Badge variant="solidOrange" className="mb-5">
              Bêta ouverte · Pilote Lomé 2026
            </Badge>
          </motion.div>

          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="font-inter text-sm font-medium uppercase tracking-wider text-white/70 sm:text-base"
          >
            Préparation intelligente aux examens nationaux
          </motion.p>

          <motion.h1
            id="hero-title"
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="mt-4 font-outfit text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl lg:text-6xl"
          >
            Réussis ton{" "}
            <span className="text-togo-orange-light">BEPC</span> et ton{" "}
            <span className="text-togo-orange-light">BAC</span> avec l'IA
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="mx-auto mt-6 max-w-2xl font-inter text-lg text-white/85 sm:text-xl"
          >
            Une application mobile gratuite, alignée sur le programme togolais,
            qui s'adapte à ton niveau. Hors-ligne, sur ton téléphone, partout au
            Togo.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="mt-10 flex justify-center"
          >
            <EmailForm variant="hero" idSuffix="hero" />
          </motion.div>

          <motion.ul
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="mt-8 flex flex-wrap items-center justify-center gap-x-6 gap-y-3 text-sm text-white/80"
          >
            <li className="inline-flex items-center gap-2">
              <BadgeCheck className="h-4 w-4 text-togo-orange-light" aria-hidden="true" />
              <span>100 % gratuit pour l'élève</span>
            </li>
            <li className="inline-flex items-center gap-2">
              <Smartphone className="h-4 w-4 text-togo-orange-light" aria-hidden="true" />
              <span>Android 5+ · APK &lt; 25 Mo</span>
            </li>
            <li className="inline-flex items-center gap-2">
              <WifiOff className="h-4 w-4 text-togo-orange-light" aria-hidden="true" />
              <span>Fonctionne hors-ligne</span>
            </li>
          </motion.ul>
        </div>
      </div>

      {/* Bottom wave */}
      <svg
        aria-hidden="true"
        viewBox="0 0 1440 80"
        preserveAspectRatio="none"
        className="block h-12 w-full fill-togo-cream sm:h-16"
      >
        <path d="M0 80 L0 40 Q360 0 720 40 T1440 40 L1440 80 Z" />
      </svg>
    </section>
  );
}
