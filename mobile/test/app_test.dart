import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/app/app.dart';
import 'package:cuentas_claras_mobile/app/app_config.dart';

void main() {
  testWidgets('renders a non-feature mobile shell placeholder', (tester) async {
    const config = AppConfig(apiBaseUrl: '', groupId: '');

    await tester.pumpWidget(const App(config: config));

    expect(find.text('Cuentas Claras'), findsOneWidget);
    expect(find.text('Mobile shell ready'), findsOneWidget);
    expect(find.text('Sign in to access your group'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('keeps dart-define routing configuration out of the UI', (
    tester,
  ) async {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      groupId: 'demo-group',
    );

    await tester.pumpWidget(const App(config: config));

    expect(
      find.text(
        'Routing configuration is ready for the next integration slice.',
      ),
      findsOneWidget,
    );
    expect(find.text('https://api.example.test'), findsNothing);
    expect(find.text('demo-group'), findsNothing);
    expect(find.text('Ana'), findsNothing);
  });

  test('treats whitespace-only dart defines as missing routing values', () {
    const config = AppConfig(apiBaseUrl: '   ', groupId: '\n\t');

    expect(config.hasRoutingConfiguration, isFalse);
  });

  test('requires both routing values before showing configured status', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      groupId: '  ',
    );

    expect(config.hasRoutingConfiguration, isFalse);
  });

  test('reads routing values from compile-time dart defines', () {
    const config = AppConfig.fromEnvironment;
    const expectedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const expectedGroupId = String.fromEnvironment('GROUP_ID');

    expect(config.apiBaseUrl, expectedApiBaseUrl);
    expect(config.groupId, expectedGroupId);
  });
}
