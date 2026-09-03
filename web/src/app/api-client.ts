import { AuthApi, Configuration } from "../generated/api";

import { createHttpClient } from "../core/http-client";
import { appEnvironment } from "./environment";

const generatedTransport = createHttpClient({
  baseUrl: appEnvironment.apiBaseUrl,
  fetchApi: (input, init) => globalThis.fetch(input, init),
});

/** Route generated requests through the credential and protected-state adapter. */
export const generatedFetchApi = (
  input: RequestInfo | URL,
  init?: RequestInit,
) => generatedTransport.request(String(input), init);

/** Shared generated-client configuration for browser session transport. */
export const apiConfiguration = new Configuration({
  basePath: appEnvironment.apiBaseUrl,
  credentials: "include",
  fetchApi: generatedFetchApi,
});

export const authApi = new AuthApi(apiConfiguration);
