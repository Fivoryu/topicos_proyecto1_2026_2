// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outing_write_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutingWriteRequest _$OutingWriteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OutingWriteRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = OutingWriteRequest(
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$OutingWriteRequestToJson(OutingWriteRequest instance) =>
    <String, dynamic>{'name': instance.name};
