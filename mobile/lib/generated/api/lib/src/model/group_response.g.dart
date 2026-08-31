// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupResponse _$GroupResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'owner_account_id',
          'settlementPolicy',
        ],
      );
      final val = GroupResponse(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        ownerAccountId: $checkedConvert('owner_account_id', (v) => v as String),
        settlementPolicy: $checkedConvert(
          'settlementPolicy',
          (v) => $enumDecode(_$GroupResponseSettlementPolicyEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'ownerAccountId': 'owner_account_id'});

Map<String, dynamic> _$GroupResponseToJson(
  GroupResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'owner_account_id': instance.ownerAccountId,
  'settlementPolicy':
      _$GroupResponseSettlementPolicyEnumEnumMap[instance.settlementPolicy]!,
};

const _$GroupResponseSettlementPolicyEnumEnumMap = {
  GroupResponseSettlementPolicyEnum.ownerOnly: 'owner_only',
  GroupResponseSettlementPolicyEnum.anyMember: 'any_member',
};
