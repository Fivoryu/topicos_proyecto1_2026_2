// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_code_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinCodeStatus _$JoinCodeStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinCodeStatus', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['active', 'generation', 'group_id'],
      );
      final val = JoinCodeStatus(
        active: $checkedConvert('active', (v) => v as bool),
        generation: $checkedConvert('generation', (v) => (v as num?)?.toInt()),
        groupId: $checkedConvert('group_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'groupId': 'group_id'});

Map<String, dynamic> _$JoinCodeStatusToJson(JoinCodeStatus instance) =>
    <String, dynamic>{
      'active': instance.active,
      'generation': instance.generation,
      'group_id': instance.groupId,
    };
