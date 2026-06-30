// lib/validators.ts
// Zod schemas for the beta signup form.
import { z } from "zod";

export const betaRoles = ["eleve", "enseignant", "directeur", "autre"] as const;
export type BetaRole = (typeof betaRoles)[number];

export const betaSignupSchema = z.object({
  email: z
    .string()
    .min(1, "Email requis")
    .email("Email invalide")
    .max(254, "Email trop long")
    .trim()
    .toLowerCase(),
  role: z.enum(betaRoles, {
    errorMap: () => ({ message: "Rôle invalide" }),
  }),
});

export type BetaSignupInput = z.infer<typeof betaSignupSchema>;

export const roleLabels: Record<BetaRole, string> = {
  eleve: "Élève",
  enseignant: "Enseignant",
  directeur: "Directeur / Établissement",
  autre: "Autre",
};
