import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "./auth/session-provider";
import {
  parseWorkspaceHash,
  serializeWorkspaceRoute,
  type WorkspaceRoute,
  LEGACY_WORKSPACE_ANCHORS,
} from "../core/workspace-navigation";
import {
  clearWorkspaceGroup,
  selectWorkspaceGroup,
  workspaceQueryKeys,
} from "../core/workspace-query-keys";
import type { GroupSummaryResponse } from "../generated/api";
import { formatFeatureError, readFeatureError } from "../features/api-error";
import {
  generatedWorkspaceClient,
  type WorkspaceClient,
} from "../features/workspace/api";

export interface WorkspaceShellProps {
  client?: WorkspaceClient;
  realtimeStatus?: "connected" | "offline";
}

function routeGroupId(route: WorkspaceRoute): string | undefined {
  return "groupId" in route ? route.groupId : undefined;
}

function writeHash(route: WorkspaceRoute): void {
  if (typeof window !== "undefined")
    window.location.hash = serializeWorkspaceRoute(route);
}

export function WorkspaceShell({
  client = generatedWorkspaceClient,
  realtimeStatus = "offline",
}: WorkspaceShellProps) {
  const session = useSession();
  const queryClient = useQueryClient();
  const [hash, setHash] = useState(() =>
    typeof window === "undefined" ? "" : window.location.hash,
  );
  const [groupName, setGroupName] = useState("");
  const [createError, setCreateError] = useState<string | null>(null);
  const previousGroup = useRef<string | undefined>(undefined);
  const accountId = session.session?.account.id ?? "";
  const groupsKey = workspaceQueryKeys.account.groups(accountId);
  const groupsQuery = useQuery({
    queryKey: groupsKey,
    queryFn: client.listGroups,
    enabled: session.isAuthenticated && Boolean(accountId),
    subscribed: session.isAuthenticated,
  });
  const groups = groupsQuery.data ?? [];
  const route = useMemo(() => parseWorkspaceHash(hash), [hash]);
  const requestedGroupId = routeGroupId(route);
  const requestedGroup = requestedGroupId
    ? groups.find(({ id }) => id === requestedGroupId)
    : undefined;
  const selectedGroup =
    requestedGroup ??
    (!requestedGroupId && groups.length === 1 ? groups[0] : undefined);
  const selectedGroupId = selectedGroup?.id;
  const staleSelection = Boolean(requestedGroupId && !requestedGroup);

  useEffect(() => {
    const update = () => setHash(window.location.hash);
    window.addEventListener("hashchange", update);
    return () => window.removeEventListener("hashchange", update);
  }, []);
  useEffect(() => {
    if (!session.isAuthenticated) {
      queryClient.clear();
      const cleanup = globalThis.setTimeout(() => queryClient.clear(), 0);
      return () => globalThis.clearTimeout(cleanup);
    }
    return undefined;
  }, [queryClient, session.isAuthenticated]);
  useEffect(() => {
    if (previousGroup.current === selectedGroupId) return;
    if (previousGroup.current)
      clearWorkspaceGroup(queryClient, previousGroup.current);
    if (selectedGroupId) {
      queryClient.setQueryData(
        workspaceQueryKeys.selection(accountId),
        selectedGroupId,
      );
    }
    previousGroup.current = selectedGroupId;
  }, [accountId, queryClient, selectedGroupId]);
  useEffect(() => {
    if (
      groupsQuery.isSuccess &&
      groups.length === 1 &&
      !requestedGroupId &&
      route.kind !== "legacy"
    ) {
      writeHash({ kind: "summary", groupId: groups[0].id });
    }
  }, [groups, groupsQuery.isSuccess, requestedGroupId, route.kind]);

  const summaryQuery = useQuery({
    queryKey: workspaceQueryKeys.group.summary(selectedGroupId ?? "none"),
    queryFn: async () => selectedGroup as GroupSummaryResponse,
    enabled: Boolean(selectedGroupId && selectedGroup),
    subscribed: session.isAuthenticated,
  });
  const createMutation = useMutation({
    mutationFn: (name: string) => client.createGroup(name.trim()),
    onSuccess: async (created) => {
      setCreateError(null);
      await queryClient.invalidateQueries({ queryKey: groupsKey });
      queryClient.setQueryData<GroupSummaryResponse[]>(
        groupsKey,
        (current = []) =>
          current.some(({ id }) => id === created.id)
            ? current
            : [...current, created],
      );
      selectWorkspaceGroup(queryClient, accountId, selectedGroupId, created.id);
      writeHash({ kind: "summary", groupId: created.id });
      setGroupName("");
    },
    onError: async (error: unknown) =>
      setCreateError(formatFeatureError(await readFeatureError(error))),
  });

  if (!session.isAuthenticated) return null;
  if (groupsQuery.isPending)
    return (
      <ShellFrame>
        <p role="status">Cargando tus grupos…</p>
      </ShellFrame>
    );
  if (groupsQuery.isError) {
    return (
      <ShellFrame>
        <p role="alert">
          No se pudieron cargar tus grupos. Intenta nuevamente.
        </p>
        <button
          type="button"
          onClick={() => void groupsQuery.refetch()}
          style={{ minHeight: 44 }}
        >
          Actualizar
        </button>
      </ShellFrame>
    );
  }

  const refresh = () => {
    void queryClient.invalidateQueries({ queryKey: groupsKey });
    if (selectedGroupId)
      void queryClient.invalidateQueries({
        queryKey: workspaceQueryKeys.group.root(selectedGroupId),
      });
  };
  const select = (id: string) => {
    selectWorkspaceGroup(queryClient, accountId, selectedGroupId, id);
    writeHash({ kind: "summary", groupId: id });
  };
  const submitCreate = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!groupName.trim() || createMutation.isPending) return;
    createMutation.mutate(groupName);
  };

  return (
    <ShellFrame>
      <header>
        <p>Sesión segura: {session.session?.account.loginName}</p>
        <h1>Tus grupos</h1>
        <button
          type="button"
          onClick={() => void session.logout()}
          style={{ minHeight: 44 }}
        >
          Cerrar sesión
        </button>
        <button type="button" onClick={refresh} style={{ minHeight: 44 }}>
          Actualizar
        </button>
        {realtimeStatus === "offline" && (
          <p role="status">
            La conexión en tiempo real no está disponible; actualización manual
            disponible.
          </p>
        )}
      </header>
      <nav aria-label="Secciones del grupo">
        {LEGACY_WORKSPACE_ANCHORS.map((anchor) => (
          <a
            key={anchor}
            href={`#${anchor}`}
            style={{
              minHeight: 44,
              display: "inline-flex",
              alignItems: "center",
            }}
          >
            {anchor}
          </a>
        ))}
      </nav>
      {groups.length === 0 ? (
        <EmptyGroupsForm
          name={groupName}
          error={createError}
          pending={createMutation.isPending}
          onNameChange={setGroupName}
          onSubmit={submitCreate}
        />
      ) : staleSelection ? (
        <section aria-labelledby="workspace-selection-error">
          <p id="workspace-selection-error" role="alert">
            No tienes acceso a ese grupo. Elige un grupo activo.
          </p>
          <GroupPicker groups={groups} onSelect={select} />
        </section>
      ) : selectedGroup ? (
        <>
          {groups.length > 1 && (
            <GroupPicker groups={groups} onSelect={select} />
          )}
          <WorkspaceSummary group={summaryQuery.data ?? selectedGroup} />
        </>
      ) : (
        <section aria-labelledby="workspace-picker-title">
          <h2 id="workspace-picker-title">Elige un grupo</h2>
          <p>Selecciona el espacio que quieres consultar.</p>
          <GroupPicker groups={groups} onSelect={select} />
        </section>
      )}
      {LEGACY_WORKSPACE_ANCHORS.map((anchor) => (
        <div id={anchor} key={`${anchor}-anchor`} tabIndex={-1} />
      ))}
    </ShellFrame>
  );
}

