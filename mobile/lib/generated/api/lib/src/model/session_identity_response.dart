//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi/src/model/account_identity_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_identity_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessionIdentityResponse {
  /// Returns a new [SessionIdentityResponse] instance.
  SessionIdentityResponse({

    required  this.account,

    required  this.activeGroupId,

    required  this.expiresAt,

    required  this.role,
  });

  @JsonKey(
    
    name: r'account',
    required: true,
    includeIfNull: false,
  )


  final AccountIdentityResponse account;



  @JsonKey(
    
    name: r'active_group_id',
    required: true,
    includeIfNull: true,
  )


  final Object? activeGroupId;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final SessionIdentityResponseRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SessionIdentityResponse &&
      other.account == account &&
      other.activeGroupId == activeGroupId &&
      other.expiresAt == expiresAt &&
      other.role == role;

    @override
    int get hashCode =>
        account.hashCode +
        (activeGroupId == null ? 0 : activeGroupId.hashCode) +
        expiresAt.hashCode +
        role.hashCode;

  factory SessionIdentityResponse.fromJson(Map<String, dynamic> json) => _$SessionIdentityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionIdentityResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SessionIdentityResponseRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'member')
member(r'member');

const SessionIdentityResponseRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


