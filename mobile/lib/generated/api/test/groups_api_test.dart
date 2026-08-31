import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for GroupsApi
void main() {
  final instance = Openapi().getGroupsApi();

  group(GroupsApi, () {
    // Get Group
    //
    // Return the authenticated group's server-owned settings.
    //
    //Future<GroupResponse> getGroupApiV1GroupsGroupIdGet(String groupId) async
    test('test getGroupApiV1GroupsGroupIdGet', () async {
      // TODO
    });

    // Update Group
    //
    // Update only settlement policy; authorization remains in GroupService.
    //
    //Future<GroupResponse> updateGroupApiV1GroupsGroupIdPatch(String groupId, String xCSRFToken, GroupUpdateRequest groupUpdateRequest) async
    test('test updateGroupApiV1GroupsGroupIdPatch', () async {
      // TODO
    });

  });
}
