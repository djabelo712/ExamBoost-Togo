// components/BetaCTA.tsx
// Final CTA: "Rejoins les 500 premiers" + EmailForm + counter.
"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Sparkles } from "lucide-react";
import { EmailForm } from "@/components/EmailForm";

// Static counter — would be hydrated from API in production.
const INSCRITS_BASE = 234;
const INSCRITS_CIBLE = 500;

export function BetaCTA() {
  return (
    <section
      id="beta"
      className="relative overflow-hidden bg-togo-green-dark py-20 text-white sm:py-24"
      aria-labelledby="beta-title"
    >
      {/* Decorative gradient */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 bg-gradient-to-br from-togo-green via-togo-green to-togo-green-dark"
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -left-32 bottom-0 h-96 w-96 rounded-full bg-togo-orange/30 blur-3xl"
      />

      <div className="relative mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 rounded-full bg-togo-orange/20 px-3 py-1 text-xs font-semibold text-togo-orange-light"
          >
            <Sparkles className="h-3.5 w-3.5" aria-hidden="true" />
            <span>Bêta fermée · 500 places</span>
          </motion.div>

          <motion.h2
            id="beta-title"
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6, delay: 0.05 }}
            className="mt-5 font-outfit text-3xl font-extrabold tracking-tight sm:text-4xl lg:text-5xl"
          >
            Rejoins les{" "}
            <span className="text-togo-orange-light">500 premiers</span>{" "}
            bêta-testeurs
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6, delay: 0.15 }}
            className="mx-auto mt-5 max-w-xl font-inter text-lg text-white/85"
          >
            Tu seras parmi les premiers à tester ExamBoost. Ton avis façonne le
            produit. Tu reçois l'APK en avant-première, dès le pilote Lomé.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6, delay: 0.25 }}
            className="mt-10 flex justify-center"
          >
            <EmailForm
              variant="hero"
              idSuffix="beta"
              redirectToMerci
            />
          </motion.div>

          <BetaCounter inscrits={INSCRITS_BASE} cible={INSCRITS_CIBLE} />
        </div>
      </div>
    </section>
  );
}

function BetaCounter({
  inscrits,
  cible,
}: {
  inscrits: number;
  cible: number;
}) {
  const pct = Math.min(100, Math.round((inscrits / cible) * 100));

  return (
    <motion.div
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.6, delay: 0.35 }}
      className="mx-auto mt-10 max-w-md"
    >
      <div className="flex items-center justify-between text-sm text-white/80">
        <span className="font-inter">
          <strong className="font-semibold text-white">{inscrits}</strong>{" "}
          inscrits
        </span>
        <span className="font-inter">{cible} places</span>
      </div>
      <div
        className="mt-2 h-2 w-full overflow-hidden rounded-full bg-white/15"
        role="progressbar"
        aria-label="Progression des inscriptions bêta"
        aria-valuenow={inscrits}
        aria-valuemin={0}
        aria-valuemax={cible}
      >
        <motion.div
          initial={{ width: 0 }}
          whileInView={{ width: `${pct}%` }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 1.2, ease: "easeOut", delay: 0.4 }}
          className="h-full rounded-full bg-togo-orange"
        />
      </div>
      <p className="mt-3 text-center font-inter text-xs text-white/70">
        Plus que {Math.max(0, cible - inscrits)} places avant la fermeture de la
        bêta.
      </p>
    </motion.div>
  );
}
