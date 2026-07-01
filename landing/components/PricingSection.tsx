// components/PricingSection.tsx
// 2 pricing cards: Élève gratuit + Établissement 100k FCFA/an.
"use client";

import { motion } from "framer-motion";
import { Check } from "lucide-react";
import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface Plan {
  name: string;
  price: string;
  period: string;
  description: string;
  features: string[];
  cta: { label: string; href: string };
  featured?: boolean;
  badge?: string;
}

const PLANS: Plan[] = [
  {
    name: "Élève",
    price: "0",
    period: "FCFA",
    description: "Tout ExamBoost, pour toujours, sans payer un franc.",
    features: [
      "Révision adaptative illimitée (SM-2 + IRT 3PL)",
      "Simulations d'examens chrono BEPC et BAC",
      "Dashboard de progression + prédiction de score",
      "Accès aux 3 000+ questions officielles",
      "Fonctionnement 100 % hors-ligne",
      "Mises à jour gratuites du catalogue",
    ],
    cta: { label: "Rejoindre la bêta", href: "#beta" },
    badge: "Pour l'élève",
  },
  {
    name: "Établissement",
    price: "100 000",
    period: "FCFA / an",
    description:
      "Dashboard agrégé par classe, alertes précoces, accompagnement dédié.",
    features: [
      "Tout ce qui est inclus dans Élève",
      "Dashboard établissement : suivi par classe et par matière",
      "Alertes précoces sur élèves en difficulté (BKT < 0,4)",
      "Rapports trimestriels pour la direction et les parents",
      "Badge « Partenaire ExamBoost » pour l'établissement",
      "Support dédié + formation équipe pédagogique",
    ],
    cta: { label: "Demander une démo", href: "#beta" },
    featured: true,
    badge: "Pour les écoles",
  },
];

export function PricingSection() {
  return (
    <section
      id="tarifs"
      className="bg-white py-20 sm:py-24"
      aria-labelledby="pricing-title"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <p className="font-inter text-sm font-semibold uppercase tracking-wider text-togo-orange">
            Tarifs
          </p>
          <h2
            id="pricing-title"
            className="mt-3 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl"
          >
            Gratuit pour l'élève. Durable pour ExamBoost.
          </h2>
          <p className="mt-4 font-inter text-lg text-gray-700">
            L'application est gratuite pour chaque élève togolais. Les
            établissements financent la mission.
          </p>
        </div>

        <div className="mx-auto mt-14 grid max-w-4xl grid-cols-1 gap-6 md:grid-cols-2">
          {PLANS.map((plan, i) => (
            <motion.div
              key={plan.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.5, delay: i * 0.12 }}
            >
              <Card
                className={cn(
                  "h-full",
                  plan.featured &&
                    "border-2 border-togo-green shadow-md ring-1 ring-togo-green/20"
                )}
              >
                <CardContent className="flex h-full flex-col p-8">
                  <div className="flex items-center justify-between">
                    <h3 className="font-outfit text-xl font-bold text-togo-ink">
                      {plan.name}
                    </h3>
                    {plan.badge && (
                      <Badge variant={plan.featured ? "solid" : "neutral"}>
                        {plan.badge}
                      </Badge>
                    )}
                  </div>

                  <div className="mt-5 flex items-baseline gap-2">
                    <span className="font-outfit text-5xl font-extrabold text-togo-green">
                      {plan.price}
                    </span>
                    <span className="font-inter text-base text-gray-500">
                      {plan.period}
                    </span>
                  </div>

                  <p className="mt-3 font-inter text-sm text-gray-600">
                    {plan.description}
                  </p>

                  <ul className="mt-6 flex-1 space-y-3">
                    {plan.features.map((f) => (
                      <li
                        key={f}
                        className="flex items-start gap-2 font-inter text-sm text-gray-700"
                      >
                        <Check
                          className="mt-0.5 h-4 w-4 flex-shrink-0 text-togo-green"
                          aria-hidden="true"
                        />
                        <span>{f}</span>
                      </li>
                    ))}
                  </ul>

                  <a
                    href={plan.cta.href}
                    className={cn(
                      buttonVariants({
                        variant: plan.featured ? "primary" : "outline",
                        size: "lg",
                      }),
                      "mt-8 w-full"
                    )}
                  >
                    {plan.cta.label}
                  </a>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>

        <p className="mx-auto mt-10 max-w-2xl text-center font-inter text-sm text-gray-500">
          Seuil de rentabilité projeté : 300 établissements partenaires d'ici la
          fin de l'année 2. Modèle B2B2C inspiré d'EDVES Nigeria.
        </p>
      </div>
    </section>
  );
}
