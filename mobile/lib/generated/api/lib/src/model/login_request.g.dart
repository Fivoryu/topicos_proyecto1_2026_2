// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['login_name', 'password']);
      final val = LoginRequest(
        loginName: $checkedConvert('login_name', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'loginName': 'login_name'});

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'login_name': instance.loginName,
      'password': instance.password,
    };
