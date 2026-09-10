//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'member_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberResponse {
  /// Returns a new [MemberResponse] instance.
  MemberResponse({

    required  this.accountId,

    required  this.active,

    required  this.loginName,

     this.participantId,

    required  this.role,
  });

  @JsonKey(
    
    name: r'account_id',
    required: true,
    includeIfNull: false,
  )


  final String accountId;



  @JsonKey(
    
    name: r'active',
    required: true,
    includeIfNull: false,
  )


  final bool active;



  @JsonKey(
    
    name: r'login_name',
    required: true,
    includeIfNull: false,
  )


  final String loginName;



  @JsonKey(
    
    name: r'participant_id',
    required: false,
    includeIfNull: false,
  )


  final String? participantId;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final MemberResponseRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemberResponse &&
      other.accountId == accountId &&
      other.active == active &&
      other.loginName == loginName &&
      other.participantId == participantId &&
      other.role == role;

    @override
    int get hashCode =>
        accountId.hashCode +
        active.hashCode +
        loginName.hashCode +
        (participantId == null ? 0 : participantId.hashCode) +
        role.hashCode;

  factory MemberResponse.fromJson(Map<String, dynamic> json) => _$MemberResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemberResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemberResponseRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'member')
member(r'member');

const MemberResponseRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


