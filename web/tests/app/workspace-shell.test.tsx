import { QueryClient } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import {
  AuthError,
  SessionProvider,
  type AuthClient,
} from "../../src/app/auth/session-provider";
import { WorkspaceShell } from "../../src/app/workspace-shell";
import {
  parseWorkspaceHash,
  serializeWorkspaceRoute,
} from "../../src/core/workspace-navigation";
import { workspaceQueryKeys } from "../../src/core/workspace-query-keys";
import type {
  GroupSummaryResponse,
  SessionIdentityResponse,
} from "../../src/generated/api";
import type { WorkspaceClient } from "../../src/features/workspace/api";

const session: SessionIdentityResponse = {
  account: { id: "account-1", loginName: "demo.owner" },
  activeGroupId: null,
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: null,
};
const group = (id: string, name = id): GroupSummaryResponse => ({
  id,
  name,
  ownerAccountId: "account-1",
  role: "owner",
  settlementPolicy: "owner_only",
  memberCount: 1,
  participantsCount: 0,
  outingsCount: 0,
  expensesCount: 0,
});

function authClient(overrides: Partial<AuthClient> = {}): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
    ...overrides,
  };
}
function renderShell(
  client: WorkspaceClient,
  options: { auth?: AuthClient; queryClient?: QueryClient } = {},
) {
  return render(
    <SessionProvider
      authClient={options.auth ?? authClient()}
      queryClient={options.queryClient}
    >
      <WorkspaceShell client={client} />
    </SessionProvider>,
  );
}

afterEach(() => {
  window.location.hash = "";
  vi.restoreAllMocks();
});

describe("workspace navigation and query identity", () => {
  it("round-trips canonical routes and legacy aliases without a router", () => {
    const route = parseWorkspaceHash("#/groups/g-1/summary");
    expect(route).toEqual({ kind: "summary", groupId: "g-1" });
    expect(serializeWorkspaceRoute(route)).toBe("#/groups/g-1/summary");
    expect(parseWorkspaceHash("#gastos")).toEqual({
      kind: "legacy",
      anchor: "gastos",
    });
    expect(serializeWorkspaceRoute({ kind: "legacy", anchor: "grupo" })).toBe(
      "#grupo",
    );
    expect(workspaceQueryKeys.account.groups("a-1")).not.toEqual(
      workspaceQueryKeys.group.summary("a-1"),
    );
    expect(workspaceQueryKeys.selection("a-1")).toEqual([
      "selection",
      "a-1",
      "group",
    ]);
  });
});

describe("authenticated workspace shell", () => {
  it("does not fetch or render protected workspace content before authentication", () => {
    let resolve!: (value: SessionIdentityResponse) => void;
    const pending = new Promise<SessionIdentityResponse>((done) => {
      resolve = done;
    });
    const client: WorkspaceClient = {
      listGroups: vi.fn(),
      createGroup: vi.fn(),
    };
    renderShell(client, {
      auth: authClient({ getSession: vi.fn(() => pending) }),
    });
    expect(screen.queryByTestId("workspace-shell")).not.toBeInTheDocument();
    expect(client.listGroups).not.toHaveBeenCalled();
    resolve(session);
  });

  it("shows the Spanish zero-group state and creates an owner workspace", async () => {
    const created = group("created", "Viaje");
    const client: WorkspaceClient = {
      listGroups: vi.fn().mockResolvedValue([]),
      createGroup: vi.fn().mockResolvedValue(created),
    };
    renderShell(client);
    expect(
      await screen.findByRole("heading", { name: /tus grupos/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(/aún no perteneces/i)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText(/nombre del grupo/i), {
      target: { value: "Viaje" },
    });
    fireEvent.click(screen.getByRole("button", { name: /crear grupo/i }));
    await waitFor(() =>
      expect(client.createGroup).toHaveBeenCalledWith("Viaje"),
    );
    expect(
      await screen.findByRole("heading", { name: "Viaje" }),
    ).toBeInTheDocument();
  });

  it("auto-selects one group, switches safely among many, and rejects a stale deep link", async () => {
    window.location.hash = "#/groups/missing/summary";
    const client: WorkspaceClient = {
      listGroups: vi
        .fn()
        .mockResolvedValue([group("g-1", "Casa"), group("g-2", "Oficina")]),
      createGroup: vi.fn(),
    };
    renderShell(client);
    expect(
      await screen.findByText(/no tienes acceso a ese grupo/i),
    ).toBeInTheDocument();
    expect(
      screen.queryByText("Casa", { selector: "h2" }),
    ).not.toBeInTheDocument();
    const casaButton = screen.getByRole("button", { name: "Casa" });
    expect(casaButton).toHaveStyle("min-height: 44px");
    fireEvent.click(casaButton);
    expect(
      await screen.findByRole("heading", { name: "Casa" }),
    ).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Oficina" }));
    await waitFor(() =>
      expect(window.location.hash).toBe("#/groups/g-2/summary"),
    );
    expect(
      await screen.findByRole("heading", { name: "Oficina" }),
    ).toBeInTheDocument();
    expect(screen.getByText(/grupo vacío/i)).toBeInTheDocument();
  });

  it("clears protected cache on logout and preserves focusable legacy anchors", async () => {
    const queryClient = new QueryClient();
    queryClient.setQueryData(["secret"], "protected");
    const client: WorkspaceClient = {
      listGroups: vi.fn().mockResolvedValue([group("g-1", "Casa")]),
      createGroup: vi.fn(),
    };
    renderShell(client, { queryClient });
    await screen.findByRole("heading", { name: "Casa" });
    expect(document.getElementById("gastos")).toBeInTheDocument();
    expect(document.getElementById("balances")).toBeInTheDocument();
    expect(document.getElementById("liquidacion")).toBeInTheDocument();
    expect(document.getElementById("participantes")).toBeInTheDocument();
    expect(document.getElementById("grupo")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: /cerrar sesión/i }));
    await waitFor(() =>
      expect(queryClient.getQueryCache().findAll()).toHaveLength(0),
    );
    expect(screen.queryByTestId("workspace-shell")).not.toBeInTheDocument();
  });

  it("removes the workspace when the authenticated session expires", async () => {
    const client: WorkspaceClient = {
      listGroups: vi.fn(),
      createGroup: vi.fn(),
    };
    renderShell(client, {
      auth: authClient({
        getSession: vi
          .fn()
          .mockRejectedValue(new AuthError(401, "session_expired", "Expired")),
      }),
    });
    await waitFor(() =>
      expect(screen.queryByTestId("workspace-shell")).not.toBeInTheDocument(),
    );
    expect(client.listGroups).not.toHaveBeenCalled();
  });

  it("provides Spanish loading/error recovery and manual refresh when realtime is unavailable", async () => {
    const listGroups = vi
      .fn()
      .mockRejectedValueOnce(new Error("offline"))
      .mockResolvedValueOnce([group("g-1", "Casa")]);
    const client: WorkspaceClient = { listGroups, createGroup: vi.fn() };
    renderShell(client);
    expect(await screen.findByRole("alert")).toHaveTextContent(
      /no se pudieron cargar tus grupos/i,
    );
    fireEvent.click(screen.getByRole("button", { name: /actualizar/i }));
    expect(
      await screen.findByRole("heading", { name: "Casa" }),
    ).toBeInTheDocument();
    expect(screen.getByText(/actualización manual/i)).toBeInTheDocument();
  });
});
