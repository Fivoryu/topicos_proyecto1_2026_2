//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'join_code_status.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinCodeStatus {
  /// Returns a new [JoinCodeStatus] instance.
  JoinCodeStatus({

    required  this.active,

    required  this.generation,

    required  this.groupId,
  });

  @JsonKey(
    
    name: r'active',
    required: true,
    includeIfNull: false,
  )


  final bool active;



  @JsonKey(
    
    name: r'generation',
    required: true,
    includeIfNull: true,
  )


  final int? generation;



  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinCodeStatus &&
      other.active == active &&
      other.generation == generation &&
      other.groupId == groupId;

    @override
    int get hashCode =>
        active.hashCode +
        (generation == null ? 0 : generation.hashCode) +
        groupId.hashCode;

  factory JoinCodeStatus.fromJson(Map<String, dynamic> json) => _$JoinCodeStatusFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCodeStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

