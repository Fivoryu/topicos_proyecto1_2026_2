import { webConfig } from "./config";

export type ProtectedState = "signedOut" | "sessionExpired";
export type ProtectedStateHandler = (state: ProtectedState) => void;

type FetchApi = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => Promise<Response>;

export interface HttpClientOptions {
  baseUrl?: string;
  fetchApi?: FetchApi;
  onProtectedState?: ProtectedStateHandler;
}

interface ErrorPayload {
  error_code?: string;
  message?: string;
  field_errors?: unknown;
}

export class HttpClientError extends Error {
  readonly status: number;
  readonly errorCode: string;
  readonly code: string;
  readonly fieldErrors?: unknown;
  readonly protectedState?: ProtectedState;
  readonly response?: Response;

  constructor(
    status: number,
    errorCode: string,
    message: string,
    fieldErrors?: unknown,
    response?: Response,
  ) {
    super(message);
    this.name = "HttpClientError";
    this.status = status;
    this.errorCode = errorCode;
    this.code = errorCode;
    this.fieldErrors = fieldErrors;
    this.response = response;
    this.protectedState =
      status === 401
        ? errorCode === "session_expired"
          ? "sessionExpired"
          : "signedOut"
        : undefined;
  }
}

const protectedStateHandlers = new Set<ProtectedStateHandler>();

export function registerProtectedStateHandler(
  handler: ProtectedStateHandler,
): () => void {
  protectedStateHandlers.add(handler);
  return () => protectedStateHandlers.delete(handler);
}

function notifyProtectedState(state: ProtectedState): void {
  protectedStateHandlers.forEach((handler) => handler(state));
}

function cookieValue(name: string): string | undefined {
  if (typeof document === "undefined") {
    return undefined;
  }

  const prefix = `${name}=`;
  const cookie = document.cookie
    .split(";")
    .map((part) => part.trim())
    .find((part) => part.startsWith(prefix));

  if (!cookie) {
    return undefined;
  }

  try {
    return decodeURIComponent(cookie.slice(prefix.length));
  } catch {
    return cookie.slice(prefix.length);
  }
}

export function getCsrfToken(): string | undefined {
  return cookieValue("cc_csrf");
}

/** Clear browser-readable auth cookies; the HttpOnly session is cleared by logout. */
export function clearAuthCookies(): void {
  if (typeof document === "undefined") {
    return;
  }

  for (const path of ["/", "/api"]) {
    document.cookie = `cc_csrf=; Max-Age=0; Path=${path}; SameSite=Lax`;
    document.cookie = `cc_session=; Max-Age=0; Path=${path}; SameSite=Lax`;
  }
}

async function readErrorPayload(response: Response): Promise<ErrorPayload> {
  try {
    const body = response.clone ? response.clone() : response;
    return (await body.json()) as ErrorPayload;
  } catch {
    return {};
  }
}

function urlFor(baseUrl: string, path: string): string {
  if (/^https?:\/\//.test(path)) {
    return path;
  }
  return `${baseUrl.replace(/\/+$/, "")}/${path.replace(/^\/+/, "")}`;
}

export function createHttpClient(options: HttpClientOptions = {}) {
  const baseUrl = options.baseUrl ?? webConfig.apiBaseUrl;
  const fetchApi = options.fetchApi ?? fetch;
  const stateHandler = options.onProtectedState ?? notifyProtectedState;

  async function request(
    path: string,
    init: RequestInit = {},
  ): Promise<Response> {
    const method = (init.method ?? "GET").toUpperCase();
    const headers = new Headers(init.headers);
    if (["POST", "PATCH", "DELETE"].includes(method)) {
      const csrf = getCsrfToken();
      if (csrf) {
        headers.set("X-CSRF-Token", csrf);
      }
    }

    const response = await fetchApi(urlFor(baseUrl, path), {
      ...init,
      method,
      headers,
      credentials: "include",
    });

    if (response.ok) {
      return response;
    }

    const payload = await readErrorPayload(response);
    const error = new HttpClientError(
      response.status,
      payload.error_code ?? "http_error",
      payload.message ?? `Request failed with status ${response.status}.`,
      payload.field_errors,
      response,
    );
    if (error.protectedState) {
      stateHandler(error.protectedState);
    }
    throw error;
  }

  async function json<T>(path: string, init: RequestInit = {}): Promise<T> {
    const response = await request(path, init);
    if (response.status === 204) {
      return undefined as T;
    }
    return (await response.json()) as T;
  }

  function jsonRequest(
    method: "POST" | "PATCH",
    path: string,
    body: unknown,
    init: RequestInit,
  ) {
    const headers = new Headers(init.headers);
    headers.set("Content-Type", "application/json");
    return json(path, {
      ...init,
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  return {
    request,
    json,
    get: <T>(path: string, init?: RequestInit) =>
      json<T>(path, { ...init, method: "GET" }),
    post: <T>(path: string, body?: unknown, init: RequestInit = {}) =>
      jsonRequest("POST", path, body, init) as Promise<T>,
    patch: <T>(path: string, body?: unknown, init: RequestInit = {}) =>
      jsonRequest("PATCH", path, body, init) as Promise<T>,
    delete: <T>(path: string, init?: RequestInit) =>
      json<T>(path, { ...init, method: "DELETE" }),
  };
}

export const httpClient = createHttpClient();
