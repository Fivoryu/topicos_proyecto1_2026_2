import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for GroupsApi
void main() {
  final instance = Openapi().getGroupsApi();

  group(GroupsApi, () {
    // Create Group
    //
    // Create an empty owner workspace for the authenticated account.
    //
    //Future<GroupSummaryResponse> createGroupApiV1GroupsPost(GroupCreateRequest groupCreateRequest) async
    test('test createGroupApiV1GroupsPost', () async {
      // TODO
    });

    // Get Group
    //
    // Return the authenticated group's server-owned settings.
    //
    //Future<GroupResponse> getGroupApiV1GroupsGroupIdGet(String groupId) async
    test('test getGroupApiV1GroupsGroupIdGet', () async {
      // TODO
    });

    // List Groups
    //
    // List only groups belonging to the authenticated account.
    //
    //Future<List<GroupSummaryResponse>> listGroupsApiV1GroupsGet() async
    test('test listGroupsApiV1GroupsGet', () async {
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
