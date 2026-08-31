export interface WebConfig {
  /** Routing only; the server session remains the authorization source. */
  readonly apiBaseUrl: string;
  /** Routing only; never sent as an authorization or role assertion. */
  readonly groupId: string;
}

export const webConfig: WebConfig = Object.freeze({
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? "",
  groupId: import.meta.env.VITE_GROUP_ID ?? "",
});

export const appConfig = webConfig;
export const config = webConfig;
