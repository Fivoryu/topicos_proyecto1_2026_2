import { QueryClient } from "@tanstack/react-query";
import { render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  SettlementPanel,
  type SettlementFeatureClient,
} from "../../../src/features/settlement";
import { workspaceQueryKeys } from "../../../src/core/workspace-query-keys";
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
  it("keeps group and outing scopes isolated in query identity", () => {
    expect(workspaceQueryKeys.group.settlement("group-demo")).toEqual([
      "group",
      "group-demo",
      "settlement",
      "group",
    ]);
    expect(
      workspaceQueryKeys.group.settlement("group-demo", null),
    ).toEqual(workspaceQueryKeys.group.settlement("group-demo"));
    expect(
      workspaceQueryKeys.group.settlement("group-demo", "outing-one"),
    ).not.toEqual(workspaceQueryKeys.group.settlement("group-demo"));
  });

  it("renders the explicit all-settled empty state without transfers", async () => {
    renderPanel({
      groupId: "group-demo",
      settlementPolicy: "owner_only",
      settled: true,
      transfers: [],
    });

    expect(
      await screen.findByText(/todos están saldados/i),
    ).toBeInTheDocument();
    expect(
      screen.queryByRole("list", { name: /transferencias/i }),
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

    const heading = await screen.findByRole("heading", { name: "Liquidación" });
    expect(heading).toBeInTheDocument();
    expect(screen.getByText("Solo propietario")).toBeInTheDocument();
    const list = screen.getByRole("list", { name: /transferencias/i });
    expect(
      within(list)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(["Diego → Ana: Bs. 400,00", "Carla → Ana: Bs. 160,00"]);
  });
});
