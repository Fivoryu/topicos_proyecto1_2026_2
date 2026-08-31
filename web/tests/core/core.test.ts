import { afterEach, describe, expect, it, vi } from "vitest";

import { formatCents } from "../../src/core/cents-formatter";
import {
  type HttpClientError,
  createHttpClient,
  getCsrfToken,
} from "../../src/core/http-client";
import {
  GROUP_QUERY_RESOURCES,
  groupQueryKey,
} from "../../src/core/query-client";

function response(status: number, body: unknown = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

afterEach(() => {
  vi.restoreAllMocks();
  document.cookie = "cc_csrf=; Max-Age=0; Path=/";
});

describe("cents formatter", () => {
  it.each([
    [0, "Bs. 0.00"],
    [5, "Bs. 0.05"],
    [99, "Bs. 0.99"],
    [1000, "Bs. 10.00"],
    [1234567, "Bs. 12,345.67"],
    [160000, "Bs. 1,600.00"],
    [-16000, "-Bs. 160.00"],
  ])("formats %s integer cents without rounding", (value, expected) => {
    expect(formatCents(value)).toBe(expected);
  });

  it("formats a lexical integer without converting it through floating point", () => {
    expect(formatCents("9007199254740991")).toBe("Bs. 90,071,992,547,409.91");
  });
});

describe("web transport", () => {
  it("sends credentials and the CSRF cookie on unsafe requests", async () => {
    document.cookie = "cc_csrf=csrf-token; Path=/";
    const fetchApi = vi
      .fn()
      .mockResolvedValue(new Response(null, { status: 204 }));
    const client = createHttpClient({
      fetchApi,
      baseUrl: "https://api.example.test",
    });

    await client.request("/api/v1/groups/demo", { method: "POST" });

    expect(fetchApi).toHaveBeenCalledWith(
      "https://api.example.test/api/v1/groups/demo",
      expect.objectContaining({
        method: "POST",
        credentials: "include",
        headers: expect.any(Headers),
      }),
    );
    const requestInit = fetchApi.mock.calls[0][1] as RequestInit;
    expect(new Headers(requestInit.headers).get("X-CSRF-Token")).toBe(
      "csrf-token",
    );
    expect(getCsrfToken()).toBe("csrf-token");
  });

  it("maps a 401 response to a protected signed-out state", async () => {
    const onProtectedState = vi.fn();
    const client = createHttpClient({
      fetchApi: vi
        .fn()
        .mockResolvedValue(
          response(401, {
            error_code: "unauthorized",
            message: "Sign in required.",
          }),
        ),
      onProtectedState,
    });

    await expect(client.request("/api/v1/groups/demo")).rejects.toMatchObject({
      status: 401,
      errorCode: "unauthorized",
      protectedState: "signedOut",
    });
    expect(onProtectedState).toHaveBeenCalledWith("signedOut");
  });

  it("preserves session-expired as a distinct protected state", async () => {
    const client = createHttpClient({
      fetchApi: vi
        .fn()
        .mockResolvedValue(
          response(401, { error_code: "session_expired", message: "Expired." }),
        ),
    });

    await expect(client.request("/api/v1/groups/demo")).rejects.toEqual(
      expect.objectContaining<Partial<HttpClientError>>({
        errorCode: "session_expired",
        protectedState: "sessionExpired",
      }),
    );
  });
});

describe("group query keys", () => {
  it("always scopes every protected resource by the configured group", () => {
    expect(GROUP_QUERY_RESOURCES).toEqual([
      "group",
      "participants",
      "expenses",
      "balances",
      "settlement",
    ]);
    expect(groupQueryKey("participants", "group-demo")).toEqual([
      "participants",
      "group-demo",
    ]);
  });
});
