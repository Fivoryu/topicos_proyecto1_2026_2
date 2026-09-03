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
      screen.getByRole("heading", { name: /inicia sesión/i }),
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/usuario/i)).toBeInTheDocument();
    expect(
      screen.queryByText(/participantes|balances|liquidación/i),
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
    expect(screen.getByRole("heading", { name: /tu grupo está protegido/i })).toBeInTheDocument();
    expect(screen.getByText(/sesión iniciada como demo\.owner/i)).toBeInTheDocument();
    expect(screen.getByText(/rol: propietario/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /cerrar sesión/i })).toBeInTheDocument();
    expect(screen.queryByLabelText(/role/i)).not.toBeInTheDocument();
  });
});
