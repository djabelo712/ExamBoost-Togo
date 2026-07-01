// app/page.tsx
// Landing page — composes the 11 sections in order.
import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { ProblemSection } from "@/components/ProblemSection";
import { SolutionSection } from "@/components/SolutionSection";
import { FeaturesSection } from "@/components/FeaturesSection";
import { HowItWorks } from "@/components/HowItWorks";
import { TestimonialsSection } from "@/components/TestimonialsSection";
import { PricingSection } from "@/components/PricingSection";
import { FAQSection } from "@/components/FAQSection";
import { BetaCTA } from "@/components/BetaCTA";
import { Footer } from "@/components/Footer";

export default function HomePage() {
  return (
    <>
      <Navbar />
      <main id="main">
        {/* 1. Hero */}
        <Hero />
        {/* 2. ProblemSection — 3 stats choc */}
        <ProblemSection />
        {/* 3. SolutionSection — 3 piliers */}
        <SolutionSection />
        {/* 4. FeaturesSection — 5 features */}
        <FeaturesSection />
        {/* 5. HowItWorks — 3 étapes */}
        <HowItWorks />
        {/* 6. TestimonialsSection — 2 citations */}
        <TestimonialsSection />
        {/* 7. PricingSection — 2 cartes */}
        <PricingSection />
        {/* 8. FAQSection — 8 questions accordéon */}
        <FAQSection />
        {/* 9. BetaCTA — section finale email capture */}
        <BetaCTA />
      </main>
      {/* 10. Footer */}
      <Footer />
    </>
  );
}
