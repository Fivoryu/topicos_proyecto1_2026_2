export type CentsInput = number | string | bigint;

function integerText(cents: CentsInput): string {
  if (typeof cents === "number") {
    if (!Number.isSafeInteger(cents)) {
      throw new TypeError("Cents must be a safe integer.");
    }
    return String(cents);
  }

  const text = typeof cents === "bigint" ? cents.toString() : cents;
  if (!/^-?\d+$/.test(text)) {
    throw new TypeError("Cents must be an integer.");
  }
  return text;
}

function groupThousands(digits: string): string {
  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

/** Format server-provided integer cents without floating-point arithmetic. */
export function formatCents(cents: CentsInput): string {
  const raw = integerText(cents);
  const negative = raw.startsWith("-");
  const digits = (negative ? raw.slice(1) : raw).replace(/^0+(?=\d)/, "");
  const whole = digits.length > 2 ? digits.slice(0, -2) : "0";
  const fraction = digits.length > 1 ? digits.slice(-2) : `0${digits}`;
  const sign = negative && digits !== "0" ? "-" : "";

  return `${sign}Bs. ${groupThousands(whole)},${fraction}`;
}

export const formatBolivianos = formatCents;

/** Format a balance, adding an explicit plus sign only for positive values. */
export function formatSignedCents(cents: CentsInput): string {
  const raw = integerText(cents);
  const formatted = formatCents(raw);
  return raw.startsWith("-") || /^0+$/.test(raw) ? formatted : `+${formatted}`;
}
