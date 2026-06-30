// components/EmailForm.tsx
// Reusable beta signup form: idle / loading / success / error states.
// Uses React Hook Form + Zod, posts to /api/beta-signup.
"use client";

import * as React from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { motion, AnimatePresence } from "framer-motion";
import { Check, Loader2, AlertCircle, ArrowRight } from "lucide-react";
import {
  betaSignupSchema,
  betaRoles,
  roleLabels,
  type BetaRole,
} from "@/lib/validators";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

type FormValues = {
  email: string;
  role: BetaRole;
};

type SubmitState = "idle" | "loading" | "success" | "error";

interface EmailFormProps {
  /** Visual variant for the hero context. */
  variant?: "hero" | "section";
  /** Redirect to /merci on success instead of showing inline success. */
  redirectToMerci?: boolean;
  /** Optional id suffix for accessibility when multiple forms on the same page. */
  idSuffix?: string;
  className?: string;
}

export function EmailForm({
  variant = "section",
  redirectToMerci = false,
  idSuffix = "",
  className,
}: EmailFormProps) {
  const [submitState, setSubmitState] = React.useState<SubmitState>("idle");
  const [serverError, setServerError] = React.useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<FormValues>({
    resolver: zodResolver(betaSignupSchema),
    defaultValues: {
      email: "",
      role: "eleve",
    },
  });

  const onSubmit = async (values: FormValues) => {
    setSubmitState("loading");
    setServerError(null);
    try {
      const res = await fetch("/api/beta-signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(values),
      });
      const data = (await res.json().catch(() => ({}))) as {
        ok?: boolean;
        message?: string;
        error?: string;
      };

      if (res.ok && data.ok) {
        setSubmitState("success");
        reset();
        if (redirectToMerci) {
          // Small delay so the success state is visible before navigating.
          setTimeout(() => {
            window.location.href = "/merci";
          }, 600);
        }
        return;
      }

      setSubmitState("error");
      setServerError(
        data.error ?? "Une erreur est survenue. Réessaie dans un instant."
      );
    } catch {
      setSubmitState("error");
      setServerError("Connexion impossible. Vérifie ton réseau.");
    }
  };

  const isHero = variant === "hero";
  const inputId = `email-${idSuffix || "default"}`;
  const roleGroupId = `role-${idSuffix || "default"}`;

  return (
    <div
      className={cn(
        "w-full",
        isHero ? "max-w-xl" : "max-w-lg",
        className
      )}
    >
      <form onSubmit={handleSubmit(onSubmit)} noValidate className="w-full">
        <div
          className={cn(
            "flex flex-col gap-3",
            isHero && "sm:flex-row sm:items-start"
          )}
        >
          <div className="flex-1">
            <label htmlFor={inputId} className="sr-only">
              Adresse e-mail
            </label>
            <Input
              id={inputId}
              type="email"
              autoComplete="email"
              inputMode="email"
              placeholder="ton@email.tg"
              aria-invalid={!!errors.email}
              aria-describedby={
                errors.email ? `${inputId}-error` : undefined
              }
              disabled={submitState === "loading"}
              {...register("email")}
            />
            {errors.email && (
              <p
                id={`${inputId}-error`}
                className="mt-1.5 text-xs text-red-600"
                role="alert"
              >
                {errors.email.message}
              </p>
            )}
          </div>

          <Button
            type="submit"
            variant={isHero ? "orange" : "primary"}
            size={isHero ? "lg" : "md"}
            disabled={submitState === "loading"}
            className={cn(isHero ? "sm:w-auto" : "w-full")}
          >
            {submitState === "loading" ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                <span>Inscription…</span>
              </>
            ) : (
              <>
                <span>Je rejoins la bêta</span>
                <ArrowRight className="h-4 w-4" aria-hidden="true" />
              </>
            )}
          </Button>
        </div>

        {/* Role selector */}
        <fieldset
          className="mt-4"
          aria-labelledby={roleGroupId}
          disabled={submitState === "loading"}
        >
          <legend id={roleGroupId} className="sr-only">
            Je suis
          </legend>
          <div
            className={cn(
              "flex flex-wrap gap-2",
              isHero && "text-white"
            )}
          >
            <span
              className={cn(
                "mr-1 inline-flex items-center text-xs font-medium",
                isHero ? "text-white/80" : "text-gray-600"
              )}
            >
              Je suis&nbsp;:
            </span>
            {betaRoles.map((role) => (
              <RoleChip
                key={role}
                role={role}
                isHero={isHero}
                register={register}
              />
            ))}
          </div>
        </fieldset>
      </form>

      <AnimatePresence mode="wait">
        {submitState === "success" && !redirectToMerci && (
          <motion.div
            key="success"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="mt-4 flex items-center gap-2 rounded-xl bg-togo-green-surface px-4 py-3 text-sm font-medium text-togo-green-dark"
            role="status"
          >
            <Check className="h-4 w-4" aria-hidden="true" />
            <span>Inscription confirmée. On te tient au courant !</span>
          </motion.div>
        )}

        {submitState === "error" && (
          <motion.div
            key="error"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="mt-4 flex items-center gap-2 rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-700"
            role="alert"
          >
            <AlertCircle className="h-4 w-4 flex-shrink-0" aria-hidden="true" />
            <span>{serverError}</span>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// Small radio-chip sub-component kept local for clarity.
function RoleChip({
  role,
  isHero,
  register,
}: {
  role: BetaRole;
  isHero: boolean;
  register: ReturnType<typeof useForm<FormValues>>["register"];
}) {
  return (
    <label
      className={cn(
        "cursor-pointer rounded-full border px-3 py-1 text-xs font-medium transition-colors",
        "has-[:checked]:border-togo-orange has-[:checked]:bg-togo-orange has-[:checked]:text-white",
        isHero
          ? "border-white/40 text-white/90 hover:border-white"
          : "border-gray-200 text-gray-700 hover:border-togo-green hover:text-togo-green"
      )}
    >
      <input
        type="radio"
        value={role}
        className="sr-only"
        {...register("role")}
      />
      {roleLabels[role]}
    </label>
  );
}
