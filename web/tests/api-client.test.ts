import { describe, expect, it } from "vitest";

import { AuthApi } from "../src/generated/api";
import { apiConfiguration, authApi } from "../src/app/api-client";

describe("generated web API transport", () => {
  it("includes browser credentials for the server session cookie", () => {
    expect(apiConfiguration.credentials).toBe("include");
    expect(authApi).toBeInstanceOf(AuthApi);
  });
});
