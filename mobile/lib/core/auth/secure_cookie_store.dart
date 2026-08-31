import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The small storage port needed by the persistent cookie jar.
///
/// Production code uses [FlutterSecureStorageBackend]. Tests can provide a
/// disposable fake without invoking a platform channel.
abstract interface class SecureStorageBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Encrypted [flutter_secure_storage] implementation for cookie-jar records.
class FlutterSecureStorageBackend implements SecureStorageBackend {
  const FlutterSecureStorageBackend({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

/// Cookie-jar storage that keeps session and CSRF values out of presentation.
///
/// [PersistCookieJar] writes only serialized cookie-jar metadata through this
/// adapter. In production each record is encrypted by the platform keystore.
class SecureCookieStore implements Storage {
  SecureCookieStore({SecureStorageBackend? backend})
    : backend = backend ?? const FlutterSecureStorageBackend();

  static const _prefix = 'cuentas_claras.cookie.';

  final SecureStorageBackend backend;

  String _storageKey(String key) => '$_prefix$key';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => backend.read(_storageKey(key));

  @override
  Future<void> write(String key, String value) =>
      backend.write(_storageKey(key), value);

  @override
  Future<void> delete(String key) => backend.delete(_storageKey(key));

  @override
  Future<void> deleteAll(List<String> keys) async {
    await Future.wait(keys.map(delete));
  }
}
