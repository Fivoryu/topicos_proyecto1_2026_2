import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for JoinApi
void main() {
  final instance = Openapi().getJoinApi();

  group(JoinApi, () {
    // Consume Join Code
    //
    //Future<JoinResponse> consumeJoinCodeApiV1GroupsJoinPost(String xCSRFToken, JoinCodeConsumeRequest joinCodeConsumeRequest) async
    test('test consumeJoinCodeApiV1GroupsJoinPost', () async {
      // TODO
    });

    // Generate Join Code
    //
    //Future<JoinCodeResponse> generateJoinCodeApiV1GroupsGroupIdJoinCodePost(String groupId, String xCSRFToken) async
    test('test generateJoinCodeApiV1GroupsGroupIdJoinCodePost', () async {
      // TODO
    });

    // Get Join Code Status
    //
    //Future<JoinCodeStatus> getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet(String groupId) async
    test('test getJoinCodeStatusApiV1GroupsGroupIdJoinCodeGet', () async {
      // TODO
    });

    // Regenerate Join Code
    //
    //Future<JoinCodeResponse> regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost(String groupId, String xCSRFToken) async
    test('test regenerateJoinCodeApiV1GroupsGroupIdJoinCodeRegeneratePost', () async {
      // TODO
    });

    // Revoke Join Code
    //
    //Future<JoinCodeStatus> revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete(String groupId, String xCSRFToken) async
    test('test revokeJoinCodeApiV1GroupsGroupIdJoinCodeDelete', () async {
      // TODO
    });

  });
}
