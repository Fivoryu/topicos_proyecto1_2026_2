//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'expense_beneficiary_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseBeneficiaryResponse {
  /// Returns a new [ExpenseBeneficiaryResponse] instance.
  ExpenseBeneficiaryResponse({

    required  this.archived,

    required  this.name,

    required  this.participantId,
  });

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
    bool operator ==(Object other) => identical(this, other) || other is ExpenseBeneficiaryResponse &&
      other.archived == archived &&
      other.name == name &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        archived.hashCode +
        name.hashCode +
        participantId.hashCode;

  factory ExpenseBeneficiaryResponse.fromJson(Map<String, dynamic> json) => _$ExpenseBeneficiaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseBeneficiaryResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

