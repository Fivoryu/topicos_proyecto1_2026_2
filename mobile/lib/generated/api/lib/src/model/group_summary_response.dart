//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'group_summary_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GroupSummaryResponse {
  /// Returns a new [GroupSummaryResponse] instance.
  GroupSummaryResponse({

     this.expensesCount,

    required  this.id,

     this.memberCount,

    required  this.name,

     this.outingsCount,

    required  this.ownerAccountId,

     this.participantsCount,

    required  this.role,

    required  this.settlementPolicy,
  });

  @JsonKey(
    
    name: r'expenses_count',
    required: false,
    includeIfNull: false,
  )


  final int? expensesCount;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'member_count',
    required: false,
    includeIfNull: false,
  )


  final int? memberCount;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'outings_count',
    required: false,
    includeIfNull: false,
  )


  final int? outingsCount;



  @JsonKey(
    
    name: r'owner_account_id',
    required: true,
    includeIfNull: false,
  )


  final String ownerAccountId;



  @JsonKey(
    
    name: r'participants_count',
    required: false,
    includeIfNull: false,
  )


  final int? participantsCount;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final GroupSummaryResponseRoleEnum role;



  @JsonKey(
    
    name: r'settlementPolicy',
    required: true,
    includeIfNull: false,
  )


  final GroupSummaryResponseSettlementPolicyEnum settlementPolicy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GroupSummaryResponse &&
      other.expensesCount == expensesCount &&
      other.id == id &&
      other.memberCount == memberCount &&
      other.name == name &&
      other.outingsCount == outingsCount &&
      other.ownerAccountId == ownerAccountId &&
      other.participantsCount == participantsCount &&
      other.role == role &&
      other.settlementPolicy == settlementPolicy;

    @override
    int get hashCode =>
        (expensesCount == null ? 0 : expensesCount.hashCode) +
        id.hashCode +
        (memberCount == null ? 0 : memberCount.hashCode) +
        name.hashCode +
        (outingsCount == null ? 0 : outingsCount.hashCode) +
        ownerAccountId.hashCode +
        (participantsCount == null ? 0 : participantsCount.hashCode) +
        role.hashCode +
        settlementPolicy.hashCode;

  factory GroupSummaryResponse.fromJson(Map<String, dynamic> json) => _$GroupSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSummaryResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GroupSummaryResponseRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'member')
member(r'member');

const GroupSummaryResponseRoleEnum(this.value);

final String value;

@override
String toString() => value;
}



enum GroupSummaryResponseSettlementPolicyEnum {
@JsonValue(r'owner_only')
ownerOnly(r'owner_only'),
@JsonValue(r'any_member')
anyMember(r'any_member');

const GroupSummaryResponseSettlementPolicyEnum(this.value);

final String value;

@override
String toString() => value;
}


