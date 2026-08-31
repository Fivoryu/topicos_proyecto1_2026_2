// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_write_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantWriteRequest _$ParticipantWriteRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ParticipantWriteRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = ParticipantWriteRequest(
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ParticipantWriteRequestToJson(
  ParticipantWriteRequest instance,
) => <String, dynamic>{'name': instance.name};
