// components/FeaturesSection.tsx
// 5 features grid with Lucide icons.
"use client";

import { motion } from "framer-motion";
import {
  BrainCircuit,
  Timer,
  LayoutDashboard,
  FileCheck2,
  CloudOff,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

interface Feature {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
}

const FEATURES: Feature[] = [
  {
    icon: BrainCircuit,
    title: "Révision adaptive",
    description:
      "Chaque question est calibrée à ton niveau par l'IRT. Les cartes reviennent au moment optimal grâce à SM-2. Tu progresses sans perdre une minute.",
  },
  {
    icon: Timer,
    title: "Simulation chrono",
    description:
      "Examen blanc complet : BEPC 2h, BAC 4h, minuteur officiel, plan d'examen, marquage de questions. Conditions réelles, sanctions réelles.",
  },
  {
    icon: LayoutDashboard,
    title: "Dashboard + prédiction",
    description:
      "Suis ta maîtrise compétence par compétence. Prédiction de score BEPC/BAC, heatmap de tes chapitres faibles, streak de révision quotidien.",
  },
  {
    icon: FileCheck2,
    title: "Annales officielles",
    description:
      "Plus de 3 000 questions extraites des sujets BEPC et BAC 2010-2025. Maths, Français, Physique, SVT, Histoire-Géo, Anglais. Toutes séries.",
  },
  {
    icon: CloudOff,
    title: "Mode offline",
    description:
      "Télécharge une fois, révise partout. Bus, taxi-moto, village, coupure courant : l'app fonctionne 100 % sans connexion. Données locales chiffrées.",
  },
];

export function FeaturesSection() {
  return (
    <section
      id="features"
      className="bg-togo-cream py-20 sm:py-24"
      aria-labelledby="features-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            Fonctionnalités
          </p>
          <h2
            id="features-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Tout ce qu'il faut pour réussir
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            Cinq outils intégrés dans une seule application légère.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => {
            const Icon = f.icon;
            const isLarge = i === 0; // First card spans 2 columns on large screens.
            return (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ duration: 0.5, delay: i * 0.08 }}
                className={isLarge ? "lg:col-span-2" : ""}
              >
                <Card className="h-full hover:shadow-md">
                  <CardContent className="flex h-full flex-col gap-4 p-6 sm:flex-row sm:items-start sm:gap-5 sm:p-7">
                    <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-xl bg-togo-orange-surface text-togo-orange">
                      <Icon className="h-5 w-5" aria-hidden="true" />
                    </div>
                    <div>
                      <h3 className="font-outfit text-lg font-bold text-togo-ink">
                        {f.title}
                      </h3>
                      <p className="mt-2 font-inter text-sm text-gray-600">
                        {f.description}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            );
          })}

          {/* Filler card with mini stats to balance the 5-feature grid */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.5, delay: 0.4 }}
          >
            <Card className="h-full bg-togo-green text-white">
              <CardContent className="flex h-full flex-col justify-between gap-4 p-6 sm:p-7">
                <div>
                  <p className="font-inter text-xs font-semibold uppercase tracking-wider text-togo-orange-light">
                    En bref
                  </p>
                  <h3 className="mt-1 font-outfit text-lg font-bold">
                    Conçu pour le terrain
                  </h3>
                </div>
                <dl className="grid grid-cols-2 gap-4 font-inter">
                  <div>
                    <dt className="text-xs text-white/70">Taille APK</dt>
                    <dd className="text-xl font-bold">&lt; 25 Mo</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-white/70">Android</dt>
                    <dd className="text-xl font-bold">5.0+</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-white/70">Questions</dt>
                    <dd className="text-xl font-bold">3 000+</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-white/70">Cible</dt>
                    <dd className="text-xl font-bold">+15 pts</dd>
                  </div>
                </dl>
              </CardContent>
            </Card>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
