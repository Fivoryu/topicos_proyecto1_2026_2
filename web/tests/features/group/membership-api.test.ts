import { JoinApi, MembershipsApi } from "../../../src/generated/api";
import { afterEach, describe, expect, it, vi } from "vitest";

import { generatedGroupClient } from "../../../src/features/group/api";

function csrfCookie(): void {
  document.cookie = "cc_csrf=test-csrf";
}

afterEach(() => {
  vi.restoreAllMocks();
  document.cookie = "cc_csrf=; Max-Age=0";
});

describe("group membership adapters", () => {
  it("maps member and join-code reads to generated request arguments without CSRF", async () => {
    const listMembers = vi
      .spyOn(MembershipsApi.prototype, "listMembersApiV1GroupsGroupIdMembersGet")
      .mockResolvedValue([]);
    const status = vi
      .spyOn(JoinApi.prototype, "getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet")
      .mockResolvedValue({} as never);

    await generatedGroupClient.listMembers("group-1");
    await generatedGroupClient.getJoinCodeStatus("group-1");

    expect(listMembers).toHaveBeenCalledWith({ groupId: "group-1" });
    expect(status).toHaveBeenCalledWith({ groupId: "group-1" });
  });

  it("maps join-code and membership mutations with the current CSRF cookie", async () => {
    csrfCookie();
    const generate = vi
      .spyOn(JoinApi.prototype, "generateJoinCodeApiV1GroupsGroupIdJoinCodePost")
      .mockResolvedValue({} as never);
    const regenerate = vi
      .spyOn(JoinApi.prototype, "regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost")
      .mockResolvedValue({} as never);
    const revoke = vi
      .spyOn(JoinApi.prototype, "revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete")
      .mockResolvedValue({} as never);
    const consume = vi
      .spyOn(JoinApi.prototype, "consumeJoinCodeApiV1GroupsJoinPost")
      .mockResolvedValue({} as never);
    const remove = vi
      .spyOn(MembershipsApi.prototype, "removeMemberApiV1GroupsGroupIdMembersAccountIdDelete")
      .mockResolvedValue(undefined);
    const leave = vi
      .spyOn(MembershipsApi.prototype, "leaveGroupApiV1GroupsGroupIdLeavePost")
      .mockResolvedValue(undefined);

    await generatedGroupClient.generateJoinCode("group-1");
    await generatedGroupClient.regenerateJoinCode("group-1");
    await generatedGroupClient.revokeJoinCode("group-1");
    await generatedGroupClient.consumeJoinCode({
      code: "JOIN-123",
      participantId: "participant-1",
    });
    await generatedGroupClient.removeMember("group-1", "account-2");
    await generatedGroupClient.leaveGroup("group-1");

    expect(generate).toHaveBeenCalledWith({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
    });
    expect(regenerate).toHaveBeenCalledWith({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
    });
    expect(revoke).toHaveBeenCalledWith({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
    });
    expect(consume).toHaveBeenCalledWith({
      xCSRFToken: "test-csrf",
      joinCodeConsumeRequest: {
        code: "JOIN-123",
        participantId: "participant-1",
      },
    });
    expect(remove).toHaveBeenCalledWith({
      groupId: "group-1",
      accountId: "account-2",
      xCSRFToken: "test-csrf",
    });
    expect(leave).toHaveBeenCalledWith({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
    });
  });
});
