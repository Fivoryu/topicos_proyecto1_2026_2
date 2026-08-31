import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for ParticipantsApi
void main() {
  final instance = Openapi().getParticipantsApi();

  group(ParticipantsApi, () {
    // Add Participant
    //
    // Add a normalized, group-scoped participant.
    //
    //Future<ParticipantResponse> addParticipantApiV1GroupsGroupIdParticipantsPost(String groupId, String xCSRFToken, ParticipantWriteRequest participantWriteRequest) async
    test('test addParticipantApiV1GroupsGroupIdParticipantsPost', () async {
      // TODO
    });

    // Archive Participant
    //
    // Archive a participant without deleting historical references.
    //
    //Future<ParticipantResponse> archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost(String groupId, String participantId, String xCSRFToken) async
    test('test archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost', () async {
      // TODO
    });

    // Delete Participant
    //
    // Physically delete only a never-referenced participant.
    //
    //Future deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete(String groupId, String participantId, String xCSRFToken) async
    test('test deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete', () async {
      // TODO
    });

    // List Participants
    //
    // List active and archived participants in stable creation order.
    //
    //Future<List<ParticipantResponse>> listParticipantsApiV1GroupsGroupIdParticipantsGet(String groupId) async
    test('test listParticipantsApiV1GroupsGroupIdParticipantsGet', () async {
      // TODO
    });

    // Reactivate Participant
    //
    // Reactivate an archived participant.
    //
    //Future<ParticipantResponse> reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost(String groupId, String participantId, String xCSRFToken) async
    test('test reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost', () async {
      // TODO
    });

    // Rename Participant
    //
    // Rename only the participant display identity.
    //
    //Future<ParticipantResponse> renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch(String groupId, String participantId, String xCSRFToken, RenameParticipantRequest renameParticipantRequest) async
    test('test renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch', () async {
      // TODO
    });

  });
}
