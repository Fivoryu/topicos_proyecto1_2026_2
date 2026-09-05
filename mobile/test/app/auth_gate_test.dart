import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/app/app.dart';
import 'package:cuentas_claras_mobile/app/app_config.dart';
import 'package:cuentas_claras_mobile/app/domain_scope.dart';
import 'package:cuentas_claras_mobile/data/auth/auth_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/auth/session_cubit.dart';

void main() {
  testWidgets('does not construct protected scope before authentication', (
    tester,
  ) async {
    final pending = Completer<Response<SessionIdentityResponse>>();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(pending.future),
        cookieJar: CookieJar(),
      ),
    );
    var constructions = 0;
    final factoryGroups = <String>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'route-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          constructions++;
          factoryGroups.add(groupId);
          return DomainScope(groupId: groupId);
        },
      ),
    );
    await tester.pump();

    expect(find.text('Restoring session…'), findsOneWidget);
    expect(constructions, 0);

    pending.complete(_response(_identity()));
    await tester.pumpAndSettle();
    expect(constructions, 1);
    expect(factoryGroups, ['server-group']);
    expect(find.text('Group'), findsOneWidget);

    session.markSessionExpired();
    await tester.pumpAndSettle();
    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(find.text('Role: owner'), findsNothing);

    await session.close();
  });

  testWidgets('disposes protected state as logout begins', (tester) async {
    final logoutResponse = Completer<Response<void>>();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(
          Future.value(_response(_identity())),
          logoutResponse: logoutResponse.future,
        ),
        cookieJar: CookieJar(),
      ),
    );
    final scopes = <DomainScope>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'configured-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          final scope = DomainScope(groupId: groupId);
          scopes.add(scope);
          return scope;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(scopes, hasLength(1));
    final logout = session.logout();
    await tester.pump();
    await tester.pump();

    expect(find.text('Sign in'), findsOneWidget);
    expect(scopes.single.groupCubit.isClosed, isTrue);
    expect(scopes.single.participantsCubit.isClosed, isTrue);
    expect(scopes.single.expensesCubit.isClosed, isTrue);
    expect(scopes.single.balancesCubit.isClosed, isTrue);
    expect(scopes.single.settlementCubit.isClosed, isTrue);

    logoutResponse.complete(_response<void>(null));
    await logout;
    await session.close();
  });

  testWidgets('disposes protected state when logout begins during a load', (
    tester,
  ) async {
    final groupResponse = Completer<GroupReadModel>();
    final logoutResponse = Completer<Response<void>>();
    final unavailable = DomainReaders.unavailable();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(
          Future.value(_response(_identity())),
          logoutResponse: logoutResponse.future,
        ),
        cookieJar: CookieJar(),
      ),
    );
    final scopes = <DomainScope>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'configured-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          final scope = DomainScope(
            groupId: groupId,
            readers: DomainReaders(
              group: _PendingGroupReader(groupResponse.future),
              participants: unavailable.participants,
              expenses: unavailable.expenses,
              balances: unavailable.balances,
              settlement: unavailable.settlement,
            ),
          );
          scopes.add(scope);
          return scope;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loading group…'), findsOneWidget);
    final logout = session.logout();
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(scopes.single.groupCubit.isClosed, isTrue);

    groupResponse.complete(_identityGroup());
    logoutResponse.complete(_response<void>(null));
    await logout;
    await tester.pump();
    await session.close();
  });

  testWidgets(
    'closes participant mutation when logout begins during mutation',
    (tester) async {
      final writerResponse = Completer<ParticipantReadModel>();
      final logoutResponse = Completer<Response<void>>();
      final unavailable = DomainReaders.unavailable();
      final session = SessionCubit(
        repository: AuthRepository(
          operations: _GateOperations(
            Future.value(_response(_identity())),
            logoutResponse: logoutResponse.future,
          ),
          cookieJar: CookieJar(),
        ),
      );
      final scopes = <DomainScope>[];
      final writer = _PendingParticipantWriter(writerResponse.future);

      await tester.pumpWidget(
        App(
          config: const AppConfig(
            apiBaseUrl: 'http://api.test',
            groupId: 'configured-group',
          ),
          sessionCubit: session,
          domainScopeFactory: (groupId) {
            final scope = DomainScope(
              groupId: groupId,
              readers: DomainReaders(
                group: _ImmediateGroupReader(),
                participants: unavailable.participants,
                expenses: unavailable.expenses,
                balances: unavailable.balances,
                settlement: unavailable.settlement,
                participantsWriter: writer,
              ),
            );
            scopes.add(scope);
            return scope;
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final mutation = scopes.single.participantsMutationCubit!;
      final request = mutation.add('Ana');
      await tester.pump();
      expect(mutation.state.isDisabled, isTrue);

      final logout = session.logout();
      await tester.pump();
      await tester.pump();

      expect(find.text('Sign in'), findsOneWidget);
      expect(mutation.isClosed, isTrue);

      writerResponse.complete(_pendingParticipant);
      await request;
      expect(writer.addCalls, 1);

      logoutResponse.complete(_response<void>(null));
      await logout;
      await session.close();
    },
  );

  testWidgets('keeps protected state disposed when logout fails', (
    tester,
  ) async {
    final logoutResponse = Completer<Response<void>>();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(
          Future.value(_response(_identity())),
          logoutResponse: logoutResponse.future,
        ),
        cookieJar: CookieJar(),
      ),
    );
    final scopes = <DomainScope>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'configured-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          final scope = DomainScope(groupId: groupId);
          scopes.add(scope);
          return scope;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(scopes, hasLength(1));
    final logout = session.logout();
    await tester.pump();
    await tester.pump();
    logoutResponse.completeError(StateError('logout unavailable'));
    await logout;

    expect(find.text('Sign in'), findsOneWidget);
    expect(scopes.single.groupCubit.isClosed, isTrue);
    expect(scopes.single.participantsCubit.isClosed, isTrue);
    expect(scopes.single.expensesCubit.isClosed, isTrue);
    expect(scopes.single.balancesCubit.isClosed, isTrue);
    expect(scopes.single.settlementCubit.isClosed, isTrue);

    await session.close();
  });

  testWidgets('disposes protected state when the session expires', (
    tester,
  ) async {
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(Future.value(_response(_identity()))),
        cookieJar: CookieJar(),
      ),
    );
    final scopes = <DomainScope>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'configured-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          final scope = DomainScope(groupId: groupId);
          scopes.add(scope);
          return scope;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(scopes, hasLength(1));
    session.markSessionExpired();
    await tester.pumpAndSettle();

    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(scopes.single.groupCubit.isClosed, isTrue);
    expect(scopes.single.participantsCubit.isClosed, isTrue);
    expect(scopes.single.expensesCubit.isClosed, isTrue);
    expect(scopes.single.balancesCubit.isClosed, isTrue);
    expect(scopes.single.settlementCubit.isClosed, isTrue);

    await session.close();
  });

  testWidgets('disposes protected state when session expires during a load', (
    tester,
  ) async {
    final groupResponse = Completer<GroupReadModel>();
    final unavailable = DomainReaders.unavailable();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(Future.value(_response(_identity()))),
        cookieJar: CookieJar(),
      ),
    );
    final scopes = <DomainScope>[];

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'configured-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) {
          final scope = DomainScope(
            groupId: groupId,
            readers: DomainReaders(
              group: _PendingGroupReader(groupResponse.future),
              participants: unavailable.participants,
              expenses: unavailable.expenses,
              balances: unavailable.balances,
              settlement: unavailable.settlement,
            ),
          );
          scopes.add(scope);
          return scope;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loading group…'), findsOneWidget);
    session.markSessionExpired();
    await tester.pumpAndSettle();

    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(scopes.single.groupCubit.isClosed, isTrue);
    expect(scopes.single.participantsCubit.isClosed, isTrue);
    expect(scopes.single.expensesCubit.isClosed, isTrue);
    expect(scopes.single.balancesCubit.isClosed, isTrue);
    expect(scopes.single.settlementCubit.isClosed, isTrue);

    groupResponse.complete(_identityGroup());
    await tester.pump();
    await session.close();
  });

  testWidgets('rejects supplied route group and role at the App boundary', (
    tester,
  ) async {
    const invalidRoutes = [
      (groupId: 'route-group', role: 'owner'),
      (groupId: 'server-group', role: 'member'),
    ];

    for (final route in invalidRoutes) {
      final session = SessionCubit(
        repository: AuthRepository(
          operations: _GateOperations(Future.value(_response(_identity()))),
          cookieJar: CookieJar(),
        ),
      );

      await tester.pumpWidget(
        App(
          config: const AppConfig(
            apiBaseUrl: 'http://api.test',
            groupId: 'configured-group',
          ),
          sessionCubit: session,
          routeGroupId: route.groupId,
          routeRole: route.role,
          domainScopeFactory: (groupId) => DomainScope(groupId: groupId),
        ),
      );
      await tester.pumpAndSettle();

      final message = find.text(
        'This route is not authorized for the active session.',
      );
      expect(message, findsOneWidget);
      expect(tester.getSemantics(message).flagsCollection.isLiveRegion, isTrue);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Role: owner'), findsNothing);

      await session.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('keeps a forbidden protected read in-domain without auth retry', (
    tester,
  ) async {
    final unavailable = DomainReaders.unavailable();
    final session = SessionCubit(
      repository: AuthRepository(
        operations: _GateOperations(Future.value(_response(_identity()))),
        cookieJar: CookieJar(),
      ),
    );
    final forbiddenReader = _ForbiddenGroupReader();

    await tester.pumpWidget(
      App(
        config: const AppConfig(
          apiBaseUrl: 'http://api.test',
          groupId: 'route-group',
        ),
        sessionCubit: session,
        domainScopeFactory: (groupId) => DomainScope(
          groupId: groupId,
          readers: DomainReaders(
            group: forbiddenReader,
            participants: unavailable.participants,
            expenses: unavailable.expenses,
            balances: unavailable.balances,
            settlement: unavailable.settlement,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Role: owner'), findsOneWidget);
    expect(find.text('You are not authorized to view group.'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(forbiddenReader.calls, 1);

    await session.close();
  });
}

class _ImmediateGroupReader implements GroupReader {
  @override
  Future<GroupReadModel> getGroup(String groupId) async => _identityGroup();
}

class _PendingParticipantWriter implements ParticipantsWriter {
  _PendingParticipantWriter(this.response);

  final Future<ParticipantReadModel> response;
  var addCalls = 0;

  @override
  Future<ParticipantReadModel> addParticipant(String groupId, String name) {
    addCalls++;
    return response;
  }

  @override
  Future<ParticipantReadModel> archiveParticipant(
    String groupId,
    String participantId,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteParticipant(String groupId, String participantId) =>
      throw UnimplementedError();

  @override
  Future<ParticipantReadModel> reactivateParticipant(
    String groupId,
    String participantId,
  ) => throw UnimplementedError();

  @override
  Future<ParticipantReadModel> renameParticipant(
    String groupId,
    String participantId,
    String name,
  ) => throw UnimplementedError();
}

const _pendingParticipant = ParticipantReadModel(
  id: 'participant-1',
  groupId: 'server-group',
  name: 'Ana',
  archived: false,
);

class _ForbiddenGroupReader implements GroupReader {
  var calls = 0;

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    calls++;
    throw DioException(
      requestOptions: RequestOptions(path: '/groups/$groupId'),
      response: Response<dynamic>(
        statusCode: 403,
        requestOptions: RequestOptions(path: '/groups/$groupId'),
      ),
    );
  }
}

class _PendingGroupReader implements GroupReader {
  _PendingGroupReader(this.response);

  final Future<GroupReadModel> response;

  @override
  Future<GroupReadModel> getGroup(String groupId) => response;
}

GroupReadModel _identityGroup() => const GroupReadModel(
  id: 'server-group',
  name: 'Protected group',
  ownerAccountId: 'account-1',
  settlementPolicy: SettlementPolicy.ownerOnly,
);

class _GateOperations implements AuthOperations {
  _GateOperations(
    this.sessionResponse, {
    Future<Response<void>>? logoutResponse,
  }) : _logoutResponse = logoutResponse ?? Future.value(_response<void>(null));

  final Future<Response<SessionIdentityResponse>> sessionResponse;
  final Future<Response<void>> _logoutResponse;

  @override
  Future<Response<SessionIdentityResponse>> session() => sessionResponse;

  @override
  Future<Response<SessionIdentityResponse>> login({
    required String xCSRFToken,
    required LoginRequest loginRequest,
  }) => throw UnimplementedError();

  @override
  Future<Response<void>> logout({required String xCSRFToken}) =>
      _logoutResponse;
}

Response<T> _response<T>(T data) => Response<T>(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: '/api/v1/auth'),
);

SessionIdentityResponse _identity() => SessionIdentityResponse(
  account: AccountIdentityResponse(id: 'account-1', loginName: 'owner'),
  activeGroupId: 'server-group',
  expiresAt: DateTime.utc(2026, 8, 26),
  role: SessionIdentityResponseRoleEnum.owner,
);
