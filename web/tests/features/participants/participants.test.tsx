import { QueryClient, useQuery } from "@tanstack/react-query";
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import {
  ParticipantsPanel,
  type ParticipantFeatureClient,
} from "../../../src/features/participants";
import {
  type AuthClient,
  AuthError,
  SessionProvider,
} from "../../../src/app/auth/session-provider";
import { groupQueryKey } from "../../../src/core/query-client";
import type {
  ParticipantResponse,
  SessionIdentityResponse,
} from "../../../src/generated/api";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

const participants: ParticipantResponse[] = [
  { id: "p1", groupId: "group-demo", name: "Ana", archived: false },
  { id: "p2", groupId: "group-demo", name: "Beto", archived: true },
  { id: "p3", groupId: "group-demo", name: "Carla", archived: false },
];

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanel(
  client: ParticipantFeatureClient,
  children?: React.ReactNode,
) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <SessionProvider authClient={authClient()} queryClient={queryClient}>
      <ParticipantsPanel client={client} />
      {children}
    </SessionProvider>,
  );
}

function baseClient(): ParticipantFeatureClient {
  return {
    listParticipants: vi.fn().mockResolvedValue(participants),
    addParticipant: vi.fn(),
    archiveParticipant: vi.fn(),
    reactivateParticipant: vi.fn(),
    deleteParticipant: vi.fn(),
    renameParticipant: vi.fn(),
  };
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("participants panel", () => {
  it("keeps the server stable order and shows archived status", async () => {
    renderPanel(baseClient());

    const list = await screen.findByRole("list", { name: /participantes/i });
    expect(
      within(list)
        .getAllByRole("listitem")
        .map((item) => item.getAttribute("data-participant-id")),
    ).toEqual(["p1", "p2", "p3"]);
    expect(within(list).getByText(/Beto.*archivado/i)).toBeInTheDocument();
  });

  it("keeps an invalid add editable without changing the list", async () => {
    const client = baseClient();
    renderPanel(client);

    await screen.findByText("Ana");
    const input = screen.getByLabelText(/nombre del nuevo participante/i);
    fireEvent.change(input, { target: { value: "   " } });
    fireEvent.click(screen.getByRole("button", { name: /agregar participante/i }));

    expect(client.addParticipant).not.toHaveBeenCalled();
    expect(screen.getAllByRole("listitem")).toHaveLength(3);
    expect(input).toHaveValue("   ");
    expect(screen.getByText(/invalid_participant_name/i)).toBeInTheDocument();
    expect(input).toHaveAttribute("aria-invalid", "true");
    expect(document.activeElement).toBe(input);
  });

  it("surfaces a duplicate add error inline and leaves the existing list intact", async () => {
    const client = baseClient();
    client.addParticipant = vi
      .fn()
      .mockRejectedValue(
        new AuthError(
          422,
          "duplicate_participant_name",
          "A participant with this name already exists.",
        ),
      );
    renderPanel(client);

    await screen.findByText("Ana");
    const input = screen.getByLabelText(/nombre del nuevo participante/i);
    fireEvent.change(input, { target: { value: " ana " } });
    fireEvent.click(screen.getByRole("button", { name: /agregar participante/i }));

    expect(
      await screen.findByText(/duplicate_participant_name/i),
    ).toBeInTheDocument();
    expect(screen.getAllByRole("listitem")).toHaveLength(3);
    expect(input).toHaveValue(" ana ");
  });

  it("archives and reactivates a participant through lifecycle actions", async () => {
    const client = baseClient();
    client.listParticipants = vi
      .fn()
      .mockResolvedValueOnce(participants)
      .mockResolvedValueOnce([
        { ...participants[0], archived: true },
        participants[1],
        participants[2],
      ])
      .mockResolvedValue([
        { ...participants[0], archived: false },
        participants[1],
        participants[2],
      ]);
    client.archiveParticipant = vi
      .fn()
      .mockResolvedValue({ ...participants[0], archived: true });
    client.reactivateParticipant = vi
      .fn()
      .mockResolvedValue({ ...participants[0], archived: false });
    renderPanel(client);

    await screen.findByText("Ana");
    fireEvent.click(screen.getByRole("button", { name: /archivar Ana/i }));
    await waitFor(() =>
      expect(client.archiveParticipant).toHaveBeenCalledWith(
        "group-demo",
        "p1",
      ),
    );

    fireEvent.click(
      await screen.findByRole("button", { name: /reactivar Ana/i }),
    );
    await waitFor(() =>
      expect(client.reactivateParticipant).toHaveBeenCalledWith(
        "group-demo",
        "p1",
      ),
    );
  });

  it("explains that an in-use participant should be archived instead of deleted", async () => {
    const client = baseClient();
    client.deleteParticipant = vi
      .fn()
      .mockRejectedValue(
        new AuthError(
          409,
          "participant_in_use",
          "This participant is referenced by historical expenses.",
        ),
      );
    renderPanel(client);

    await screen.findByText("Ana");
    fireEvent.click(screen.getByRole("button", { name: /eliminar Ana/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent(
      /participant_in_use.*archiva este participante/i,
    );
    expect(screen.getByText("Ana")).toBeInTheDocument();
  });

  it("binds invalid rename errors to the name field with focus and no state change", async () => {
    const client = baseClient();
    renderPanel(client);

    const input = await screen.findByRole("textbox", { name: /renombrar Ana/i });
    fireEvent.change(input, { target: { value: "  " } });
    fireEvent.click(screen.getByRole("button", { name: /renombrar Ana/i }));

    expect(client.renameParticipant).not.toHaveBeenCalled();
    expect(input).toHaveValue("  ");
    expect(input).toHaveAttribute("aria-invalid", "true");
    expect(input).toHaveAttribute(
      "aria-describedby",
      expect.stringContaining("error"),
    );
    expect(document.activeElement).toBe(input);
    expect(screen.getByText("Ana")).toBeInTheDocument();
  });

  it("keeps a normalized rename conflict bound to the edited field", async () => {
    const client = baseClient();
    client.renameParticipant = vi
      .fn()
      .mockRejectedValue(
        new AuthError(
          422,
          "duplicate_participant_name",
          "That participant name is already in use.",
        ),
      );
    renderPanel(client);

    const input = await screen.findByRole("textbox", { name: /renombrar Beto/i });
    fireEvent.change(input, { target: { value: " ana " } });
    fireEvent.click(screen.getByRole("button", { name: /renombrar Beto/i }));

    expect(
      await screen.findByText(/duplicate_participant_name/i),
    ).toBeInTheDocument();
    expect(input).toHaveAttribute("aria-invalid", "true");
    expect(document.activeElement).toBe(input);
    expect(
      within(screen.getByRole("list")).getByText(/Beto.*archivado/i),
    ).toBeInTheDocument();
  });

  it("refetches after a successful rename without changing the participant identity or balance", async () => {
    const client = baseClient();
    client.listParticipants = vi
      .fn()
      .mockResolvedValueOnce(participants)
      .mockResolvedValue([
        participants[0] && { ...participants[0], name: "Ana L." },
        participants[1],
        participants[2],
      ]);
    client.renameParticipant = vi.fn().mockResolvedValue({
      ...participants[0],
      name: "Ana L.",
    });
    const fetchBalances = vi.fn().mockResolvedValue({
      groupId: "group-demo",
      participants: [{ participantId: "p1", name: "Ana", balanceCents: 56000 }],
    });

    function BalanceProbe() {
      const { data } = useQuery({
        queryKey: groupQueryKey("balances", "group-demo"),
        queryFn: fetchBalances,
      });
      return (
        <output data-testid="balance">
          {data?.participants[0]?.balanceCents}
        </output>
      );
    }

    renderPanel(client, <BalanceProbe />);
    const input = await screen.findByRole("textbox", { name: /renombrar Ana/i });
    fireEvent.change(input, { target: { value: "Ana L." } });
    fireEvent.click(screen.getByRole("button", { name: /renombrar Ana/i }));

    await waitFor(() =>
      expect(client.renameParticipant).toHaveBeenCalledWith(
        "group-demo",
        "p1",
        "Ana L.",
      ),
    );
    expect(await screen.findByDisplayValue("Ana L.")).toBeInTheDocument();
    await waitFor(() => expect(fetchBalances).toHaveBeenCalledTimes(2));
    expect(screen.getByTestId("balance")).toHaveTextContent("56000");
  });
});
