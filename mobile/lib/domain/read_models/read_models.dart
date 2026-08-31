import 'package:openapi/openapi.dart';

String _requiredId(Object? value, String field) {
  if (value == null) {
    throw FormatException('Missing $field in server response.');
  }
  return value.toString();
}

String? _optionalId(Object? value) => value?.toString();

enum ServerRole { owner, member }

enum SettlementPolicy { ownerOnly, anyMember }

ServerRole _serverRole(SessionIdentityResponseRoleEnum value) =>
    switch (value) {
      SessionIdentityResponseRoleEnum.owner => ServerRole.owner,
      SessionIdentityResponseRoleEnum.member => ServerRole.member,
    };

SettlementPolicy _settlementPolicy(Object value) {
  final raw = value.toString();
  return raw == 'any_member' ||
          raw == 'SettlementResponseSettlementPolicyEnum.anyMember'
      ? SettlementPolicy.anyMember
      : SettlementPolicy.ownerOnly;
}

class SessionIdentityReadModel {
  const SessionIdentityReadModel({
    required this.accountId,
    required this.loginName,
    required this.activeGroupId,
    required this.expiresAt,
    required this.role,
  });

  factory SessionIdentityReadModel.fromDto(SessionIdentityResponse dto) {
    return SessionIdentityReadModel(
      accountId: _requiredId(dto.account.id, 'account.id'),
      loginName: dto.account.loginName,
      activeGroupId: _optionalId(dto.activeGroupId),
      expiresAt: dto.expiresAt,
      role: _serverRole(dto.role),
    );
  }

  factory SessionIdentityReadModel.fromResponse(SessionIdentityResponse dto) =>
      SessionIdentityReadModel.fromDto(dto);

  final String accountId;
  final String loginName;
  final String? activeGroupId;
  final DateTime expiresAt;
  final ServerRole role;
}

class GroupReadModel {
  const GroupReadModel({
    required this.id,
    required this.name,
    required this.ownerAccountId,
    required this.settlementPolicy,
  });

  factory GroupReadModel.fromDto(GroupResponse dto) {
    return GroupReadModel(
      id: dto.id,
      name: dto.name,
      ownerAccountId: dto.ownerAccountId,
      settlementPolicy: _settlementPolicy(dto.settlementPolicy),
    );
  }

  factory GroupReadModel.fromResponse(GroupResponse dto) =>
      GroupReadModel.fromDto(dto);

  final String id;
  final String name;
  final String ownerAccountId;
  final SettlementPolicy settlementPolicy;
}

class ParticipantReadModel {
  const ParticipantReadModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.archived,
    this.createdAt,
  });

  factory ParticipantReadModel.fromDto(ParticipantResponse dto) {
    return ParticipantReadModel(
      id: dto.id,
      groupId: dto.groupId,
      name: dto.name,
      archived: dto.archived,
      createdAt: dto.createdAt,
    );
  }

  factory ParticipantReadModel.fromResponse(ParticipantResponse dto) =>
      ParticipantReadModel.fromDto(dto);

  final String id;
  final String groupId;
  final String name;
  final bool archived;
  final DateTime? createdAt;
}

class ExpenseContributorReadModel {
  const ExpenseContributorReadModel({
    required this.participantId,
    required this.name,
    required this.archived,
    required this.amountCents,
  });

  factory ExpenseContributorReadModel.fromDto(ExpenseContributorResponse dto) {
    return ExpenseContributorReadModel(
      participantId: dto.participantId,
      name: dto.name,
      archived: dto.archived,
      amountCents: dto.amountCents,
    );
  }

  final String participantId;
  final String name;
  final bool archived;
  final int amountCents;
}

class ExpenseBeneficiaryReadModel {
  const ExpenseBeneficiaryReadModel({
    required this.participantId,
    required this.name,
    required this.archived,
  });

