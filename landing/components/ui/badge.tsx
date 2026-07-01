// components/ui/badge.tsx
// shadcn/ui Badge — manually coded.
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold ring-1 ring-inset",
  {
    variants: {
      variant: {
        default:
          "bg-togo-green-surface text-togo-green ring-togo-green/20",
        orange:
          "bg-togo-orange-surface text-togo-orange ring-togo-orange/20",
        neutral: "bg-gray-100 text-gray-700 ring-gray-200",
        solid: "bg-togo-green text-white ring-transparent",
        solidOrange: "bg-togo-orange text-white ring-transparent",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <span className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { badgeVariants };
