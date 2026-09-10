// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinResponse _$JoinResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'JoinResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['account_id', 'group_id', 'participant_id'],
        );
        final val = JoinResponse(
          accountId: $checkedConvert('account_id', (v) => v as String),
          groupId: $checkedConvert('group_id', (v) => v as String),
          participantId: $checkedConvert('participant_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'accountId': 'account_id',
        'groupId': 'group_id',
        'participantId': 'participant_id',
      },
    );

Map<String, dynamic> _$JoinResponseToJson(JoinResponse instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'group_id': instance.groupId,
      'participant_id': instance.participantId,
    };
