import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/repositories/repository_support.dart';
import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';

Response<T> response<T>(T? data) => Response<T>(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: '/api/v1/groups/group-1'),
);

void main() {
  test('maps the group response through the read repository', () async {
    final operations = _FakeGroupOperations(
      GroupResponse(
        id: 'group-1',
        name: 'Samaipata',
        ownerAccountId: 'account-1',
        settlementPolicy: GroupResponseSettlementPolicyEnum.ownerOnly,
      ),
    );

    final group = await GroupRepository(
      operations: operations,
    ).getGroup('group-1');

    expect(group.name, 'Samaipata');
    expect(group.settlementPolicy, SettlementPolicy.ownerOnly);
    expect(operations.groupId, 'group-1');
  });

  test('maps current renamed and archived participant names', () async {
    final participants = await ParticipantsRepository(
      operations: _FakeParticipantsOperations([
        ParticipantResponse(
          id: 'ana-id',
          groupId: 'group-1',
          name: 'Ana Renamed',
          archived: false,
          createdAt: DateTime.utc(2026, 8, 26),
        ),
        ParticipantResponse(
          id: 'diego-id',
          groupId: 'group-1',
          name: 'Diego',
          archived: true,
          createdAt: DateTime.utc(2026, 8, 27),
        ),
      ]),
    ).listParticipants('group-1');

    expect(participants.map((item) => item.name), ['Ana Renamed', 'Diego']);
    expect(participants.last.archived, isTrue);
    expect(participants.last.id, 'diego-id');
  });

  test('maps expense history with server-resolved participant names', () async {
    final expenses = await ExpensesRepository(
      operations: _FakeExpensesOperations([
        ExpenseResponse(
          id: 'expense-1',
          groupId: 'group-1',
          description: 'Lodging',
          amountCents: 96000,
          createdAt: DateTime.utc(2026, 8, 26),
          updatedAt: DateTime.utc(2026, 8, 26),
          contributors: [
            ExpenseContributorResponse(
              participantId: 'ana-id',
              name: 'Ana Renamed',
              archived: false,
              amountCents: 96000,
            ),
          ],
          beneficiaries: [
            ExpenseBeneficiaryResponse(
              participantId: 'diego-id',
              name: 'Diego',
              archived: true,
            ),
          ],
        ),
      ]),
    ).listExpenses('group-1');

    expect(expenses.single.amountCents, 96000);
    expect(expenses.single.contributors.single.name, 'Ana Renamed');
    expect(expenses.single.beneficiaries.single.archived, isTrue);
  });

  test('maps balances and settlement without recalculating money', () async {
    final balances = await BalancesRepository(
      operations: _FakeBalancesOperations(
        BalancesResponse(
          groupId: 'group-1',
          participants: [
            BalanceParticipantResponse(
              participantId: 'ana-id',
              name: 'Ana',
              archived: false,
              paidCents: 96000,
              owedCents: 40000,
              balanceCents: 56000,
            ),
            BalanceParticipantResponse(
              participantId: 'archived-id',
              name: 'Former guest',
              archived: true,
              paidCents: 0,
              owedCents: 0,
              balanceCents: 0,
            ),
          ],
        ),
      ),
    ).getBalances('group-1');
    final settlement = await SettlementRepository(
      operations: _FakeSettlementOperations(
        SettlementResponse(
          groupId: 'group-1',
          settlementPolicy: SettlementResponseSettlementPolicyEnum.ownerOnly,
          settled: false,
          transfers: [
            SettlementTransferResponse(
              fromParticipantId: 'diego-id',
              fromName: 'Diego',
              toParticipantId: 'ana-id',
              toName: 'Ana',
              amountCents: 40000,
            ),
          ],
        ),
      ),
    ).getSettlement('group-1');

    expect(balances.participants.first.balanceCents, 56000);
    expect(balances.participants.last.archived, isTrue);
    expect(balances.participants.last.balanceCents, 0);
    expect(settlement.transfers.single.amountCents, 40000);
    expect(settlement.transfers.single.fromName, 'Diego');
  });

  test('turns a missing response body into a corruption failure', () async {
    final repository = GroupRepository(operations: _FakeGroupOperations(null));

    await expectLater(
      repository.getGroup('group-1'),
      throwsA(
        isA<ReadRepositoryException>().having(
          (error) => error.isCorruption,
          'isCorruption',
          isTrue,
        ),
      ),
    );
  });
}

class _FakeGroupOperations implements GroupOperations {
  _FakeGroupOperations(this.data);

  final GroupResponse? data;
  String? groupId;

  @override
  Future<Response<GroupResponse>> getGroup({required String groupId}) async {
    this.groupId = groupId;
    return response(data);
  }
}

class _FakeParticipantsOperations implements ParticipantsOperations {
  _FakeParticipantsOperations(this.data);

  final List<ParticipantResponse> data;

  @override
  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  }) async => response(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExpensesOperations implements ExpensesOperations {
  _FakeExpensesOperations(this.data);

  final List<ExpenseResponse> data;

  @override
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  }) async => response(data);
}

class _FakeBalancesOperations implements BalancesOperations {
  _FakeBalancesOperations(this.data);

  final BalancesResponse data;

  @override
  Future<Response<BalancesResponse>> getBalances({
    required String groupId,
  }) async => response(data);
}

class _FakeSettlementOperations implements SettlementOperations {
  _FakeSettlementOperations(this.data);

  final SettlementResponse data;

  @override
  Future<Response<SettlementResponse>> getSettlement({
    required String groupId,
  }) async => response(data);
}
