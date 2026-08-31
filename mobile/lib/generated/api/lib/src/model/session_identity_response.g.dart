// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_identity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionIdentityResponse _$SessionIdentityResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SessionIdentityResponse',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['account', 'active_group_id', 'expires_at', 'role'],
    );
    final val = SessionIdentityResponse(
      account: $checkedConvert(
        'account',
        (v) => AccountIdentityResponse.fromJson(v as Map<String, dynamic>),
      ),
      activeGroupId: $checkedConvert('active_group_id', (v) => v),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$SessionIdentityResponseRoleEnumEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'activeGroupId': 'active_group_id',
    'expiresAt': 'expires_at',
  },
);

Map<String, dynamic> _$SessionIdentityResponseToJson(
  SessionIdentityResponse instance,
) => <String, dynamic>{
  'account': instance.account.toJson(),
  'active_group_id': instance.activeGroupId,
  'expires_at': instance.expiresAt.toIso8601String(),
  'role': _$SessionIdentityResponseRoleEnumEnumMap[instance.role]!,
};

const _$SessionIdentityResponseRoleEnumEnumMap = {
  SessionIdentityResponseRoleEnum.owner: 'owner',
  SessionIdentityResponseRoleEnum.member: 'member',
};
