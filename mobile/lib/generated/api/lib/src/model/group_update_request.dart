//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'group_update_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GroupUpdateRequest {
  /// Returns a new [GroupUpdateRequest] instance.
  GroupUpdateRequest({

    required  this.settlementPolicy,
  });

  @JsonKey(
    
    name: r'settlementPolicy',
    required: true,
    includeIfNull: false,
  )


  final GroupUpdateRequestSettlementPolicyEnum settlementPolicy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GroupUpdateRequest &&
      other.settlementPolicy == settlementPolicy;

    @override
    int get hashCode =>
        settlementPolicy.hashCode;

  factory GroupUpdateRequest.fromJson(Map<String, dynamic> json) => _$GroupUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GroupUpdateRequestSettlementPolicyEnum {
@JsonValue(r'owner_only')
ownerOnly(r'owner_only'),
@JsonValue(r'any_member')
anyMember(r'any_member');

const GroupUpdateRequestSettlementPolicyEnum(this.value);

final String value;

@override
String toString() => value;
}


