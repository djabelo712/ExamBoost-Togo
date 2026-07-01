// app/merci/page.tsx
// Thank-you page after a successful beta signup.
import Link from "next/link";
import { CheckCircle2, ArrowLeft, Share2 } from "lucide-react";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export const metadata = {
  title: "Merci ! Tu es inscrit·e à la bêta",
  description:
    "Ton inscription à la bêta d'ExamBoost Togo est confirmée. On te tiendra au courant de l'ouverture du pilote Lomé.",
  robots: { index: false, follow: false },
};

export default function MerciPage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-togo-cream px-4 py-20">
      <div className="mx-auto w-full max-w-xl rounded-2xl border border-gray-100 bg-white p-8 text-center shadow-sm sm:p-12">
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-togo-green-surface">
          <CheckCircle2
            className="h-9 w-9 text-togo-green"
            aria-hidden="true"
          />
        </div>

        <h1 className="mt-6 font-outfit text-3xl font-extrabold tracking-tight text-togo-ink sm:text-4xl">
          Merci ! Tu es inscrit·e.
        </h1>

        <p className="mx-auto mt-4 max-w-md font-inter text-base text-gray-600">
          Bienvenue dans la bêta d'ExamBoost Togo. Tu fais maintenant partie des
          500 premiers testeurs. On t'écrira dès que l'APK du pilote Lomé est
          prête à être téléchargée.
        </p>

        <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <Link
            href="/"
            className={cn(buttonVariants({ variant: "outline", size: "md" }))}
          >
            <ArrowLeft className="h-4 w-4" aria-hidden="true" />
            <span>Retour à l'accueil</span>
          </Link>
          <a
            href={`https://wa.me/?text=${encodeURIComponent(
              "Je viens de rejoindre la bêta d'ExamBoost Togo. Rejoins-moi : https://examboost-landing.vercel.app"
            )}`}
            target="_blank"
            rel="noopener noreferrer"
            className={cn(buttonVariants({ variant: "primary", size: "md" }))}
          >
            <Share2 className="h-4 w-4" aria-hidden="true" />
            <span>Partager sur WhatsApp</span>
          </a>
        </div>

        <p className="mt-8 font-inter text-xs text-gray-500">
          Un e-mail de confirmation t'a été envoyé (vérifie tes spams).
          Questions ? Écris-nous à{" "}
          <a
            href="mailto:hello@examboost.tg"
            className="font-medium text-togo-green underline-offset-2 hover:underline"
          >
            hello@examboost.tg
          </a>
          .
        </p>
      </div>
    </main>
  );
}
