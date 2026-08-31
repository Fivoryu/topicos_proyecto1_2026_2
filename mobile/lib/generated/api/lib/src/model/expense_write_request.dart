//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/expense_contributor_request.dart';
import 'package:json_annotation/json_annotation.dart';

part 'expense_write_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseWriteRequest {
  /// Returns a new [ExpenseWriteRequest] instance.
  ExpenseWriteRequest({

    required  this.amount,

    required  this.beneficiaryIds,

    required  this.contributors,

    required  this.description,
  });

  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final String amount;



  @JsonKey(
    
    name: r'beneficiary_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> beneficiaryIds;



  @JsonKey(
    
    name: r'contributors',
    required: true,
    includeIfNull: false,
  )


  final List<ExpenseContributorRequest> contributors;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExpenseWriteRequest &&
      other.amount == amount &&
      other.beneficiaryIds == beneficiaryIds &&
      other.contributors == contributors &&
      other.description == description;

    @override
    int get hashCode =>
        amount.hashCode +
        beneficiaryIds.hashCode +
        contributors.hashCode +
        description.hashCode;

  factory ExpenseWriteRequest.fromJson(Map<String, dynamic> json) => _$ExpenseWriteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseWriteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

