import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
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
    return <section className="feature-card">Cargando liquidación…</section>;
  }
  if (settlementQuery.isError || !settlementQuery.data) {
    return (
      <section className="feature-card" role="alert">
        No se pudo cargar la liquidación. Intenta nuevamente.
      </section>
    );
  }

  const settlement = settlementQuery.data;
  return (
    <section
      className="feature-card settlement-card"
      aria-labelledby="settlement-title"
    >
      <div className="feature-heading">
        <div>
          <p className="feature-eyebrow">Transferencias calculadas por el servidor</p>
          <h2 id="settlement-title">Liquidación</h2>
        </div>
        <span>
          {settlement.settlementPolicy === "owner_only"
            ? "Solo propietario"
            : "Cualquier miembro"}
        </span>
      </div>
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
              <span>
                <strong>{transfer.fromName}</strong> →{" "}
                <strong>{transfer.toName}</strong>:{" "}
                <span className="tabular-figures">
                  {formatCents(transfer.amountCents)}
                </span>
              </span>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}
