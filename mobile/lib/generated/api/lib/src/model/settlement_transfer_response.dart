//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'settlement_transfer_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettlementTransferResponse {
  /// Returns a new [SettlementTransferResponse] instance.
  SettlementTransferResponse({

    required  this.amountCents,

    required  this.fromName,

    required  this.fromParticipantId,

    required  this.toName,

    required  this.toParticipantId,
  });

  @JsonKey(
    
    name: r'amount_cents',
    required: true,
    includeIfNull: false,
  )


  final int amountCents;



  @JsonKey(
    
    name: r'from_name',
    required: true,
    includeIfNull: false,
  )


  final String fromName;



  @JsonKey(
    
    name: r'from_participant_id',
    required: true,
    includeIfNull: false,
  )


  final String fromParticipantId;



  @JsonKey(
    
    name: r'to_name',
    required: true,
    includeIfNull: false,
  )


  final String toName;



  @JsonKey(
    
    name: r'to_participant_id',
    required: true,
    includeIfNull: false,
  )


  final String toParticipantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SettlementTransferResponse &&
      other.amountCents == amountCents &&
      other.fromName == fromName &&
      other.fromParticipantId == fromParticipantId &&
      other.toName == toName &&
      other.toParticipantId == toParticipantId;

    @override
    int get hashCode =>
        amountCents.hashCode +
        fromName.hashCode +
        fromParticipantId.hashCode +
        toName.hashCode +
        toParticipantId.hashCode;

  factory SettlementTransferResponse.fromJson(Map<String, dynamic> json) => _$SettlementTransferResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementTransferResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

