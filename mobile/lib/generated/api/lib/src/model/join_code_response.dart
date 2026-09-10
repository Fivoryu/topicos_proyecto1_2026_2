//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'join_code_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinCodeResponse {
  /// Returns a new [JoinCodeResponse] instance.
  JoinCodeResponse({

    required  this.code,

    required  this.generation,

    required  this.groupId,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'generation',
    required: true,
    includeIfNull: false,
  )


  final int generation;



  @JsonKey(
    
    name: r'group_id',
    required: true,
    includeIfNull: false,
  )


  final String groupId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinCodeResponse &&
      other.code == code &&
      other.generation == generation &&
      other.groupId == groupId;

    @override
    int get hashCode =>
        code.hashCode +
        generation.hashCode +
        groupId.hashCode;

  factory JoinCodeResponse.fromJson(Map<String, dynamic> json) => _$JoinCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCodeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

