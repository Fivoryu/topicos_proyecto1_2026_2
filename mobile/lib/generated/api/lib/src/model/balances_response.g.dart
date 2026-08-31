// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balances_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalancesResponse _$BalancesResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BalancesResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['group_id', 'participants']);
      final val = BalancesResponse(
        groupId: $checkedConvert('group_id', (v) => v as String),
        participants: $checkedConvert(
          'participants',
          (v) => (v as List<dynamic>)
              .map(
                (e) => BalanceParticipantResponse.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'groupId': 'group_id'});

Map<String, dynamic> _$BalancesResponseToJson(BalancesResponse instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'participants': instance.participants.map((e) => e.toJson()).toList(),
    };
