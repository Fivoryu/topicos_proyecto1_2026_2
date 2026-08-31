// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupUpdateRequest _$GroupUpdateRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupUpdateRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['settlementPolicy']);
      final val = GroupUpdateRequest(
        settlementPolicy: $checkedConvert(
          'settlementPolicy',
          (v) =>
              $enumDecode(_$GroupUpdateRequestSettlementPolicyEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GroupUpdateRequestToJson(GroupUpdateRequest instance) =>
    <String, dynamic>{
      'settlementPolicy':
          _$GroupUpdateRequestSettlementPolicyEnumEnumMap[instance
              .settlementPolicy]!,
    };

const _$GroupUpdateRequestSettlementPolicyEnumEnumMap = {
  GroupUpdateRequestSettlementPolicyEnum.ownerOnly: 'owner_only',
  GroupUpdateRequestSettlementPolicyEnum.anyMember: 'any_member',
};
