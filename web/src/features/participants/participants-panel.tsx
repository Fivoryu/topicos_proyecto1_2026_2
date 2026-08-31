import {
  useEffect,
  useRef,
  useState,
  type ChangeEvent,
  type FormEvent,
} from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { groupQueryKey, groupQueryKeys } from "../../core/query-client";
import type { ParticipantResponse } from "../../generated/api";
import { formatFeatureError, readFeatureError } from "../api-error";
import {
  generatedParticipantClient,
  type ParticipantFeatureClient,
} from "./api";

export interface ParticipantsPanelProps {
  client?: ParticipantFeatureClient;
  groupId?: string;
}
type LifecycleAction = "archive" | "reactivate";
type MutationAction =
  | { kind: "add"; name: string }
  | { kind: "lifecycle"; id: string; action: LifecycleAction }
  | { kind: "delete"; id: string }
  | { kind: "rename"; id: string; name: string };
type ErrorState = Record<string, string>;
const groupIdFor = (configured: string | undefined, server: unknown) =>
  configured ?? (typeof server === "string" ? server : "");
const actionKey = (action: MutationAction) =>
  action.kind === "add"
    ? "add"
    : `${action.kind === "lifecycle" ? action.action : action.kind}:${action.id}`;
const focus = (input: HTMLInputElement | null) => input?.focus();

