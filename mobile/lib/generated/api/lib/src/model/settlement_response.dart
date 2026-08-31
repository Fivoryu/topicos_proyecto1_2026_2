//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/settlement_transfer_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settlement_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettlementResponse {
  /// Returns a new [SettlementResponse] instance.
  SettlementResponse({

    required  this.groupId,

    required  this.settled,

    required  this.settlementPolicy,

    required  this.transfers,
  });

  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;



  @JsonKey(
    
    name: r'settled',
    required: true,
    includeIfNull: false,
  )


  final bool settled;



  @JsonKey(
    
    name: r'settlementPolicy',
    required: true,
    includeIfNull: false,
  )


  final SettlementResponseSettlementPolicyEnum settlementPolicy;



  @JsonKey(
    
    name: r'transfers',
    required: true,
    includeIfNull: false,
  )


  final List<SettlementTransferResponse> transfers;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SettlementResponse &&
      other.groupId == groupId &&
      other.settled == settled &&
      other.settlementPolicy == settlementPolicy &&
      other.transfers == transfers;

    @override
    int get hashCode =>
        groupId.hashCode +
        settled.hashCode +
        settlementPolicy.hashCode +
        transfers.hashCode;

  factory SettlementResponse.fromJson(Map<String, dynamic> json) => _$SettlementResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SettlementResponseSettlementPolicyEnum {
@JsonValue(r'owner_only')
ownerOnly(r'owner_only'),
@JsonValue(r'any_member')
anyMember(r'any_member');

const SettlementResponseSettlementPolicyEnum(this.value);

final String value;

@override
String toString() => value;
}


