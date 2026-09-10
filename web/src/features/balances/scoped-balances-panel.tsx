import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { formatCents, formatSignedCents } from "../../core/cents-formatter";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import type { BalanceParticipantResponse, BalancesResponse } from "../../generated/api";
import { generatedBalanceClient, type BalanceFeatureClient } from "./api";

export interface ScopedBalancesPanelProps {
  client?: BalanceFeatureClient;
  groupId?: string;
  outingId?: string | null;
}

const groupIdFor = (configured: string | undefined, server: unknown) =>
  configured ?? (typeof server === "string" ? server : "");
const scope = (outingId: string | null | undefined) => outingId == null ? "grupo" : "salida";
const scopeTitle = (outingId: string | null | undefined) => outingId == null ? "del grupo" : "de la salida";

function assertScope(data: BalancesResponse, groupId: string, outingId?: string | null) {
  if (data.groupId !== groupId || (data.outingId ?? null) !== (outingId ?? null)) {
    throw new Error("La respuesta de balances no coincide con el alcance solicitado.");
  }
  return data;
}
function state(value: number): "credit" | "debt" | "neutral" {
  return value > 0 ? "credit" : value < 0 ? "debt" : "neutral";
}
function stateLabel(value: ReturnType<typeof state>) {
  return value === "credit" ? "Le deben" : value === "debt" ? "Debe" : "Saldado";
}
function Refresh({ pending, onClick }: { pending: boolean; onClick: () => void }) {
  return <Button type="button" variant="secondary" onClick={onClick} disabled={pending} aria-busy={pending}>
    {pending ? "Actualizando…" : "Actualizar balances"}
  </Button>;
}
function participantLabel(participant: BalanceParticipantResponse) {
  return participant.archived ? `${participant.name} (archivado)` : participant.name;
}

export function ScopedBalancesPanel({ client = generatedBalanceClient, groupId: configuredGroupId, outingId }: ScopedBalancesPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const noun = scope(outingId);
  const title = `Balances ${scopeTitle(outingId)}`;
  const query = useQuery({
    queryKey: workspaceQueryKeys.group.balances(groupId, outingId),
    queryFn: () => client.getBalances(groupId, outingId).then((data) => assertScope(data, groupId, outingId)),
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  if (query.isPending) return <LoadingCard>Cargando balances {scopeTitle(outingId)}…</LoadingCard>;
  if (query.isError || !query.data) return <ErrorCard>
    <span>No se pudieron cargar los balances {scopeTitle(outingId)}. Intenta nuevamente.</span>{" "}
    <Refresh pending={query.isFetching} onClick={() => void query.refetch()} />
  </ErrorCard>;

  return <Panel className="balances-card summary-card" labelledBy={`scoped-balances-title-${outingId ?? "group"}`}>
    <PanelHeading
      eyebrow={`Alcance: ${noun}`}
      title={title}
      titleId={`scoped-balances-title-${outingId ?? "group"}`}
      action={<><StatusBadge tone="info">{outingId == null ? "Grupo completo" : "Salida seleccionada"}</StatusBadge>{" "}<Refresh pending={query.isFetching} onClick={() => void query.refetch()} /></>}
    />
    {!query.data.participants.length ? <p className="feature-empty" role="status">No hay participantes en este alcance.</p> :
      <div className="table-scroll"><table className="balance-table" aria-label={title}>
        <thead><tr><th scope="col">Participante</th><th scope="col">Pagó</th><th scope="col">Le corresponde</th><th scope="col">Balance</th><th scope="col">Estado</th></tr></thead>
        <tbody>{query.data.participants.map((participant) => {
          const kind = state(participant.balanceCents);
          return <tr key={participant.participantId}>
            <th scope="row">{participantLabel(participant)}</th>
            <td className="tabular-figures">{formatCents(participant.paidCents)}</td>
            <td className="tabular-figures">{formatCents(participant.owedCents)}</td>
            <td className={`tabular-figures balance-${kind}`}>{formatSignedCents(participant.balanceCents)}</td>
            <td className={`balance-state balance-${kind}`}><StatusBadge tone={kind === "credit" ? "success" : kind === "debt" ? "danger" : "neutral"}>{stateLabel(kind)}</StatusBadge></td>
          </tr>;
        })}</tbody>
      </table></div>}
  </Panel>;
}
