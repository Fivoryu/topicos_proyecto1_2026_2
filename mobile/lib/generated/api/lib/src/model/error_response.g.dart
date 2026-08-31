// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ErrorResponse',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['error_code', 'message']);
        final val = ErrorResponse(
          errorCode: $checkedConvert('error_code', (v) => v as String),
          fieldErrors: $checkedConvert(
            'field_errors',
            (v) => (v as List<dynamic>?)
                ?.map((e) => FieldError.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          message: $checkedConvert('message', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'errorCode': 'error_code',
        'fieldErrors': 'field_errors',
      },
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'error_code': instance.errorCode,
      'field_errors': ?instance.fieldErrors?.map((e) => e.toJson()).toList(),
      'message': instance.message,
    };
