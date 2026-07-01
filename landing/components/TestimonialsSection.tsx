// components/TestimonialsSection.tsx
// 2 student quotes (Terminale C Lomé + 3e Atakpamé).
"use client";

import { motion } from "framer-motion";
import { Quote } from "lucide-react";

interface Testimonial {
  quote: string;
  author: string;
  context: string;
}

const TESTIMONIALS: Testimonial[] = [
  {
    quote:
      "Je révise avec des PDF sur WhatsApp, mais c'est complètement désorganisé. J'aimerais un vrai parcours de révision.",
    author: "Élève, Terminale C",
    context: "Lomé — Enquête terrain juin 2026",
  },
  {
    quote:
      "J'aimerais tant savoir où j'en suis vraiment dans mes révisions. Mes profs ne le disent pas assez précisément.",
    author: "Élève, classe de 3e",
    context: "Atakpamé — Enquête terrain juin 2026",
  },
];

export function TestimonialsSection() {
  return (
    <section
      id="temoignages"
      className="bg-togo-cream py-20 sm:py-24"
      aria-labelledby="testimonials-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            Témoignages
          </p>
          <h2
            id="testimonials-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Ce que disent les élèves
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            30 élèves interrogés à Lomé en juin 2026. Voici deux voix parmi
            beaucoup d'autres.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-2">
          {TESTIMONIALS.map((t, i) => (
            <motion.figure
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.5, delay: i * 0.12 }}
              className="rounded-2xl border border-gray-100 border-l-4 border-l-togo-orange bg-white p-8 shadow-sm"
            >
              <Quote
                className="h-8 w-8 text-togo-orange/40"
                aria-hidden="true"
              />
              <blockquote className="mt-4 font-inter text-lg italic text-togo-ink">
                « {t.quote} »
              </blockquote>
              <figcaption className="mt-5 flex flex-col gap-0.5">
                <span className="font-outfit text-base font-bold text-togo-green">
                  {t.author}
                </span>
                <span className="font-inter text-sm text-gray-500">
                  {t.context}
                </span>
              </figcaption>
            </motion.figure>
          ))}
        </div>

        <p className="mx-auto mt-10 max-w-2xl text-center font-inter text-sm text-gray-600">
          Sur 30 élèves interrogés :{" "}
          <strong className="font-semibold text-togo-ink">87 %</strong> n'ont
          aucun outil numérique pour préparer leurs examens,{" "}
          <strong className="font-semibold text-togo-ink">94 %</strong> sont
          prêts à utiliser ExamBoost dès aujourd'hui.
        </p>
      </div>
    </section>
  );
}
