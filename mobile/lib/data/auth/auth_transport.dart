import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:openapi/openapi.dart';

import '../../core/auth/secure_cookie_store.dart';

const _csrfCookieName = 'cc_csrf';
const _handledUnauthorizedKey = 'cuentas_claras.unauthorized_handled';

const _unsafeMethods = {'POST', 'PATCH', 'PUT', 'DELETE'};

enum SessionFailure { signedOut, sessionExpired }

typedef UnauthorizedHandler = FutureOr<void> Function(SessionFailure failure);

/// Adds the readable CSRF cookie to unsafe requests.
class CsrfInterceptor extends Interceptor {
  const CsrfInterceptor(this.cookieJar);

  final CookieJar cookieJar;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_unsafeMethods.contains(options.method.toUpperCase())) {
      handler.next(options);
      return;
    }
    unawaited(_attachToken(options, handler));
  }

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final cookies = await cookieJar.loadForRequest(options.uri);
      for (final cookie in cookies) {
        if (cookie.name == _csrfCookieName) {
          options.headers['X-CSRF-Token'] = cookie.value;
          break;
        }
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Converts one unauthorized response into local signed-out state.
///
/// The interceptor deliberately forwards the original error and never retries
/// it. The caller must explicitly authenticate again.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor(this.cookieJar, {this.onUnauthorized});

  final CookieJar cookieJar;
  UnauthorizedHandler? onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(_handle(err, handler));
  }

  Future<void> _handle(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = error.response?.statusCode == 401;
    final alreadyHandled =
        error.requestOptions.extra[_handledUnauthorizedKey] == true;
    if (!isUnauthorized || alreadyHandled) {
      handler.next(error);
      return;
    }

    error.requestOptions.extra[_handledUnauthorizedKey] = true;
    try {
      await cookieJar.deleteAll();
    } finally {
      final failure = _failureFor(error.response?.data);
      final callback = onUnauthorized;
      if (callback != null) {
        await callback(failure);
      }
      handler.next(error);
    }
  }

  SessionFailure _failureFor(Object? data) {
    if (data is Map && data['error_code'] == 'session_expired') {
      return SessionFailure.sessionExpired;
    }
    return SessionFailure.signedOut;
  }
}

/// Configures Dio for the generated client and the protected cookie contract.
class AuthTransport {
  AuthTransport({
    required SecureCookieStore cookieStore,
    String? baseUrl,
    Dio? dio,
    this.onUnauthorized,
  }) : cookieJar = PersistCookieJar(storage: cookieStore),
       dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? '')),
       baseUri = Uri.tryParse(baseUrl ?? '') ?? Uri.parse('http://localhost') {
    if (!this.dio.interceptors.any(
      (interceptor) => interceptor is CookieManager,
    )) {
      this.dio.interceptors.add(CookieManager(cookieJar));
    }
    if (!this.dio.interceptors.any(
      (interceptor) => interceptor is CsrfInterceptor,
    )) {
      this.dio.interceptors.add(CsrfInterceptor(cookieJar));
    }
    if (!this.dio.interceptors.any(
      (interceptor) => interceptor is UnauthorizedInterceptor,
    )) {
      this.dio.interceptors.add(
        UnauthorizedInterceptor(cookieJar, onUnauthorized: _handleUnauthorized),
      );
    }
    _client = Openapi(dio: this.dio, interceptors: const []);
  }

  final CookieJar cookieJar;
  final Dio dio;
  final Uri baseUri;
  UnauthorizedHandler? onUnauthorized;
  late final Openapi _client;

  AuthApi get authApi => _client.getAuthApi();

  Openapi get client => _client;

  Future<void> clearCookies() => cookieJar.deleteAll();

  FutureOr<void> _handleUnauthorized(SessionFailure failure) {
    return onUnauthorized?.call(failure);
  }
}
