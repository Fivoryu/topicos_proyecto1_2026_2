import { HttpClientError } from "../core/http-client";

export interface FeatureError {
  code: string;
  message: string;
  fieldErrors: Array<{ field: string; message: string }>;
}
type RecordValue = Record<string, unknown>;
const isRecord = (value: unknown): value is RecordValue =>
  typeof value === "object" && value !== null;
const stringValue = (value: unknown) =>
  typeof value === "string" && value ? value : undefined;
function readFields(value: unknown): FeatureError["fieldErrors"] {
  if (!Array.isArray(value)) return [];
  return value.flatMap((item) => {
    if (!isRecord(item)) return [];
    const field = stringValue(item.field);
    const message = stringValue(item.message);
    return field && message ? [{ field, message }] : [];
  });
}

/** Normalize generated-client and transport errors without changing server codes. */
export async function readFeatureError(error: unknown): Promise<FeatureError> {
  const candidate = isRecord(error) ? error : {};
  let code =
    (error instanceof HttpClientError ? error.errorCode : undefined) ??
    stringValue(candidate.errorCode) ??
    stringValue(candidate.code);
  let message = error instanceof Error ? error.message : "Request failed.";
  let fieldErrors = readFields(candidate.fieldErrors);
  const response = candidate.response;
  if (response instanceof Response) {
    try {
      const payload = (await response.clone().json()) as unknown;
      if (isRecord(payload)) {
        code ??= stringValue(payload.error_code);
        message = stringValue(payload.message) ?? message;
        fieldErrors = readFields(payload.field_errors);
      }
    } catch {
      // The generated/transport message is the best available fallback.
    }
    code ??= response.status === 403 ? "forbidden" : "http_error";
  }
  return { code: code ?? "http_error", message, fieldErrors };
}
export const formatFeatureError = (error: FeatureError) =>
  `${error.code}: ${error.message}`;
