import { useQuery } from "@tanstack/react-query";
import type { GroupSummaryResponse } from "../../generated/api";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import type { WorkspaceClient } from "./api";
import { generatedWorkspaceClient } from "./api";

export interface SummaryPanelProps {
  client?: WorkspaceClient;
  groupId: string;
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

function errorMessage(error: unknown): string {
  if (error instanceof Error && error.message.startsWith("La respuesta")) {
    return error.message;
  }
  const code = isRecord(error) && typeof error.errorCode === "string"
    ? error.errorCode
    : "";
  return code === "forbidden"
    ? "No tienes permisos para consultar este grupo."
    : "No se pudo cargar el grupo. Intenta nuevamente.";
}

function count(value: number | null | undefined, label: string): string {
  return value == null ? `— ${label}` : `${value} ${label}`;
}

export function SummaryPanel({
  client = generatedWorkspaceClient,
  groupId,
}: SummaryPanelProps) {
  const session = useSession();
  const summaryQuery = useQuery({
    queryKey: workspaceQueryKeys.group.summary(groupId),
    queryFn: async () => {
      const groups = await client.listGroups();
      const summary = groups.find((item) => item.id === groupId);
      if (!summary) throw new Error("La respuesta no coincide con el grupo solicitado.");
      return summary;
    },
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  const refresh = () => void summaryQuery.refetch();

  if (summaryQuery.isPending) return <LoadingCard>Cargando resumen…</LoadingCard>;
  if (summaryQuery.isError || !summaryQuery.data) {
    return (
      <ErrorCard>
        <span>{errorMessage(summaryQuery.error)}</span>{" "}
        <Button
          type="button"
          variant="secondary"
          onClick={refresh}
          disabled={summaryQuery.isFetching}
          aria-busy={summaryQuery.isFetching}
        >
          {summaryQuery.isFetching ? "Actualizando…" : "Actualizar grupo"}
        </Button>
      </ErrorCard>
    );
  }

  const group: GroupSummaryResponse = summaryQuery.data;
  const empty = [group.participantsCount, group.outingsCount, group.expensesCount]
    .every((value) => (value ?? 0) === 0);
  return (
    <Panel className="summary-card" labelledBy="summary-title">
      <PanelHeading
        eyebrow="Resumen del grupo"
        title={group.name}
        titleId="summary-title"
        action={<StatusBadge tone="info">{group.role === "owner" ? "Propietario" : "Miembro"}</StatusBadge>}
      />
      <dl className="group-details">
        <div><dt>Miembros</dt><dd>{count(group.memberCount, "miembros")}</dd></div>
        <div><dt>Participantes</dt><dd>{count(group.participantsCount, "participantes")}</dd></div>
        <div><dt>Salidas</dt><dd>{count(group.outingsCount, "salidas")}</dd></div>
        <div><dt>Gastos</dt><dd>{count(group.expensesCount, "gastos")}</dd></div>
      </dl>
      {empty && <p className="feature-empty" role="status">Aún no hay información en este grupo.</p>}
    </Panel>
  );
}
