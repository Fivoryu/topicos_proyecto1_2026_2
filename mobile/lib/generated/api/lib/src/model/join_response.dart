//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'join_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinResponse {
  /// Returns a new [JoinResponse] instance.
  JoinResponse({

    required  this.accountId,

    required  this.groupId,

    required  this.participantId,
  });

  @JsonKey(
    
    name: r'account_id',
    required: true,
    includeIfNull: false,
  )


  final String accountId;



  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;



  @JsonKey(
    
    name: r'participant_id',
    required: true,
    includeIfNull: false,
  )


  final String participantId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinResponse &&
      other.accountId == accountId &&
      other.groupId == groupId &&
      other.participantId == participantId;

    @override
    int get hashCode =>
        accountId.hashCode +
        groupId.hashCode +
        participantId.hashCode;

  factory JoinResponse.fromJson(Map<String, dynamic> json) => _$JoinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

