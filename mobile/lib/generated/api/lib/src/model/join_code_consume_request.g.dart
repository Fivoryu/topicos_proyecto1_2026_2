// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_code_consume_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinCodeConsumeRequest _$JoinCodeConsumeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'JoinCodeConsumeRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['code']);
    final val = JoinCodeConsumeRequest(
      code: $checkedConvert('code', (v) => v as String),
      newParticipantName: $checkedConvert(
        'new_participant_name',
        (v) => v as String?,
      ),
      participantId: $checkedConvert('participant_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'newParticipantName': 'new_participant_name',
    'participantId': 'participant_id',
  },
);

Map<String, dynamic> _$JoinCodeConsumeRequestToJson(
  JoinCodeConsumeRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'new_participant_name': ?instance.newParticipantName,
  'participant_id': ?instance.participantId,
};
