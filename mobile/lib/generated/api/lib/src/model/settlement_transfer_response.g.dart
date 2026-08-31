// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_transfer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementTransferResponse _$SettlementTransferResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SettlementTransferResponse',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'amount_cents',
        'from_name',
        'from_participant_id',
        'to_name',
        'to_participant_id',
      ],
    );
    final val = SettlementTransferResponse(
      amountCents: $checkedConvert('amount_cents', (v) => (v as num).toInt()),
      fromName: $checkedConvert('from_name', (v) => v as String),
      fromParticipantId: $checkedConvert(
        'from_participant_id',
        (v) => v as String,
      ),
      toName: $checkedConvert('to_name', (v) => v as String),
      toParticipantId: $checkedConvert('to_participant_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'amountCents': 'amount_cents',
    'fromName': 'from_name',
    'fromParticipantId': 'from_participant_id',
    'toName': 'to_name',
    'toParticipantId': 'to_participant_id',
  },
);

Map<String, dynamic> _$SettlementTransferResponseToJson(
  SettlementTransferResponse instance,
) => <String, dynamic>{
  'amount_cents': instance.amountCents,
  'from_name': instance.fromName,
  'from_participant_id': instance.fromParticipantId,
  'to_name': instance.toName,
  'to_participant_id': instance.toParticipantId,
};
