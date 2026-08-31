//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'participant_write_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ParticipantWriteRequest {
  /// Returns a new [ParticipantWriteRequest] instance.
  ParticipantWriteRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ParticipantWriteRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory ParticipantWriteRequest.fromJson(Map<String, dynamic> json) => _$ParticipantWriteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantWriteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

