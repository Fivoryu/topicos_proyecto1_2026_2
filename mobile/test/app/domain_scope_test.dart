import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/auth/auth_transport.dart';

import 'package:cuentas_claras_mobile/app/domain_scope.dart';
import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/repository_support.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/data/refresh/refresh_coordinator.dart';
import 'package:cuentas_claras_mobile/data/websocket/data_changed_listener.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';
import 'package:cuentas_claras_mobile/presentation/read_status.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_policy_mutation_cubit.dart';

void main() {
  test('owns all protected read cubits for one active group', () async {
    final scope = DomainScope(groupId: 'group-1');

    expect(scope.groupId, 'group-1');
    expect(scope.groupCubit.groupId, 'group-1');
    expect(scope.participantsCubit.groupId, 'group-1');
    expect(scope.expensesCubit.groupId, 'group-1');
    expect(scope.balancesCubit.groupId, 'group-1');
    expect(scope.settlementCubit.groupId, 'group-1');
    expect(scope.participantsMutationCubit, isNull);
    expect(scope.expenseMutationCubit, isNull);

    await scope.close();

    expect(scope.groupCubit.isClosed, isTrue);
    expect(scope.participantsCubit.isClosed, isTrue);
    expect(scope.expensesCubit.isClosed, isTrue);
    expect(scope.balancesCubit.isClosed, isTrue);
    expect(scope.settlementCubit.isClosed, isTrue);
  });

  test(
    'owns an optional policy mutation only when a group writer exists',
    () async {
      final unavailable = DomainReaders.unavailable();
      final readOnly = DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
      );
      final writable = DomainReaders(
        group: _ScopeGroupReader(),
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        groupWriter: _ScopeGroupWriter(),
      );
      final readOnlyScope = DomainScope(groupId: 'group-1', readers: readOnly);
      final writableScope = DomainScope(groupId: 'group-1', readers: writable);

      expect(readOnlyScope.policyMutationCubit, isNull);
      expect(
        writableScope.policyMutationCubit,
        isA<GroupPolicyMutationCubit>(),
      );

      await readOnlyScope.close();
      await writableScope.close();
      expect(writableScope.policyMutationCubit!.isClosed, isTrue);
    },
  );

  test(
    'only transport readers expose participant, expense, and group writers',
    () {
      final readers = DomainReaders.fromTransport(
        AuthTransport(baseUrl: 'https://api.example.test'),
      );
      final unavailable = DomainReaders.unavailable();
      final custom = DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
      );

      expect(readers.groupWriter, same(readers.group));
      expect(readers.groupWriter, isA<GroupRepository>());
      expect(readers.participantsWriter, same(readers.participants));
      expect(readers.participantsWriter, isA<ParticipantsRepository>());
      expect(readers.expensesWriter, same(readers.expenses));
      expect(readers.expensesWriter, isA<ExpensesRepository>());
      expect(unavailable.groupWriter, isNull);
      expect(unavailable.participantsWriter, isNull);
      expect(unavailable.expensesWriter, isNull);
      expect(custom.groupWriter, isNull);
      expect(custom.participantsWriter, isNull);
      expect(custom.expensesWriter, isNull);
    },
  );

  test(
    'owns an optional expense mutation and closes it with the scope',
    () async {
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
          expensesWriter: _ScopeExpensesWriter(),
        ),
      );

      expect(scope.expenseMutationCubit, isA<ExpenseMutationCubit>());
      await scope.close();
      await scope.close();
      expect(scope.expenseMutationCubit, isNotNull);
      expect(scope.expenseMutationCubit!.isClosed, isTrue);
    },
  );

  test(
    'refreshes expense-impact readers before reporting mutation success',
    () async {
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: _PendingParticipantsReader(
            Future.value(const <ParticipantReadModel>[]),
          ),
          expenses: _PendingExpensesReader(
            Future.value(const <ExpenseReadModel>[]),
          ),
          balances: _PendingBalancesReader(
            Future.value(
              const BalancesReadModel(groupId: 'group-1', participants: []),
            ),
          ),
          settlement: _PendingSettlementReader(
            Future.value(
              const SettlementReadModel(
                groupId: 'group-1',
                settlementPolicy: SettlementPolicy.ownerOnly,
                settled: true,
                transfers: [],
              ),
            ),
          ),
          expensesWriter: _ScopeExpensesWriter(),
        ),
      );

      await scope.expenseMutationCubit!.create(_validExpenseDraft);

      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(scope.participantsCubit.state.status, ReadStatus.empty);
      expect(scope.expensesCubit.state.status, ReadStatus.empty);
      expect(scope.balancesCubit.state.status, ReadStatus.empty);
      expect(scope.settlementCubit.state.status, ReadStatus.empty);
      await scope.close();
    },
  );

  test('does not call an expense writer after the scope is closed', () async {
    final unavailable = DomainReaders.unavailable();
    final writer = _ScopeExpensesWriter();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        expensesWriter: writer,
      ),
    );

    await scope.close();
    await scope.expenseMutationCubit!.create(_validExpenseDraft);

    expect(writer.calls, isEmpty);
  });

  test('closes expense mutation before a late submit completion', () async {
    final unavailable = DomainReaders.unavailable();
    final response = Completer<ExpenseReadModel>();
    final writer = _PendingScopeExpensesWriter(response.future);
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        expensesWriter: writer,
      ),
    );
    final mutation = scope.expenseMutationCubit!;
    final request = mutation.create(_validExpenseDraft);
    await Future<void>.delayed(Duration.zero);

    expect(mutation.state.status, ExpenseMutationStatus.loading);
    expect(writer.calls, ['create']);

    await scope.close();
    response.complete(_scopeExpense);
    await request;

    expect(mutation.isClosed, isTrue);
    expect(mutation.state.status, ExpenseMutationStatus.loading);
    expect(scope.refreshCoordinator.isClosed, isTrue);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
    expect(writer.calls, ['create']);
  });

  test(
    'awaits group refresh before reporting policy mutation success',
    () async {
      final response = Completer<GroupReadModel>();
      final writer = _PendingGroupWriter(response.future);
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: _PendingGroupReader(response.future),
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
          groupWriter: writer,
        ),
      );
      final mutation = scope.policyMutationCubit!;
      final request = mutation.update(SettlementPolicy.anyMember);
      await Future<void>.delayed(Duration.zero);
      expect(mutation.state.status, GroupPolicyMutationStatus.loading);
      expect(writer.policies, [SettlementPolicy.anyMember]);

      response.complete(
        const GroupReadModel(
          id: 'group-1',
          name: 'Trip',
          ownerAccountId: 'owner-1',
          settlementPolicy: SettlementPolicy.anyMember,
        ),
      );
      await request;

      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(mutation.state.status, GroupPolicyMutationStatus.success);
      expect(
        scope.groupCubit.state.group?.settlementPolicy,
        SettlementPolicy.anyMember,
      );
      await scope.close();
    },
  );

  test('closes policy mutation before late writer completion', () async {
    final response = Completer<GroupReadModel>();
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        groupWriter: _PendingGroupWriter(response.future),
      ),
    );
    final mutation = scope.policyMutationCubit!;
    final request = mutation.update(SettlementPolicy.anyMember);
    await Future<void>.delayed(Duration.zero);

    await scope.close();
    response.complete(
      const GroupReadModel(
        id: 'group-1',
        name: 'Trip',
        ownerAccountId: 'owner-1',
        settlementPolicy: SettlementPolicy.anyMember,
      ),
    );
    await request;

    expect(mutation.isClosed, isTrue);
    expect(mutation.state.status, GroupPolicyMutationStatus.loading);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
  });

  test('owns mutation and refreshes all participant-impact readers', () async {
    const participant = ParticipantReadModel(
      id: 'participant-1',
      groupId: 'group-1',
      name: 'Ana',
      archived: false,
    );
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: _PendingParticipantsReader(
          Future.value(const [participant]),
        ),
        expenses: _PendingExpensesReader(
          Future.value(const <ExpenseReadModel>[]),
        ),
        balances: _PendingBalancesReader(
          Future.value(
            const BalancesReadModel(groupId: 'group-1', participants: []),
          ),
        ),
        settlement: _PendingSettlementReader(
          Future.value(
            const SettlementReadModel(
              groupId: 'group-1',
              settlementPolicy: SettlementPolicy.ownerOnly,
              settled: true,
              transfers: [],
            ),
          ),
        ),
        participantsWriter: _SuccessfulParticipantsWriter(participant),
      ),
    );
    final mutation = scope.participantsMutationCubit;

    expect(mutation, isNotNull);
    await mutation!.add('Ana');

    expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
    expect(scope.participantsCubit.state.status, ReadStatus.loaded);
    expect(scope.expensesCubit.state.status, ReadStatus.empty);
    expect(scope.balancesCubit.state.status, ReadStatus.empty);
    expect(scope.settlementCubit.state.status, ReadStatus.empty);

    await scope.close();
    expect(mutation.isClosed, isTrue);
    await scope.close();
  });

  test('retries participant refresh through the scope coordinator', () async {
    const participant = ParticipantReadModel(
      id: 'participant-1',
      groupId: 'group-1',
      name: 'Ana',
      archived: false,
    );
    final participantsReader = _MutableParticipantsReader();
    final writer = _SuccessfulParticipantsWriter(participant);
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: participantsReader,
        expenses: _PendingExpensesReader(
          Future.value(const <ExpenseReadModel>[]),
        ),
        balances: _PendingBalancesReader(
          Future.value(
            const BalancesReadModel(groupId: 'group-1', participants: []),
          ),
        ),
        settlement: _PendingSettlementReader(
          Future.value(
            const SettlementReadModel(
              groupId: 'group-1',
              settlementPolicy: SettlementPolicy.ownerOnly,
              settled: true,
              transfers: [],
            ),
          ),
        ),
        participantsWriter: writer,
      ),
    );
    participantsReader.failure = StateError('refresh failed');
    final mutation = scope.participantsMutationCubit!;

    await mutation.add('Ana');

    expect(writer.commands, ['add']);
    expect(mutation.canRetryPostMutationRefresh, isTrue);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.failed);

    participantsReader.failure = null;
    await mutation.retryPostMutationRefresh();

    expect(writer.commands, ['add']);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
    expect(mutation.state.status, ParticipantsMutationStatus.success);
    await scope.close();
  });

  test(
    'does not publish a protected result after logout closes a loading scope',
    () async {
      final response = Completer<GroupReadModel>();
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: _PendingGroupReader(response.future),
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
        ),
      );

      final load = scope.groupCubit.load();
      await Future<void>.delayed(Duration.zero);
      await scope.close();
      response.complete(
        const GroupReadModel(
          id: 'group-1',
          name: 'Protected group',
          ownerAccountId: 'account-1',
          settlementPolicy: SettlementPolicy.ownerOnly,
        ),
      );
      await load;

      expect(scope.groupCubit.isClosed, isTrue);
    },
  );

  test(
    'does not publish a protected error after logout closes a loading scope',
    () async {
      final response = Completer<GroupReadModel>();
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: _PendingGroupReader(response.future),
          participants: unavailable.participants,
          expenses: unavailable.expenses,
          balances: unavailable.balances,
          settlement: unavailable.settlement,
        ),
      );

      final load = scope.groupCubit.load();
      await Future<void>.delayed(Duration.zero);
      await scope.close();
      response.completeError(StateError('connection closed'));
      await load;

      expect(scope.groupCubit.isClosed, isTrue);
    },
  );

  test(
    'does not publish late read successes after logout closes the scope',
    () async {
      final participantsResponse = Completer<List<ParticipantReadModel>>();
      final expensesResponse = Completer<List<ExpenseReadModel>>();
      final balancesResponse = Completer<BalancesReadModel>();
      final settlementResponse = Completer<SettlementReadModel>();
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: _PendingParticipantsReader(participantsResponse.future),
          expenses: _PendingExpensesReader(expensesResponse.future),
          balances: _PendingBalancesReader(balancesResponse.future),
          settlement: _PendingSettlementReader(settlementResponse.future),
        ),
      );

      final loads = <Future<void>>[
        scope.participantsCubit.load(),
        scope.expensesCubit.load(),
        scope.balancesCubit.load(),
        scope.settlementCubit.load(),
      ];
      await Future<void>.delayed(Duration.zero);
      await scope.close();

      participantsResponse.complete([
        const ParticipantReadModel(
          id: 'participant-1',
          groupId: 'group-1',
          name: 'Ana',
          archived: false,
        ),
      ]);
      expensesResponse.complete([
        const ExpenseReadModel(
          id: 'expense-1',
          groupId: 'group-1',
          description: 'Lunch',
          amountCents: 1200,
          contributors: [],
          beneficiaries: [],
        ),
      ]);
      balancesResponse.complete(
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
        ),
      );
      settlementResponse.complete(
        const SettlementReadModel(
          groupId: 'group-1',
          settlementPolicy: SettlementPolicy.ownerOnly,
          settled: false,
          transfers: [
            SettlementTransferReadModel(
              fromParticipantId: 'participant-2',
              fromName: 'Beto',
              toParticipantId: 'participant-1',
              toName: 'Ana',
              amountCents: 1200,
            ),
          ],
        ),
      );

      await Future.wait(loads);

      expect(scope.participantsCubit.isClosed, isTrue);
      expect(scope.expensesCubit.isClosed, isTrue);
      expect(scope.balancesCubit.isClosed, isTrue);
      expect(scope.settlementCubit.isClosed, isTrue);
    },
  );

  test(
    'does not publish late read failures after logout closes the scope',
    () async {
      final participantsResponse = Completer<List<ParticipantReadModel>>();
      final expensesResponse = Completer<List<ExpenseReadModel>>();
      final balancesResponse = Completer<BalancesReadModel>();
      final settlementResponse = Completer<SettlementReadModel>();
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: _PendingParticipantsReader(participantsResponse.future),
          expenses: _PendingExpensesReader(expensesResponse.future),
          balances: _PendingBalancesReader(balancesResponse.future),
          settlement: _PendingSettlementReader(settlementResponse.future),
        ),
      );

      final loads = <Future<void>>[
        scope.participantsCubit.load(),
        scope.expensesCubit.load(),
        scope.balancesCubit.load(),
        scope.settlementCubit.load(),
      ];
      await Future<void>.delayed(Duration.zero);
      await scope.close();

      participantsResponse.completeError(StateError('participants closed'));
      expensesResponse.completeError(StateError('expenses closed'));
      balancesResponse.completeError(StateError('balances closed'));
      settlementResponse.completeError(StateError('settlement closed'));

      await Future.wait(loads);

      expect(scope.participantsCubit.isClosed, isTrue);
      expect(scope.expensesCubit.isClosed, isTrue);
      expect(scope.balancesCubit.isClosed, isTrue);
      expect(scope.settlementCubit.isClosed, isTrue);
    },
  );

  test('closes participant mutation before late writer completion', () async {
    final response = Completer<ParticipantReadModel>();
    final unavailable = DomainReaders.unavailable();
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: unavailable.group,
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
        participantsWriter: _PendingParticipantsWriter(response.future),
      ),
    );
    final mutation = scope.participantsMutationCubit!;
    final request = mutation.add('Ana');
    await Future<void>.delayed(Duration.zero);
    expect(mutation.state.status, ParticipantsMutationStatus.loading);

    await scope.close();
    response.complete(_activeParticipant);
    await request;

    expect(mutation.isClosed, isTrue);
    expect(mutation.state.status, ParticipantsMutationStatus.loading);
    expect(scope.refreshCoordinator.isClosed, isTrue);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
    expect(scope.participantsCubit.state.status, ReadStatus.loading);
  });

  test(
    'suppresses late participant mutation success after refresh close',
    () async {
      final response = Completer<List<ParticipantReadModel>>();
      final scope = _scopeWithPendingParticipantRefresh(response.future);
      final mutation = scope.participantsMutationCubit!;
      final request = mutation.add('Ana');
      await Future<void>.delayed(Duration.zero);
      expect(scope.refreshCoordinator.state.status, RefreshStatus.refreshing);
      expect(mutation.state.status, ParticipantsMutationStatus.loading);

      await scope.close();
      response.complete(const [_activeParticipant]);
      await request;

      expect(mutation.isClosed, isTrue);
      expect(mutation.state.status, ParticipantsMutationStatus.loading);
      expect(scope.refreshCoordinator.isClosed, isTrue);
      expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
      expect(scope.participantsCubit.state.status, ReadStatus.loading);
    },
  );

  test(
    'suppresses late participant mutation failure after refresh close',
    () async {
      final response = Completer<List<ParticipantReadModel>>();
      final scope = _scopeWithPendingParticipantRefresh(response.future);
      final mutation = scope.participantsMutationCubit!;
      final request = mutation.add('Ana');
      await Future<void>.delayed(Duration.zero);
      expect(scope.refreshCoordinator.state.status, RefreshStatus.refreshing);
      expect(mutation.state.status, ParticipantsMutationStatus.loading);

      await scope.close();
      response.completeError(StateError('late refresh failure'));
      await request;

      expect(mutation.isClosed, isTrue);
      expect(mutation.state.status, ParticipantsMutationStatus.loading);
      expect(scope.refreshCoordinator.isClosed, isTrue);
      expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
      expect(scope.participantsCubit.state.status, ReadStatus.loading);
    },
  );

  test(
    'does not start read loads after the protected scope is closed',
    () async {
      final scope = DomainScope(groupId: 'group-1');
      await scope.close();

      await Future.wait([
        scope.participantsCubit.load(),
        scope.expensesCubit.load(),
        scope.balancesCubit.load(),
        scope.settlementCubit.load(),
      ]);

      expect(scope.participantsCubit.isClosed, isTrue);
      expect(scope.expensesCubit.isClosed, isTrue);
      expect(scope.balancesCubit.isClosed, isTrue);
      expect(scope.settlementCubit.isClosed, isTrue);
    },
  );

  test('routes invalidations through the scope-owned coordinator', () async {
    final controller = StreamController<Object?>();
    final listener = DataChangedListener(frames: controller.stream);
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: _PendingGroupReader(
          Future.value(
            const GroupReadModel(
              id: 'group-1',
              name: 'Protected group',
              ownerAccountId: 'account-1',
              settlementPolicy: SettlementPolicy.ownerOnly,
            ),
          ),
        ),
        participants: _PendingParticipantsReader(
          Future.value(const <ParticipantReadModel>[]),
        ),
        expenses: _PendingExpensesReader(
          Future.value(const <ExpenseReadModel>[]),
        ),
        balances: _PendingBalancesReader(
          Future.value(
            const BalancesReadModel(groupId: 'group-1', participants: []),
          ),
        ),
        settlement: _PendingSettlementReader(
          Future.value(
            const SettlementReadModel(
              groupId: 'group-1',
              settlementPolicy: SettlementPolicy.ownerOnly,
              settled: true,
              transfers: [],
            ),
          ),
        ),
      ),
      listener: listener,
    );

    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
    controller.add({'type': 'data_changed', 'impact': 'participant'});
    await Future<void>.delayed(Duration.zero);

    expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
    expect(scope.refreshCoordinator.state.canRetry, isFalse);

    await scope.close();
    await controller.close();
  });

  test('closes coordinator ownership during an invalidation reload', () async {
    final response = Completer<GroupReadModel>();
    final unavailable = DomainReaders.unavailable();
    final controller = StreamController<Object?>();
    final listener = DataChangedListener(frames: controller.stream);
    final scope = DomainScope(
      groupId: 'group-1',
      readers: DomainReaders(
        group: _PendingGroupReader(response.future),
        participants: unavailable.participants,
        expenses: unavailable.expenses,
        balances: unavailable.balances,
        settlement: unavailable.settlement,
      ),
      listener: listener,
    );

    controller.add({'type': 'data_changed'});
    await Future<void>.delayed(Duration.zero);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.refreshing);

    await scope.close();

    expect(listener.isListening, isFalse);
    expect(scope.refreshCoordinator.isClosed, isTrue);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
    response.complete(
      const GroupReadModel(
        id: 'group-1',
        name: 'Protected group',
        ownerAccountId: 'account-1',
        settlementPolicy: SettlementPolicy.ownerOnly,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
    await controller.close();
  });

  test(
    'closes the coordinator and invalidation subscription with scope',
    () async {
      final controller = StreamController<Object?>();
      final listener = DataChangedListener(frames: controller.stream)..start();
      final scope = DomainScope(groupId: 'group-1', listener: listener);

      await scope.close();

      expect(listener.isListening, isFalse);
      expect(scope.refreshCoordinator.isClosed, isTrue);
      controller.add({'type': 'data_changed'});
      await Future<void>.delayed(Duration.zero);
      expect(scope.refreshCoordinator.state.status, RefreshStatus.idle);
      await controller.close();
    },
  );

  test('keeps 401 and 403 refresh failures distinct and retryable', () async {
    final failures = {
      401: 'Your session expired. Please sign in again.',
      403: 'You are not authorized to view group.',
    };
    for (final entry in failures.entries) {
      final reader = _MutableGroupReader();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: reader,
          participants: DomainReaders.unavailable().participants,
          expenses: DomainReaders.unavailable().expenses,
          balances: DomainReaders.unavailable().balances,
          settlement: DomainReaders.unavailable().settlement,
        ),
      );
      await scope.groupCubit.load();
      reader.failure = DioException(
        requestOptions: RequestOptions(path: '/groups/group-1'),
        response: Response<dynamic>(
          statusCode: entry.key,
          requestOptions: RequestOptions(path: '/groups/group-1'),
        ),
      );

      await expectLater(
        scope.refreshCoordinator.refresh(RefreshImpact.policy),
        throwsA(isA<DioException>()),
      );
      expect(scope.groupCubit.state.status, ReadStatus.error);
      expect(scope.groupCubit.state.message, entry.value);
      expect(scope.refreshCoordinator.state.canRetry, isTrue);

      reader.failure = null;
      await scope.refreshCoordinator.retry();
      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(scope.groupCubit.state.status, ReadStatus.loaded);
      await scope.close();
    }
  });

  test(
    'keeps corrupt refresh data recoverable without local replacement',
    () async {
      final reader = _MutableGroupReader();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: reader,
          participants: DomainReaders.unavailable().participants,
          expenses: DomainReaders.unavailable().expenses,
          balances: DomainReaders.unavailable().balances,
          settlement: DomainReaders.unavailable().settlement,
        ),
      );
      await scope.groupCubit.load();
      reader.failure = const ReadRepositoryException(
        'The server returned incomplete group data.',
        isCorruption: true,
      );

      await expectLater(
        scope.refreshCoordinator.refresh(RefreshImpact.policy),
        throwsA(isA<ReadRepositoryException>()),
      );
      expect(scope.groupCubit.state.status, ReadStatus.corruptionRecovery);
      expect(scope.groupCubit.state.group, isNull);
      expect(scope.refreshCoordinator.state.canRetry, isTrue);

      reader.failure = null;
      await scope.refreshCoordinator.retry();
      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(scope.groupCubit.state.status, ReadStatus.loaded);
      expect(scope.groupCubit.state.group?.name, 'Protected group');
      await scope.close();
    },
  );

  test(
    'uses REST read models after data_changed without trusting frame values',
    () async {
      const restGroup = GroupReadModel(
        id: 'group-1',
        name: 'REST group',
        ownerAccountId: 'rest-owner',
        settlementPolicy: SettlementPolicy.anyMember,
      );
      const restParticipant = ParticipantReadModel(
        id: 'participant-1',
        groupId: 'group-1',
        name: 'REST Ana',
        archived: false,
      );
      const restExpense = ExpenseReadModel(
        id: 'expense-1',
        groupId: 'group-1',
        description: 'REST dinner',
        amountCents: 1200,
        contributors: [
          ExpenseContributorReadModel(
            participantId: 'participant-1',
            name: 'REST Ana',
            archived: false,
            amountCents: 700,
          ),
        ],
        beneficiaries: [
          ExpenseBeneficiaryReadModel(
            participantId: 'participant-1',
            name: 'REST Ana',
            archived: false,
          ),
        ],
      );
      const restBalances = BalancesReadModel(
        groupId: 'group-1',
        participants: [
          BalanceParticipantReadModel(
            participantId: 'participant-1',
            name: 'REST Ana',
            archived: false,
            paidCents: 1200,
            owedCents: 700,
            balanceCents: 500,
          ),
        ],
      );
      const restSettlement = SettlementReadModel(
        groupId: 'group-1',
        settlementPolicy: SettlementPolicy.anyMember,
        settled: false,
        transfers: [
          SettlementTransferReadModel(
            fromParticipantId: 'participant-2',
            fromName: 'REST Beto',
            toParticipantId: 'participant-1',
            toName: 'REST Ana',
            amountCents: 500,
          ),
        ],
      );
      final controller = StreamController<Object?>();
      final scope = DomainScope(
        groupId: 'group-1',

        readers: DomainReaders(
          group: _PendingGroupReader(Future.value(restGroup)),
          participants: _PendingParticipantsReader(
            Future.value(const [restParticipant]),
          ),
          expenses: _PendingExpensesReader(Future.value(const [restExpense])),
          balances: _PendingBalancesReader(Future.value(restBalances)),
          settlement: _PendingSettlementReader(Future.value(restSettlement)),
        ),
        listener: DataChangedListener(frames: controller.stream),
      );

      controller.add({
        'type': 'data_changed',
        'impact': 'participant',
        'group': {'name': 'forged group'},
        'participant': {'name': 'forged participant'},
        'expense': {'amount_cents': 999999},
        'balance_cents': 999999,
        'settlement': {'amount_cents': 999999},
        'residual_cents': 999999,
        'role': 'owner',
      });
      await Future<void>.delayed(Duration.zero);

      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(scope.groupCubit.state.group?.name, 'REST group');
      expect(
        scope.groupCubit.state.group?.settlementPolicy,
        SettlementPolicy.anyMember,
      );
      expect(
        scope.participantsCubit.state.participants.single.name,
        'REST Ana',
      );
      final expense = scope.expensesCubit.state.expenses.single;
      expect(expense.description, 'REST dinner');
      expect(expense.amountCents, 1200);
      expect(expense.contributors.single.amountCents, 700);
      final balance = scope.balancesCubit.state.balances!.participants.single;
      expect(balance.paidCents, 1200);
      expect(balance.owedCents, 700);
      expect(balance.balanceCents, 500);
      final settlement = scope.settlementCubit.state.settlement!;
      expect(settlement.settled, isFalse);
      expect(settlement.transfers.single.amountCents, 500);
      expect(settlement.transfers.single.fromName, 'REST Beto');

      await scope.close();
      await controller.close();
    },
  );

  test(
    'does not fabricate derived data after incomplete REST reloads and retries',
    () async {
      const restBalances = BalancesReadModel(
        groupId: 'group-1',
        participants: [
          BalanceParticipantReadModel(
            participantId: 'participant-1',
            name: 'REST Ana',
            archived: false,
            paidCents: 1200,
            owedCents: 700,
            balanceCents: 500,
          ),
        ],
      );
      const restSettlement = SettlementReadModel(
        groupId: 'group-1',
        settlementPolicy: SettlementPolicy.ownerOnly,
        settled: false,
        transfers: [
          SettlementTransferReadModel(
            fromParticipantId: 'participant-2',
            fromName: 'REST Beto',
            toParticipantId: 'participant-1',
            toName: 'REST Ana',
            amountCents: 500,
          ),
        ],
      );
      final balancesReader = _MutableBalancesReader(restBalances);
      final settlementReader = _MutableSettlementReader(restSettlement);
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: _PendingParticipantsReader(
            Future.value(const <ParticipantReadModel>[]),
          ),
          expenses: _PendingExpensesReader(
            Future.value(const <ExpenseReadModel>[]),
          ),
          balances: balancesReader,
          settlement: settlementReader,
        ),
      );

      await Future.wait<void>([
        scope.participantsCubit.load(),
        scope.expensesCubit.load(),
        scope.balancesCubit.load(),
        scope.settlementCubit.load(),
      ]);
      balancesReader.failure = const ReadRepositoryException(
        'The server returned incomplete balances data.',
        isCorruption: true,
      );
      settlementReader.failure = const ReadRepositoryException(
        'The server returned incomplete settlement data.',
        isCorruption: true,
      );

      await expectLater(
        scope.refreshCoordinator.refresh(RefreshImpact.expense),
        throwsA(isA<ReadRepositoryException>()),
      );

      expect(scope.balancesCubit.state.status, ReadStatus.corruptionRecovery);
      expect(scope.balancesCubit.state.balances, isNull);
      expect(scope.settlementCubit.state.status, ReadStatus.corruptionRecovery);
      expect(scope.settlementCubit.state.settlement, isNull);
      expect(scope.refreshCoordinator.state.targets, {
        RefreshTarget.balances,
        RefreshTarget.settlement,
      });
      expect(scope.refreshCoordinator.state.canRetry, isTrue);

      balancesReader.failure = null;
      settlementReader.failure = null;
      await scope.refreshCoordinator.retry();

      expect(scope.refreshCoordinator.state.status, RefreshStatus.ready);
      expect(
        scope.balancesCubit.state.balances!.participants.single.balanceCents,
        500,
      );
      expect(
        scope.settlementCubit.state.settlement!.transfers.single.amountCents,
        500,
      );
      await scope.close();
    },
  );

  test(
    'refreshes archive/reactivate transitions from server read state',
    () async {
      const active = ParticipantReadModel(
        id: 'participant-1',
        groupId: 'group-1',
        name: 'Ana',
        archived: false,
      );
      const archived = ParticipantReadModel(
        id: 'participant-1',
        groupId: 'group-1',
        name: 'Ana',
        archived: true,
      );
      final participantsReader = _MutableParticipantsReader()
        ..data = const [active];
      final writer = _LifecycleParticipantsWriter(
        reader: participantsReader,
        active: active,
        archived: archived,
      );
      final unavailable = DomainReaders.unavailable();
      final scope = DomainScope(
        groupId: 'group-1',
        readers: DomainReaders(
          group: unavailable.group,
          participants: participantsReader,
          expenses: _PendingExpensesReader(
            Future.value(const <ExpenseReadModel>[]),
          ),
          balances: _PendingBalancesReader(
            Future.value(
              const BalancesReadModel(groupId: 'group-1', participants: []),
            ),
          ),
          settlement: _PendingSettlementReader(
            Future.value(
              const SettlementReadModel(
                groupId: 'group-1',
                settlementPolicy: SettlementPolicy.ownerOnly,
                settled: true,
                transfers: [],
              ),
            ),
          ),
          participantsWriter: writer,
        ),
      );

      await scope.participantsCubit.load();
      final mutation = scope.participantsMutationCubit!;
      await mutation.archive(active.id);
      expect(
        scope.participantsCubit.state.participants.single.archived,
        isTrue,
      );
      expect(writer.commands, ['archive']);

      await mutation.reactivate(active.id);
      expect(
        scope.participantsCubit.state.participants.single.archived,
        isFalse,
      );
      expect(writer.commands, ['archive', 'reactivate']);
      await scope.close();
    },
  );
}

