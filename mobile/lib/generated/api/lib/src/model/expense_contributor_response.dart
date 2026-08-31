//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'expense_contributor_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseContributorResponse {
  /// Returns a new [ExpenseContributorResponse] instance.
  ExpenseContributorResponse({

    required  this.amountCents,

    required  this.archived,

    required  this.name,

    required  this.participantId,
  });

  @JsonKey(
    
    name: r'amount_cents',
    required: true,
    includeIfNull: false,
  )


  final int amountCents;



  @JsonKey(
    
    name: r'archived',
    required: true,
    includeIfNull: false,
  )


  final bool archived;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'participant_id',
    required: true,
    includeIfNull: false,
  )


  final String participantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExpenseContributorResponse &&
      other.amountCents == amountCents &&
      other.archived == archived &&
      other.name == name &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        amountCents.hashCode +
        archived.hashCode +
        name.hashCode +
        participantId.hashCode;

  factory ExpenseContributorResponse.fromJson(Map<String, dynamic> json) => _$ExpenseContributorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseContributorResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

