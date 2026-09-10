import { QueryClient } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import type { ReactNode } from "react";

import { SessionProvider, type AuthClient } from "../../../src/app/auth/session-provider";
import type { BalancesResponse, SessionIdentityResponse, SettlementResponse } from "../../../src/generated/api";
import { ScopedBalancesPanel, type BalanceFeatureClient } from "../../../src/features/balances";
import { ScopedSettlementPanel, type SettlementFeatureClient } from "../../../src/features/settlement";
import { workspaceQueryKeys } from "../../../src/core/workspace-query-keys";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" }, activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"), role: "member",
};
const balances: BalancesResponse = {
  groupId: "group-demo", outingId: "outing-one", participants: [
    { participantId: "ana", name: "Ana", archived: false, paidCents: 24000, owedCents: 12000, balanceCents: 12000 },
    { participantId: "diego", name: "Diego", archived: true, paidCents: 0, owedCents: 12000, balanceCents: -12000 },
  ],
};
const settlement: SettlementResponse = {
  groupId: "group-demo", outingId: "outing-one", settlementPolicy: "owner_only", settled: false,
  transfers: [{ fromParticipantId: "diego", fromName: "Diego", toParticipantId: "ana", toName: "Ana", amountCents: 12000 }],
};
function authClient(): AuthClient {
  return { getSession: vi.fn().mockResolvedValue(session), login: vi.fn(), logout: vi.fn() };
}
function renderInSession(children: ReactNode) {
  return render(<SessionProvider authClient={authClient()} queryClient={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>{children}</SessionProvider>);
}

describe("scoped derived panels", () => {
  it("isolates query keys and forwards the selected outing to the balance client", async () => {
    const client: BalanceFeatureClient = { getBalances: vi.fn().mockResolvedValue(balances) };
    renderInSession(<ScopedBalancesPanel client={client} outingId="outing-one" />);
    expect(workspaceQueryKeys.group.balances("group-demo")).toEqual(["group", "group-demo", "balances", "group"]);
    expect(workspaceQueryKeys.group.balances("group-demo", "outing-one")).toEqual(["group", "group-demo", "balances", "outing-one"]);
    expect(workspaceQueryKeys.group.balances("other", "outing-one")).not.toEqual(workspaceQueryKeys.group.balances("group-demo", "outing-one"));
    await screen.findByRole("table", { name: /balances de la salida/i });
    expect(client.getBalances).toHaveBeenCalledWith("group-demo", "outing-one");
  });

  it("shows a loading state while scoped balances are pending", async () => {
    const client: BalanceFeatureClient = { getBalances: vi.fn().mockReturnValue(new Promise<BalancesResponse>(() => {})) };
    renderInSession(<ScopedBalancesPanel client={client} />);
    expect(await screen.findByText(/cargando balances del grupo/i)).toBeInTheDocument();
  });

  it("renders server cents, archived labels, empty, and refresh states", async () => {
    const client: BalanceFeatureClient = { getBalances: vi.fn().mockResolvedValue(balances) };
    renderInSession(<ScopedBalancesPanel client={client} outingId="outing-one" />);
    const table = await screen.findByRole("table", { name: /balances de la salida/i });
    expect(within(table).getByText("+Bs. 120,00")).toBeInTheDocument();
    expect(within(table).getByText("Diego (archivado)")).toBeInTheDocument();

    const empty: BalanceFeatureClient = { getBalances: vi.fn().mockResolvedValue({ groupId: "group-demo", outingId: null, participants: [] }) };
    renderInSession(<ScopedBalancesPanel client={empty} />);
    expect(await screen.findByText(/no hay participantes/i)).toBeInTheDocument();

    const failed: BalanceFeatureClient = { getBalances: vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce({ groupId: "group-demo", participants: [] }) };
    renderInSession(<ScopedBalancesPanel client={failed} />);
    const alert = await screen.findByRole("alert");
    fireEvent.click(within(alert).getByRole("button", { name: /actualizar balances/i }));
    await waitFor(() => expect(failed.getBalances).toHaveBeenCalledTimes(2));
  });

  it("does not render a stale or cross-group balance response", async () => {
    const client: BalanceFeatureClient = { getBalances: vi.fn().mockResolvedValue({ ...balances, groupId: "other", participants: [{ ...balances.participants[0], name: "Dato filtrado" }] }) };
    renderInSession(<ScopedBalancesPanel client={client} outingId="outing-one" />);
    expect(await screen.findByRole("alert")).toHaveTextContent(/no se pudieron cargar/i);
    expect(screen.queryByText("Dato filtrado")).not.toBeInTheDocument();
  });

  it("renders ordered scoped settlement and the all-settled state", async () => {
    const client: SettlementFeatureClient = { getSettlement: vi.fn().mockResolvedValue(settlement) };
    renderInSession(<ScopedSettlementPanel client={client} outingId="outing-one" />);
    const list = await screen.findByRole("list", { name: /transferencias de la salida/i });
    expect(screen.getByText(/alcance: salida/i)).toBeInTheDocument();
    expect(screen.getByText("Solo propietario")).toBeInTheDocument();
    expect(within(list).getByRole("listitem")).toHaveTextContent("Diego → Ana: Bs. 120,00");
    expect(client.getSettlement).toHaveBeenCalledWith("group-demo", "outing-one");

    const settled: SettlementFeatureClient = { getSettlement: vi.fn().mockResolvedValue({ groupId: "group-demo", outingId: null, settlementPolicy: "any_member", settled: true, transfers: [] }) };
    renderInSession(<ScopedSettlementPanel client={settled} />);
    expect(await screen.findByText(/todos están saldados/i)).toBeInTheDocument();
  });

  it("rejects stale settlement data before rendering it", async () => {
    const client: SettlementFeatureClient = { getSettlement: vi.fn().mockResolvedValue({ ...settlement, outingId: "other-outing", transfers: [{ ...settlement.transfers[0], fromName: "Dato filtrado" }] }) };
    renderInSession(<ScopedSettlementPanel client={client} outingId="outing-one" />);
    expect(await screen.findByRole("alert")).toHaveTextContent(/no se pudo cargar/i);
    expect(screen.queryByText("Dato filtrado")).not.toBeInTheDocument();
  });

  it("refreshes after a settlement error", async () => {
    const client: SettlementFeatureClient = { getSettlement: vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce({ ...settlement, settled: true, transfers: [], outingId: null }) };
    renderInSession(<ScopedSettlementPanel client={client} />);
    const alert = await screen.findByRole("alert");
    fireEvent.click(within(alert).getByRole("button", { name: /actualizar liquidación/i }));
    await waitFor(() => expect(client.getSettlement).toHaveBeenCalledTimes(2));
  });
});
