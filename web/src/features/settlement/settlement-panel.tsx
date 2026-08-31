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
    return <section className="feature-card">Loading settlement…</section>;
  }
  if (settlementQuery.isError || !settlementQuery.data) {
    return (
      <section className="feature-card" role="alert">
        Unable to load settlement. Please try again.
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
          <p className="feature-eyebrow">Server-derived transfers</p>
          <h2 id="settlement-title">Settlement</h2>
        </div>
        <span>
          {settlement.settlementPolicy === "owner_only"
            ? "Owner only"
            : "Any member"}
        </span>
      </div>
      {settlement.settled ? (
        <p className="feature-empty" role="status">
          Everyone is settled.
        </p>
      ) : (
        <ol className="transfer-list" aria-label="Transfers">
          {settlement.transfers.map((transfer, index) => (
            <li
              className="transfer-row"
              key={`${transfer.fromParticipantId}-${transfer.toParticipantId}-${index}`}
            >
              <span>
                <strong>{transfer.fromName}</strong> pays{" "}
                <strong>{transfer.toName}</strong>
              </span>
              <span className="tabular-figures">
                {formatCents(transfer.amountCents)}
              </span>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}
