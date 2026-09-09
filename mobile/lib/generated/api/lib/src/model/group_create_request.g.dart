// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupCreateRequest _$GroupCreateRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupCreateRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = GroupCreateRequest(
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$GroupCreateRequestToJson(GroupCreateRequest instance) =>
    <String, dynamic>{'name': instance.name};
