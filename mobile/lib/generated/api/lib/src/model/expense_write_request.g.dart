// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_write_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseWriteRequest _$ExpenseWriteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExpenseWriteRequest', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'amount',
          'beneficiary_ids',
          'contributors',
          'description',
        ],
      );
      final val = ExpenseWriteRequest(
        amount: $checkedConvert('amount', (v) => v as String),
        beneficiaryIds: $checkedConvert(
          'beneficiary_ids',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        contributors: $checkedConvert(
          'contributors',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ExpenseContributorRequest.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        description: $checkedConvert('description', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'beneficiaryIds': 'beneficiary_ids'});

Map<String, dynamic> _$ExpenseWriteRequestToJson(
  ExpenseWriteRequest instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'beneficiary_ids': instance.beneficiaryIds,
  'contributors': instance.contributors.map((e) => e.toJson()).toList(),
  'description': instance.description,
};
