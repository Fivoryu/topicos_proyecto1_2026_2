//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'join_code_consume_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinCodeConsumeRequest {
  /// Returns a new [JoinCodeConsumeRequest] instance.
  JoinCodeConsumeRequest({

    required  this.code,

     this.newParticipantName,

     this.participantId,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'new_participant_name',
    required: false,
    includeIfNull: false,
  )


  final String? newParticipantName;



  @JsonKey(
    
    name: r'participant_id',
    required: false,
    includeIfNull: false,
  )


  final String? participantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinCodeConsumeRequest &&
      other.code == code &&
      other.newParticipantName == newParticipantName &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        code.hashCode +
        (newParticipantName == null ? 0 : newParticipantName.hashCode) +
        (participantId == null ? 0 : participantId.hashCode);

  factory JoinCodeConsumeRequest.fromJson(Map<String, dynamic> json) => _$JoinCodeConsumeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCodeConsumeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

