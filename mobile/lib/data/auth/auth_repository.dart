import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import 'auth_transport.dart';

/// The generated auth operations needed by the repository boundary.
abstract interface class AuthOperations {
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  });

  Future<Response<void>> logout({required String xCSRFToken});

  Future<Response<SessionIdentityResponse>> session();
}

class GeneratedAuthOperations implements AuthOperations {
  const GeneratedAuthOperations(this.api);

  final AuthApi api;

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) => api.loginApiV1AuthLoginPost(
    xCSRFToken: xCSRFToken,
    loginRequest: loginRequest,
  );

  @override
  Future<Response<void>> logout({required String xCSRFToken}) =>
      api.logoutApiV1AuthLogoutPost(xCSRFToken: xCSRFToken);

  @override
  Future<Response<SessionIdentityResponse>> session() =>
      api.sessionApiV1AuthSessionGet();
}

class AuthRepositoryException extends StateError {
  AuthRepositoryException(super.message);
}

/// Owns all generated authentication calls and never returns cookie values.
class AuthRepository {
  AuthRepository({
    required this.operations,
    required this.cookieJar,
    Uri? baseUri,
  }) : baseUri = baseUri ?? Uri.parse('http://localhost');

  factory AuthRepository.fromTransport(AuthTransport transport) {
    final repository = AuthRepository(
      operations: GeneratedAuthOperations(transport.authApi),
      cookieJar: transport.cookieJar,
      baseUri: transport.baseUri,
    );
    transport.onUnauthorized = (failure) =>
        repository.onUnauthorized?.call(failure);
    return repository;
  }

  final AuthOperations operations;
  final CookieJar cookieJar;
  final Uri baseUri;

  /// Set by [SessionCubit] without exposing the underlying cookie transport.
  UnauthorizedHandler? onUnauthorized;

  Future<SessionIdentityReadModel> login({
    required String loginName,
    required String password,
  }) async {
    final response = await operations.login(
      xCSRFToken: await _csrfToken(),
      loginRequest: LoginRequest(loginName: loginName, password: password),
    );
    return _identity(response);
  }

  Future<SessionIdentityReadModel> session() async {
    final response = await operations.session();
    return _identity(response);
  }

  Future<SessionIdentityReadModel> getSession() => session();

  Future<void> logout() async {
    try {
      await operations.logout(xCSRFToken: await _csrfToken());
    } finally {
      await clearCookies();
    }
  }

  Future<void> clearCookies() => cookieJar.deleteAll();

  Future<String> _csrfToken() async {
    final cookies = await cookieJar.loadForRequest(baseUri);
    for (final cookie in cookies) {
      if (cookie.name == 'cc_csrf') {
        return cookie.value;
      }
    }
    return '';
  }

  SessionIdentityReadModel _identity(
    Response<SessionIdentityResponse> response,
  ) {
    final data = response.data;
    if (data == null) {
      throw AuthRepositoryException('Authentication response had no identity.');
    }
    return SessionIdentityReadModel.fromDto(data);
  }
}
