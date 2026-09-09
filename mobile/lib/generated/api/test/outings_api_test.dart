import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for OutingsApi
void main() {
  final instance = Openapi().getOutingsApi();

  group(OutingsApi, () {
    // Archive Outing
    //
    // Archive an outing as a server-authorized owner operation.
    //
    //Future<OutingResponse> archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost(String groupId, String outingId, String xCSRFToken) async
    test('test archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost', () async {
      // TODO
    });

    // Create Outing
    //
    // Create an active outing for any active group member.
    //
    //Future<OutingResponse> createOutingApiV1GroupsGroupIdOutingsPost(String groupId, String xCSRFToken, OutingWriteRequest outingWriteRequest) async
    test('test createOutingApiV1GroupsGroupIdOutingsPost', () async {
      // TODO
    });

    // Delete Outing
    //
    // Delete an empty active outing as its server-authorized owner.
    //
    //Future deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete(String groupId, String outingId, String xCSRFToken) async
    test('test deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete', () async {
      // TODO
    });

    // Edit Outing
    //
    // Edit only the name of an active outing.
    //
    //Future<OutingResponse> editOutingApiV1GroupsGroupIdOutingsOutingIdPatch(String groupId, String outingId, String xCSRFToken, OutingWriteRequest outingWriteRequest) async
    test('test editOutingApiV1GroupsGroupIdOutingsOutingIdPatch', () async {
      // TODO
    });

    // Get Outing
    //
    // Read an active or archived outing in the requested group.
    //
    //Future<OutingResponse> getOutingApiV1GroupsGroupIdOutingsOutingIdGet(String groupId, String outingId) async
    test('test getOutingApiV1GroupsGroupIdOutingsOutingIdGet', () async {
      // TODO
    });

    // List Outings
    //
    // List active and archived outings in stable creation order.
    //
    //Future<List<OutingResponse>> listOutingsApiV1GroupsGroupIdOutingsGet(String groupId) async
    test('test listOutingsApiV1GroupsGroupIdOutingsGet', () async {
      // TODO
    });

    // Unarchive Outing
    //
    // Restore an archived outing to active state as its owner.
    //
    //Future<OutingResponse> unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost(String groupId, String outingId, String xCSRFToken) async
    test('test unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost', () async {
      // TODO
    });

  });
}
