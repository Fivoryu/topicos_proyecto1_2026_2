import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { formatCents } from "../../core/cents-formatter";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import type { SettlementResponse } from "../../generated/api";
import { generatedSettlementClient, type SettlementFeatureClient } from "./api";

export interface ScopedSettlementPanelProps {
  client?: SettlementFeatureClient;
  groupId?: string;
  outingId?: string | null;
}

const groupIdFor = (configured: string | undefined, server: unknown) =>
  configured ?? (typeof server === "string" ? server : "");
const scope = (outingId: string | null | undefined) => outingId == null ? "grupo" : "salida";
const scopeTitle = (outingId: string | null | undefined) => outingId == null ? "del grupo" : "de la salida";
function Refresh({ pending, onClick }: { pending: boolean; onClick: () => void }) {
  return <Button type="button" variant="secondary" onClick={onClick} disabled={pending} aria-busy={pending}>
    {pending ? "Actualizando…" : "Actualizar liquidación"}
  </Button>;
}
function assertScope(data: SettlementResponse, groupId: string, outingId?: string | null) {
  if (data.groupId !== groupId || (data.outingId ?? null) !== (outingId ?? null)) {
    throw new Error("La respuesta de liquidación no coincide con el alcance solicitado.");
  }
  return data;
}

export function ScopedSettlementPanel({ client = generatedSettlementClient, groupId: configuredGroupId, outingId }: ScopedSettlementPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const noun = scope(outingId);
  const title = `Liquidación ${scopeTitle(outingId)}`;
  const query = useQuery({
    queryKey: workspaceQueryKeys.group.settlement(groupId, outingId),
    queryFn: () => client.getSettlement(groupId, outingId).then((data) => assertScope(data, groupId, outingId)),
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  if (query.isPending) return <LoadingCard>Cargando liquidación {scopeTitle(outingId)}…</LoadingCard>;
  if (query.isError || !query.data) return <ErrorCard>
    <span>No se pudo cargar la liquidación {scopeTitle(outingId)}. Intenta nuevamente.</span>{" "}
    <Refresh pending={query.isFetching} onClick={() => void query.refetch()} />
  </ErrorCard>;

  return <Panel className="settlement-card summary-card" labelledBy={`scoped-settlement-title-${outingId ?? "group"}`}>
    <PanelHeading
      eyebrow={`Alcance: ${noun}`}
      title={title}
      titleId={`scoped-settlement-title-${outingId ?? "group"}`}
      action={<><StatusBadge tone="info">{outingId == null ? "Grupo completo" : "Salida seleccionada"}</StatusBadge>{" "}<StatusBadge>{query.data.settlementPolicy === "owner_only" ? "Solo propietario" : "Cualquier miembro"}</StatusBadge>{" "}<Refresh pending={query.isFetching} onClick={() => void query.refetch()} /></>}
    />
    {query.data.settled ? <p className="feature-empty" role="status">Todos están saldados.</p> :
      <ol className="transfer-list" aria-label={`Transferencias ${scopeTitle(outingId)}`}>
        {query.data.transfers.map((transfer, index) => <li className="transfer-row" key={`${transfer.fromParticipantId}-${transfer.toParticipantId}-${index}`}>
          <span className="transfer-copy"><strong>{transfer.fromName}</strong> → <strong>{transfer.toName}</strong>{": "}<span className="tabular-figures transfer-amount">{formatCents(transfer.amountCents)}</span></span>
        </li>)}
      </ol>}
  </Panel>;
}
