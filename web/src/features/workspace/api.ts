import { GroupsApi, type GroupSummaryResponse } from "../../generated/api";
import { apiConfiguration } from "../../app/api-client";

export interface WorkspaceClient {
  listGroups: () => Promise<GroupSummaryResponse[]>;
  createGroup: (name: string) => Promise<GroupSummaryResponse>;
}

const groupsApi = new GroupsApi(apiConfiguration);

export const generatedWorkspaceClient: WorkspaceClient = {
  listGroups: () => groupsApi.listGroupsApiV1GroupsGet(),
  createGroup: (name) =>
    groupsApi.createGroupApiV1GroupsPost({ groupCreateRequest: { name } }),
};
