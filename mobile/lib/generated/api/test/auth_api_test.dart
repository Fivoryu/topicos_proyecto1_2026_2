// ignore_for_file: uri_does_not_exist, undefined_function, unused_local_variable
import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AuthApi
void main() {
  final instance = Openapi().getAuthApi();

  group(AuthApi, () {
    // Login
    //
    // Authenticate seeded credentials and establish both transport cookies.
    //
    //Future<SessionIdentityResponse> loginApiV1AuthLoginPost(String xCSRFToken, LoginRequest loginRequest) async
    test('test loginApiV1AuthLoginPost', () async {
      // TODO
    });

    // Logout
    //
    // Revoke the current session and expire both browser-visible cookies.
    //
    //Future logoutApiV1AuthLogoutPost(String xCSRFToken) async
    test('test logoutApiV1AuthLogoutPost', () async {
      // TODO
    });

    // Session
    //
    // Session probe outcomes: no cc_session without the exact X-Client: mobile marker returns browser HTTP 204 with no content; no cc_session with that exact marker remains HTTP 401. Every present cc_session is validated, and unusable values remain HTTP 401, including session_expired where emitted. All outcomes initialize the server-owned root cc_csrf cookie and clean the legacy /api cookie. This anonymous exception applies only to the session probe and does not authorize protected resources.
    //
    //Future<SessionIdentityResponse> sessionApiV1AuthSessionGet() async
    test('test sessionApiV1AuthSessionGet', () async {
      // TODO
    });

  });
}
