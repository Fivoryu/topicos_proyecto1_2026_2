//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'rename_participant_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RenameParticipantRequest {
  /// Returns a new [RenameParticipantRequest] instance.
  RenameParticipantRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RenameParticipantRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory RenameParticipantRequest.fromJson(Map<String, dynamic> json) => _$RenameParticipantRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RenameParticipantRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

