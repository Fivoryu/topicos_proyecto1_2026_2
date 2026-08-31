import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/core/formatters/cents_formatter.dart';

void main() {
  test('formats integer cents with a fixed boliviano display', () {
    expect(formatCents(0), 'Bs. 0.00');
    expect(formatCents(5), 'Bs. 0.05');
    expect(formatCents(99), 'Bs. 0.99');
    expect(formatCents(1000), 'Bs. 10.00');
    expect(formatCents(1234567), 'Bs. 12,345.67');
    expect(formatCents(-5), '-Bs. 0.05');
    expect(formatCents(-1234567), '-Bs. 12,345.67');
  });

  test('uses integer input only', () {
    expect(() => formatCents(0), returnsNormally);
  });
}
