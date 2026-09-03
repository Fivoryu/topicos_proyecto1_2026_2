import { describe, expect, it } from "vitest";

import { resolveApiBaseUrl } from "../../src/core/config";

describe("resolveApiBaseUrl", () => {
  it.each([
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://[::1]:5173",
  ])(
    "uses the page origin for a local Vite URL in development: %s",
    (baseUrl) => {
      expect(resolveApiBaseUrl(baseUrl, true)).toBe("");
    },
  );

  it.each([
    "http://localhost",
    "http://localhost:80",
    "http://127.0.0.1",
    "http://127.0.0.1:80",
    "http://[::1]",
    "http://[::1]:80",
  ])(
    "uses the page origin for a default-port local loopback URL in development: %s",
    (baseUrl) => {
      expect(resolveApiBaseUrl(baseUrl, true)).toBe("");
    },
  );

  it("preserves empty development values", () => {
    expect(resolveApiBaseUrl("", true)).toBe("");
    expect(resolveApiBaseUrl(undefined, true)).toBe("");
  });

  it("preserves a direct API URL in development", () => {
    expect(resolveApiBaseUrl("http://localhost:8000", true)).toBe(
      "http://localhost:8000",
    );
  });

  it("preserves configured values in production", () => {
    expect(resolveApiBaseUrl("http://localhost:5173", false)).toBe(
      "http://localhost:5173",
    );
  });
});
