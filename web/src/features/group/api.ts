import {
  GroupsApi,
  JoinApi,
  MembershipsApi,
  type GroupResponse,
  type GroupResponseSettlementPolicyEnum,
  type JoinCodeConsumeRequest,
  type JoinCodeResponse,
  type JoinCodeStatus,
  type JoinResponse,
  type MemberResponse,
} from "../../generated/api";
import { getCsrfToken } from "../../core/http-client";
import { apiConfiguration } from "../../app/api-client";

export interface GroupFeatureClient {
  getGroup: (groupId: string) => Promise<GroupResponse>;
  updatePolicy: (
    groupId: string,
    policy: GroupResponseSettlementPolicyEnum,
  ) => Promise<GroupResponse>;
}

export interface GroupMembershipClient {
  listMembers: (groupId: string) => Promise<MemberResponse[]>;
  getJoinCodeStatus: (groupId: string) => Promise<JoinCodeStatus>;
  generateJoinCode: (groupId: string) => Promise<JoinCodeResponse>;
  regenerateJoinCode: (groupId: string) => Promise<JoinCodeResponse>;
  revokeJoinCode: (groupId: string) => Promise<JoinCodeStatus>;
  consumeJoinCode: (request: JoinCodeConsumeRequest) => Promise<JoinResponse>;
  removeMember: (groupId: string, accountId: string) => Promise<void>;
  leaveGroup: (groupId: string) => Promise<void>;
}

const groupsApi = new GroupsApi(apiConfiguration);
const joinApi = new JoinApi(apiConfiguration);
const membershipsApi = new MembershipsApi(apiConfiguration);

export const generatedGroupClient: GroupFeatureClient & GroupMembershipClient = {
  getGroup: (groupId) => groupsApi.getGroupApiV1GroupsGroupIdGet({ groupId }),
  updatePolicy: (groupId, policy) =>
    groupsApi.updateGroupApiV1GroupsGroupIdPatch({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
      groupUpdateRequest: { settlementPolicy: policy },
    }),
  listMembers: (groupId) =>
    membershipsApi.listMembersApiV1GroupsGroupIdMembersGet({ groupId }),
  getJoinCodeStatus: (groupId) =>
    joinApi.getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet({ groupId }),
  generateJoinCode: (groupId) =>
    joinApi.generateJoinCodeApiV1GroupsGroupIdJoinCodePost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  regenerateJoinCode: (groupId) =>
    joinApi.regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  revokeJoinCode: (groupId) =>
    joinApi.revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  consumeJoinCode: (request) =>
    joinApi.consumeJoinCodeApiV1GroupsJoinPost({
      xCSRFToken: getCsrfToken() ?? "",
      joinCodeConsumeRequest: request,
    }),
  removeMember: (groupId, accountId) =>
    membershipsApi.removeMemberApiV1GroupsGroupIdMembersAccountIdDelete({
      groupId,
      accountId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  leaveGroup: (groupId) =>
    membershipsApi.leaveGroupApiV1GroupsGroupIdLeavePost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
};
