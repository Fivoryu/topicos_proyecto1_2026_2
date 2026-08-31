// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_beneficiary_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseBeneficiaryResponse _$ExpenseBeneficiaryResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExpenseBeneficiaryResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['archived', 'name', 'participant_id']);
  final val = ExpenseBeneficiaryResponse(
    archived: $checkedConvert('archived', (v) => v as bool),
    name: $checkedConvert('name', (v) => v as String),
    participantId: $checkedConvert('participant_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'participantId': 'participant_id'});

Map<String, dynamic> _$ExpenseBeneficiaryResponseToJson(
  ExpenseBeneficiaryResponse instance,
) => <String, dynamic>{
  'archived': instance.archived,
  'name': instance.name,
  'participant_id': instance.participantId,
};