  factory ExpenseBeneficiaryReadModel.fromDto(ExpenseBeneficiaryResponse dto) {
    return ExpenseBeneficiaryReadModel(
      participantId: dto.participantId,
      name: dto.name,
      archived: dto.archived,
    );
  }

  final String participantId;
  final String name;
  final bool archived;
}

class ExpenseReadModel {
  const ExpenseReadModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amountCents,
    required this.contributors,
    required this.beneficiaries,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseReadModel.fromDto(ExpenseResponse dto) {
    return ExpenseReadModel(
      id: dto.id,
      groupId: dto.groupId,
      description: dto.description,
      amountCents: dto.amountCents,
      contributors: List.unmodifiable(
        dto.contributors.map(ExpenseContributorReadModel.fromDto),
      ),
      beneficiaries: List.unmodifiable(
        dto.beneficiaries.map(ExpenseBeneficiaryReadModel.fromDto),
      ),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  factory ExpenseReadModel.fromResponse(ExpenseResponse dto) =>
      ExpenseReadModel.fromDto(dto);

  final String id;
  final String groupId;
  final String description;
  final int amountCents;
  final List<ExpenseContributorReadModel> contributors;
  final List<ExpenseBeneficiaryReadModel> beneficiaries;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class BalanceParticipantReadModel {
  const BalanceParticipantReadModel({
    required this.participantId,
    required this.name,
    required this.archived,
    required this.paidCents,
    required this.owedCents,
    required this.balanceCents,
  });

  factory BalanceParticipantReadModel.fromDto(BalanceParticipantResponse dto) {
    return BalanceParticipantReadModel(
      participantId: dto.participantId,
      name: dto.name,
      archived: dto.archived,
      paidCents: dto.paidCents,
      owedCents: dto.owedCents,
      balanceCents: dto.balanceCents,
    );
  }

  final String participantId;
  final String name;
  final bool archived;
  final int paidCents;
  final int owedCents;
  final int balanceCents;
}

class BalancesReadModel {
  const BalancesReadModel({required this.groupId, required this.participants});

  factory BalancesReadModel.fromDto(BalancesResponse dto) {
    return BalancesReadModel(
      groupId: dto.groupId,
      participants: List.unmodifiable(
        dto.participants.map(BalanceParticipantReadModel.fromDto),
      ),
    );
  }

  factory BalancesReadModel.fromResponse(BalancesResponse dto) =>
      BalancesReadModel.fromDto(dto);

  final String groupId;
  final List<BalanceParticipantReadModel> participants;
}

class SettlementTransferReadModel {
  const SettlementTransferReadModel({
    required this.fromParticipantId,
    required this.fromName,
    required this.toParticipantId,
    required this.toName,
    required this.amountCents,
  });

  factory SettlementTransferReadModel.fromDto(SettlementTransferResponse dto) {
    return SettlementTransferReadModel(
      fromParticipantId: dto.fromParticipantId,
      fromName: dto.fromName,
      toParticipantId: dto.toParticipantId,
      toName: dto.toName,
      amountCents: dto.amountCents,
    );
  }

  final String fromParticipantId;
  final String fromName;
  final String toParticipantId;
  final String toName;
  final int amountCents;
}

class SettlementReadModel {
  const SettlementReadModel({
    required this.groupId,
    required this.settlementPolicy,
    required this.settled,
    required this.transfers,
  });

  factory SettlementReadModel.fromDto(SettlementResponse dto) {
    return SettlementReadModel(
      groupId: dto.groupId,
      settlementPolicy: _settlementPolicy(dto.settlementPolicy),
      settled: dto.settled,
      transfers: List.unmodifiable(
        dto.transfers.map(SettlementTransferReadModel.fromDto),
      ),
    );
  }

  factory SettlementReadModel.fromResponse(SettlementResponse dto) =>
      SettlementReadModel.fromDto(dto);

  final String groupId;
  final SettlementPolicy settlementPolicy;
  final bool settled;
  final List<SettlementTransferReadModel> transfers;
}
