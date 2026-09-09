// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outing_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutingResponse _$OutingResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OutingResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['archived', 'group_id', 'id', 'name'],
        );
        final val = OutingResponse(
          archived: $checkedConvert('archived', (v) => v as bool),
          archivedAt: $checkedConvert(
            'archived_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          groupId: $checkedConvert('group_id', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'archivedAt': 'archived_at',
        'createdAt': 'created_at',
        'groupId': 'group_id',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$OutingResponseToJson(OutingResponse instance) =>
    <String, dynamic>{
      'archived': instance.archived,
      'archived_at': ?instance.archivedAt?.toIso8601String(),
      'created_at': ?instance.createdAt?.toIso8601String(),
      'group_id': instance.groupId,
      'id': instance.id,
      'name': instance.name,
      'updated_at': ?instance.updatedAt?.toIso8601String(),
    };
