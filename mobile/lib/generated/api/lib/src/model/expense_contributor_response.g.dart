// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_contributor_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseContributorResponse _$ExpenseContributorResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ExpenseContributorResponse',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'amount_cents',
        'archived',
        'name',
        'participant_id',
      ],
    );
    final val = ExpenseContributorResponse(
      amountCents: $checkedConvert('amount_cents', (v) => (v as num).toInt()),
      archived: $checkedConvert('archived', (v) => v as bool),
      name: $checkedConvert('name', (v) => v as String),
      participantId: $checkedConvert('participant_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'amountCents': 'amount_cents',
    'participantId': 'participant_id',
  },
);

Map<String, dynamic> _$ExpenseContributorResponseToJson(
  ExpenseContributorResponse instance,
) => <String, dynamic>{
  'amount_cents': instance.amountCents,
  'archived': instance.archived,
  'name': instance.name,
  'participant_id': instance.participantId,
};
