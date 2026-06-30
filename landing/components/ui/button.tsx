// components/ui/button.tsx
// shadcn/ui Button — manually coded (no CLI).
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-xl text-sm font-semibold ring-offset-2 transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-togo-green focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-[0.98]",
  {
    variants: {
      variant: {
        primary:
          "bg-togo-green text-white shadow-sm hover:bg-togo-green-dark hover:shadow-md",
        outline:
          "border border-togo-green bg-transparent text-togo-green hover:bg-togo-green-surface",
        ghost:
          "bg-transparent text-togo-ink hover:bg-togo-green-surface hover:text-togo-green",
        orange:
          "bg-togo-orange text-white shadow-sm hover:brightness-110 hover:shadow-md",
      },
      size: {
        sm: "h-9 px-4 text-sm",
        md: "h-11 px-6 text-base",
        lg: "h-12 px-8 text-base",
        icon: "h-10 w-10 p-0",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, type, ...props }, ref) => {
    return (
      <button
        ref={ref}
        type={type ?? "button"}
        className={cn(buttonVariants({ variant, size }), className)}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { buttonVariants };
