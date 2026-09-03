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
  let message = error instanceof Error ? error.message : "La solicitud falló.";
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
const USER_MESSAGES: Record<string, string> = {
  invalid_amount: "Ingresa un monto positivo con máximo dos decimales.",
  no_beneficiaries: "Selecciona al menos un beneficiario.",
  no_participants: "Agrega al menos un participante.",
  invalid_participant_reference: "Uno de los participantes seleccionados ya no es válido.",
  contribution_mismatch: "La suma de los pagadores debe coincidir con el monto del gasto.",
  invalid_participant_name: "Ingresa un nombre de participante válido.",
  duplicate_participant_name: "Ya existe un participante con ese nombre.",
  participant_in_use: "El participante tiene gastos asociados; archívalo para conservar el historial.",
  invalid_description: "Ingresa una descripción válida.",
  invalid_settlement_policy: "Selecciona una política de liquidación válida.",
  invalid_credentials: "El usuario o la contraseña son incorrectos.",
  unauthorized: "Debes iniciar sesión para continuar.",
  session_expired: "Tu sesión expiró. Inicia sesión nuevamente.",
  forbidden: "No tienes permisos para realizar esta acción.",
  csrf_failed: "La solicitud de seguridad no fue aceptada. Recarga la página e intenta nuevamente.",
  invalid_request: "La solicitud contiene datos no válidos.",
  not_found: "No se encontró el recurso solicitado.",
  persistence_corrupted: "Los datos guardados no son consistentes. Restablece la demostración antes de continuar.",
};

export function featureErrorMessage(error: FeatureError): string {
  return USER_MESSAGES[error.code] ?? "No se pudo completar la operación. Intenta nuevamente.";
}

export const formatFeatureError = (error: FeatureError) =>
  `${error.code}: ${featureErrorMessage(error)}`;
