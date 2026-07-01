// components/ui/input.tsx
// shadcn/ui Input — manually coded.
import * as React from "react";
import { cn } from "@/lib/utils";

export type InputProps = React.InputHTMLAttributes<HTMLInputElement>;

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        ref={ref}
        type={type ?? "text"}
        className={cn(
          "flex h-11 w-full rounded-xl border border-gray-200 bg-white px-4 py-2 text-base text-togo-ink placeholder:text-gray-400",
          "transition-colors duration-200",
          "focus-visible:outline-none focus-visible:border-togo-green focus-visible:ring-2 focus-visible:ring-togo-green/30",
          "disabled:cursor-not-allowed disabled:opacity-50",
          "aria-[invalid=true]:border-red-500 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-red-500/30",
          className
        )}
        {...props}
      />
    );
  }
);
Input.displayName = "Input";
