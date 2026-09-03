import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { formatCents } from "../../core/cents-formatter";
import { groupQueryKey } from "../../core/query-client";
import { generatedSettlementClient, type SettlementFeatureClient } from "./api";

export interface SettlementPanelProps {
  client?: SettlementFeatureClient;
  groupId?: string;
}

function groupIdFor(configured: string | undefined, server: unknown): string {
  return configured ?? (typeof server === "string" ? server : "");
}

export function SettlementPanel({
  client = generatedSettlementClient,
  groupId: configuredGroupId,
}: SettlementPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const settlementQuery = useQuery({
    queryKey: groupQueryKey("settlement", groupId),
    queryFn: () => client.getSettlement(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });

  if (settlementQuery.isPending) {
    return <LoadingCard>Cargando liquidación…</LoadingCard>;
  }
  if (settlementQuery.isError || !settlementQuery.data) {
    return <ErrorCard>No se pudo cargar la liquidación. Intenta nuevamente.</ErrorCard>;
  }

  const settlement = settlementQuery.data;
  return (
    <Panel className="settlement-card" labelledBy="settlement-title">
      <PanelHeading
        eyebrow="Transferencias calculadas por el servidor"
        title="Liquidación"
        titleId="settlement-title"
        action={
          <StatusBadge tone="info">
            {settlement.settlementPolicy === "owner_only"
              ? "Solo propietario"
              : "Cualquier miembro"}
          </StatusBadge>
        }
      />
      {settlement.settled ? (
        <p className="feature-empty" role="status">
          Todos están saldados.
        </p>
      ) : (
        <ol className="transfer-list" aria-label="Transferencias">
          {settlement.transfers.map((transfer, index) => (
            <li
              className="transfer-row"
              key={`${transfer.fromParticipantId}-${transfer.toParticipantId}-${index}`}
            >
              <span className="transfer-copy">
                <strong>{transfer.fromName}</strong> →{" "}
                <strong>{transfer.toName}</strong>:{" "}
                <span className="tabular-figures transfer-amount">
                  {formatCents(transfer.amountCents)}
                </span>
              </span>
            </li>
          ))}
        </ol>
      )}
    </Panel>
  );
}
