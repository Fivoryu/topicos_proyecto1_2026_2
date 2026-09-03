import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/auth/auth_repository.dart';
import 'package:cuentas_claras_mobile/data/auth/auth_transport.dart';
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

      cubit.markSessionExpired();
      expect(cubit.state.status, SessionStatus.sessionExpired);
      expect(cubit.state.role, isNull);
      expect(cubit.state.activeGroupId, isNull);

      await cubit.login(loginName: 'demo.owner', password: 'password');
      expect(cubit.state.status, SessionStatus.authenticated);

      await cubit.logout();
      expect(cubit.state.status, SessionStatus.signedOut);
      expect(cubit.state.role, isNull);
      expect(cubit.state.activeGroupId, isNull);

      await cubit.close();
    },
  );

  test('clears nullable identity fields when state is copied explicitly', () {
    const state = SessionState(
      status: SessionStatus.authenticated,
      role: 'owner',
      activeGroupId: 'group-1',
      errorMessage: 'stale error',
    );

    final cleared = state.copyWith(
      status: SessionStatus.sessionExpired,
      role: null,
      activeGroupId: null,
      errorMessage: null,
    );

    expect(cleared.status, SessionStatus.sessionExpired);
    expect(cleared.role, isNull);
    expect(cleared.activeGroupId, isNull);
    expect(cleared.errorMessage, isNull);
  });

  test('logout wins over a session restore that is still loading', () async {
    final response = Completer<Response<SessionIdentityResponse>>();
    final cubit = SessionCubit(
      repository: AuthRepository(
        operations: _PendingAuthOperations(response.future),
        cookieJar: CookieJar(),
      ),
    );

    final restore = cubit.restoreSession();
    await Future<void>.delayed(Duration.zero);
    await cubit.logout();
    response.complete(_response(identity()));
    await restore;

    expect(cubit.state.status, SessionStatus.signedOut);
    expect(cubit.state.role, isNull);
    expect(cubit.state.activeGroupId, isNull);
    await cubit.close();
  });

  test('session expiry wins over a restore that completes later', () async {
    final response = Completer<Response<SessionIdentityResponse>>();
    final cubit = SessionCubit(
      repository: AuthRepository(
        operations: _PendingAuthOperations(response.future),
        cookieJar: CookieJar(),
      ),
    );

    final restore = cubit.restoreSession();
    await Future<void>.delayed(Duration.zero);
    cubit.markSessionExpired();
    response.complete(_response(identity()));
    await restore;

    expect(cubit.state.status, SessionStatus.sessionExpired);
    expect(cubit.state.role, isNull);
    expect(cubit.state.activeGroupId, isNull);
    await cubit.close();
  });

  test(
    'repeated unauthorized notifications do not retry or re-authenticate',
    () async {
      final operations = FakeAuthOperations(
        Response<SessionIdentityResponse>(
          data: identity(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth'),
        ),
      );
      final repository = AuthRepository(
        operations: operations,
        cookieJar: CookieJar(),
      );
      final cubit = SessionCubit(repository: repository);
      await cubit.restoreSession();
      final statuses = <SessionStatus>[];
      final subscription = cubit.stream.listen(
        (state) => statuses.add(state.status),
      );

      await repository.onUnauthorized?.call(SessionFailure.sessionExpired);
      await repository.onUnauthorized?.call(SessionFailure.sessionExpired);

      expect(operations.sessionCalls, 1);
      expect(cubit.state.status, SessionStatus.sessionExpired);
      expect(
        statuses.where((status) => status == SessionStatus.sessionExpired),
        [SessionStatus.sessionExpired],
      );
      await subscription.cancel();
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

Response<T> _response<T>(T data) => Response<T>(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: '/api/v1/auth'),
);

class _PendingAuthOperations implements AuthOperations {
  _PendingAuthOperations(this.sessionResponse);

  final Future<Response<SessionIdentityResponse>> sessionResponse;

  @override
  Future<Response<SessionIdentityResponse>> session() => sessionResponse;

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) => throw UnimplementedError();

  @override
  Future<Response<void>> logout({required String xCSRFToken}) =>
      Future.value(_response<void>(null));
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
