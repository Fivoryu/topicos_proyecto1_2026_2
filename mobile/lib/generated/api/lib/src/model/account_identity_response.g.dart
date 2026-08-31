// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_identity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountIdentityResponse _$AccountIdentityResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AccountIdentityResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'login_name']);
  final val = AccountIdentityResponse(
    id: $checkedConvert('id', (v) => v),
    loginName: $checkedConvert('login_name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'loginName': 'login_name'});

Map<String, dynamic> _$AccountIdentityResponseToJson(
  AccountIdentityResponse instance,
) => <String, dynamic>{'id': instance.id, 'login_name': instance.loginName};
