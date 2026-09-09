//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'outing_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OutingResponse {
  /// Returns a new [OutingResponse] instance.
  OutingResponse({

    required  this.archived,

     this.archivedAt,

     this.createdAt,

    required  this.groupId,

    required  this.id,

    required  this.name,

     this.updatedAt,
  });

  @JsonKey(
    
    name: r'archived',
    required: true,
    includeIfNull: false,
  )


  final bool archived;



  @JsonKey(
    
    name: r'archived_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? archivedAt;



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



  @JsonKey(
    
    name: r'updated_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OutingResponse &&
      other.archived == archived &&
      other.archivedAt == archivedAt &&
      other.createdAt == createdAt &&
      other.groupId == groupId &&
      other.id == id &&
      other.name == name &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        archived.hashCode +
        (archivedAt == null ? 0 : archivedAt.hashCode) +
        (createdAt == null ? 0 : createdAt.hashCode) +
        groupId.hashCode +
        id.hashCode +
        name.hashCode +
        (updatedAt == null ? 0 : updatedAt.hashCode);

  factory OutingResponse.fromJson(Map<String, dynamic> json) => _$OutingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OutingResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