export function ParticipantsPanel({
  client = generatedParticipantClient,
  groupId: configuredGroupId,
}: ParticipantsPanelProps) {
  const session = useSession();
  const queryClient = useQueryClient();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const [addName, setAddName] = useState("");
  const [renameNames, setRenameNames] = useState<Record<string, string>>({});
  const [errors, setErrors] = useState<ErrorState>({});
  const [focusErrorKey, setFocusErrorKey] = useState<string | null>(null);
  const addInputRef = useRef<HTMLInputElement>(null);
  const renameInputRefs = useRef<Record<string, HTMLInputElement | null>>({});
  useEffect(() => {
    if (!focusErrorKey) return;
    if (focusErrorKey === "add") focus(addInputRef.current);
    else if (focusErrorKey.startsWith("rename:"))
      focus(renameInputRefs.current[focusErrorKey.slice(7)]);
    setFocusErrorKey(null);
  }, [focusErrorKey]);
  const participantsQuery = useQuery({
    queryKey: groupQueryKey("participants", groupId),
    queryFn: () => client.listParticipants(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  const invalidate = async () =>
    Promise.all(
      Object.values(groupQueryKeys(groupId)).map((queryKey) =>
        queryClient.invalidateQueries({ queryKey }),
      ),
    );
  const mutation = useMutation<
    ParticipantResponse | void,
    unknown,
    MutationAction
  >({
    mutationFn: (action: MutationAction) => {
      if (action.kind === "add")
        return client.addParticipant(groupId, action.name);
      if (action.kind === "delete")
        return client.deleteParticipant(groupId, action.id);
      if (action.kind === "rename")
        return client.renameParticipant(groupId, action.id, action.name);
      return action.action === "archive"
        ? client.archiveParticipant(groupId, action.id)
        : client.reactivateParticipant(groupId, action.id);
    },
    onSuccess: async (_result, action) => {
      if (action.kind === "add") setAddName("");
      if (action.kind === "rename")
        setRenameNames((current) => {
          const next = { ...current };
          delete next[action.id];
          return next;
        });
      setErrors((current) => {
        const next = { ...current };
        delete next[actionKey(action)];
        return next;
      });
      await invalidate();
    },
    onError: async (error: unknown, action) => {
      const key = actionKey(action);
      const problem = await readFeatureError(error);
      setErrors((current) => ({
        ...current,
        [key]: formatFeatureError(problem),
      }));
      if (action.kind === "add") setFocusErrorKey(key);
      if (action.kind === "rename") setFocusErrorKey(key);
    },
  });
  const setInputError = (key: string, value: string | null) =>
    setErrors((current) => {
      const next = { ...current };
      if (value === null) delete next[key];
      else next[key] = value;
      return next;
    });
  function submitAdd(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!addName.trim()) {
      setInputError(
        "add",
        "invalid_participant_name: Enter a participant name.",
      );
      setFocusErrorKey("add");
      return;
    }
    setInputError("add", null);
    mutation.mutate({ kind: "add", name: addName });
  }
  function submitRename(
    event: FormEvent<HTMLFormElement>,
    participant: ParticipantResponse,
  ) {
    event.preventDefault();
    const name = renameNames[participant.id] ?? participant.name;
    const key = `rename:${participant.id}`;
    if (!name.trim()) {
      setInputError(key, "invalid_participant_name: Enter a participant name.");
      setFocusErrorKey(key);
      return;
    }
    setInputError(key, null);
    mutation.mutate({ kind: "rename", id: participant.id, name });
  }
  function changeRename(
    participant: ParticipantResponse,
    event: ChangeEvent<HTMLInputElement>,
  ) {
    setRenameNames((current) => ({
      ...current,
      [participant.id]: event.target.value,
    }));
    setInputError(`rename:${participant.id}`, null);
  }
  if (participantsQuery.isPending)
    return <section className="feature-card">Loading participants…</section>;
  if (participantsQuery.isError || !participantsQuery.data) {
    return (
      <section className="feature-card" role="alert">
        Unable to load participants. Please try again.
      </section>
    );
  }
  return (
    <section className="feature-card" aria-labelledby="participants-title">
      <div className="feature-heading">
        <div>
          <p className="feature-eyebrow">Group people</p>
          <h2 id="participants-title">Participants</h2>
        </div>
        <span>{participantsQuery.data.length} total</span>
      </div>
      <form className="feature-form participant-add-form" onSubmit={submitAdd}>
        <div className="feature-field">
          <label htmlFor="new-participant-name">New participant name</label>
          <input
            ref={addInputRef}
            id="new-participant-name"
            value={addName}
            onChange={(event) => {
              setAddName(event.target.value);
              setInputError("add", null);
            }}
            aria-invalid={Boolean(errors.add)}
            aria-describedby={errors.add ? "new-participant-error" : undefined}
            disabled={mutation.isPending}
          />
        </div>
        <button
          type="submit"
          className="feature-button"
          disabled={mutation.isPending}
          aria-busy={mutation.isPending}
        >
          {mutation.isPending ? "Adding…" : "Add participant"}
        </button>
      </form>
      {errors.add && (
        <p id="new-participant-error" className="feature-error" role="alert">
          {errors.add}
        </p>
      )}
      <ul className="participant-list" aria-label="Participants">
        {participantsQuery.data.map((participant) => {
          const renameKey = `rename:${participant.id}`;
          const lifecycleKey = `${participant.archived ? "reactivate" : "archive"}:${participant.id}`;
          const deleteKey = `delete:${participant.id}`;
          const renameError = errors[renameKey];
          const lifecycleError = errors[lifecycleKey];
          const deleteError = errors[deleteKey];
          const inputId = `rename-participant-${participant.id}`;
          const errorId = `${inputId}-error`;
          return (
            <li
              className="participant-row"
              data-participant-id={participant.id}
              key={participant.id}
            >
              <div className="participant-heading">
                <strong>
                  {participant.name}
                  {participant.archived ? " (archived)" : ""}
                </strong>
                <span>{participant.archived ? "Archived" : "Active"}</span>
              </div>
              <form
                className="feature-form participant-rename-form"
                onSubmit={(event) => submitRename(event, participant)}
              >
                <div className="feature-field">
                  <label htmlFor={inputId}>Rename {participant.name}</label>
                  <input
                    ref={(input) => {
                      renameInputRefs.current[participant.id] = input;
                    }}
                    id={inputId}
                    value={renameNames[participant.id] ?? participant.name}
                    onChange={(event) => changeRename(participant, event)}
                    aria-invalid={Boolean(renameError)}
                    aria-describedby={`${inputId}-helper${renameError ? ` ${errorId}` : ""}`}
                    disabled={mutation.isPending}
                  />
                  <span id={`${inputId}-helper`} className="feature-help">
                    identity and balances remain stable
                  </span>
                </div>
                <button
                  type="submit"
                  className="feature-button feature-button-secondary"
                  disabled={mutation.isPending}
                  aria-busy={mutation.isPending}
                >
                  {mutation.isPending
                    ? "Working…"
                    : `Rename ${participant.name}`}
                </button>
              </form>
              {renameError && (
                <p id={errorId} className="feature-error" role="alert">
                  {renameError}
                </p>
              )}
              <div className="participant-actions">
                <button
                  type="button"
                  className="feature-button feature-button-secondary"
                  onClick={() =>
                    mutation.mutate({
                      kind: "lifecycle",
                      id: participant.id,
                      action: participant.archived ? "reactivate" : "archive",
                    })
                  }
                  disabled={mutation.isPending}
                >
                  {participant.archived ? "Reactivate" : "Archive"}{" "}
                  {participant.name}
                </button>
                <button
                  type="button"
                  className="feature-button feature-button-danger"
                  onClick={() =>
                    mutation.mutate({ kind: "delete", id: participant.id })
                  }
                  disabled={mutation.isPending}
                >
                  Delete {participant.name}
                </button>
              </div>
              {(lifecycleError || deleteError) && (
                <p className="feature-error" role="alert" aria-live="polite">
                  {lifecycleError ?? deleteError}
                  {deleteError?.startsWith("participant_in_use") &&
                    " Archive this participant instead to preserve history."}
                </p>
              )}
            </li>
          );
        })}
      </ul>
    </section>
  );
}
export { ParticipantsPanel as ParticipantsFeature };
