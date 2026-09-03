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
import 'package:cuentas_claras_mobile/presentation/read_status.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';

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

    await scope.close();

    expect(scope.groupCubit.isClosed, isTrue);
    expect(scope.participantsCubit.isClosed, isTrue);
    expect(scope.expensesCubit.isClosed, isTrue);
    expect(scope.balancesCubit.isClosed, isTrue);
    expect(scope.settlementCubit.isClosed, isTrue);
  });

  test('only transport readers expose a participant writer', () {
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

    expect(readers.participantsWriter, same(readers.participants));
    expect(readers.participantsWriter, isA<ParticipantsRepository>());
    expect(unavailable.participantsWriter, isNull);
    expect(custom.participantsWriter, isNull);
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

class _MutableParticipantsReader implements ParticipantsReader {
  Object? failure;

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async {
    if (failure != null) throw failure!;
    return const [];
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
