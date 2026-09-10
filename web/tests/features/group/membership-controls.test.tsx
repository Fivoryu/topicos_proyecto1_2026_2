import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { MembershipControls } from "../../../src/features/group/membership-controls";
import type { GroupMembershipClient } from "../../../src/features/group/api";

const members = [
  {
    accountId: "owner-1",
    active: true,
    loginName: "ana.owner",
    participantId: "participant-1",
    role: "owner" as const,
  },
  {
    accountId: "member-1",
    active: true,
    loginName: "beto.member",
    participantId: null,
    role: "member" as const,
  },
];

function renderControls(
  client: GroupMembershipClient,
  role: "owner" | "member" = "owner",
) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  vi.spyOn(queryClient, "invalidateQueries");
  render(
    <QueryClientProvider client={queryClient}>
      <MembershipControls
        client={client}
        groupId="group-demo"
        role={role}
      />
    </QueryClientProvider>,
  );
  return queryClient;
}

function membershipClient(): GroupMembershipClient {
  return {
    listMembers: vi.fn().mockResolvedValue(members),
    getJoinCodeStatus: vi.fn().mockResolvedValue({
      active: true,
      generation: 2,
      groupId: "group-demo",
    }),
    generateJoinCode: vi.fn().mockResolvedValue({
      code: "SAMAIPATA-123",
      generation: 3,
      groupId: "group-demo",
    }),
    regenerateJoinCode: vi.fn().mockResolvedValue({
      code: "SAMAIPATA-123",
      generation: 3,
      groupId: "group-demo",
    }),
    revokeJoinCode: vi.fn().mockResolvedValue({
      active: false,
      generation: 3,
      groupId: "group-demo",
    }),
    consumeJoinCode: vi.fn(),
    removeMember: vi.fn().mockResolvedValue(undefined),
    leaveGroup: vi.fn().mockResolvedValue(undefined),
  };
}

describe("membership controls", () => {
  it("shows server membership data and never exposes plaintext from status", async () => {
    const client = membershipClient();

    renderControls(client);

    expect(await screen.findByText("ana.owner")).toBeInTheDocument();
    expect(screen.getByText("Propietario")).toBeInTheDocument();
    expect(screen.getByText("beto.member")).toBeInTheDocument();
    expect(screen.getByText(/código activo/i)).toBeInTheDocument();
    expect(screen.queryByText("SAMAIPATA-123")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: /participante de ana.owner/i })).toHaveAttribute(
      "href",
      "#participant-participant-1",
    );
  });

  it("reveals a newly generated code and invalidates the status query", async () => {
    const client = membershipClient();
    const queryClient = renderControls(client);

    await screen.findByText("ana.owner");
    fireEvent.click(screen.getByRole("button", { name: /regenerar código/i }));

    expect(await screen.findByText("SAMAIPATA-123")).toBeInTheDocument();
    expect(queryClient.invalidateQueries).toHaveBeenCalled();
  });

  it("protects owner removal and lets a member leave", async () => {
    const ownerClient = membershipClient();
    const ownerQueryClient = renderControls(ownerClient);
    await screen.findByText("beto.member");
    fireEvent.click(screen.getByRole("button", { name: /quitar a beto.member/i }));
    await waitFor(() =>
      expect(ownerClient.removeMember).toHaveBeenCalledWith("group-demo", "member-1"),
    );
    expect(ownerQueryClient.invalidateQueries).toHaveBeenCalled();
    cleanup();

    const memberClient = membershipClient();
    renderControls(memberClient, "member");
    await screen.findByText("beto.member");
    expect(memberClient.getJoinCodeStatus).not.toHaveBeenCalled();
    expect(screen.queryByRole("button", { name: /código/i })).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: /salir del grupo/i }));
    await waitFor(() => expect(memberClient.leaveGroup).toHaveBeenCalledWith("group-demo"));
    expect(screen.queryByRole("button", { name: /quitar a/i })).not.toBeInTheDocument();
  });

  it("keeps a forbidden removal in the shell with server error copy", async () => {
    const client = membershipClient();
    client.removeMember = vi.fn().mockRejectedValue({ code: "forbidden" });

    renderControls(client);

    await screen.findByText("beto.member");
    fireEvent.click(screen.getByRole("button", { name: /quitar a beto.member/i }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "forbidden: No tienes permisos para realizar esta acción.",
    );
  });

  it("offers recovery for a membership read failure and handles an empty list", async () => {
    const listMembers = vi
      .fn()
      .mockRejectedValueOnce(new Error("offline"))
      .mockResolvedValueOnce([]);
    const client = {
      ...membershipClient(),
      listMembers,
    };

    renderControls(client);

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "No se pudieron cargar los miembros.",
    );
    fireEvent.click(screen.getByRole("button", { name: /reintentar miembros/i }));
    expect(await screen.findByText("Todavía no hay miembros activos.")).toBeInTheDocument();
  });
});