const _activeParticipant = ParticipantReadModel(
  id: 'participant-1',
  groupId: 'group-1',
  name: 'Ana',
  archived: false,
);

DomainScope _scopeWithPendingParticipantRefresh(
  Future<List<ParticipantReadModel>> response,
) {
  final unavailable = DomainReaders.unavailable();
  return DomainScope(
    groupId: 'group-1',
    readers: DomainReaders(
      group: unavailable.group,
      participants: _PendingParticipantsReader(response),
      expenses: _PendingExpensesReader(
        Future.value(const <ExpenseReadModel>[]),
      ),
      balances: _PendingBalancesReader(
        Future.value(
          const BalancesReadModel(groupId: 'group-1', participants: []),
        ),
      ),
      settlement: _PendingSettlementReader(
        Future.value(
          const SettlementReadModel(
            groupId: 'group-1',
            settlementPolicy: SettlementPolicy.ownerOnly,
            settled: true,
            transfers: [],
          ),
        ),
      ),
      participantsWriter: _SuccessfulParticipantsWriter(_activeParticipant),
    ),
  );
}

class _MutableGroupReader implements GroupReader {
  Object? failure;

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    if (failure != null) throw failure!;
    return const GroupReadModel(
      id: 'group-1',
      name: 'Protected group',
      ownerAccountId: 'account-1',
      settlementPolicy: SettlementPolicy.ownerOnly,
    );
  }
}

