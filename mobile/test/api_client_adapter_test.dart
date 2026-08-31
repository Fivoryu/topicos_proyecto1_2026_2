import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/api_client_adapter.dart';

void main() {
  test('configures the generated Dio client with a cookie manager', () {
    final adapter = ApiClientAdapter(baseUrl: 'https://api.example.test');

    expect(adapter.dio.options.baseUrl, 'https://api.example.test');
    expect(adapter.dio.interceptors.whereType<CookieManager>(), hasLength(1));
    expect(adapter.api.dio, same(adapter.dio));
  });
}
