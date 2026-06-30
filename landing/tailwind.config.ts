// tailwind.config.ts
// Tailwind 4 is CSS-first via @theme in globals.css.
// This file is kept for editor tooling and explicit content paths.
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // ExamBoost Togo palette (mirrors @theme in globals.css)
        togo: {
          green: "#006837",
          "green-dark": "#004A26",
          "green-light": "#4CAF7A",
          "green-surface": "#E8F5ED",
          orange: "#D97700",
          "orange-light": "#FFB74D",
          "orange-surface": "#FFF3E0",
          cream: "#F8F9FA",
          ink: "#1A1A1A",
        },
      },
      fontFamily: {
        outfit: ["var(--font-outfit)", "system-ui", "sans-serif"],
        inter: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
