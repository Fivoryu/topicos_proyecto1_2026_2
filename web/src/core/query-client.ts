import { QueryClient } from "@tanstack/react-query";

export const GROUP_QUERY_RESOURCES = [
  "group",
  "participants",
  "expenses",
  "balances",
  "settlement",
] as const;

export type GroupQueryResource = (typeof GROUP_QUERY_RESOURCES)[number];
export type GroupQueryKey = readonly [GroupQueryResource, string];

export function groupQueryKey(
  resource: GroupQueryResource,
  groupId: string,
): GroupQueryKey {
  return [resource, groupId];
}

export function groupQueryKeys(
  groupId: string,
): Record<GroupQueryResource, GroupQueryKey> {
  return GROUP_QUERY_RESOURCES.reduce(
    (keys, resource) => {
      keys[resource] = groupQueryKey(resource, groupId);
      return keys;
    },
    {} as Record<GroupQueryResource, GroupQueryKey>,
  );
}

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});
