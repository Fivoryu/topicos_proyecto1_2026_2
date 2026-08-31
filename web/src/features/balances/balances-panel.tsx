import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { formatCents } from "../../core/cents-formatter";
import { groupQueryKey } from "../../core/query-client";
import type { BalanceParticipantResponse } from "../../generated/api";
import { generatedBalanceClient, type BalanceFeatureClient } from "./api";

export interface BalancesPanelProps {
  client?: BalanceFeatureClient;
  groupId?: string;
}

function balanceState(balanceCents: number): "credit" | "debt" | "neutral" {
  if (balanceCents > 0) return "credit";
  if (balanceCents < 0) return "debt";
  return "neutral";
}

function stateLabel(state: ReturnType<typeof balanceState>): string {
  if (state === "credit") return "Credit";
  if (state === "debt") return "Debt";
  return "Neutral";
}

function stateIcon(state: ReturnType<typeof balanceState>): string {
  if (state === "credit") return "↑";
  if (state === "debt") return "↓";
  return "—";
}

function groupIdFor(configured: string | undefined, server: unknown): string {
  return configured ?? (typeof server === "string" ? server : "");
}

function participantLabel(participant: BalanceParticipantResponse): string {
  return participant.archived
    ? `${participant.name} (archived)`
    : participant.name;
}

export function BalancesPanel({
  client = generatedBalanceClient,
  groupId: configuredGroupId,
}: BalancesPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const balancesQuery = useQuery({
    queryKey: groupQueryKey("balances", groupId),
    queryFn: () => client.getBalances(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });

  if (balancesQuery.isPending) {
    return <section className="feature-card">Loading balances…</section>;
  }
  if (balancesQuery.isError || !balancesQuery.data) {
    return (
      <section className="feature-card" role="alert">
        Unable to load balances. Please try again.
      </section>
    );
  }

  return (
    <section
      className="feature-card balances-card"
      aria-labelledby="balances-title"
    >
      <div className="feature-heading">
        <div>
          <p className="feature-eyebrow">Server-derived totals</p>
          <h2 id="balances-title">Balances</h2>
        </div>
        <button
          type="button"
          className="feature-button feature-button-secondary"
          onClick={() => void balancesQuery.refetch()}
          disabled={balancesQuery.isFetching}
          aria-busy={balancesQuery.isFetching}
        >
          {balancesQuery.isFetching ? "Refreshing…" : "Refresh balances"}
        </button>
      </div>
      <div className="table-scroll">
        <table className="balance-table" aria-label="Balances">
          <thead>
            <tr>
              <th scope="col">Participant</th>
              <th scope="col">Paid</th>
              <th scope="col">Owed</th>
              <th scope="col">Balance</th>
              <th scope="col">Position</th>
            </tr>
          </thead>
          <tbody>
            {balancesQuery.data.participants.map((participant) => {
              const state = balanceState(participant.balanceCents);
              return (
                <tr key={participant.participantId}>
                  <th scope="row">{participantLabel(participant)}</th>
                  <td className="tabular-figures">
                    {formatCents(participant.paidCents)}
                  </td>
                  <td className="tabular-figures">
                    {formatCents(participant.owedCents)}
                  </td>
                  <td className={`tabular-figures balance-${state}`}>
                    {formatCents(participant.balanceCents)}
                  </td>
                  <td className={`balance-state balance-${state}`}>
                    <span aria-hidden="true">{stateIcon(state)}</span>{" "}
                    {stateLabel(state)}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}