class _LifecycleParticipantsWriter implements ParticipantsWriter {
  _LifecycleParticipantsWriter({
    required this.reader,
    required this.active,
    required this.archived,
  });

  final _MutableParticipantsReader reader;
  final ParticipantReadModel active;
  final ParticipantReadModel archived;
  final commands = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #archiveParticipant:
        commands.add('archive');
        reader.data = [archived];
        return Future<ParticipantReadModel>.value(archived);
      case #reactivateParticipant:
        commands.add('reactivate');
        reader.data = [active];
        return Future<ParticipantReadModel>.value(active);
      default:
        throw UnimplementedError(invocation.memberName.toString());
    }
  }
}

class _MutableParticipantsReader implements ParticipantsReader {
  Object? failure;
  List<ParticipantReadModel> data = const [];

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async {
    if (failure != null) throw failure!;
    return data;
  }
}

class _MutableBalancesReader implements BalancesReader {
  _MutableBalancesReader(this.data);

  final BalancesReadModel data;
  Object? failure;

  @override
  Future<BalancesReadModel> getBalances(String groupId) async {
    if (failure != null) throw failure!;
    return data;
  }
}

class _MutableSettlementReader implements SettlementReader {
  _MutableSettlementReader(this.data);

  final SettlementReadModel data;
  Object? failure;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async {
    if (failure != null) throw failure!;
    return data;
  }
}

