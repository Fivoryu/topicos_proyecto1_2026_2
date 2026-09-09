import type { QueryClient, QueryKey } from "@tanstack/react-query";

export const workspaceQueryKeys = {
  account: {
    groups: (accountId: string) => ["account", accountId, "groups"] as const,
  },
  selection: (accountId: string) => ["selection", accountId, "group"] as const,
  group: {
    root: (groupId: string) => ["group", groupId] as const,
    summary: (groupId: string) => ["group", groupId, "summary"] as const,
    members: (groupId: string) => ["group", groupId, "members"] as const,
    outings: (groupId: string) => ["group", groupId, "outings"] as const,
    expenses: (groupId: string, scope = "all") =>
      ["group", groupId, "expenses", scope] as const,
    balances: (groupId: string, outingId?: string | null) =>
      ["group", groupId, "balances", outingId ?? "group"] as const,
    settlement: (groupId: string, outingId?: string | null) =>
      ["group", groupId, "settlement", outingId ?? "group"] as const,
  },
} as const;

export const accountGroupsQueryKey = workspaceQueryKeys.account.groups;
export const selectionQueryKey = workspaceQueryKeys.selection;
export const groupSummaryQueryKey = workspaceQueryKeys.group.summary;

export function clearWorkspaceGroup(
  queryClient: QueryClient,
  groupId: string,
): void {
  queryClient.removeQueries({
    queryKey: workspaceQueryKeys.group.root(groupId),
  });
}

export function clearWorkspaceCache(queryClient: QueryClient): void {
  queryClient.clear();
}

export function selectWorkspaceGroup(
  queryClient: QueryClient,
  accountId: string,
  previousGroupId: string | undefined,
  nextGroupId: string,
): void {
  if (previousGroupId && previousGroupId !== nextGroupId) {
    clearWorkspaceGroup(queryClient, previousGroupId);
  }
  queryClient.setQueryData(
    workspaceQueryKeys.selection(accountId),
    nextGroupId,
  );
}

export function isWorkspaceQueryKey(key: QueryKey): boolean {
  return key[0] === "account" || key[0] === "group" || key[0] === "selection";
}
