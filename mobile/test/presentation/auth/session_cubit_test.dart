import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/auth/auth_repository.dart';
import 'package:cuentas_claras_mobile/presentation/auth/session_cubit.dart';

class FakeAuthOperations implements AuthOperations {
  FakeAuthOperations(this.response);

  final Response<SessionIdentityResponse> response;
  var sessionCalls = 0;
  var loginCalls = 0;
  var logoutCalls = 0;

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) async {
    loginCalls++;
    return response;
  }

  @override
  Future<Response<void>> logout({required String xCSRFToken}) async {
    logoutCalls++;
    return Response<void>(
      statusCode: 204,
      requestOptions: RequestOptions(path: '/api/v1/auth/logout'),
    );
  }

  @override
  Future<Response<SessionIdentityResponse>> session() async {
    sessionCalls++;
    return response;
  }
}

SessionIdentityResponse identity() => SessionIdentityResponse(
  account: AccountIdentityResponse(id: 'account-1', loginName: 'demo.owner'),
  activeGroupId: 'group-1',
  expiresAt: DateTime.utc(2026, 8, 26),
  role: SessionIdentityResponseRoleEnum.owner,
);

void main() {
  test(
    'covers unknown, signedOut, authenticating, authenticated, and expired states',
    () async {
      final operations = FakeAuthOperations(
        Response<SessionIdentityResponse>(
          data: identity(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth'),
        ),
      );
      final cubit = SessionCubit(
        repository: AuthRepository(
          operations: operations,
          cookieJar: CookieJar(),
        ),
      );

      expect(cubit.state.status, SessionStatus.unknown);
      await cubit.restoreSession();
      expect(cubit.state.status, SessionStatus.authenticated);
      expect(cubit.state.role, 'owner');

      await cubit.login(loginName: 'demo.owner', password: 'password');
      expect(cubit.state.status, SessionStatus.authenticated);
      expect(operations.loginCalls, 1);

      await cubit.logout();
      expect(cubit.state.status, SessionStatus.signedOut);
      cubit.markSessionExpired();
      expect(cubit.state.status, SessionStatus.sessionExpired);
      await cubit.login(loginName: 'demo.owner', password: 'password');
      expect(cubit.state.status, SessionStatus.authenticated);

      await cubit.close();
    },
  );

  test(
    'a failed restore is signed out without exposing cookie values',
    () async {
      final operations = _FailingAuthOperations();
      final cubit = SessionCubit(
        repository: AuthRepository(
          operations: operations,
          cookieJar: CookieJar(),
        ),
      );

      await cubit.restoreSession();

      expect(cubit.state.status, SessionStatus.signedOut);
      expect(cubit.state.toString(), isNot(contains('session-secret')));
      await cubit.close();
    },
  );
}

class _FailingAuthOperations implements AuthOperations {
  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) => throw DioException(
    requestOptions: RequestOptions(path: '/api/v1/auth/login'),
    response: Response<dynamic>(
      statusCode: 401,
      data: {'error_code': 'invalid_credentials'},
      requestOptions: RequestOptions(path: '/api/v1/auth/login'),
    ),
  );

  @override
  Future<Response<void>> logout({required String xCSRFToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<SessionIdentityResponse>> session() => throw DioException(
    requestOptions: RequestOptions(path: '/api/v1/auth/session'),
    response: Response<dynamic>(
      statusCode: 401,
      data: {'error_code': 'unauthorized'},
      requestOptions: RequestOptions(path: '/api/v1/auth/session'),
    ),
  );
}
