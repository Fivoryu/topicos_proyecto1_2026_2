import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/app/app.dart';
import 'package:cuentas_claras_mobile/app/app_config.dart';
import 'package:cuentas_claras_mobile/data/auth/auth_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/auth/session_cubit.dart';

void main() {
  testWidgets('shows a configuration message when routing is unavailable', (
    tester,
  ) async {
    const config = AppConfig(apiBaseUrl: '', groupId: '');

    await tester.pumpWidget(const App(config: config));

    expect(find.text('Cuentas Claras'), findsNothing);
    expect(
      find.text(
        'Mobile configuration is missing. Provide API_BASE_URL and GROUP_ID.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('restores, signs in, reads the group, and logs out', (
    tester,
  ) async {
    const config = AppConfig(
      apiBaseUrl: 'http://api.example.test:8000',
      groupId: 'group-1',
    );
    final operations = _FakeAuthOperations();
    final sessionCubit = SessionCubit(
      repository: AuthRepository(
        operations: operations,
        cookieJar: CookieJar(),
      ),
    );

    await tester.pumpWidget(
      App(
        config: config,
        sessionCubit: sessionCubit,
        groupReader: _FakeGroupReader(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login name'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('http://api.example.test:8000'), findsNothing);
    expect(find.text('group-1'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'demo.owner');
    await tester.enterText(find.byType(TextFormField).at(1), 'owner-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Role: owner'), findsOneWidget);
    expect(find.text('Samaipata'), findsOneWidget);
    expect(find.text('Owner only'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Role: owner'), findsNothing);
    expect(operations.logoutCalls, 1);

    await sessionCubit.close();
  });

  testWidgets(
    'loads the server active group instead of the configured routing group',
    (tester) async {
      const config = AppConfig(
        apiBaseUrl: 'http://api.example.test:8000',
        groupId: 'configured-group',
      );
      final operations = _FakeAuthOperations(activeGroupId: 'server-group');
      final sessionCubit = SessionCubit(
        repository: AuthRepository(
          operations: operations,
          cookieJar: CookieJar(),
        ),
      );
      final groupReader = _FakeGroupReader(groupName: 'Server group');

      await tester.pumpWidget(
        App(
          config: config,
          sessionCubit: sessionCubit,
          groupReader: groupReader,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'demo.owner');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'owner-password',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(groupReader.requestedGroupIds, contains('server-group'));
      expect(
        groupReader.requestedGroupIds,
        isNot(contains('configured-group')),
      );
      expect(find.text('Server group'), findsOneWidget);

      await sessionCubit.close();
    },
  );

  testWidgets('fails closed when the server has no active group', (
    tester,
  ) async {
    const config = AppConfig(
      apiBaseUrl: 'http://api.example.test:8000',
      groupId: 'configured-group',
    );
    final operations = _FakeAuthOperations(activeGroupId: null);
    final sessionCubit = SessionCubit(
      repository: AuthRepository(
        operations: operations,
        cookieJar: CookieJar(),
      ),
    );
    final groupReader = _FakeGroupReader();

    await tester.pumpWidget(
      App(config: config, sessionCubit: sessionCubit, groupReader: groupReader),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'demo.owner');
    await tester.enterText(find.byType(TextFormField).at(1), 'owner-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Mobile configuration is missing. Provide API_BASE_URL and GROUP_ID.',
      ),
      findsOneWidget,
    );
    expect(groupReader.requestedGroupIds, isEmpty);

    await sessionCubit.close();
  });

  test('treats whitespace-only dart defines as missing routing values', () {
    const config = AppConfig(apiBaseUrl: '   ', groupId: '\n\t');

    expect(config.hasRoutingConfiguration, isFalse);
  });

  test('requires both routing values before showing configured status', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      groupId: '  ',
    );

    expect(config.hasRoutingConfiguration, isFalse);
  });

  test('reads routing values from compile-time dart defines', () {
    const config = AppConfig.fromEnvironment;
    const expectedApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const expectedGroupId = String.fromEnvironment('GROUP_ID');

    expect(config.apiBaseUrl, expectedApiBaseUrl);
    expect(config.groupId, expectedGroupId);
  });
}

class _FakeAuthOperations implements AuthOperations {
  _FakeAuthOperations({this.activeGroupId = 'group-1'});

  final String? activeGroupId;
  var logoutCalls = 0;

  Response<T> _response<T>(T data) => Response<T>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/api/v1/auth'),
  );

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) async => _response(_identity(activeGroupId: activeGroupId));

  @override
  Future<Response<void>> logout({required String xCSRFToken}) async {
    logoutCalls++;
    return _response<void>(null);
  }

  @override
  Future<Response<SessionIdentityResponse>> session() async =>
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/session'),
        response: Response<dynamic>(
          statusCode: 401,
          data: {'error_code': 'unauthorized'},
          requestOptions: RequestOptions(path: '/api/v1/auth/session'),
        ),
      );
}

SessionIdentityResponse _identity({String? activeGroupId = 'group-1'}) =>
    SessionIdentityResponse(
      account: AccountIdentityResponse(
        id: 'account-1',
        loginName: 'demo.owner',
      ),
      activeGroupId: activeGroupId,
      expiresAt: DateTime.utc(2026, 8, 26),
      role: SessionIdentityResponseRoleEnum.owner,
    );

class _FakeGroupReader implements GroupReader {
  _FakeGroupReader({this.groupName = 'Samaipata'});

  final String groupName;
  final requestedGroupIds = <String>[];

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    requestedGroupIds.add(groupId);
    return GroupReadModel(
      id: groupId,
      name: groupName,
      ownerAccountId: 'account-1',
      settlementPolicy: SettlementPolicy.ownerOnly,
    );
  }
}
