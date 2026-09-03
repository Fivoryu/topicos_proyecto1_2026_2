import type {
  ButtonHTMLAttributes,
  HTMLAttributes,
  PropsWithChildren,
  ReactNode,
} from "react";

type ButtonVariant = "primary" | "secondary" | "danger" | "ghost";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
}

export function Button({
  variant = "primary",
  className = "",
  ...props
}: ButtonProps) {
  const variantClass =
    variant === "primary"
      ? "feature-button"
      : variant === "secondary"
        ? "feature-button feature-button-secondary"
        : variant === "danger"
          ? "feature-button feature-button-danger"
          : "feature-button feature-button-ghost";
  return <button className={`${variantClass} ${className}`.trim()} {...props} />;
}

interface PanelProps extends HTMLAttributes<HTMLElement> {
  labelledBy?: string;
}

export function Panel({
  children,
  className = "",
  labelledBy,
  ...props
}: PropsWithChildren<PanelProps>) {
  return (
    <section
      className={`feature-card ${className}`.trim()}
      aria-labelledby={labelledBy}
      {...props}
    >
      {children}
    </section>
  );
}

interface PanelHeadingProps {
  eyebrow: string;
  title: ReactNode;
  titleId: string;
  action?: ReactNode;
}

export function PanelHeading({
  eyebrow,
  title,
  titleId,
  action,
}: PanelHeadingProps) {
  return (
    <div className="feature-heading">
      <div className="feature-heading-copy">
        <p className="feature-eyebrow">{eyebrow}</p>
        <h2 id={titleId}>{title}</h2>
      </div>
      {action ? <div className="feature-heading-action">{action}</div> : null}
    </div>
  );
}

interface StatusBadgeProps {
  tone?: "neutral" | "success" | "warning" | "danger" | "info";
  children: ReactNode;
}

export function StatusBadge({ tone = "neutral", children }: StatusBadgeProps) {
  return <span className={`status-badge status-badge-${tone}`}>{children}</span>;
}

interface LoadingCardProps {
  children: ReactNode;
}

export function LoadingCard({ children }: LoadingCardProps) {
  return (
    <section className="feature-card feature-state-card" aria-live="polite">
      <span className="loading-dot" aria-hidden="true" />
      <span>{children}</span>
    </section>
  );
}

interface ErrorCardProps {
  children: ReactNode;
}

export function ErrorCard({ children }: ErrorCardProps) {
  return (
    <section className="feature-card feature-state-card feature-state-error" role="alert">
      <span className="state-symbol" aria-hidden="true">!</span>
      <span>{children}</span>
    </section>
  );
}
