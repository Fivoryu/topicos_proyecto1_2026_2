import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for MembershipsApi
void main() {
  final instance = Openapi().getMembershipsApi();

  group(MembershipsApi, () {
    // Leave Group
    //
    //Future leaveGroupApiV1GroupsGroupIdLeavePost(String groupId, String xCSRFToken) async
    test('test leaveGroupApiV1GroupsGroupIdLeavePost', () async {
      // TODO
    });

    // List Members
    //
    //Future<List<MemberResponse>> listMembersApiV1GroupsGroupIdMembersGet(String groupId) async
    test('test listMembersApiV1GroupsGroupIdMembersGet', () async {
      // TODO
    });

    // Remove Member
    //
    //Future removeMemberApiV1GroupsGroupIdMembersAccountIdDelete(String groupId, String accountId, String xCSRFToken) async
    test('test removeMemberApiV1GroupsGroupIdMembersAccountIdDelete', () async {
      // TODO
    });

  });
}
