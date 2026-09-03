import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { formatCents, formatSignedCents } from "../../core/cents-formatter";
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
  if (state === "credit") return "Le deben";
  if (state === "debt") return "Debe";
  return "Saldado";
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
    ? `${participant.name} (archivado)`
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
    return <section className="feature-card">Cargando balances…</section>;
  }
  if (balancesQuery.isError || !balancesQuery.data) {
    return (
      <section className="feature-card" role="alert">
        No se pudieron cargar los balances. Intenta nuevamente.
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
          <p className="feature-eyebrow">Totales calculados por el servidor</p>
          <h2 id="balances-title">Balances</h2>
        </div>
        <button
          type="button"
          className="feature-button feature-button-secondary"
          onClick={() => void balancesQuery.refetch()}
          disabled={balancesQuery.isFetching}
          aria-busy={balancesQuery.isFetching}
        >
          {balancesQuery.isFetching ? "Actualizando…" : "Actualizar balances"}
        </button>
      </div>
      <div className="table-scroll">
        <table className="balance-table" aria-label="Balances">
          <thead>
            <tr>
              <th scope="col">Participante</th>
              <th scope="col">Pagó</th>
              <th scope="col">Le corresponde</th>
              <th scope="col">Balance</th>
              <th scope="col">Estado</th>
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
                    {formatSignedCents(participant.balanceCents)}
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
