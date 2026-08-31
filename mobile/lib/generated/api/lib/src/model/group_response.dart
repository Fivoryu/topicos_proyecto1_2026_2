//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'group_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GroupResponse {
  /// Returns a new [GroupResponse] instance.
  GroupResponse({

    required  this.id,

    required  this.name,

    required  this.ownerAccountId,

    required  this.settlementPolicy,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'owner_account_id',
    required: true,
    includeIfNull: false,
  )


  final String ownerAccountId;



  @JsonKey(
    
    name: r'settlementPolicy',
    required: true,
    includeIfNull: false,
  )


  final GroupResponseSettlementPolicyEnum settlementPolicy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GroupResponse &&
      other.id == id &&
      other.name == name &&
      other.ownerAccountId == ownerAccountId &&
      other.settlementPolicy == settlementPolicy;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        ownerAccountId.hashCode +
        settlementPolicy.hashCode;

  factory GroupResponse.fromJson(Map<String, dynamic> json) => _$GroupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GroupResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GroupResponseSettlementPolicyEnum {
@JsonValue(r'owner_only')
ownerOnly(r'owner_only'),
@JsonValue(r'any_member')
anyMember(r'any_member');

const GroupResponseSettlementPolicyEnum(this.value);

final String value;

@override
String toString() => value;
}


