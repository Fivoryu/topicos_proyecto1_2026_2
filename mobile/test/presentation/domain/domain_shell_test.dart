import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/app/domain_scope.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/domain/domain_shell.dart';

void main() {
  testWidgets('shows five labeled destinations on a narrow window', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(
          scope: DomainScope(groupId: 'group-1'),
          role: 'owner',
          onLogout: () async {},
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in const [
      'Group',
      'Participants',
      'Expenses',
      'Balances',
      'Settlement',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Switch group'), findsNothing);
    expect(find.text('Role: owner'), findsOneWidget);
  });

  testWidgets('passes scope mutation composition to participants screen', (
    tester,
  ) async {
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: _ShellParticipantsReader(),
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        participantsWriter: _ShellParticipantsWriter(),
      ),
    );
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
      ),
    );
    await tester.tap(find.text('Participants'));
    await tester.pumpAndSettle();

    expect(find.text('Add participant'), findsNWidgets(2));
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('allows route values matching the active session authority', (
    tester,
  ) async {
    final scope = DomainScope(groupId: 'group-1');
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(
          scope: scope,
          role: 'owner',
          routeGroupId: 'group-1',
          routeRole: 'owner',
          onLogout: () async {},
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Group'), findsOneWidget);
    expect(
      find.text('This route is not authorized for the active session.'),
      findsNothing,
    );
  });

  testWidgets(
    'keeps settlement failure retryable without local settlement data',
    (tester) async {
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: _FlakySettlementReader(),
        ),
      );
      addTearDown(scope.close);

      await tester.pumpWidget(
        MaterialApp(
          home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
        ),
      );
      await tester.tap(find.text('Settlement'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to load settlement'), findsOneWidget);
      expect(find.text('Retry settlement'), findsOneWidget);
      expect(find.text('Everyone is settled'), findsNothing);

      await tester.tap(find.text('Retry settlement'));
      await tester.pumpAndSettle();
      expect(find.text('Everyone is settled'), findsOneWidget);
    },
  );

  testWidgets('rejects a conflicting route group', (tester) async {
    final scope = DomainScope(groupId: 'server-group');
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(
          scope: scope,
          role: 'owner',
          routeGroupId: 'route-group',
          routeRole: 'owner',
          onLogout: () async {},
        ),
      ),
    );

    expect(
      find.text('This route is not authorized for the active session.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Group'), findsNothing);
  });

  testWidgets('rejects a conflicting route role', (tester) async {
    final scope = DomainScope(groupId: 'group-1');
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(
          scope: scope,
          role: 'owner',
          routeGroupId: 'group-1',
          routeRole: 'member',
          onLogout: () async {},
        ),
      ),
    );

    expect(
      find.text('This route is not authorized for the active session.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Group'), findsNothing);
  });

  testWidgets('uses labeled rail navigation on a large window', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(
          scope: DomainScope(groupId: 'group-1'),
          role: 'member',
          onLogout: () async {},
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Settlement'), findsOneWidget);
  });

  testWidgets('keeps shell controls usable with large text', (tester) async {
    final scope = DomainScope(groupId: 'group-1');
    addTearDown(scope.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: DomainShell(
            scope: scope,
            role: 'member',
            onLogout: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SafeArea), findsAtLeastNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextButton).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(NavigationBar)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('Log out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ShellParticipantsReader implements ParticipantsReader {
  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) =>
      Future.value(const [
        ParticipantReadModel(
          id: 'participant-1',
          groupId: 'group-1',
          name: 'Ana',
          archived: false,
        ),
      ]);
}

class _ShellParticipantsWriter implements ParticipantsWriter {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #deleteParticipant
      ? Future<void>.value()
      : Future<ParticipantReadModel>.value(
          const ParticipantReadModel(
            id: 'participant-1',
            groupId: 'group-1',
            name: 'Ana',
            archived: false,
          ),
        );
}

class _FlakySettlementReader implements SettlementReader {
  var calls = 0;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async {
    if (++calls == 1) throw StateError('offline');
    return const SettlementReadModel(
      groupId: 'group-1',
      settlementPolicy: SettlementPolicy.ownerOnly,
      settled: true,
      transfers: [],
    );
  }
}
