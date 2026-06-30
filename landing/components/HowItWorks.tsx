// components/HowItWorks.tsx
// 3 steps: Crée profil → Révise 15 min/jour → Simule examen.
"use client";

import { motion } from "framer-motion";
import { UserPlus, CalendarCheck, ClipboardCheck } from "lucide-react";

interface Step {
  num: string;
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
}

const STEPS: Step[] = [
  {
    num: "01",
    icon: UserPlus,
    title: "Crée ton profil",
    description:
      "Niveau (3e, Terminale C/D, etc.), matières prioritaires, prochain examen. 2 minutes, sans connexion.",
  },
  {
    num: "02",
    icon: CalendarCheck,
    title: "Révise 15 min par jour",
    description:
      "L'algorithme te sert les bonnes cartes au bon moment. Streak quotidien, rétroaction immédiate, progression visible.",
  },
  {
    num: "03",
    icon: ClipboardCheck,
    title: "Simule ton examen",
    description:
      "Examen blanc chrono, conditions réelles. Tu sais exactement où tu en es — et ce qui te reste à travailler.",
  },
];

export function HowItWorks() {
  return (
    <section
      id="comment"
      className="bg-white py-20 sm:py-24"
      aria-labelledby="how-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            Comment ça marche
          </p>
          <h2
            id="how-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Trois étapes. Aucune excuse.
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            Du premier lancement à ta simulation d'examen, en moins d'une
            semaine.
          </p>
        </div>

        <ol className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-3">
          {STEPS.map((step, i) => {
            const Icon = step.icon;
            return (
              <motion.li
                key={step.num}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{ duration: 0.5, delay: i * 0.12 }}
                className="relative rounded-2xl border border-gray-100 bg-white p-8 shadow-sm"
              >
                <div className="absolute right-6 top-6 font-outfit text-5xl font-extrabold text-gray-100">
                  {step.num}
                </div>
                <div className="relative flex h-12 w-12 items-center justify-center rounded-xl bg-togo-green text-white">
                  <Icon className="h-6 w-6" aria-hidden="true" />
                </div>
                <h3 className="relative mt-5 font-outfit text-xl font-bold text-togo-ink">
                  {step.title}
                </h3>
                <p className="relative mt-3 font-inter text-base text-gray-600">
                  {step.description}
                </p>
              </motion.li>
            );
          })}
        </ol>
      </div>
    </section>
  );
}
