import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/auth/auth_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';

class FakeAuthOperations implements AuthOperations {
  FakeAuthOperations(this.sessionResponse);

  final SessionIdentityResponse sessionResponse;
  String? loginCsrf;
  String? logoutCsrf;
  var logoutCalls = 0;

  Response<T> response<T>(T data) => Response<T>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/api/v1/auth'),
  );

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) async {
    loginCsrf = xCSRFToken;
    return response(sessionResponse);
  }

  @override
  Future<Response<void>> logout({required String xCSRFToken}) async {
    logoutCsrf = xCSRFToken;
    logoutCalls++;
    return response<void>(null);
  }

  @override
  Future<Response<SessionIdentityResponse>> session() async =>
      response(sessionResponse);
}

void main() {
  test(
    'uses generated auth operations and maps login/session identity',
    () async {
      final api = FakeAuthOperations(
        SessionIdentityResponse(
          account: AccountIdentityResponse(
            id: 'account-1',
            loginName: 'demo.owner',
          ),
          activeGroupId: 'group-1',
          expiresAt: DateTime.utc(2026, 8, 26),
          role: SessionIdentityResponseRoleEnum.owner,
        ),
      );
      final jar = CookieJar();
      final uri = Uri.parse('https://api.example.test/api/v1/auth/login');
      await jar.saveFromResponse(uri, [Cookie('cc_csrf', 'csrf-secret')]);
      final repository = AuthRepository(
        operations: api,
        cookieJar: jar,
        baseUri: uri,
      );

      final identity = await repository.login(
        loginName: 'demo.owner',
        password: 'password',
      );
      final session = await repository.session();

      expect(api.loginCsrf, 'csrf-secret');
      expect(identity.accountId, 'account-1');
      expect(identity.role, ServerRole.owner);
      expect(session.activeGroupId, 'group-1');
    },
  );

  test('logout clears the cookie jar after the generated operation', () async {
    final api = FakeAuthOperations(
      SessionIdentityResponse(
        account: AccountIdentityResponse(
          id: 'account-1',
          loginName: 'demo.owner',
        ),
        activeGroupId: 'group-1',
        expiresAt: DateTime.utc(2026, 8, 26),
        role: SessionIdentityResponseRoleEnum.member,
      ),
    );
    final jar = CookieJar();
    final uri = Uri.parse('https://api.example.test/api/v1/auth/logout');
    await jar.saveFromResponse(uri, [
      Cookie('cc_csrf', 'csrf-secret'),
      Cookie('cc_session', 'session-secret'),
    ]);
    final repository = AuthRepository(
      operations: api,
      cookieJar: jar,
      baseUri: uri,
    );

    await repository.logout();

    expect(api.logoutCsrf, 'csrf-secret');
    expect(api.logoutCalls, 1);
    expect(await jar.loadForRequest(uri), isEmpty);
  });
}
