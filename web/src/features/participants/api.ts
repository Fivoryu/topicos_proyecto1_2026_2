import { ParticipantsApi, type ParticipantResponse } from "../../generated/api";
import { getCsrfToken } from "../../core/http-client";
import { apiConfiguration } from "../../app/api-client";

export interface ParticipantFeatureClient {
  listParticipants: (groupId: string) => Promise<ParticipantResponse[]>;
  addParticipant: (
    groupId: string,
    name: string,
  ) => Promise<ParticipantResponse>;
  archiveParticipant: (
    groupId: string,
    participantId: string,
  ) => Promise<ParticipantResponse>;
  reactivateParticipant: (
    groupId: string,
    participantId: string,
  ) => Promise<ParticipantResponse>;
  deleteParticipant: (groupId: string, participantId: string) => Promise<void>;
  renameParticipant: (
    groupId: string,
    participantId: string,
    name: string,
  ) => Promise<ParticipantResponse>;
}

const participantsApi = new ParticipantsApi(apiConfiguration);

export const generatedParticipantClient: ParticipantFeatureClient = {
  listParticipants: (groupId) =>
    participantsApi.listParticipantsApiV1GroupsGroupIdParticipantsGet({
      groupId,
    }),
  addParticipant: (groupId, name) =>
    participantsApi.addParticipantApiV1GroupsGroupIdParticipantsPost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
      participantWriteRequest: { name },
    }),
  archiveParticipant: (groupId, participantId) =>
    participantsApi.archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost(
      {
        groupId,
        participantId,
        xCSRFToken: getCsrfToken() ?? "",
      },
    ),
  reactivateParticipant: (groupId, participantId) =>
    participantsApi.reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost(
      {
        groupId,
        participantId,
        xCSRFToken: getCsrfToken() ?? "",
      },
    ),
  deleteParticipant: (groupId, participantId) =>
    participantsApi.deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete(
      {
        groupId,
        participantId,
        xCSRFToken: getCsrfToken() ?? "",
      },
    ),
  renameParticipant: (groupId, participantId, name) =>
    participantsApi.renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch(
      {
        groupId,
        participantId,
        xCSRFToken: getCsrfToken() ?? "",
        renameParticipantRequest: { name },
      },
    ),
};
