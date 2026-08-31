import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/repository_support.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/read_status.dart';
import 'package:cuentas_claras_mobile/presentation/balances/balances_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expenses_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/settlement/settlement_cubit.dart';

void main() {
  test(
    'read cubits expose loading, loaded, empty, error, and recovery states',
    () async {
      final groupReader = _GroupReader();
      final groupCubit = GroupCubit(reader: groupReader, groupId: 'group-1');
      expect(groupCubit.state.status, ReadStatus.loading);

      await groupCubit.load();
      expect(groupCubit.state.status, ReadStatus.loaded);
      expect(groupCubit.state.group?.name, 'Samaipata');

      groupReader.failure = StateError('offline');
      await groupCubit.reload();
      expect(groupCubit.state.status, ReadStatus.error);
      expect(groupCubit.state.message, contains('offline'));

      groupReader.failure = const ReadRepositoryException(
        'The server returned invalid group data.',
        isCorruption: true,
      );
      await groupCubit.reload();
      expect(groupCubit.state.status, ReadStatus.corruptionRecovery);
      await groupCubit.close();
    },
  );

  test('list read cubits distinguish empty data from an error', () async {
    final participantsReader = _ParticipantsReader();
    final participantsCubit = ParticipantsCubit(
      reader: participantsReader,
      groupId: 'group-1',
    );
    await participantsCubit.load();
    expect(participantsCubit.state.status, ReadStatus.empty);

    participantsReader.data = [
      const ParticipantReadModel(
        id: 'ana-id',
        groupId: 'group-1',
        name: 'Ana',
        archived: false,
      ),
    ];
    await participantsCubit.reload();
    expect(participantsCubit.state.status, ReadStatus.loaded);
    expect(participantsCubit.state.participants.single.name, 'Ana');

    final expensesCubit = ExpensesCubit(
      reader: _ExpensesReader(),
      groupId: 'group-1',
    );
    await expensesCubit.load();
    expect(expensesCubit.state.status, ReadStatus.empty);

    final balancesCubit = BalancesCubit(
      reader: _EmptyBalancesReader(),
      groupId: 'group-1',
    );
    await balancesCubit.load();
    expect(balancesCubit.state.status, ReadStatus.empty);

    final settlementCubit = SettlementCubit(
      reader: _SettlementReader(
        const SettlementReadModel(
          groupId: 'group-1',
          settlementPolicy: SettlementPolicy.ownerOnly,
          settled: true,
          transfers: [],
        ),
      ),
      groupId: 'group-1',
    );
    await settlementCubit.load();
    expect(settlementCubit.state.status, ReadStatus.empty);
    expect(settlementCubit.state.settlement?.settled, isTrue);

    await participantsCubit.close();
    await expensesCubit.close();
    await balancesCubit.close();
    await settlementCubit.close();
  });

  test('reload can be called after startup and refetches REST state', () async {
    final reader = _BalancesReader();
    final cubit = BalancesCubit(reader: reader, groupId: 'group-1');

    await cubit.load();
    await cubit.reload();

    expect(reader.calls, 2);
    expect(cubit.state.status, ReadStatus.loaded);
    await cubit.close();
  });
}

GroupReadModel group() => const GroupReadModel(
  id: 'group-1',
  name: 'Samaipata',
  ownerAccountId: 'account-1',
  settlementPolicy: SettlementPolicy.ownerOnly,
);

class _GroupReader implements GroupReader {
  Object? failure;

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    if (failure != null) throw failure!;
    return group();
  }
}

class _ParticipantsReader implements ParticipantsReader {
  List<ParticipantReadModel> data = const [];

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async =>
      data;
}

class _ExpensesReader implements ExpensesReader {
  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async => const [];
}

class _EmptyBalancesReader implements BalancesReader {
  @override
  Future<BalancesReadModel> getBalances(String groupId) async =>
      const BalancesReadModel(groupId: 'group-1', participants: []);
}

class _BalancesReader implements BalancesReader {
  var calls = 0;

  @override
  Future<BalancesReadModel> getBalances(String groupId) async {
    calls++;
    return const BalancesReadModel(
      groupId: 'group-1',
      participants: [
        BalanceParticipantReadModel(
          participantId: 'ana-id',
          name: 'Ana',
          archived: false,
          paidCents: 56000,
          owedCents: 0,
          balanceCents: 56000,
        ),
      ],
    );
  }
}

class _SettlementReader implements SettlementReader {
  _SettlementReader(this.data);

  final SettlementReadModel data;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async => data;
}
