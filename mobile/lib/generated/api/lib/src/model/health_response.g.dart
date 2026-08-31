// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['database', 'status']);
      final val = HealthResponse(
        database: $checkedConvert(
          'database',
          (v) => $enumDecode(_$DatabaseStatusEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthStatusEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthResponseToJson(HealthResponse instance) =>
    <String, dynamic>{
      'database': _$DatabaseStatusEnumMap[instance.database]!,
      'status': _$HealthStatusEnumMap[instance.status]!,
    };

const _$DatabaseStatusEnumMap = {
  DatabaseStatus.ok: 'ok',
  DatabaseStatus.unavailable: 'unavailable',
};

const _$HealthStatusEnumMap = {
  HealthStatus.ok: 'ok',
  HealthStatus.error: 'error',
};
