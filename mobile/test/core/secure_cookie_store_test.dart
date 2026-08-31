import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/core/auth/secure_cookie_store.dart';

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
    'persists the session and CSRF cookie jar through secure storage',
    () async {
      final backend = FakeSecureStorageBackend();
      final storage = SecureCookieStore(backend: backend);
      final jar = PersistCookieJar(storage: storage);
      final uri = Uri.parse('https://api.example.test/api/v1/auth/session');

      await jar.saveFromResponse(uri, [
        Cookie('cc_session', 'session-secret'),
        Cookie('cc_csrf', 'csrf-secret'),
      ]);

      final restored = await PersistCookieJar(
        storage: storage,
      ).loadForRequest(uri);
      expect(
        restored.map((cookie) => '${cookie.name}=${cookie.value}'),
        containsAll(['cc_session=session-secret', 'cc_csrf=csrf-secret']),
      );
      expect(
        backend.values.keys,
        everyElement(startsWith('cuentas_claras.cookie.')),
      );
    },
  );

  test(
    'clears every persisted cookie key without exposing it to presentation',
    () async {
      final backend = FakeSecureStorageBackend();
      final storage = SecureCookieStore(backend: backend);
      final jar = PersistCookieJar(storage: storage);
      final uri = Uri.parse('https://api.example.test/api/v1/auth/session');

      await jar.saveFromResponse(uri, [Cookie('cc_session', 'session-secret')]);
      await jar.deleteAll();

      expect(await jar.loadForRequest(uri), isEmpty);
      expect(backend.values, isEmpty);
    },
  );
}
