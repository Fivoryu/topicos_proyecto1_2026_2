import { describe, expect, it } from "vitest";

import { workspaceQueryKeys } from "../../src/core/workspace-query-keys";

describe("workspace group query identity", () => {
  it("keeps members and join-code status scoped to the group", () => {
    expect(workspaceQueryKeys.group.members("group-1")).toEqual([
      "group",
      "group-1",
      "members",
    ]);
    expect(workspaceQueryKeys.group.joinCodeStatus("group-1")).toEqual([
      "group",
      "group-1",
      "join-code-status",
    ]);
    expect(workspaceQueryKeys.group.joinCodeStatus("group-1")).not.toEqual(
      workspaceQueryKeys.group.joinCodeStatus("group-2"),
    );
  });
});
