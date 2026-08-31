//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'balance_participant_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BalanceParticipantResponse {
  /// Returns a new [BalanceParticipantResponse] instance.
  BalanceParticipantResponse({

    required  this.archived,

    required  this.balanceCents,

    required  this.name,

    required  this.owedCents,

    required  this.paidCents,

    required  this.participantId,
  });

  @JsonKey(
    
    name: r'archived',
    required: true,
    includeIfNull: false,
  )


  final bool archived;



  @JsonKey(
    
    name: r'balance_cents',
    required: true,
    includeIfNull: false,
  )


  final int balanceCents;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'owed_cents',
    required: true,
    includeIfNull: false,
  )


  final int owedCents;



  @JsonKey(
    
    name: r'paid_cents',
    required: true,
    includeIfNull: false,
  )


  final int paidCents;



  @JsonKey(
    
    name: r'participant_id',
    required: true,
    includeIfNull: false,
  )


  final String participantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BalanceParticipantResponse &&
      other.archived == archived &&
      other.balanceCents == balanceCents &&
      other.name == name &&
      other.owedCents == owedCents &&
      other.paidCents == paidCents &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        archived.hashCode +
        balanceCents.hashCode +
        name.hashCode +
        owedCents.hashCode +
        paidCents.hashCode +
        participantId.hashCode;

  factory BalanceParticipantResponse.fromJson(Map<String, dynamic> json) => _$BalanceParticipantResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceParticipantResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

