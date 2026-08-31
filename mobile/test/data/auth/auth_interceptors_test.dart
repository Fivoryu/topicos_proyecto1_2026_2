import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/core/auth/secure_cookie_store.dart';
import 'package:cuentas_claras_mobile/data/auth/auth_transport.dart';

class MemoryAdapter implements HttpClientAdapter {
  MemoryAdapter(
    this.statusCode, {
    this.body = '',
    this.responseHeaders = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, List<String>> responseHeaders;
  var requestCount = 0;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    lastRequest = options;
    return ResponseBody.fromString(body, statusCode, headers: responseHeaders);
  }

  @override
  void close({bool force = false}) {}
}

class FakeSecureStorageBackend implements SecureStorageBackend {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test(
    'installs CookieManager and adds CSRF only to unsafe requests',
    () async {
      final store = SecureCookieStore(backend: FakeSecureStorageBackend());
      final transport = AuthTransport(
        baseUrl: 'https://api.example.test',
        cookieStore: store,
      );
      final adapter = MemoryAdapter(204);
      transport.dio.httpClientAdapter = adapter;
      final uri = Uri.parse('https://api.example.test/api/v1/auth');
      await transport.cookieJar.saveFromResponse(uri, [
        Cookie('cc_csrf', 'csrf-secret'),
      ]);

      await transport.dio.post<void>('/api/v1/auth/logout');

      expect(
        transport.dio.interceptors.whereType<CookieManager>(),
        hasLength(1),
      );
      expect(adapter.lastRequest?.headers['X-CSRF-Token'], 'csrf-secret');
      expect(
        adapter.lastRequest?.headers['Cookie'],
        contains('cc_csrf=csrf-secret'),
      );
    },
  );

  test(
    'maps one 401 to session expiry, clears cookies, and never retries',
    () async {
      final store = SecureCookieStore(backend: FakeSecureStorageBackend());
      SessionFailure? failure;
      final transport = AuthTransport(
        baseUrl: 'https://api.example.test',
        cookieStore: store,
        onUnauthorized: (value) => failure = value,
      );
      final adapter = MemoryAdapter(
        401,
        body: '{"error_code":"session_expired","message":"expired"}',
        responseHeaders: const {
          'content-type': ['application/json'],
        },
      );
      transport.dio.httpClientAdapter = adapter;
      final uri = Uri.parse('https://api.example.test/api/v1/auth');
      await transport.cookieJar.saveFromResponse(uri, [
        Cookie('cc_session', 'session-secret'),
      ]);

      await expectLater(
        transport.dio.get<void>('/api/v1/groups/group-1'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requestCount, 1);
      expect(failure, SessionFailure.sessionExpired);
      expect(await transport.cookieJar.loadForRequest(uri), isEmpty);
    },
  );
}
