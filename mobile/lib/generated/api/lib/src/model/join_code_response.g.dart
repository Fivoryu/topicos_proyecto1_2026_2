// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinCodeResponse _$JoinCodeResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('JoinCodeResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'generation', 'group_id']);
      final val = JoinCodeResponse(
        code: $checkedConvert('code', (v) => v as String),
        generation: $checkedConvert('generation', (v) => (v as num).toInt()),
        groupId: $checkedConvert('group_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'groupId': 'group_id'});

Map<String, dynamic> _$JoinCodeResponseToJson(JoinCodeResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'generation': instance.generation,
      'group_id': instance.groupId,
    };
