//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'group_create_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GroupCreateRequest {
  /// Returns a new [GroupCreateRequest] instance.
  GroupCreateRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GroupCreateRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory GroupCreateRequest.fromJson(Map<String, dynamic> json) => _$GroupCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupCreateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

