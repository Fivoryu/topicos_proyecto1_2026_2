import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for BalancesApi
void main() {
  final instance = Openapi().getBalancesApi();

  group(BalancesApi, () {
    // Get Balances
    //
    // Compute balances from source expenses in stable participant order.
    //
    //Future<BalancesResponse> getBalancesApiV1GroupsGroupIdBalancesGet(String groupId) async
    test('test getBalancesApiV1GroupsGroupIdBalancesGet', () async {
      // TODO
    });

  });
}
