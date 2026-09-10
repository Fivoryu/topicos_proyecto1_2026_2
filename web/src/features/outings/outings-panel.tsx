import { useQuery } from "@tanstack/react-query";
import type { OutingResponse } from "../../generated/api";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import type { OutingFeatureClient } from "./api";
import { generatedOutingClient } from "./api";

export interface OutingsPanelProps {
  client?: OutingFeatureClient;
  groupId?: string;
}

export interface OutingDetailPanelProps {
  client?: OutingFeatureClient;
  groupId: string;
  outingId: string;
}

function groupIdFor(configured: string | undefined, server: unknown): string {
  return configured ?? (typeof server === "string" ? server : "");
}

function RefreshButton({
  label,
  pending,
  onClick,
}: {
  label: string;
  pending: boolean;
  onClick: () => void;
}) {
  return (
    <Button
      type="button"
      variant="secondary"
      onClick={onClick}
      disabled={pending}
      aria-busy={pending}
    >
      {pending ? "Actualizando…" : label}
    </Button>
  );
}

function archivedDate(outing: OutingResponse) {
  if (!outing.archivedAt) return null;
  return (
    <p>
      Archivada el{" "}
      <time dateTime={outing.archivedAt.toISOString()}>
        {new Intl.DateTimeFormat("es-BO", { dateStyle: "medium" }).format(
          outing.archivedAt,
        )}
      </time>
    </p>
  );
}

function OutingList({ outings, archived }: { outings: OutingResponse[]; archived: boolean }) {
  return (
    <ul className="outing-list" aria-label={archived ? "Salidas archivadas" : "Salidas activas"}>
      {outings.map((outing) => (
        <li className="outing-row" data-outing-id={outing.id} key={outing.id}>
          <div className="outing-heading">
            <strong>{outing.name}</strong>
            <StatusBadge tone={archived ? "warning" : "success"}>
              {archived ? "Archivada" : "Activa"}
            </StatusBadge>
          </div>
          {archivedDate(outing)}
        </li>
      ))}
    </ul>
  );
}

export function OutingsPanel({
  client = generatedOutingClient,
  groupId: configuredGroupId,
}: OutingsPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const outingsQuery = useQuery({
    queryKey: ["group", groupId, "outings"],
    queryFn: () => client.listOutings(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });

  if (outingsQuery.isPending) return <LoadingCard>Cargando salidas…</LoadingCard>;
  if (outingsQuery.isError || !outingsQuery.data) {
    return (
      <ErrorCard>
        <span>No se pudieron cargar las salidas. Intenta nuevamente.</span>{" "}
        <RefreshButton
          label="Actualizar salidas"
          pending={outingsQuery.isFetching}
          onClick={() => void outingsQuery.refetch()}
        />
      </ErrorCard>
    );
  }

  const activeOutings = outingsQuery.data.filter((outing) => !outing.archived);
  const archivedOutings = outingsQuery.data.filter((outing) => outing.archived);
  return (
    <Panel className="outings-card" labelledBy="outings-title">
      <PanelHeading
        eyebrow="Espacios del grupo"
        title="Salidas"
        titleId="outings-title"
        action={
          <RefreshButton
            label="Actualizar salidas"
            pending={outingsQuery.isFetching}
            onClick={() => void outingsQuery.refetch()}
          />
        }
      />
      {!outingsQuery.data.length ? (
        <p className="feature-empty" role="status">
          Aún no hay salidas en este grupo.
        </p>
      ) : (
        <div className="outing-sections">
          <section aria-labelledby="active-outings-title">
            <h3 id="active-outings-title">Salidas activas</h3>
            <OutingList outings={activeOutings} archived={false} />
          </section>
          <section aria-labelledby="archived-outings-title">
            <h3 id="archived-outings-title">Salidas archivadas</h3>
            <OutingList outings={archivedOutings} archived />
          </section>
        </div>
      )}
    </Panel>
  );
}

export function OutingDetailPanel({
  client = generatedOutingClient,
  groupId,
  outingId,
}: OutingDetailPanelProps) {
  const session = useSession();
  const detailQuery = useQuery({
    queryKey: ["group", groupId, "outing", outingId],
    queryFn: () => client.getOuting(groupId, outingId),
    enabled: session.isAuthenticated && Boolean(groupId) && Boolean(outingId),
  });

  if (detailQuery.isPending) return <LoadingCard>Cargando salida…</LoadingCard>;
  if (detailQuery.isError || !detailQuery.data) {
    return (
      <ErrorCard>
        <span>No se pudo cargar la salida. Intenta nuevamente.</span>{" "}
        <RefreshButton
          label="Actualizar salida"
          pending={detailQuery.isFetching}
          onClick={() => void detailQuery.refetch()}
        />
      </ErrorCard>
    );
  }
  const outing = detailQuery.data;
  if (outing.groupId !== groupId || outing.id !== outingId) {
    return (
      <ErrorCard>
        <span>La respuesta no coincide con la salida solicitada.</span>{" "}
        <RefreshButton
          label="Actualizar salida"
          pending={detailQuery.isFetching}
          onClick={() => void detailQuery.refetch()}
        />
      </ErrorCard>
    );
  }

  return (
    <Panel className="outing-detail-card" labelledBy="outing-detail-title">
      <PanelHeading eyebrow="Detalle de salida" title={outing.name} titleId="outing-detail-title" />
      {outing.archived ? (
        <aside className="feature-state-card" role="note">
          <StatusBadge tone="warning">Archivada</StatusBadge>{" "}
          <span>Esta salida es de solo lectura. Su historial se conserva.</span>
          {archivedDate(outing)}
        </aside>
      ) : (
        <StatusBadge tone="success">Activa</StatusBadge>
      )}
    </Panel>
  );
}
