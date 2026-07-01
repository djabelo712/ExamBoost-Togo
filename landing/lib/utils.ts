// lib/utils.ts
// Tailwind merge + clsx helper used across shadcn/ui components.
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * cn — concatenate conditional class names and resolve Tailwind conflicts.
 * The last conflicting class wins.
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
