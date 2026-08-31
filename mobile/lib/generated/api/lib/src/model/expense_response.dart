//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/expense_beneficiary_response.dart';
import 'package:openapi/src/model/expense_contributor_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseResponse {
  /// Returns a new [ExpenseResponse] instance.
  ExpenseResponse({

    required  this.amountCents,

    required  this.beneficiaries,

    required  this.contributors,

     this.createdAt,

    required  this.description,

    required  this.groupId,

    required  this.id,

     this.updatedAt,
  });

  @JsonKey(
    
    name: r'amount_cents',
    required: true,
    includeIfNull: false,
  )


  final int amountCents;



  @JsonKey(
    
    name: r'beneficiaries',
    required: true,
    includeIfNull: false,
  )


  final List<ExpenseBeneficiaryResponse> beneficiaries;



  @JsonKey(
    
    name: r'contributors',
    required: true,
    includeIfNull: false,
  )


  final List<ExpenseContributorResponse> contributors;



  @JsonKey(
    
    name: r'created_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? createdAt;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'updated_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExpenseResponse &&
      other.amountCents == amountCents &&
      other.beneficiaries == beneficiaries &&
      other.contributors == contributors &&
      other.createdAt == createdAt &&
      other.description == description &&
      other.groupId == groupId &&
      other.id == id &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        amountCents.hashCode +
        beneficiaries.hashCode +
        contributors.hashCode +
        (createdAt == null ? 0 : createdAt.hashCode) +
        description.hashCode +
        groupId.hashCode +
        id.hashCode +
        (updatedAt == null ? 0 : updatedAt.hashCode);

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) => _$ExpenseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

