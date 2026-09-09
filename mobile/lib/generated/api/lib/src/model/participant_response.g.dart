// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantResponse _$ParticipantResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ParticipantResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['archived', 'group_id', 'id', 'name'],
      );
      final val = ParticipantResponse(
        archived: $checkedConvert('archived', (v) => v as bool),
        createdAt: $checkedConvert(
          'created_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        groupId: $checkedConvert('group_id', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at', 'groupId': 'group_id'});

Map<String, dynamic> _$ParticipantResponseToJson(
  ParticipantResponse instance,
) => <String, dynamic>{
  'archived': instance.archived,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'group_id': instance.groupId,
  'id': instance.id,
  'name': instance.name,
};
