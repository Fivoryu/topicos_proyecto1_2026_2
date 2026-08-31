// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseResponse _$ExpenseResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ExpenseResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'amount_cents',
            'beneficiaries',
            'contributors',
            'description',
            'group_id',
            'id',
          ],
        );
        final val = ExpenseResponse(
          amountCents: $checkedConvert(
            'amount_cents',
            (v) => (v as num).toInt(),
          ),
          beneficiaries: $checkedConvert(
            'beneficiaries',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => ExpenseBeneficiaryResponse.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
          contributors: $checkedConvert(
            'contributors',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => ExpenseContributorResponse.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          description: $checkedConvert('description', (v) => v as String),
          groupId: $checkedConvert('group_id', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'amountCents': 'amount_cents',
        'createdAt': 'created_at',
        'groupId': 'group_id',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$ExpenseResponseToJson(ExpenseResponse instance) =>
    <String, dynamic>{
      'amount_cents': instance.amountCents,
      'beneficiaries': instance.beneficiaries.map((e) => e.toJson()).toList(),
      'contributors': instance.contributors.map((e) => e.toJson()).toList(),
      'created_at': ?instance.createdAt?.toIso8601String(),
      'description': instance.description,
      'group_id': instance.groupId,
      'id': instance.id,
      'updated_at': ?instance.updatedAt?.toIso8601String(),
    };
