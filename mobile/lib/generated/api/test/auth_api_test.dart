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
    // Return server identity and initialize CSRF even for an anonymous probe.
    //
    //Future<SessionIdentityResponse> sessionApiV1AuthSessionGet() async
    test('test sessionApiV1AuthSessionGet', () async {
      // TODO
    });

  });
}
