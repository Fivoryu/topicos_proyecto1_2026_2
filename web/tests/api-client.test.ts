import { describe, expect, it } from "vitest";

import { AuthApi } from "../src/generated/api";
import { apiConfiguration, authApi } from "../src/app/api-client";
import { appEnvironment } from "../src/app/environment";

describe("generated web API transport", () => {
  it("includes browser credentials for the server session cookie", () => {
    expect(apiConfiguration.credentials).toBe("include");
    expect(authApi).toBeInstanceOf(AuthApi);
  });

  it("passes the resolved API base to avoid the generated localhost fallback", () => {
    expect(apiConfiguration.basePath).toBe(appEnvironment.apiBaseUrl);
    expect(apiConfiguration.basePath).not.toBe("http://localhost");
  });
});
