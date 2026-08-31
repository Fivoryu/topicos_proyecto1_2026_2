// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_contributor_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseContributorRequest _$ExpenseContributorRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExpenseContributorRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['amount', 'participant_id']);
  final val = ExpenseContributorRequest(
    amount: $checkedConvert('amount', (v) => v as String),
    participantId: $checkedConvert('participant_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'participantId': 'participant_id'});

Map<String, dynamic> _$ExpenseContributorRequestToJson(
  ExpenseContributorRequest instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'participant_id': instance.participantId,
};
