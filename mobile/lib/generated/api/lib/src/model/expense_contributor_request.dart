//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'expense_contributor_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseContributorRequest {
  /// Returns a new [ExpenseContributorRequest] instance.
  ExpenseContributorRequest({

    required  this.amount,

    required  this.participantId,
  });

  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final String amount;



  @JsonKey(
    
    name: r'participant_id',
    required: true,
    includeIfNull: false,
  )


  final String participantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExpenseContributorRequest &&
      other.amount == amount &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        amount.hashCode +
        participantId.hashCode;

  factory ExpenseContributorRequest.fromJson(Map<String, dynamic> json) => _$ExpenseContributorRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseContributorRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

