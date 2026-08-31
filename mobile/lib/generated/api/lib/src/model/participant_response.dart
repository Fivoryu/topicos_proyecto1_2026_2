//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'participant_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ParticipantResponse {
  /// Returns a new [ParticipantResponse] instance.
  ParticipantResponse({

    required  this.archived,

     this.createdAt,

    required  this.groupId,

    required  this.id,

    required  this.name,
  });

  @JsonKey(
    
    name: r'archived',
    required: true,
    includeIfNull: false,
  )


  final bool archived;



  @JsonKey(
    
    name: r'created_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? createdAt;



  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ParticipantResponse &&
      other.archived == archived &&
      other.createdAt == createdAt &&
      other.groupId == groupId &&
      other.id == id &&
      other.name == name;

    @override
    int get hashCode =>
        archived.hashCode +
        (createdAt == null ? 0 : createdAt.hashCode) +
        groupId.hashCode +
        id.hashCode +
        name.hashCode;

  factory ParticipantResponse.fromJson(Map<String, dynamic> json) => _$ParticipantResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

