//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'account_identity_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountIdentityResponse {
  /// Returns a new [AccountIdentityResponse] instance.
  AccountIdentityResponse({

    required  this.id,

    required  this.loginName,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: true,
  )


  final Object? id;



  @JsonKey(
    
    name: r'login_name',
    required: true,
    includeIfNull: false,
  )


  final String loginName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AccountIdentityResponse &&
      other.id == id &&
      other.loginName == loginName;

    @override
    int get hashCode =>
        (id == null ? 0 : id.hashCode) +
        loginName.hashCode;

  factory AccountIdentityResponse.fromJson(Map<String, dynamic> json) => _$AccountIdentityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AccountIdentityResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

