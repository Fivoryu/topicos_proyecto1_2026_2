import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 26);

  test('maps the server session and role without client authority', () {
    final model = SessionIdentityReadModel.fromDto(
      SessionIdentityResponse(
        account: AccountIdentityResponse(
          id: 'account-1',
          loginName: 'demo.owner',
        ),
        activeGroupId: 'group-1',
        expiresAt: createdAt,
        role: SessionIdentityResponseRoleEnum.owner,
      ),
    );

    expect(model.accountId, 'account-1');
    expect(model.loginName, 'demo.owner');
    expect(model.activeGroupId, 'group-1');
    expect(model.role, ServerRole.owner);
  });

  test('maps current participant names and archived status', () {
    final model = ParticipantReadModel.fromDto(
      ParticipantResponse(
        id: 'participant-1',
        groupId: 'group-1',
        name: 'Carla',
        archived: true,
        createdAt: createdAt,
      ),
    );

    expect(model.id, 'participant-1');
    expect(model.name, 'Carla');
    expect(model.archived, isTrue);
  });

  test('maps server monetary fields verbatim as integer cents', () {
    final balances = BalancesReadModel.fromDto(
      BalancesResponse(
        groupId: 'group-1',
        participants: [
          BalanceParticipantResponse(
            participantId: 'participant-1',
            name: 'Ana',
            archived: false,
            paidCents: 96000,
            owedCents: 40000,
            balanceCents: 56000,
          ),
        ],
      ),
    );

    expect(balances.groupId, 'group-1');
    expect(balances.participants.single.paidCents, 96000);
    expect(balances.participants.single.owedCents, 40000);
    expect(balances.participants.single.balanceCents, 56000);
  });

  test('maps settlement transfers and expense history DTOs', () {
    final settlement = SettlementReadModel.fromDto(
      SettlementResponse(
        groupId: 'group-1',
        settlementPolicy: SettlementResponseSettlementPolicyEnum.ownerOnly,
        settled: false,
        transfers: [
          SettlementTransferResponse(
            fromParticipantId: 'diego',
            fromName: 'Diego',
            toParticipantId: 'ana',
            toName: 'Ana',
            amountCents: 40000,
          ),
        ],
      ),
    );
    final expense = ExpenseReadModel.fromDto(
      ExpenseResponse(
        id: 'expense-1',
        groupId: 'group-1',
        description: 'Lodging',
        amountCents: 96000,
        createdAt: createdAt,
        updatedAt: createdAt,
        contributors: [
          ExpenseContributorResponse(
            participantId: 'ana',
            name: 'Ana',
            archived: false,
            amountCents: 96000,
          ),
        ],
        beneficiaries: [
          ExpenseBeneficiaryResponse(
            participantId: 'ana',
            name: 'Ana',
            archived: false,
          ),
        ],
      ),
    );

    expect(settlement.transfers.single.amountCents, 40000);
    expect(settlement.settlementPolicy, SettlementPolicy.ownerOnly);
    expect(expense.amountCents, 96000);
    expect(expense.contributors.single.amountCents, 96000);
    expect(expense.beneficiaries.single.name, 'Ana');
  });
}
