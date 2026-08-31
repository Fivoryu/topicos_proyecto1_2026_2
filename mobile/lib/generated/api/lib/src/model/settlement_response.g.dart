// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementResponse _$SettlementResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SettlementResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'group_id',
          'settled',
          'settlementPolicy',
          'transfers',
        ],
      );
      final val = SettlementResponse(
        groupId: $checkedConvert('group_id', (v) => v as String),
        settled: $checkedConvert('settled', (v) => v as bool),
        settlementPolicy: $checkedConvert(
          'settlementPolicy',
          (v) =>
              $enumDecode(_$SettlementResponseSettlementPolicyEnumEnumMap, v),
        ),
        transfers: $checkedConvert(
          'transfers',
          (v) => (v as List<dynamic>)
              .map(
                (e) => SettlementTransferResponse.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'groupId': 'group_id'});

Map<String, dynamic> _$SettlementResponseToJson(SettlementResponse instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'settled': instance.settled,
      'settlementPolicy':
          _$SettlementResponseSettlementPolicyEnumEnumMap[instance
              .settlementPolicy]!,
      'transfers': instance.transfers.map((e) => e.toJson()).toList(),
    };

const _$SettlementResponseSettlementPolicyEnumEnumMap = {
  SettlementResponseSettlementPolicyEnum.ownerOnly: 'owner_only',
  SettlementResponseSettlementPolicyEnum.anyMember: 'any_member',
};
