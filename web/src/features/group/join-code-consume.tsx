import { useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Button, LoadingCard } from "../../components/ui";
import { groupMembershipQueryKeys, groupQueryKey } from "../../core/query-client";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import { featureErrorMessage, formatFeatureError, readFeatureError } from "../api-error";
import {
  generatedParticipantClient,
  type ParticipantFeatureClient,
} from "../participants/api";
import {
  generatedGroupClient,
  type GroupMembershipClient,
} from "./api";

export interface JoinCodeConsumeProps {
  client?: Pick<GroupMembershipClient, "consumeJoinCode">;
  participantsClient?: Pick<ParticipantFeatureClient, "listParticipants">;
  groupId: string;
  accountId?: string;
}

const joinMessages: Record<string, string> = {
  invalid_join_code: "El código de invitación no es válido.",
  revoked_join_code: "El código de invitación fue revocado.",
  duplicate_membership: "Ya perteneces a este grupo.",
  duplicate_participant_link: "Tu cuenta ya tiene un participante vinculado en este grupo.",
  invalid_participant_link_choice: "Elige un participante activo o escribe un nombre nuevo.",
  duplicate_participant_name: "Ya existe un participante con ese nombre.",
};

export function JoinCodeConsume({
  client = generatedGroupClient,
  participantsClient = generatedParticipantClient,
  groupId,
  accountId,
}: JoinCodeConsumeProps) {
  const queryClient = useQueryClient();
  const [code, setCode] = useState("");
  const [choice, setChoice] = useState("");
  const [newName, setNewName] = useState("");
  const [formError, setFormError] = useState<string | null>(null);
  const [joined, setJoined] = useState(false);
  const participantsQuery = useQuery({
    queryKey: groupQueryKey("participants", groupId),
    queryFn: () => participantsClient.listParticipants(groupId),
    enabled: Boolean(groupId),
  });
  const activeParticipants =
    participantsQuery.data?.filter((participant) => !participant.archived) ?? [];
  const selectedChoice =
    choice === "new" || activeParticipants.some(({ id }) => choice === id)
      ? choice
      : activeParticipants[0]?.id ?? "new";

  const joinMutation = useMutation({
    mutationFn: () => {
      const request = selectedChoice === "new"
        ? { code: code.trim(), newParticipantName: newName.trim() }
        : { code: code.trim(), participantId: selectedChoice };
      return client.consumeJoinCode(request);
    },
    onSuccess: async (result) => {
      setFormError(null);
      setCode("");
      setNewName("");
      setJoined(true);
      await Promise.all([
        accountId && queryClient.invalidateQueries({
          queryKey: workspaceQueryKeys.account.groups(accountId),
        }),
        queryClient.invalidateQueries({ queryKey: workspaceQueryKeys.group.root(result.groupId) }),
        queryClient.invalidateQueries({
          queryKey: groupMembershipQueryKeys(result.groupId).members,
        }),
        queryClient.invalidateQueries({ queryKey: groupQueryKey("participants", result.groupId) }),
      ]);
    },
    onError: async (error: unknown) => {
      const detail = await readFeatureError(error);
      setFormError(
        `${detail.code}: ${joinMessages[detail.code] ?? featureErrorMessage(detail)}`,
      );
    },
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (joinMutation.isPending) return;
    if (!code.trim()) {
      setFormError("Ingresa un código de invitación.");
      return;
    }
    if (selectedChoice === "new" && !newName.trim()) {
      setFormError("Ingresa el nombre del participante nuevo.");
      return;
    }
    if (!selectedChoice) {
      setFormError("Elige exactamente un participante.");
      return;
    }
    setFormError(null);
    joinMutation.mutate();
  };

  if (participantsQuery.isPending) return <LoadingCard>Cargando participantes para unirte…</LoadingCard>;
  if (participantsQuery.isError) {
    return (
      <div className="feature-state-card feature-state-error" role="alert">
        <span>No se pudieron cargar los participantes.</span>
        <Button variant="secondary" onClick={() => void participantsQuery.refetch()}>
          Reintentar participantes
        </Button>
      </div>
    );
  }
  if (joined) {
    return (
      <section className="membership-section" role="status" aria-live="polite" aria-labelledby="join-success-title">
        <h3 id="join-success-title">Te uniste al grupo correctamente</h3>
        <p className="feature-help">La lista de tus grupos se actualizará con la respuesta del servidor.</p>
        <Button variant="secondary" onClick={() => setJoined(false)}>Usar otro código</Button>
      </section>
    );
  }

  return (
    <section className="membership-section" aria-labelledby="join-consume-title">
      <h3 id="join-consume-title">Unirme a un grupo</h3>
      <p className="feature-help">Usá un código recibido y elegí exactamente un participante activo o uno nuevo.</p>
      <form className="feature-form" noValidate onSubmit={submit}>
        <div className="feature-field">
          <label htmlFor="join-code">Código de invitación</label>
          <input
            id="join-code"
            value={code}
            onChange={(event) => { setCode(event.target.value); setFormError(null); }}
            autoComplete="off"
            spellCheck={false}
            required
          />
        </div>
        <fieldset className="feature-field">
          <legend>Participante para este grupo</legend>
          {activeParticipants.map((participant) => (
            <label key={participant.id}>
              <input
                type="radio"
                name="join-participant"
                value={participant.id}
                checked={selectedChoice === participant.id}
                onChange={() => { setChoice(participant.id); setFormError(null); }}
              />
              Usar {participant.name}
            </label>
          ))}
          <label>
            <input
              type="radio"
              name="join-participant"
              value="new"
              checked={selectedChoice === "new"}
              onChange={() => { setChoice("new"); setFormError(null); }}
            />
            Crear un participante nuevo
          </label>
        </fieldset>
        {selectedChoice === "new" && (
          <div className="feature-field">
            <label htmlFor="new-participant-name">Nombre del participante nuevo</label>
            <input
              id="new-participant-name"
              value={newName}
              onChange={(event) => { setNewName(event.target.value); setFormError(null); }}
              required
            />
          </div>
        )}
        <Button type="submit" disabled={joinMutation.isPending} aria-busy={joinMutation.isPending}>
          {joinMutation.isPending ? "Uniéndome…" : "Unirme al grupo"}
        </Button>
      </form>
      {formError && <p className="feature-error" role="alert" aria-live="polite">{formError}</p>}
    </section>
  );
}
