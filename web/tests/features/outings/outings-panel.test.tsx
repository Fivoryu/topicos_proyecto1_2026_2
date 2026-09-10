import { QueryClient } from "@tanstack/react-query";
import { render, screen, waitFor, within, fireEvent } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { SessionProvider, type AuthClient } from "../../../src/app/auth/session-provider";
import type { OutingResponse, SessionIdentityResponse } from "../../../src/generated/api";
import {
  OutingDetailPanel,
  OutingsPanel,
  type OutingFeatureClient,
} from "../../../src/features/outings";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

const active: OutingResponse = {
  id: "outing-active",
  groupId: "group-demo",
  name: "Samaipata",
  archived: false,
};
const archived: OutingResponse = {
  id: "outing-archived",
  groupId: "group-demo",
  name: "La Paz histórica",
  archived: true,
  archivedAt: new Date("2026-01-15T10:30:00.000Z"),
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanel(
  element: React.ReactNode,
  queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } }),
) {
  return render(
    <SessionProvider authClient={authClient()} queryClient={queryClient}>
      {element}
    </SessionProvider>,
  );
}

describe("outing workspace panels", () => {
  it("shows loading, then separates active and archived outings with server metadata", async () => {
    let resolve!: (value: OutingResponse[]) => void;
    const pending = new Promise<OutingResponse[]>((res) => {
      resolve = res;
    });
    const client: OutingFeatureClient = {
      listOutings: vi.fn().mockReturnValue(pending),
      getOuting: vi.fn(),
      createOuting: vi.fn(),
      editOuting: vi.fn(),
      archiveOuting: vi.fn(),
      unarchiveOuting: vi.fn(),
      deleteOuting: vi.fn(),
    };

    renderPanel(<OutingsPanel client={client} />);
    expect(await screen.findByRole("status")).toHaveTextContent("Cargando salidas…");
    resolve([active, archived]);

    expect(await screen.findByRole("heading", { name: "Salidas" })).toBeInTheDocument();
    expect(screen.getByRole("list", { name: "Salidas activas" })).toHaveTextContent("Samaipata");
    const archivedList = screen.getByRole("list", { name: "Salidas archivadas" });
    expect(archivedList).toHaveTextContent("La Paz histórica");
    expect(archivedList).toHaveTextContent("Archivada");
    expect(archivedList.querySelector("time")).toHaveAttribute(
      "dateTime",
      archived.archivedAt?.toISOString(),
    );
    expect(client.listOutings).toHaveBeenCalledWith("group-demo");
  });

  it("shows the empty state and offers manual refresh after a recoverable error", async () => {
    const client: OutingFeatureClient = {
      listOutings: vi
        .fn()
        .mockRejectedValueOnce(new Error("offline"))
        .mockResolvedValueOnce([]),
      getOuting: vi.fn(),
      createOuting: vi.fn(),
      editOuting: vi.fn(),
      archiveOuting: vi.fn(),
      unarchiveOuting: vi.fn(),
      deleteOuting: vi.fn(),
    };
    renderPanel(<OutingsPanel client={client} />);

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "No se pudieron cargar las salidas.",
    );
    fireEvent.click(screen.getByRole("button", { name: "Actualizar salidas" }));
    expect(await screen.findByRole("heading", { name: "Salidas" })).toBeInTheDocument();
    expect(screen.getByRole("status")).toHaveTextContent(/aún no hay salidas/i);
    await waitFor(() => expect(client.listOutings).toHaveBeenCalledTimes(2));
  });

  it("marks an archived detail read-only without adding lifecycle controls", async () => {
    const client: OutingFeatureClient = {
      listOutings: vi.fn(),
      getOuting: vi.fn().mockResolvedValue(archived),
      createOuting: vi.fn(),
      editOuting: vi.fn(),
      archiveOuting: vi.fn(),
      unarchiveOuting: vi.fn(),
      deleteOuting: vi.fn(),
    };
    renderPanel(
      <OutingDetailPanel client={client} groupId="group-demo" outingId={archived.id} />,
    );

    const panel = await screen.findByRole("region", { name: archived.name });
    expect(within(panel).getByRole("heading", { name: archived.name })).toBeInTheDocument();
    expect(within(panel).getByRole("note")).toHaveTextContent(/solo lectura/i);
    expect(within(panel).getByText("Archivada")).toBeInTheDocument();
    expect(within(panel).queryByRole("button")).not.toBeInTheDocument();
    expect(client.getOuting).toHaveBeenCalledWith("group-demo", archived.id);
  });

  it("does not render stale detail data from another group or outing", async () => {
    const client: OutingFeatureClient = {
      listOutings: vi.fn(),
      getOuting: vi.fn().mockResolvedValue({
        ...active,
        id: "other-outing",
        groupId: "other-group",
        name: "Dato ajeno",
      }),
      createOuting: vi.fn(),
      editOuting: vi.fn(),
      archiveOuting: vi.fn(),
      unarchiveOuting: vi.fn(),
      deleteOuting: vi.fn(),
    };
    renderPanel(
      <OutingDetailPanel client={client} groupId="group-demo" outingId="outing-requested" />,
    );

    expect(await screen.findByRole("alert")).toHaveTextContent(/no coincide con la salida solicitada/i);
    expect(screen.queryByText("Dato ajeno")).not.toBeInTheDocument();
  });
});
