// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_summary_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSummaryResponse _$GroupSummaryResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'GroupSummaryResponse',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'owner_account_id',
        'role',
        'settlementPolicy',
      ],
    );
    final val = GroupSummaryResponse(
      expensesCount: $checkedConvert(
        'expenses_count',
        (v) => (v as num?)?.toInt(),
      ),
      id: $checkedConvert('id', (v) => v as String),
      memberCount: $checkedConvert('member_count', (v) => (v as num?)?.toInt()),
      name: $checkedConvert('name', (v) => v as String),
      outingsCount: $checkedConvert(
        'outings_count',
        (v) => (v as num?)?.toInt(),
      ),
      ownerAccountId: $checkedConvert('owner_account_id', (v) => v as String),
      participantsCount: $checkedConvert(
        'participants_count',
        (v) => (v as num?)?.toInt(),
      ),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$GroupSummaryResponseRoleEnumEnumMap, v),
      ),
      settlementPolicy: $checkedConvert(
        'settlementPolicy',
        (v) =>
            $enumDecode(_$GroupSummaryResponseSettlementPolicyEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'expensesCount': 'expenses_count',
    'memberCount': 'member_count',
    'outingsCount': 'outings_count',
    'ownerAccountId': 'owner_account_id',
    'participantsCount': 'participants_count',
  },
);

Map<String, dynamic> _$GroupSummaryResponseToJson(
  GroupSummaryResponse instance,
) => <String, dynamic>{
  'expenses_count': ?instance.expensesCount,
  'id': instance.id,
  'member_count': ?instance.memberCount,
  'name': instance.name,
  'outings_count': ?instance.outingsCount,
  'owner_account_id': instance.ownerAccountId,
  'participants_count': ?instance.participantsCount,
  'role': _$GroupSummaryResponseRoleEnumEnumMap[instance.role]!,
  'settlementPolicy':
      _$GroupSummaryResponseSettlementPolicyEnumEnumMap[instance
          .settlementPolicy]!,
};

const _$GroupSummaryResponseRoleEnumEnumMap = {
  GroupSummaryResponseRoleEnum.owner: 'owner',
  GroupSummaryResponseRoleEnum.member: 'member',
};

const _$GroupSummaryResponseSettlementPolicyEnumEnumMap = {
  GroupSummaryResponseSettlementPolicyEnum.ownerOnly: 'owner_only',
  GroupSummaryResponseSettlementPolicyEnum.anyMember: 'any_member',
};
