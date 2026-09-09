import { render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { App } from "../src/app/App";
import { ErrorCard, LoadingCard } from "../src/components/ui";

const validSession = {
  account: { id: "account-1", login_name: "demo.owner" },
  active_group_id: "group-demo",
  expires_at: "2026-08-29T12:00:00.000Z",
  role: "owner",
};

const zeroGroupSession = {
  account: { id: "account-2", login_name: "new.account" },
  active_group_id: null,
  expires_at: "2026-08-29T12:00:00.000Z",
  role: null,
};

afterEach(() => {
  vi.unstubAllGlobals();
  window.history.replaceState(
    null,
    "",
    window.location.pathname + window.location.search,
  );
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
    expect(
      screen.getByRole("heading", { name: /tu grupo está protegido/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/sesión iniciada como demo\.owner/i),
    ).toBeInTheDocument();
    expect(screen.getByText(/rol: propietario/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /cerrar sesión/i }),
    ).toBeInTheDocument();

    const navigations = screen.getAllByRole("navigation", {
      name: "Secciones del grupo",
    });
    expect(navigations).toHaveLength(2);
    for (const navigation of navigations) {
      const links = within(navigation);
      expect(links.getByRole("link", { name: "Gastos" })).toHaveAttribute(
        "href",
        "#gastos",
      );
      expect(links.getByRole("link", { name: "Gastos" })).toHaveAttribute(
        "aria-current",
        "page",
      );
      expect(links.getByRole("link", { name: "Balances" })).toHaveAttribute(
        "href",
        "#balances",
      );
      expect(links.getByRole("link", { name: "Liquidación" })).toHaveAttribute(
        "href",
        "#liquidacion",
      );
      expect(
        links.getByRole("link", { name: "Participantes" }),
      ).toHaveAttribute("href", "#participantes");
      expect(links.getByRole("link", { name: "Grupo" })).toHaveAttribute(
        "href",
        "#grupo",
      );
    }
    expect(screen.queryByLabelText(/role/i)).not.toBeInTheDocument();
  });

  it("renders workspace selection for an authenticated zero-group session", async () => {
    const fetchApi = vi.fn().mockImplementation((input: RequestInfo | URL) => {
      const url = String(input);
      const body = url.includes("/api/v1/auth/session")
        ? zeroGroupSession
        : [];
      return Promise.resolve(
        new Response(JSON.stringify(body), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    });
    vi.stubGlobal("fetch", fetchApi);
    render(<App />);

    await waitFor(() =>
      expect(
        screen.getByRole("heading", { name: /aún no perteneces a ningún grupo/i }),
      ).toBeInTheDocument(),
    );
    expect(screen.getByTestId("workspace-shell")).toBeInTheDocument();
    expect(screen.queryByTestId("protected-shell")).not.toBeInTheDocument();
  });

  it("groups the expense anchor ahead of secondary administration", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(JSON.stringify(validSession), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      ),
    );
    render(<App />);

    await waitFor(() =>
      expect(screen.getByTestId("protected-shell")).toBeInTheDocument(),
    );

    const primary = screen.getByRole("region", {
      name: "Flujo financiero principal",
    });
    const secondary = screen.getByRole("complementary", {
      name: "Administración del grupo",
    });
    expect(primary.compareDocumentPosition(secondary)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    );
  });

  it("keeps expense and financial anchors before administration in document order", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(JSON.stringify(validSession), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      ),
    );
    render(<App />);

    await waitFor(() =>
      expect(screen.getByTestId("protected-shell")).toBeInTheDocument(),
    );

    const expensesAnchor = document.getElementById("gastos");
    const balancesAnchor = document.getElementById("balances");
    const participantsAnchor = document.getElementById("participantes");
    expect(expensesAnchor).not.toBeNull();
    expect(balancesAnchor).not.toBeNull();
    expect(participantsAnchor).not.toBeNull();
    expect(expensesAnchor!.compareDocumentPosition(balancesAnchor!)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    );
    expect(balancesAnchor!.compareDocumentPosition(participantsAnchor!)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    );
  });
});

describe("shared presentation states", () => {
  it("announces loading and error text through semantic state roles", () => {
    render(
      <>
        <LoadingCard>Cargando balances…</LoadingCard>
        <ErrorCard>
          No se pudieron cargar los balances. Intenta nuevamente.
        </ErrorCard>
      </>,
    );

    const loadingState = screen.getByRole("status");
    expect(loadingState).toHaveAttribute("aria-live", "polite");
    expect(loadingState).toHaveTextContent("Cargando balances…");

    const errorState = screen.getByRole("alert");
    expect(errorState).toHaveTextContent(
      "No se pudieron cargar los balances. Intenta nuevamente.",
    );
  });

  it("keeps a deep-linked section active across the desktop and mobile navigation", async () => {
    window.history.replaceState(null, "", "#balances");
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(JSON.stringify(validSession), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      ),
    );
    render(<App />);

    await waitFor(() =>
      expect(screen.getByTestId("protected-shell")).toBeInTheDocument(),
    );

    const navigations = screen.getAllByRole("navigation", {
      name: "Secciones del grupo",
    });
    expect(navigations).toHaveLength(2);
    for (const navigation of navigations) {
      expect(
        within(navigation).getByRole("link", { name: "Balances" }),
      ).toHaveAttribute("aria-current", "page");
    }
  });
});
