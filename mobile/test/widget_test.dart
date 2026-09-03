import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/app/app.dart';
import 'package:cuentas_claras_mobile/app/app_config.dart';

void main() {
  testWidgets('renders the app entry point', (tester) async {
    const config = AppConfig(apiBaseUrl: '', groupId: '');

    await tester.pumpWidget(const App(config: config));

    expect(
      find.text(
        'Mobile configuration is missing. Provide API_BASE_URL and GROUP_ID.',
      ),
      findsOneWidget,
    );
  });
}
