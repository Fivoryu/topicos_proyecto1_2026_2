import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/app/domain_scope.dart';
import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';
import 'package:cuentas_claras_mobile/presentation/domain/domain_shell.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_widgets.dart';

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

  testWidgets('navigates to each authenticated read destination', (
    tester,
  ) async {
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: _ShellGroupReader(SettlementPolicy.ownerOnly),
        participants: _ShellParticipantsReader(),
        expenses: _ShellExpensesReader(),
        balances: _ShellBalancesReader(),
        settlement: _ShellSettlementReader(),
      ),
    );
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip'), findsOneWidget);
    await tester.tap(find.text('Participants'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Lodging'), findsOneWidget);

    await tester.tap(find.text('Balances'));
    await tester.pumpAndSettle();
    expect(find.text('Bs. 12.00'), findsOneWidget);

    await tester.tap(find.text('Settlement'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone is settled'), findsOneWidget);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SafeArea), findsAtLeastNWidgets(2));
  });

  testWidgets('passes role and policy mutation composition to group screen', (
    tester,
  ) async {
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: _ShellGroupReader(SettlementPolicy.anyMember),
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        groupWriter: _ShellGroupWriter(),
      ),
    );
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<SettlementPolicy>), findsNWidgets(2));
    expect(find.text('Any member'), findsOneWidget);
    expect(
      find.text('Only the group owner can change this policy.'),
      findsNothing,
    );
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

  testWidgets('passes expense mutation composition to expense history', (
    tester,
  ) async {
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: _ShellParticipantsReader(),
        expenses: _ShellExpensesReader(),
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        expensesWriter: _ShellExpensesWriter(),
      ),
    );
    addTearDown(scope.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
      ),
    );
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseWriteForm), findsOneWidget);
    expect(find.byType(ExpenseDeleteAction), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets(
    'preserves expense history controls when mutation support is absent',
    (tester) async {
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: _ShellParticipantsReader(),
          expenses: _ShellExpensesReader(),
          balances: unavailable.balances,
          settlement: unavailable.settlement,
        ),
      );
      addTearDown(scope.close);

      await tester.pumpWidget(
        MaterialApp(
          home: DomainShell(scope: scope, role: 'owner', onLogout: () async {}),
        ),
      );
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseWriteForm), findsNothing);
      expect(find.byType(ExpenseDeleteAction), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Lodging'), findsOneWidget);
    },
  );

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

  testWidgets(
    're-enters with a fresh protected scope after the previous scope closes',
    (tester) async {
      final unavailable = DomainReaders.unavailable();
      final previous = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: _ShellGroupReader(SettlementPolicy.ownerOnly),
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
        ),
      );
      await previous.groupCubit.load();
      expect(previous.groupCubit.state.group?.name, 'Trip');
      await previous.close();

      final current = DomainScope(
        groupId: 'group-2',
        readers: DomainReaders(
          group: _ReentryGroupReader(),
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
        ),
      );
      addTearDown(current.close);

      await tester.pumpWidget(
        MaterialApp(
          home: DomainShell(
            scope: current,
            role: 'member',
            routeGroupId: 'group-2',
            routeRole: 'member',
            onLogout: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(previous.groupCubit.isClosed, isTrue);
      expect(find.text('Re-entered group'), findsOneWidget);
      expect(find.text('Trip'), findsNothing);
      expect(
        find.text('This route is not authorized for the active session.'),
        findsNothing,
      );
    },
  );

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

class _ShellExpensesReader implements ExpensesReader {
  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) =>
      Future.value(const [_shellExpense]);
}

class _ShellExpensesWriter implements ExpensesWriter {
  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async => _shellExpense;

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async => _shellExpense;

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {}
}

const _shellExpense = ExpenseReadModel(
  id: 'expense-1',
  groupId: 'group-1',
  description: 'Lodging',
  amountCents: 96000,
  contributors: [
    ExpenseContributorReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
      amountCents: 96000,
    ),
  ],
  beneficiaries: [
    ExpenseBeneficiaryReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
    ),
  ],
);

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

class _ShellBalancesReader implements BalancesReader {
  @override
  Future<BalancesReadModel> getBalances(String groupId) async =>
      const BalancesReadModel(
        groupId: 'group-1',
        participants: [
          BalanceParticipantReadModel(
            participantId: 'participant-1',
            name: 'Ana',
            archived: false,
            paidCents: 1200,
            owedCents: 0,
            balanceCents: 1200,
          ),
        ],
      );
}

class _ShellSettlementReader implements SettlementReader {
  @override
  Future<SettlementReadModel> getSettlement(String groupId) async =>
      const SettlementReadModel(
        groupId: 'group-1',
        settlementPolicy: SettlementPolicy.ownerOnly,
        settled: true,
        transfers: [],
      );
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

class _ShellGroupReader implements GroupReader {
  _ShellGroupReader(this.policy);

  final SettlementPolicy policy;

  @override
  Future<GroupReadModel> getGroup(String groupId) async => GroupReadModel(
    id: groupId,
    name: 'Trip',
    ownerAccountId: 'owner-1',
    settlementPolicy: policy,
  );
}

class _ShellGroupWriter implements GroupWriter {
  @override
  Future<GroupReadModel> updateSettlementPolicy(
    String groupId,
    SettlementPolicy policy,
  ) async => GroupReadModel(
    id: groupId,
    name: 'Trip',
    ownerAccountId: 'owner-1',
    settlementPolicy: policy,
  );
}

class _ReentryGroupReader implements GroupReader {
  @override
  Future<GroupReadModel> getGroup(String groupId) async => const GroupReadModel(
    id: 'group-2',
    name: 'Re-entered group',
    ownerAccountId: 'owner-2',
    settlementPolicy: SettlementPolicy.anyMember,
  );
}
