import { QueryClient } from "@tanstack/react-query";
import { render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  SettlementPanel,
  type SettlementFeatureClient,
} from "../../../src/features/settlement";
import {
  type AuthClient,
  SessionProvider,
} from "../../../src/app/auth/session-provider";
import type {
  SessionIdentityResponse,
  SettlementResponse,
} from "../../../src/generated/api";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanel(response: SettlementResponse) {
  const client: SettlementFeatureClient = {
    getSettlement: vi.fn().mockResolvedValue(response),
  };
  render(
    <SessionProvider
      authClient={authClient()}
      queryClient={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <SettlementPanel client={client} />
    </SessionProvider>,
  );
}

describe("settlement panel", () => {
  it("renders the explicit all-settled empty state without transfers", async () => {
    renderPanel({
      groupId: "group-demo",
      settlementPolicy: "owner_only",
      settled: true,
      transfers: [],
    });

    expect(await screen.findByText(/everyone is settled/i)).toBeInTheDocument();
    expect(
      screen.queryByRole("list", { name: /transfers/i }),
    ).not.toBeInTheDocument();
  });

  it("renders ordered server transfers with formatted amounts", async () => {
    renderPanel({
      groupId: "group-demo",
      settlementPolicy: "owner_only",
      settled: false,
      transfers: [
        {
          fromParticipantId: "p4",
          fromName: "Diego",
          toParticipantId: "p1",
          toName: "Ana",
          amountCents: 40000,
        },
        {
          fromParticipantId: "p3",
          fromName: "Carla",
          toParticipantId: "p1",
          toName: "Ana",
          amountCents: 16000,
        },
      ],
    });

    const list = await screen.findByRole("list", { name: /transfers/i });
    expect(
      within(list)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual([
      expect.stringContaining("Diego"),
      expect.stringContaining("Carla"),
    ]);
    expect(within(list).getByText("Bs. 400.00")).toBeInTheDocument();
    expect(within(list).getByText("Bs. 160.00")).toBeInTheDocument();
  });
});
