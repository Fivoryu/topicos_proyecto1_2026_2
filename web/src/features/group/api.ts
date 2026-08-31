import {
  GroupsApi,
  type GroupResponse,
  type GroupResponseSettlementPolicyEnum,
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

const groupsApi = new GroupsApi(apiConfiguration);

export const generatedGroupClient: GroupFeatureClient = {
  getGroup: (groupId) => groupsApi.getGroupApiV1GroupsGroupIdGet({ groupId }),
  updatePolicy: (groupId, policy) =>
    groupsApi.updateGroupApiV1GroupsGroupIdPatch({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
      groupUpdateRequest: { settlementPolicy: policy },
    }),
};
