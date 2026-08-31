import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for SettlementApi
void main() {
  final instance = Openapi().getSettlementApi();

  group(SettlementApi, () {
    // Get Settlement
    //
    // Return policy and deterministic transfers derived from current balances.
    //
    //Future<SettlementResponse> getSettlementApiV1GroupsGroupIdSettlementGet(String groupId) async
    test('test getSettlementApiV1GroupsGroupIdSettlementGet', () async {
      // TODO
    });

  });
}