class _PendingParticipantsReader implements ParticipantsReader {
  _PendingParticipantsReader(this.response);

  final Future<List<ParticipantReadModel>> response;

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) =>
      response;
}

class _PendingExpensesReader implements ExpensesReader {
  _PendingExpensesReader(this.response);

  final Future<List<ExpenseReadModel>> response;

  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) => response;
}

class _PendingBalancesReader implements BalancesReader {
  _PendingBalancesReader(this.response);

  final Future<BalancesReadModel> response;

  @override
  Future<BalancesReadModel> getBalances(String groupId) => response;
}

class _PendingSettlementReader implements SettlementReader {
  _PendingSettlementReader(this.response);

  final Future<SettlementReadModel> response;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) => response;
}

class _PendingParticipantsWriter implements ParticipantsWriter {
  _PendingParticipantsWriter(this.response);

  final Future<ParticipantReadModel> response;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #addParticipant) {
      throw UnimplementedError();
    }
    return response;
  }
}

class _ScopeExpensesWriter implements ExpensesWriter {
  final calls = <String>[];

  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async {
    calls.add('create');
    return _scopeExpense;
  }

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async {
    calls.add('edit:$expenseId');
    return _scopeExpense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    calls.add('delete:$expenseId');
  }
}

class _PendingScopeExpensesWriter implements ExpensesWriter {
  _PendingScopeExpensesWriter(this.response);

