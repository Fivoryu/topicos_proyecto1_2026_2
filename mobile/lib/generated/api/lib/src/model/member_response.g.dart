// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberResponse _$MemberResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['account_id', 'active', 'login_name', 'role'],
        );
        final val = MemberResponse(
          accountId: $checkedConvert('account_id', (v) => v as String),
          active: $checkedConvert('active', (v) => v as bool),
          loginName: $checkedConvert('login_name', (v) => v as String),
          participantId: $checkedConvert('participant_id', (v) => v as String?),
          role: $checkedConvert(
            'role',
            (v) => $enumDecode(_$MemberResponseRoleEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'accountId': 'account_id',
        'loginName': 'login_name',
        'participantId': 'participant_id',
      },
    );

Map<String, dynamic> _$MemberResponseToJson(MemberResponse instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'active': instance.active,
      'login_name': instance.loginName,
      'participant_id': ?instance.participantId,
      'role': _$MemberResponseRoleEnumEnumMap[instance.role]!,
    };

const _$MemberResponseRoleEnumEnumMap = {
  MemberResponseRoleEnum.owner: 'owner',
  MemberResponseRoleEnum.member: 'member',
};
