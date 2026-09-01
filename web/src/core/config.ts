export interface WebConfig {
  /** Routing only; the server session remains the authorization source. */
  readonly apiBaseUrl: string;
  /** Routing only; never sent as an authorization or role assertion. */
  readonly groupId: string;
}

const LOCAL_LOOPBACK_HOSTNAMES = new Set(["localhost", "127.0.0.1", "[::1]"]);

export function resolveApiBaseUrl(
  configuredBaseUrl: string | undefined,
  isDevelopment: boolean,
): string {
  const baseUrl = configuredBaseUrl ?? "";
  if (!isDevelopment || baseUrl === "") {
    return baseUrl;
  }

  try {
    const url = new URL(baseUrl);
    if (
      url.protocol === "http:" &&
      LOCAL_LOOPBACK_HOSTNAMES.has(url.hostname) &&
      (url.port === "" || url.port === "5173")
    ) {
      return "";
    }
  } catch {
    // Preserve non-absolute values for the transport layer to resolve.
  }

  return baseUrl;
}

export const webConfig: WebConfig = Object.freeze({
  apiBaseUrl: resolveApiBaseUrl(
    import.meta.env.VITE_API_BASE_URL,
    import.meta.env.DEV,
  ),
  groupId: import.meta.env.VITE_GROUP_ID ?? "",
});

export const appConfig = webConfig;
export const config = webConfig;
