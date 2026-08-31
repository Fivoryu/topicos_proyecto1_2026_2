import { render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { App } from "../src/app/App";

const validSession = {
  account: { id: "account-1", login_name: "demo.owner" },
  active_group_id: "group-demo",
  expires_at: "2026-08-29T12:00:00.000Z",
  role: "owner",
};

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("Cuentas Claras web shell", () => {
  it("shows the login state without presenting an anonymous protected shell", () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(() => new Promise<Response>(() => undefined)),
    );
    render(<App />);

    expect(
      screen.getByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/login name/i)).toBeInTheDocument();
    expect(
      screen.queryByText(/participants|balances|settlement/i),
    ).not.toBeInTheDocument();
    expect(screen.queryByTestId("protected-shell")).not.toBeInTheDocument();
  });

  it("renders the protected shell only after the server session authenticates", async () => {
    const fetchApi = vi.fn().mockResolvedValue(
      new Response(JSON.stringify(validSession), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
    vi.stubGlobal("fetch", fetchApi);
    render(<App />);

    await waitFor(() =>
      expect(screen.getByTestId("protected-shell")).toBeInTheDocument(),
    );
    expect(fetchApi).toHaveBeenCalledWith(
      expect.stringContaining("/api/v1/auth/session"),
      expect.objectContaining({ credentials: "include" }),
    );
    expect(screen.getByText(/role: owner/i)).toBeInTheDocument();
    expect(screen.queryByLabelText(/role/i)).not.toBeInTheDocument();
  });
});
