// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_participant_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenameParticipantRequest _$RenameParticipantRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RenameParticipantRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = RenameParticipantRequest(
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RenameParticipantRequestToJson(
  RenameParticipantRequest instance,
) => <String, dynamic>{'name': instance.name};
