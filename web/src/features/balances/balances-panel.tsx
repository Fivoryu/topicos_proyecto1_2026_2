import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
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
    return <LoadingCard>Cargando balances…</LoadingCard>;
  }
  if (balancesQuery.isError || !balancesQuery.data) {
    return <ErrorCard>No se pudieron cargar los balances. Intenta nuevamente.</ErrorCard>;
  }

  return (
    <Panel className="balances-card" labelledBy="balances-title">
      <PanelHeading
        eyebrow="Totales calculados por el servidor"
        title="Balances"
        titleId="balances-title"
        action={<Button
          type="button"
          variant="secondary"
          onClick={() => void balancesQuery.refetch()}
          disabled={balancesQuery.isFetching}
          aria-busy={balancesQuery.isFetching}
        >
          {balancesQuery.isFetching ? "Actualizando…" : "Actualizar balances"}
        </Button>}
      />
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
                  <th scope="row" data-label="Participante">{participantLabel(participant)}</th>
                  <td className="tabular-figures" data-label="Pagó">
                    {formatCents(participant.paidCents)}
                  </td>
                  <td className="tabular-figures" data-label="Le corresponde">
                    {formatCents(participant.owedCents)}
                  </td>
                  <td className={`tabular-figures balance-${state}`} data-label="Balance">
                    {formatSignedCents(participant.balanceCents)}
                  </td>
                  <td className={`balance-state balance-${state}`} data-label="Estado">
                    <StatusBadge tone={state === "credit" ? "success" : state === "debt" ? "danger" : "neutral"}>
                      <span aria-hidden="true">{stateIcon(state)}</span>{" "}
                      {stateLabel(state)}
                    </StatusBadge>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </Panel>
  );
}
