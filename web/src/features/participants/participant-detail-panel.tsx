import { useQuery } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import type { ParticipantResponse } from "../../generated/api";
import type { ParticipantFeatureClient } from "./api";
import { generatedParticipantClient } from "./api";

export interface ParticipantDetailPanelProps {
  client?: ParticipantFeatureClient;
  groupId: string;
  participantId: string;
}

const staleMessage = "La respuesta no coincide con el participante solicitado.";
const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    if (error.message === staleMessage || error.message.startsWith("No se encontró")) {
      return error.message;
    }
  }
  const code = isRecord(error) && typeof error.errorCode === "string"
    ? error.errorCode
    : "";
  return code === "forbidden"
    ? "No tienes permisos para consultar este participante."
    : "No se pudo cargar el participante. Intenta nuevamente.";
}

export function ParticipantDetailPanel({
  client = generatedParticipantClient,
  groupId,
  participantId,
}: ParticipantDetailPanelProps) {
  const session = useSession();
  const detailQuery = useQuery({
    queryKey: ["group", groupId, "participant", participantId] as const,
    queryFn: async () => {
      const participants = await client.listParticipants(groupId);
      const participant = participants.find((item) => item.id === participantId);
      if (!participant) throw new Error("No se encontró el participante solicitado.");
      if (participant.groupId !== groupId) throw new Error(staleMessage);
      return participant;
    },
    enabled: session.isAuthenticated && Boolean(groupId) && Boolean(participantId),
  });
  const refresh = () => void detailQuery.refetch();

  if (detailQuery.isPending) return <LoadingCard>Cargando participante…</LoadingCard>;
  if (detailQuery.isError || !detailQuery.data) {
    return (
      <ErrorCard>
        <span>{errorMessage(detailQuery.error)}</span>{" "}
        <Button
          type="button"
          variant="secondary"
          onClick={refresh}
          disabled={detailQuery.isFetching}
          aria-busy={detailQuery.isFetching}
        >
          {detailQuery.isFetching ? "Actualizando…" : "Actualizar participante"}
        </Button>
      </ErrorCard>
    );
  }

  const participant: ParticipantResponse = detailQuery.data;
  return (
    <Panel className="participant-detail-card" labelledBy="participant-detail-title">
      <PanelHeading
        eyebrow="Detalle del participante"
        title={participant.name}
        titleId="participant-detail-title"
        action={<StatusBadge tone={participant.archived ? "warning" : "success"}>{participant.archived ? "Archivado" : "Activo"}</StatusBadge>}
      />
      {participant.archived ? (
        <aside className="feature-state-card" role="note">
          Este participante está archivado. Su historial se conserva.
        </aside>
      ) : (
        <p>Participante activo en este grupo.</p>
      )}
    </Panel>
  );
}
