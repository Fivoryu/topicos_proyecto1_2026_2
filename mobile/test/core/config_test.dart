import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/core/config/app_config.dart';

void main() {
  test('reads API base URL and group ID from dart defines', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      groupId: 'group-1',
    );

    expect(config.apiBaseUrl, 'https://api.example.test');
    expect(config.groupId, 'group-1');
    expect(config.hasRoutingConfiguration, isTrue);
  });

  test('requires both non-blank routing values', () {
    const config = AppConfig(apiBaseUrl: '  ', groupId: '\n');

    expect(config.hasRoutingConfiguration, isFalse);
  });
}
