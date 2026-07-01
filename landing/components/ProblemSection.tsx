// components/ProblemSection.tsx
// "Une crise silencieuse" — 3 animated count-up stats.
"use client";

import { useEffect, useRef, useState } from "react";
import { useInView, useMotionValue, useSpring, motion } from "framer-motion";

interface Stat {
  value: number;
  suffix: string;
  label: string;
  source: string;
}

const STATS: Stat[] = [
  {
    value: 44,
    suffix: " %",
    label: "Taux de réussite au BEPC 2024",
    source: "MEPST Togo — chute de 37 points en un an",
  },
  {
    value: 86,
    suffix: " %",
    label: "Enfants togolais de 10 ans ne lisant pas couramment",
    source: "Banque Mondiale — Learning Poverty Brief 2019",
  },
  {
    value: 0,
    suffix: "",
    label: "Outil numérique aligné sur le programme BEPC/BAC togolais",
    source: "Audit ExamBoost — juin 2026",
  },
];

export function ProblemSection() {
  return (
    <section
      id="probleme"
      className="bg-togo-cream py-20 sm:py-24"
      aria-labelledby="problem-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            Le problème
          </p>
          <h2
            id="problem-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Une crise silencieuse
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            Les élèves togolais n'ont pas les outils pour réussir. Une crise
            documentée, mesurable, urgente.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-8 md:grid-cols-3">
          {STATS.map((stat, i) => (
            <StatCard key={i} stat={stat} delay={i * 0.12} />
          ))}
        </div>

        <p className="mx-auto mt-12 max-w-2xl text-center font-inter text-xs italic text-gray-500">
          Sources : MEPST Togo 2024 ; World Bank Learning Poverty Brief 2019 ;
          enquête terrain ExamBoost Lomé, juin 2026.
        </p>
      </div>
    </section>
  );
}

function StatCard({ stat, delay }: { stat: Stat; delay: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });
  const [display, setDisplay] = useState(0);

  const mv = useMotionValue(0);
  const spring = useSpring(mv, {
    stiffness: 70,
    damping: 20,
    duration: 1400,
  });

  useEffect(() => {
    if (inView) {
      const t = setTimeout(() => mv.set(stat.value), 60 + delay * 1000);
      return () => clearTimeout(t);
    }
  }, [inView, stat.value, mv, delay]);

  useEffect(() => {
    const unsub = spring.on("change", (v) => {
      setDisplay(Math.round(v));
    });
    return () => unsub();
  }, [spring]);

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 16 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay }}
      className="rounded-2xl border border-gray-100 bg-white p-8 text-center shadow-sm"
    >
      <div className="font-outfit text-6xl font-extrabold text-togo-orange sm:text-7xl">
        {display}
        {stat.suffix}
      </div>
      <p className="mt-4 font-inter text-base font-medium text-togo-ink">
        {stat.label}
      </p>
      <p className="mt-2 font-inter text-sm text-gray-500">{stat.source}</p>
    </motion.div>
  );
}
