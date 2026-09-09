export const LEGACY_WORKSPACE_ANCHORS = [
  "gastos",
  "balances",
  "liquidacion",
  "participantes",
  "grupo",
] as const;
export type LegacyWorkspaceAnchor = (typeof LEGACY_WORKSPACE_ANCHORS)[number];

type GroupRoute = { groupId: string };
export type WorkspaceRoute =
  | { kind: "groups" }
  | ({ kind: "summary" } & GroupRoute)
  | ({ kind: "outings" } & GroupRoute)
  | ({ kind: "outing"; outingId: string } & GroupRoute)
  | ({ kind: "outing-expenses"; outingId: string } & GroupRoute)
  | ({ kind: "expenses" } & GroupRoute)
  | ({ kind: "participant"; participantId: string } & GroupRoute)
  | ({ kind: "balances" } & GroupRoute)
  | ({ kind: "settlement" } & GroupRoute)
  | ({ kind: "settings" } & GroupRoute)
  | { kind: "legacy"; anchor: LegacyWorkspaceAnchor }
  | { kind: "unknown"; hash: string };

function decode(value: string): string | undefined {
  try {
    const decoded = decodeURIComponent(value);
    return decoded && !decoded.includes("/") ? decoded : undefined;
  } catch {
    return undefined;
  }
}

export function parseWorkspaceHash(hash: string): WorkspaceRoute {
  const value = hash.replace(/^#/, "");
  if (LEGACY_WORKSPACE_ANCHORS.includes(value as LegacyWorkspaceAnchor)) {
    return { kind: "legacy", anchor: value as LegacyWorkspaceAnchor };
  }
  if (value === "/groups" || value === "groups" || value === "") {
    return { kind: "groups" };
  }
  const parts = value.replace(/^\//, "").split("/");
  if (parts[0] !== "groups") return { kind: "unknown", hash };
  const groupId = decode(parts[1] ?? "");
  if (!groupId) return { kind: "unknown", hash };
  if (parts.length === 2 || parts[2] === "summary") {
    return parts.length === 2
      ? { kind: "summary", groupId }
      : { kind: "summary", groupId };
  }
  if (parts[2] === "outings" && parts.length === 3)
    return { kind: "outings", groupId };
  if (parts[2] === "outings" && parts[3] && parts.length === 4) {
    const outingId = decode(parts[3]);
    return outingId
      ? { kind: "outing", groupId, outingId }
      : { kind: "unknown", hash };
  }
  if (
    parts[2] === "outings" &&
    parts[3] &&
    parts[4] === "expenses" &&
    parts.length === 5
  ) {
    const outingId = decode(parts[3]);
    return outingId
      ? { kind: "outing-expenses", groupId, outingId }
      : { kind: "unknown", hash };
  }
  const simple = {
    expenses: "expenses",
    participants: "participant",
    balances: "balances",
    settlement: "settlement",
    settings: "settings",
  } as const;
  if (parts.length === 3 && parts[2] in simple && parts[2] !== "participants") {
    return {
      kind: simple[parts[2] as keyof typeof simple],
      groupId,
    } as WorkspaceRoute;
  }
  if (parts[2] === "participants" && parts[3] && parts.length === 4) {
    const participantId = decode(parts[3]);
    return participantId
      ? { kind: "participant", groupId, participantId }
      : { kind: "unknown", hash };
  }
  return { kind: "unknown", hash };
}

export function serializeWorkspaceRoute(route: WorkspaceRoute): string {
  if (route.kind === "legacy") return `#${route.anchor}`;
  if (route.kind === "groups") return "#/groups";
  if (route.kind === "unknown") return route.hash;
  const group = encodeURIComponent(route.groupId);
  if (route.kind === "summary") return `#/groups/${group}/summary`;
  if (route.kind === "outings") return `#/groups/${group}/outings`;
  if (route.kind === "outing")
    return `#/groups/${group}/outings/${encodeURIComponent(route.outingId)}`;
  if (route.kind === "outing-expenses")
    return `#/groups/${group}/outings/${encodeURIComponent(route.outingId)}/expenses`;
  if (route.kind === "expenses") return `#/groups/${group}/expenses`;
  if (route.kind === "participant")
    return `#/groups/${group}/participants/${encodeURIComponent(route.participantId)}`;
  if (route.kind === "balances") return `#/groups/${group}/balances`;
  if (route.kind === "settlement") return `#/groups/${group}/settlement`;
  return `#/groups/${group}/settings`;
}
