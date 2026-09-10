import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { JoinCodeConsume } from "../../../src/features/group/join-code-consume";
import type { GroupMembershipClient } from "../../../src/features/group/api";
import type { ParticipantFeatureClient } from "../../../src/features/participants/api";

const participants = [
  { id: "p-1", name: "Ana", archived: false, groupId: "g-1" },
  { id: "p-2", name: "Beto", archived: false, groupId: "g-1" },
  { id: "p-old", name: "Carla", archived: true, groupId: "g-1" },
];

function renderJoin(
  consumeJoinCode: GroupMembershipClient["consumeJoinCode"],
  listParticipants: ParticipantFeatureClient["listParticipants"] = vi
    .fn()
    .mockResolvedValue(participants),
) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  vi.spyOn(queryClient, "invalidateQueries");
  render(
    <QueryClientProvider client={queryClient}>
      <JoinCodeConsume
        client={{ consumeJoinCode }}
        participantsClient={{ listParticipants }}
        groupId="g-1"
        accountId="account-1"
      />
    </QueryClientProvider>,
  );
  return queryClient;
}

afterEach(cleanup);

describe("join-code consumption", () => {
  it("offers one active participant choice and never echoes the code", async () => {
    const consume = vi.fn();
    renderJoin(consume);

    expect(await screen.findByRole("radio", { name: /usar ana/i })).toBeChecked();
    expect(screen.getByRole("radio", { name: /usar beto/i })).toBeInTheDocument();
    expect(screen.queryByText("SECRET-123")).not.toBeInTheDocument();
    expect(screen.getByLabelText("Código de invitación")).toHaveAttribute(
      "autocomplete",
      "off",
    );
  });

  it("submits the selected existing participant and invalidates protected queries", async () => {
    const consume = vi.fn().mockResolvedValue({
      accountId: "account-1",
      groupId: "g-1",
      participantId: "p-1",
    });
    const queryClient = renderJoin(consume);
    await screen.findByLabelText("Código de invitación");
    fireEvent.change(screen.getByLabelText(/código de invitación/i), {
      target: { value: "SECRET-123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /unirme al grupo/i }));

    await waitFor(() =>
      expect(consume).toHaveBeenCalledWith({
        code: "SECRET-123",
        participantId: "p-1",
      }),
    );
    expect(await screen.findByRole("status")).toHaveTextContent(
      /te uniste al grupo correctamente/i,
    );
    expect(screen.getByRole("button", { name: /usar otro código/i })).toBeInTheDocument();
    expect(queryClient.invalidateQueries).toHaveBeenCalled();
  });

  it("switches exclusively to a new participant and validates the name", async () => {
    const consume = vi.fn().mockResolvedValue({
      accountId: "account-1",
      groupId: "g-1",
      participantId: "p-new",
    });
    renderJoin(consume);
    await screen.findByRole("radio", { name: /crear un participante nuevo/i });
    fireEvent.click(screen.getByRole("radio", { name: /crear un participante nuevo/i }));
    expect(screen.getByRole("radio", { name: /usar ana/i })).not.toBeChecked();
    fireEvent.change(screen.getByLabelText(/código de invitación/i), {
      target: { value: "SECRET-123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /unirme al grupo/i }));
    expect(consume).not.toHaveBeenCalled();
    fireEvent.change(screen.getByLabelText(/nombre del participante nuevo/i), {
      target: { value: "  Diego  " },
    });
    fireEvent.click(screen.getByRole("button", { name: /unirme al grupo/i }));

    await waitFor(() =>
      expect(consume).toHaveBeenCalledWith({
        code: "SECRET-123",
        newParticipantName: "Diego",
      }),
    );
  });

  it("shows participant loading recovery and server errors without losing the form", async () => {
    const listParticipants = vi
      .fn()
      .mockRejectedValueOnce(new Error("offline"))
      .mockResolvedValueOnce([]);
    const consume = vi.fn().mockRejectedValue({ code: "invalid_join_code" });
    renderJoin(consume, listParticipants);
    expect(await screen.findByRole("alert")).toHaveTextContent(
      /no se pudieron cargar los participantes/i,
    );
    fireEvent.click(screen.getByRole("button", { name: /reintentar participantes/i }));
    expect(await screen.findByText(/crear un participante nuevo/i)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Nombre del participante nuevo"), {
      target: { value: "Diego" },
    });
    fireEvent.change(screen.getByLabelText("Código de invitación"), {
      target: { value: "SECRET-123" },
    });
    fireEvent.click(screen.getByRole("button", { name: /unirme al grupo/i }));
    expect(await screen.findByRole("alert")).toHaveTextContent(/invalid_join_code/i);
    expect(screen.getByLabelText("Código de invitación")).toHaveValue("SECRET-123");
  });
});