function ShellFrame({ children }: { children: React.ReactNode }) {
  return (
    <main data-testid="workspace-shell" tabIndex={-1}>
      {children}
    </main>
  );
}
function GroupPicker({
  groups,
  onSelect,
}: {
  groups: GroupSummaryResponse[];
  onSelect: (id: string) => void;
}) {
  return (
    <ul aria-label="Grupos disponibles">
      {groups.map((group) => (
        <li key={group.id}>
          <button
            type="button"
            onClick={() => onSelect(group.id)}
            style={{ minHeight: 44 }}
          >
            {group.name}
          </button>
        </li>
      ))}
    </ul>
  );
}
function EmptyGroupsForm({
  name,
  error,
  pending,
  onNameChange,
  onSubmit,
}: {
  name: string;
  error: string | null;
  pending: boolean;
  onNameChange: (value: string) => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
}) {
  return (
    <section aria-labelledby="empty-groups-title">
      <h2 id="empty-groups-title">Aún no perteneces a ningún grupo</h2>
      <p>Crea un grupo para empezar a organizar tus gastos.</p>
      <form onSubmit={onSubmit}>
        <label htmlFor="workspace-group-name">Nombre del grupo</label>
        <input
          id="workspace-group-name"
          value={name}
          onChange={(event) => onNameChange(event.target.value)}
          required
        />
        <button type="submit" disabled={pending} style={{ minHeight: 44 }}>
          {pending ? "Creando…" : "Crear grupo"}
        </button>
      </form>
      {error && <p role="alert">{error}</p>}
    </section>
  );
}
function WorkspaceSummary({ group }: { group: GroupSummaryResponse }) {
  const empty =
    (group.outingsCount ?? 0) === 0 && (group.expensesCount ?? 0) === 0;
  return (
    <section aria-labelledby="selected-workspace-title">
      <p>Grupo activo · {group.role === "owner" ? "Propietario" : "Miembro"}</p>
      <h2 id="selected-workspace-title">{group.name}</h2>
      {empty && <p>Grupo vacío: todavía no hay gastos ni salidas.</p>}
      <dl>
        <div>
          <dt>Participantes</dt>
          <dd>{group.participantsCount ?? 0}</dd>
        </div>
        <div>
          <dt>Salidas</dt>
          <dd>{group.outingsCount ?? 0}</dd>
        </div>
        <div>
          <dt>Gastos</dt>
          <dd>{group.expensesCount ?? 0}</dd>
        </div>
      </dl>
    </section>
  );
}
