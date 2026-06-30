// components/SolutionSection.tsx
// "3 piliers" — Adaptatif / Localisé / Hors-ligne.
"use client";

import { motion } from "framer-motion";
import { Brain, Library, WifiOff } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

interface Pillar {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  tag: string;
  description: string;
}

const PILLARS: Pillar[] = [
  {
    icon: Brain,
    title: "Adaptatif par IA",
    tag: "IRT + SM-2 + BKT",
    description:
      "L'algorithme SM-2 planifie tes révisions au moment optimal. L'IRT 3PL calibre chaque question à ton niveau exact. Le BKT suit ta maîtrise compétence par compétence.",
  },
  {
    icon: Library,
    title: "Localisé pour le Togo",
    tag: "Annales 2010-2025",
    description:
      "Plus de 3 000 questions extraites des sujets officiels BEPC et BAC de 2010 à 2025. Alignées sur le programme MEPST, en français togolais.",
  },
  {
    icon: WifiOff,
    title: "Hors-ligne, sur smartphone basique",
    tag: "APK < 25 Mo · Android 5+",
    description:
      "L'app fonctionne 100 % sans connexion. Testée sur Tecno, Itel, Infinix. 25 Mo à télécharger une fois, des mois de révision autonomes.",
  },
];

export function SolutionSection() {
  return (
    <section
      id="solution"
      className="bg-white py-20 sm:py-24"
      aria-labelledby="solution-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            La solution
          </p>
          <h2
            id="solution-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            3 piliers, un seul objectif
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            Mettre chaque élève togolais dans les conditions de réussir son
            examen national.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-3">
          {PILLARS.map((pillar, i) => {
            const Icon = pillar.icon;
            return (
              <motion.div
                key={pillar.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
              >
                <Card className="h-full hover:shadow-md">
                  <CardContent className="flex h-full flex-col gap-4 p-8">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-togo-green-surface text-togo-green">
                      <Icon className="h-6 w-6" aria-hidden="true" />
                    </div>
                    <div>
                      <span className="font-inter text-xs font-semibold uppercase tracking-wider text-togo-orange">
                        {pillar.tag}
                      </span>
                      <h3 className="mt-1 font-outfit text-xl font-bold text-togo-ink">
                        {pillar.title}
                      </h3>
                    </div>
                    <p className="font-inter text-base text-gray-600">
                      {pillar.description}
                    </p>
                  </CardContent>
                </Card>
              </motion.div>
            );
          })}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.5 }}
          className="mx-auto mt-10 max-w-3xl rounded-2xl bg-togo-green-surface px-6 py-5 text-center"
        >
          <p className="font-inter text-base font-semibold text-togo-green-dark">
            Objectif : +15 points de pourcentage aux examens après 6 mois
            d'utilisation régulière.
          </p>
        </motion.div>
      </div>
    </section>
  );
}
