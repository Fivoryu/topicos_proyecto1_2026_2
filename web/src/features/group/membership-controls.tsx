import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Button, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { groupMembershipQueryKeys } from "../../core/query-client";
import { formatFeatureError, readFeatureError } from "../api-error";
import type { GroupMembershipClient } from "./api";

type MembershipControlsProps = {
  client: GroupMembershipClient;
  groupId: string;
  role: "owner" | "member";
};

export function MembershipControls({ client, groupId, role }: MembershipControlsProps) {
  const queryClient = useQueryClient();
  const [revealedCode, setRevealedCode] = useState<string | null>(null);
  const [mutationError, setMutationError] = useState<string | null>(null);
  const membersQuery = useQuery({
    queryKey: groupMembershipQueryKeys(groupId).members,
    queryFn: () => client.listMembers(groupId),
    enabled: Boolean(groupId),
  });
  const statusQuery = useQuery({
    queryKey: groupMembershipQueryKeys(groupId)["join-code-status"],
    queryFn: () => client.getJoinCodeStatus(groupId),
    enabled: Boolean(groupId) && role === "owner",
  });
  const invalidate = (resource: "members" | "join-code-status") =>
    queryClient.invalidateQueries({ queryKey: groupMembershipQueryKeys(groupId)[resource] });
  const handleError = async (error: unknown) =>
    setMutationError(formatFeatureError(await readFeatureError(error)));
  const codeMutation = useMutation({
    mutationFn: async (action: "generate" | "regenerate" | "revoke") => {
      if (action === "generate") return client.generateJoinCode(groupId);
      if (action === "regenerate") return client.regenerateJoinCode(groupId);
      await client.revokeJoinCode(groupId);
      return null;
    },
    onSuccess: async (result) => {
      setMutationError(null);
      setRevealedCode(result?.code ?? null);
      await invalidate("join-code-status");
    },
    onError: (error) => void handleError(error),
  });
  const memberMutation = useMutation({
    mutationFn: (accountId: string | null) =>
      accountId ? client.removeMember(groupId, accountId) : client.leaveGroup(groupId),
    onSuccess: async () => {
      setMutationError(null);
      await invalidate("members");
    },
    onError: (error) => void handleError(error),
  });
  const activeMembers = membersQuery.data?.filter((member) => member.active) ?? [];
  const busy = codeMutation.isPending || memberMutation.isPending;
  const status = statusQuery.data;

  return (
    <Panel className="membership-card management-card" labelledBy="membership-controls-title">
      <PanelHeading eyebrow="Acceso al grupo" title="Miembros y acceso" titleId="membership-controls-title" />
      <section className="membership-section" aria-labelledby="members-title">
        <div className="membership-section-heading"><h3 id="members-title">Miembros activos</h3><span>{activeMembers.length} activos</span></div>
        {membersQuery.isPending && <LoadingCard>Cargando miembros…</LoadingCard>}
        {membersQuery.isError && (
          <div className="feature-state-card feature-state-error" role="alert">
            <span>No se pudieron cargar los miembros.</span>
            <Button variant="secondary" onClick={() => void membersQuery.refetch()}>Reintentar miembros</Button>
          </div>
        )}
        {membersQuery.isSuccess && activeMembers.length === 0 && <p className="feature-empty">Todavía no hay miembros activos.</p>}
        {activeMembers.length > 0 && (
          <ul className="membership-list">
            {activeMembers.map((member) => (
              <li className="membership-row" key={member.accountId}>
                <div>
                  <strong>{member.loginName}</strong>
                  <span className="membership-role">{member.role === "owner" ? "Propietario" : "Miembro"}</span>
                  {member.participantId ? <a href={`#participant-${member.participantId}`} aria-label={`Participante de ${member.loginName}`}>Participante vinculado</a> : <span className="membership-unlinked">Sin participante vinculado</span>}
                </div>
                {role === "owner" && member.role !== "owner" && (
                  <Button variant="danger" disabled={busy} aria-busy={memberMutation.isPending} aria-label={`Quitar a ${member.loginName}`} onClick={() => { setMutationError(null); memberMutation.mutate(member.accountId); }}>Quitar</Button>
                )}
              </li>
            ))}
          </ul>
        )}
        {role === "member" && <Button variant="danger" disabled={busy} aria-busy={memberMutation.isPending} onClick={() => { setMutationError(null); memberMutation.mutate(null); }}>Salir del grupo</Button>}
      </section>
      {role === "owner" && (
        <section className="membership-section" aria-labelledby="join-code-title">
          <div className="membership-section-heading"><h3 id="join-code-title">Código de invitación</h3><StatusBadge tone={status?.active ? "success" : "neutral"}>{status?.active ? "Activo" : "Inactivo"}</StatusBadge></div>
          {statusQuery.isPending && <LoadingCard>Cargando estado del código…</LoadingCard>}
          {statusQuery.isError && (
            <div className="feature-state-card feature-state-error" role="alert">
              <span>No se pudo cargar el estado del código.</span>
              <Button variant="secondary" onClick={() => void statusQuery.refetch()}>Reintentar código</Button>
            </div>
          )}
          {statusQuery.isSuccess && <p className="feature-help">{statusQuery.data.active ? `Código activo, generación ${statusQuery.data.generation ?? "actual"}.` : "No hay un código activo."}</p>}
          {revealedCode && <p className="join-code-reveal" aria-live="polite">Código nuevo: <code>{revealedCode}</code></p>}
          <div className="membership-actions">
            <Button disabled={busy || statusQuery.isPending} aria-busy={codeMutation.isPending} onClick={() => { setMutationError(null); codeMutation.mutate(status?.active ? "regenerate" : "generate"); }}>{status?.active ? "Regenerar código" : "Generar código"}</Button>
            {status?.active && <Button variant="secondary" disabled={busy} onClick={() => { setMutationError(null); codeMutation.mutate("revoke"); }}>Revocar código</Button>}
          </div>
        </section>
      )}
      {mutationError && <p className="feature-error" role="alert" aria-live="polite">{mutationError}</p>}
    </Panel>
  );
}
