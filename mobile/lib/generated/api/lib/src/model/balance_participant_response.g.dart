// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_participant_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceParticipantResponse _$BalanceParticipantResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BalanceParticipantResponse',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'archived',
        'balance_cents',
        'name',
        'owed_cents',
        'paid_cents',
        'participant_id',
      ],
    );
    final val = BalanceParticipantResponse(
      archived: $checkedConvert('archived', (v) => v as bool),
      balanceCents: $checkedConvert('balance_cents', (v) => (v as num).toInt()),
      name: $checkedConvert('name', (v) => v as String),
      owedCents: $checkedConvert('owed_cents', (v) => (v as num).toInt()),
      paidCents: $checkedConvert('paid_cents', (v) => (v as num).toInt()),
      participantId: $checkedConvert('participant_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'balanceCents': 'balance_cents',
    'owedCents': 'owed_cents',
    'paidCents': 'paid_cents',
    'participantId': 'participant_id',
  },
);

Map<String, dynamic> _$BalanceParticipantResponseToJson(
  BalanceParticipantResponse instance,
) => <String, dynamic>{
  'archived': instance.archived,
  'balance_cents': instance.balanceCents,
  'name': instance.name,
  'owed_cents': instance.owedCents,
  'paid_cents': instance.paidCents,
  'participant_id': instance.participantId,
};
