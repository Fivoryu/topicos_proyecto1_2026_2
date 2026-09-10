import { QueryClient } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  AuthError,
  SessionProvider,
  type AuthClient,
} from "../../../src/app/auth/session-provider";
import type {
  GroupSummaryResponse,
  ParticipantResponse,
  SessionIdentityResponse,
} from "../../../src/generated/api";
import { SummaryPanel, type WorkspaceClient } from "../../../src/features/workspace";
import {
  ParticipantDetailPanel,
  type ParticipantFeatureClient,
} from "../../../src/features/participants";

const session: SessionIdentityResponse = {
  account: { id: "account-1", loginName: "demo.member" },
  activeGroupId: "group-1",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

const group: GroupSummaryResponse = {
  id: "group-1",
  name: "Viaje a Samaipata",
  ownerAccountId: "account-owner",
  role: "owner",
  settlementPolicy: "owner_only",
  memberCount: 4,
  participantsCount: 4,
  outingsCount: 2,
  expensesCount: 3,
};

const archivedParticipant: ParticipantResponse = {
  id: "participant-1",
  groupId: "group-1",
  name: "Ana",
  archived: true,
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanels(element: React.ReactNode) {
  return render(
    <SessionProvider
      authClient={authClient()}
      queryClient={new QueryClient({ defaultOptions: { queries: { retry: false } } })}
    >
      {element}
    </SessionProvider>,
  );
}

function workspaceClient(groups: GroupSummaryResponse[]): WorkspaceClient {
  return { listGroups: vi.fn().mockResolvedValue(groups), createGroup: vi.fn() };
}

function participantClient(
  participants: ParticipantResponse[],
): ParticipantFeatureClient {
  return {
    listParticipants: vi.fn().mockResolvedValue(participants),
    addParticipant: vi.fn(),
    archiveParticipant: vi.fn(),
    reactivateParticipant: vi.fn(),
    deleteParticipant: vi.fn(),
    renameParticipant: vi.fn(),
  };
}

describe("summary and participant detail panels", () => {
  it("renders server group metadata and an explicit empty state", async () => {
    const empty = {
      ...group,
      name: "Grupo vacío",
      memberCount: 0,
      participantsCount: 0,
      outingsCount: 0,
      expensesCount: 0,
    };
    renderPanels(<SummaryPanel client={workspaceClient([empty])} groupId="group-1" />);

    expect(await screen.findByRole("heading", { name: "Grupo vacío" })).toBeInTheDocument();
    expect(screen.getByText("Propietario")).toBeInTheDocument();
    expect(screen.getByText("Aún no hay información en este grupo.")).toBeInTheDocument();
    expect(screen.getByText("0 participantes")).toBeInTheDocument();
  });

  it("shows Spanish loading, forbidden and manual refresh states", async () => {
    const client = workspaceClient([]);
    client.listGroups = vi
      .fn()
      .mockRejectedValueOnce(new AuthError(403, "forbidden", "denied"))
      .mockResolvedValueOnce([group]);
    renderPanels(<SummaryPanel client={client} groupId="group-1" />);

    expect(await screen.findByRole("alert")).toHaveTextContent(/no tienes permisos/i);
    fireEvent.click(screen.getByRole("button", { name: "Actualizar grupo" }));
    expect(await screen.findByRole("heading", { name: group.name })).toBeInTheDocument();
    expect(client.listGroups).toHaveBeenCalledTimes(2);
  });

  it("shows a Spanish loading state while the summary request resolves", async () => {
    const client = workspaceClient([]);
    client.listGroups = vi.fn().mockReturnValue(new Promise(() => {}));
    renderPanels(<SummaryPanel client={client} groupId="group-1" />);

    expect(await screen.findByRole("status")).toHaveTextContent("Cargando resumen…");
  });

  it("does not render a summary returned for another group", async () => {
    renderPanels(
      <SummaryPanel
        client={workspaceClient([{ ...group, id: "group-other", name: "Dato ajeno" }])}
        groupId="group-1"
      />,
    );

    expect(await screen.findByRole("alert")).toHaveTextContent(/no coincide con el grupo solicitado/i);
    expect(screen.queryByText("Dato ajeno")).not.toBeInTheDocument();
  });

  it("renders archived participant history without account identity", async () => {
    const client = participantClient([archivedParticipant]);
    renderPanels(
      <ParticipantDetailPanel
        client={client}
        groupId="group-1"
        participantId="participant-1"
      />,
    );

    const panel = await screen.findByRole("region", { name: "Ana" });
    expect(panel).toHaveTextContent(/archivado/i);
    expect(panel).toHaveTextContent(/historial se conserva/i);
    expect(panel).not.toHaveTextContent("account-1");
    expect(client.listParticipants).toHaveBeenCalledWith("group-1");
  });

  it("shows not-found and recovers after a participant refresh", async () => {
    const client = participantClient([]);
    client.listParticipants = vi
      .fn()
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([archivedParticipant]);
    renderPanels(
      <ParticipantDetailPanel client={client} groupId="group-1" participantId="participant-1" />,
    );

    expect(await screen.findByRole("alert")).toHaveTextContent(/no se encontró el participante/i);
    fireEvent.click(screen.getByRole("button", { name: "Actualizar participante" }));
    expect(await screen.findByRole("heading", { name: "Ana" })).toBeInTheDocument();
  });

  it("rejects a participant response from another group before rendering it", async () => {
    renderPanels(
      <ParticipantDetailPanel
        client={participantClient([{ ...archivedParticipant, groupId: "group-other", name: "Dato ajeno" }])}
        groupId="group-1"
        participantId="participant-1"
      />,
    );

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent(/no coincide/i));
    expect(screen.queryByText("Dato ajeno")).not.toBeInTheDocument();
  });
});