  final Future<ExpenseReadModel> response;
  final calls = <String>[];

  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async {
    calls.add('create');
    return response;
  }

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async => _scopeExpense;

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {}
}

final _validExpenseDraft = ExpenseWriteDraft(
  description: 'Dinner',
  amount: ExpenseAmount.parse('10.00'),
  contributors: [
    ExpenseContributorDraft(
      participantId: 'participant-1',
      amount: ExpenseAmount.parse('10.00'),
    ),
  ],
  beneficiaryIds: ['participant-1'],
);

const _scopeExpense = ExpenseReadModel(
  id: 'expense-1',
  groupId: 'group-1',
  description: 'Dinner',
  amountCents: 1000,
  contributors: [],
  beneficiaries: [],
);

class _SuccessfulParticipantsWriter implements ParticipantsWriter {
  _SuccessfulParticipantsWriter(this.participant);

  final ParticipantReadModel participant;
  final commands = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final command = switch (invocation.memberName) {
      #addParticipant => 'add',
      #renameParticipant => 'rename',
      #archiveParticipant => 'archive',
      #reactivateParticipant => 'reactivate',
      #deleteParticipant => 'delete',
      _ => throw UnimplementedError(),
    };
    commands.add(command);
    if (command == 'delete') return Future<void>.value();
    return Future<ParticipantReadModel>.value(participant);
  }
}

class _PendingGroupReader implements GroupReader {
  _PendingGroupReader(this.response);

  final Future<GroupReadModel> response;

  @override
  Future<GroupReadModel> getGroup(String groupId) => response;
}

class _ScopeGroupReader implements GroupReader {
  @override
  Future<GroupReadModel> getGroup(String groupId) async => const GroupReadModel(
    id: 'group-1',
    name: 'Trip',
    ownerAccountId: 'owner-1',
    settlementPolicy: SettlementPolicy.ownerOnly,
  );
}

class _ScopeGroupWriter implements GroupWriter {
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

class _PendingGroupWriter implements GroupWriter {
  _PendingGroupWriter(this.response);

  final Future<GroupReadModel> response;
  final policies = <SettlementPolicy>[];

  @override
  Future<GroupReadModel> updateSettlementPolicy(
    String groupId,
    SettlementPolicy policy,
  ) {
    policies.add(policy);
    return response;
  }
}
