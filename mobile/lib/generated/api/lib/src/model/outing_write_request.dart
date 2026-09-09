//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'outing_write_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OutingWriteRequest {
  /// Returns a new [OutingWriteRequest] instance.
  OutingWriteRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OutingWriteRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory OutingWriteRequest.fromJson(Map<String, dynamic> json) => _$OutingWriteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OutingWriteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

