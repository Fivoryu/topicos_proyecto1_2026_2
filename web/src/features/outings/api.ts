import {
  OutingsApi,
  type OutingResponse,
  type OutingWriteRequest,
} from "../../generated/api";
import { getCsrfToken } from "../../core/http-client";
import { apiConfiguration } from "../../app/api-client";

export interface OutingFeatureClient {
  listOutings: (groupId: string) => Promise<OutingResponse[]>;
  getOuting: (groupId: string, outingId: string) => Promise<OutingResponse>;
  createOuting: (
    groupId: string,
    request: OutingWriteRequest,
  ) => Promise<OutingResponse>;
  editOuting: (
    groupId: string,
    outingId: string,
    request: OutingWriteRequest,
  ) => Promise<OutingResponse>;
  archiveOuting: (groupId: string, outingId: string) => Promise<OutingResponse>;
  unarchiveOuting: (groupId: string, outingId: string) => Promise<OutingResponse>;
  deleteOuting: (groupId: string, outingId: string) => Promise<void>;
}

const outingsApi = new OutingsApi(apiConfiguration);

export const generatedOutingClient: OutingFeatureClient = {
  listOutings: (groupId) =>
    outingsApi.listOutingsApiV1GroupsGroupIdOutingsGet({ groupId }),
  getOuting: (groupId, outingId) =>
    outingsApi.getOutingApiV1GroupsGroupIdOutingsOutingIdGet({
      groupId,
      outingId,
    }),
  createOuting: (groupId, request) =>
    outingsApi.createOutingApiV1GroupsGroupIdOutingsPost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
      outingWriteRequest: request,
    }),
  editOuting: (groupId, outingId, request) =>
    outingsApi.editOutingApiV1GroupsGroupIdOutingsOutingIdPatch({
      groupId,
      outingId,
      xCSRFToken: getCsrfToken() ?? "",
      outingWriteRequest: request,
    }),
  archiveOuting: (groupId, outingId) =>
    outingsApi.archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost({
      groupId,
      outingId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  unarchiveOuting: (groupId, outingId) =>
    outingsApi.unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost({
      groupId,
      outingId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
  deleteOuting: (groupId, outingId) =>
    outingsApi.deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete({
      groupId,
      outingId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
};

export const generatedOutingsClient = generatedOutingClient;
