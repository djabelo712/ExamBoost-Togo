// components/FAQSection.tsx
// 8 questions in an accessible accordion (single-open by default).
"use client";

import * as React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

interface QA {
  q: string;
  a: string;
}

const FAQS: QA[] = [
  {
    q: "Faut-il une connexion Internet pour utiliser ExamBoost ?",
    a: "Non. ExamBoost fonctionne 100 % hors-ligne après une première installation. Tu peux réviser, simuler un examen et suivre ta progression sans aucune connexion. Une connexion est utile uniquement pour télécharger l'APK et recevoir les mises à jour du catalogue de questions.",
  },
  {
    q: "Quels examens sont couverts ?",
    a: "ExamBoost couvre le BEPC, le Probatoire, le BAC 1 et le BAC 2 togolais, en séries A, B, C, D et F. Les questions sont alignées sur le programme officiel du MEPST et extraites des annales 2010 à 2025.",
  },
  {
    q: "Sur quels téléphones l'application fonctionne-t-elle ?",
    a: "Sur tout smartphone Android à partir de la version 5.0 (Lollipop). L'APK pèse moins de 25 Mo et a été testée sur Tecno, Itel et Infinix, y compris les modèles avec 1 Go de RAM. iOS n'est pas dans la roadmap court terme.",
  },
  {
    q: "L'application est-elle vraiment gratuite pour l'élève ?",
    a: "Oui, 100 % gratuite. Aucune publicité, aucun freemium. Le modèle économique repose sur les licences établissements (100 000 FCFA/an), les grants éducatifs (GPE, UNICEF, AFD) et une API de données pour le Ministère. L'élève ne paie jamais.",
  },
  {
    q: "Comment les questions sont-elles créées ?",
    a: "Les questions proviennent de deux sources : (1) un pipeline OCR qui extrait automatiquement les sujets officiels scannés depuis 2010, avec validation humaine ; (2) un comité pédagogique d'enseignants togolais qui rédige et relit. Chaque question est calibrée par IRT à partir des réponses réelles des élèves.",
  },
  {
    q: "L'IA adaptative, comment ça marche concrètement ?",
    a: "Trois algorithmes complémentaires : SM-2 planifie chaque carte au moment optimal pour contrer l'oubli ; IRT 3PL calibre la difficulté de chaque question à ton niveau θ ; BKT estime ta probabilité de maîtrise P(L) par compétence, avec un seuil de maîtrise à 0,85. La prochaine question choisie est toujours celle qui t'apprend le plus.",
  },
  {
    q: "Mes données personnelles sont-elles protégées ?",
    a: "Oui. Toutes les données restent sur ton téléphone (stockage local chiffré). Aucune donnée personnelle n'est envoyée à un serveur sans ton consentement explicite. ExamBoost se conforme à la loi togolaise 2019-014 sur la protection des données et au RGPD pour les utilisateurs européens éventuels.",
  },
  {
    q: "Quand l'application sera-t-elle disponible au grand public ?",
    a: "La bêta ouvre en 2026 pour 500 premiers testeurs (élèves et enseignants). Le pilote officiel avec 5 établissements de Lomé démarre en M5-M6. Le déploiement Play Store national est prévu en M8, après calibration IRT réelle sur les données pilote.",
  },
];

export function FAQSection() {
  const [openIdx, setOpenIdx] = React.useState<number | null>(0);

  return (
    <section
      id="faq"
      className="bg-togo-cream py-20 sm:py-24"
      aria-labelledby="faq-title"
    >
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            FAQ
          </p>
          <h2
            id="faq-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Questions fréquentes
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            Tout ce que tu dois savoir avant de rejoindre la bêta.
          </p>
        </div>

        <div className="mt-12 space-y-3">
          {FAQS.map((faq, i) => {
            const isOpen = openIdx === i;
            return (
              <div
                key={i}
                className="overflow-hidden rounded-xl border border-gray-100 bg-white"
              >
                <h3>
                  <button
                    type="button"
                    onClick={() => setOpenIdx(isOpen ? null : i)}
                    aria-expanded={isOpen}
                    aria-controls={`faq-panel-${i}`}
                    id={`faq-trigger-${i}`}
                    className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left font-inter text-base font-semibold text-togo-ink transition-colors hover:bg-togo-green-surface focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green"
                  >
                    <span>{faq.q}</span>
                    <ChevronDown
                      className={cn(
                        "h-5 w-5 flex-shrink-0 text-togo-green transition-transform duration-300",
                        isOpen && "rotate-180"
                      )}
                      aria-hidden="true"
                    />
                  </button>
                </h3>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      id={`faq-panel-${i}`}
                      role="region"
                      aria-labelledby={`faq-trigger-${i}`}
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.25, ease: "easeOut" }}
                      className="overflow-hidden"
                    >
                      <p className="px-5 pb-5 font-inter text-base text-gray-600">
                        {faq.a}
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
