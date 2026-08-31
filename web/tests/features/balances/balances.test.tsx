import { QueryClient } from "@tanstack/react-query";
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  BalancesPanel,
  type BalanceFeatureClient,
} from "../../../src/features/balances";
import {
  type AuthClient,
  SessionProvider,
} from "../../../src/app/auth/session-provider";
import type {
  BalancesResponse,
  SessionIdentityResponse,
} from "../../../src/generated/api";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

const balances: BalancesResponse = {
  groupId: "group-demo",
  participants: [
    {
      participantId: "p1",
      name: "Ana",
      archived: false,
      paidCents: 96000,
      owedCents: 40000,
      balanceCents: 56000,
    },
    {
      participantId: "p2",
      name: "Beto",
      archived: false,
      paidCents: 40000,
      owedCents: 40000,
      balanceCents: 0,
    },
    {
      participantId: "p3",
      name: "Carla",
      archived: false,
      paidCents: 24000,
      owedCents: 40000,
      balanceCents: -16000,
    },
    {
      participantId: "p4",
      name: "Diego",
      archived: true,
      paidCents: 0,
      owedCents: 0,
      balanceCents: 0,
    },
  ],
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanel(client: BalanceFeatureClient) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <SessionProvider authClient={authClient()} queryClient={queryClient}>
      <BalancesPanel client={client} />
    </SessionProvider>,
  );
}

describe("balances panel", () => {
  it("renders server balances in stable order with archived zero and non-color meaning", async () => {
    const client: BalanceFeatureClient = {
      getBalances: vi.fn().mockResolvedValue(balances),
    };
    renderPanel(client);

    const table = await screen.findByRole("table", { name: /balances/i });
    expect(
      within(table)
        .getAllByRole("row")
        .slice(1)
        .map((row) => within(row).getByRole("rowheader").textContent),
    ).toEqual(["Ana", "Beto", "Carla", "Diego (archived)"]);
    expect(within(table).getByText("Bs. 560.00")).toBeInTheDocument();
    expect(within(table).getAllByText("Bs. 0.00")).toHaveLength(4);
    expect(within(table).getByText("-Bs. 160.00")).toBeInTheDocument();
    expect(within(table).getByText(/Credit/)).toBeInTheDocument();
    expect(within(table).getByText(/Debt/)).toBeInTheDocument();
    expect(within(table).getAllByText(/Neutral/)).toHaveLength(2);
    expect(within(table).getByText("↑")).toBeInTheDocument();
  });

  it("uses REST on startup and when the WebSocket is unavailable", async () => {
    const client: BalanceFeatureClient = {
      getBalances: vi.fn().mockResolvedValue(balances),
    };
    renderPanel(client);

    await screen.findByRole("table", { name: /balances/i });
    expect(client.getBalances).toHaveBeenCalledWith("group-demo");
    fireEvent.click(screen.getByRole("button", { name: /refresh balances/i }));
    await waitFor(() => expect(client.getBalances).toHaveBeenCalledTimes(2));
  });
});
