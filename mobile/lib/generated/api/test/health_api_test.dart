import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for HealthApi
void main() {
  final instance = Openapi().getHealthApi();

  group(HealthApi, () {
    // Health
    //
    // Report application availability and PostgreSQL connectivity.
    //
    //Future<HealthResponse> healthHealthGet() async
    test('test healthHealthGet', () async {
      // TODO
    });

  });
}
